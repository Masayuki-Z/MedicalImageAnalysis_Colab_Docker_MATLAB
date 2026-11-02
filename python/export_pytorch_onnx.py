"""Export a validation-selected PyTorch checkpoint and compare ONNX Runtime outputs."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
import torch
from torch.utils.data import DataLoader

from pytorch_pipeline import LGGDataset, UNet, collect_pairs, model_configuration, save_json


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--checkpoint", type=Path, default=Path("model_output/pytorch/best_unet.pth"))
    parser.add_argument("--data-dir", type=Path, default=Path("data/lgg-mri-segmentation/kaggle_3m"))
    parser.add_argument("--split-file", type=Path, default=Path("model_output/pytorch/patient_split.json"))
    parser.add_argument("--output", type=Path, default=Path("model_output/pytorch/unet_model.onnx"))
    parser.add_argument("--parity-report", type=Path, default=None)
    parser.add_argument("--samples", type=int, default=5)
    parser.add_argument("--atol", type=float, default=1e-5)
    parser.add_argument("--rtol", type=float, default=1e-4)
    return parser.parse_args()


def main() -> None:
    arguments = parse_args()
    if arguments.samples < 1:
        raise ValueError("samples must be positive.")
    if arguments.atol < 0 or arguments.rtol < 0:
        raise ValueError("Numerical tolerances must be nonnegative.")
    if not arguments.checkpoint.is_file():
        raise FileNotFoundError(f"Trained checkpoint not found: {arguments.checkpoint}")
    checkpoint = torch.load(arguments.checkpoint, map_location="cpu", weights_only=True)
    if checkpoint.get("smoke_test", False):
        raise ValueError(
            "Refusing final ONNX export from a smoke-test checkpoint; train the full model first."
        )
    try:
        import onnx
        import onnxruntime as ort
    except ImportError as error:
        raise RuntimeError(
            "ONNX export requires dependencies in python/requirements-pytorch-onnx.txt."
        ) from error

    architecture = checkpoint.get("architecture", model_configuration())
    image_size = int(architecture["input_shape_nchw"][-1])
    model = UNet(use_checkpointing=False)
    model.load_state_dict(checkpoint["model_state_dict"], strict=True)
    model.eval()
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    dummy = torch.zeros(1, 1, image_size, image_size, dtype=torch.float32)
    torch.onnx.export(
        model,
        dummy,
        arguments.output,
        input_names=["flair"],
        output_names=["probability"],
        dynamic_axes={"flair": {0: "batch"}, "probability": {0: "batch"}},
        opset_version=17,
        do_constant_folding=True,
        dynamo=False,
    )
    exported_model = onnx.load(arguments.output)
    onnx.checker.check_model(exported_model)
    session = ort.InferenceSession(
        str(arguments.output), providers=["CPUExecutionProvider"]
    )
    if len(session.get_inputs()) != 1 or len(session.get_outputs()) != 1:
        raise RuntimeError("Exported model must have exactly one input and one output.")
    input_shape = session.get_inputs()[0].shape
    output_shape = session.get_outputs()[0].shape
    expected_shape = [None, 1, image_size, image_size]
    normalized_shapes = [
        [None if isinstance(value, str) or value is None else value for value in shape]
        for shape in (input_shape, output_shape)
    ]
    if normalized_shapes != [expected_shape, expected_shape]:
        raise RuntimeError(
            f"Unexpected ONNX dimensions: {normalized_shapes}; expected "
            f"{[expected_shape, expected_shape]}."
        )

    if not arguments.split_file.is_file():
        raise FileNotFoundError(f"Patient split file not found: {arguments.split_file}")
    manifest = json.loads(arguments.split_file.read_text(encoding="utf-8"))
    if manifest["seed"] != checkpoint.get("seed"):
        raise ValueError("Checkpoint seed does not match the saved patient split.")
    test_patients = set(manifest["patient_splits"]["test"])
    pairs = [pair for pair in collect_pairs(arguments.data_dir) if pair.patient_id in test_patients]
    if not pairs:
        raise RuntimeError("No unseen test samples found for parity verification.")
    dataset = LGGDataset(pairs[: arguments.samples], image_size=image_size, augment=False)
    loader = DataLoader(dataset, batch_size=1, shuffle=False, num_workers=0)

    max_absolute_error = 0.0
    max_relative_error = 0.0
    threshold = float(architecture.get("probability_threshold", 0.5))
    threshold_mismatch_pixels = 0
    verified_samples = 0
    for (images, _) in loader:
        with torch.inference_mode():
            torch_output = model(images).numpy()
        onnx_output = session.run(
            ["probability"], {"flair": images.numpy()}
        )[0]
        np.testing.assert_allclose(
            torch_output, onnx_output, atol=arguments.atol, rtol=arguments.rtol
        )
        threshold_mismatch_pixels += int(
            np.count_nonzero((torch_output >= threshold) != (onnx_output >= threshold))
        )
        difference = np.abs(torch_output - onnx_output)
        relative = difference / np.maximum(np.abs(torch_output), np.finfo(np.float32).eps)
        max_absolute_error = max(max_absolute_error, float(difference.max()))
        max_relative_error = max(max_relative_error, float(relative.max()))
        verified_samples += 1
    report = {
        "checkpoint": str(arguments.checkpoint),
        "onnx_model": str(arguments.output),
        "input_name": session.get_inputs()[0].name,
        "output_name": session.get_outputs()[0].name,
        "input_shape_nchw": normalized_shapes[0],
        "output_shape_nchw": normalized_shapes[1],
        "dtype": session.get_inputs()[0].type,
        "providers": session.get_providers(),
        "test_patients_used": sorted({pair.patient_id for pair in pairs[:verified_samples]}),
        "samples_compared": verified_samples,
        "atol": arguments.atol,
        "rtol": arguments.rtol,
        "max_absolute_error": max_absolute_error,
        "max_relative_error": max_relative_error,
        "allclose_passed": True,
        "probability_threshold": threshold,
        "thresholded_mask_mismatch_pixels": threshold_mismatch_pixels,
        "thresholded_mask_parity_passed": threshold_mismatch_pixels == 0,
        "note": "Parity check uses unseen test inputs only; no metrics or threshold were tuned.",
    }
    report_path = arguments.parity_report or arguments.output.with_name("onnx_parity.json")
    save_json(report_path, report)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
