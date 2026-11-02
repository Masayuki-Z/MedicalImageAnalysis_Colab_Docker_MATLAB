"""MATLAB bridge for the audited FLAIR preprocessing and ONNX Runtime model."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import numpy as np
import numpy.typing as npt
import onnxruntime as ort
from PIL import Image

from pytorch_pipeline import IMAGE_SIZE, normalize_flair

_SESSIONS: dict[tuple[str, int], ort.InferenceSession] = {}


def _session_for(model_path: str | Path) -> ort.InferenceSession:
    path = Path(model_path).expanduser().resolve(strict=True)
    if path.suffix.lower() != ".onnx":
        raise ValueError(f"Expected an ONNX model file, got: {path}")
    cache_key = (str(path), path.stat().st_mtime_ns)
    if cache_key not in _SESSIONS:
        _SESSIONS.clear()
        _SESSIONS[cache_key] = ort.InferenceSession(
            str(path), providers=["CPUExecutionProvider"]
        )
    return _SESSIONS[cache_key]


def _shape_is_model_input(shape: list[Any]) -> bool:
    return (
        len(shape) == 4
        and shape[1:] == [1, IMAGE_SIZE, IMAGE_SIZE]
        and (shape[0] is None or isinstance(shape[0], str) or shape[0] == 1)
    )


def get_model_metadata_json(model_path: str | Path) -> str:
    """Return inspected input/output signature and provider as JSON."""
    session = _session_for(model_path)
    inputs = session.get_inputs()
    outputs = session.get_outputs()
    if len(inputs) != 1 or len(outputs) != 1:
        raise ValueError(
            f"Expected one ONNX input and output; found {len(inputs)} and {len(outputs)}."
        )
    input_shape = list(inputs[0].shape)
    output_shape = list(outputs[0].shape)
    if not _shape_is_model_input(input_shape) or not _shape_is_model_input(output_shape):
        raise ValueError(
            "ONNX signature must be dynamic-batch float32 NCHW [N,1,256,256]; "
            f"found input {input_shape} and output {output_shape}."
        )
    if inputs[0].type != "tensor(float)" or outputs[0].type != "tensor(float)":
        raise ValueError(
            f"ONNX input and output must be float32; found {inputs[0].type} and {outputs[0].type}."
        )
    return json.dumps(
        {
            "model_path": str(Path(model_path).resolve()),
            "input_name": inputs[0].name,
            "output_name": outputs[0].name,
            "input_shape_nchw": input_shape,
            "output_shape_nchw": output_shape,
            "input_type": inputs[0].type,
            "output_type": outputs[0].type,
            "providers": session.get_providers(),
            "onnxruntime_version": ort.__version__,
            "preprocessing": {
                "source_channel": "RGB channel index 1 (MATLAB channel 2); grayscale is treated as selected FLAIR",
                "resize": [IMAGE_SIZE, IMAGE_SIZE],
                "normalization": "per-slice population z-score after float32 scale to [0,1]",
                "epsilon": 1e-6,
                "threshold": 0.5,
            },
        },
        sort_keys=True,
    )


def preprocess_flair_plane(
    flair_plane: npt.ArrayLike,
) -> tuple[npt.NDArray[np.float32], float, float, list[int]]:
    """Match load_flair_and_mask preprocessing for one already-selected FLAIR plane."""
    source = np.asarray(flair_plane)
    if source.ndim != 2 or source.size == 0:
        raise ValueError("FLAIR plane must be a nonempty two-dimensional array.")
    if source.dtype == np.uint8:
        flair = source.astype(np.float32) / np.float32(255.0)
    elif np.issubdtype(source.dtype, np.floating):
        flair = np.asarray(source, dtype=np.float32)
        if not np.isfinite(flair).all() or np.any(flair < 0) or np.any(flair > 1):
            raise ValueError("Floating-point FLAIR values must be finite and in [0, 1].")
    else:
        raise ValueError("FLAIR plane must be uint8 or floating-point in [0, 1].")
    original_shape = [int(value) for value in flair.shape]
    if flair.shape != (IMAGE_SIZE, IMAGE_SIZE):
        flair = np.asarray(
            Image.fromarray(flair, mode="F").resize(
                (IMAGE_SIZE, IMAGE_SIZE), Image.Resampling.BILINEAR
            ),
            dtype=np.float32,
        )
    normalized, mean, standard_deviation = normalize_flair(flair)
    input_nchw = np.ascontiguousarray(normalized[None, None, :, :], dtype=np.float32)
    if input_nchw.shape != (1, 1, IMAGE_SIZE, IMAGE_SIZE):
        raise RuntimeError(f"Unexpected preprocessed input shape: {input_nchw.shape}")
    return input_nchw, mean, standard_deviation, original_shape


def run_onnx_inference(
    model_path: str | Path, input_nchw: npt.ArrayLike
) -> npt.NDArray[np.float32]:
    """Run one preprocessed FLAIR slice and return a validated NCHW probability map."""
    model_input = np.asarray(input_nchw, dtype=np.float32)
    expected_shape = (1, 1, IMAGE_SIZE, IMAGE_SIZE)
    if model_input.shape != expected_shape:
        raise ValueError(f"Input must have shape {expected_shape}; got {model_input.shape}.")
    if not np.isfinite(model_input).all():
        raise ValueError("ONNX input must contain only finite values.")
    session = _session_for(model_path)
    input_meta = session.get_inputs()
    output_meta = session.get_outputs()
    if len(input_meta) != 1 or len(output_meta) != 1:
        raise ValueError("ONNX model must have exactly one input and one output.")
    outputs = session.run(
        [output_meta[0].name], {input_meta[0].name: model_input}
    )
    probabilities = np.asarray(outputs[0], dtype=np.float32)
    if probabilities.shape != expected_shape:
        raise RuntimeError(
            f"ONNX output must have shape {expected_shape}; got {probabilities.shape}."
        )
    if not np.isfinite(probabilities).all():
        raise RuntimeError("ONNX output contains non-finite probability values.")
    if np.any(probabilities < 0) or np.any(probabilities > 1):
        raise RuntimeError("ONNX output probabilities must be in [0, 1].")
    return probabilities
