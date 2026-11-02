"""Dataset, model, and metric utilities for the PyTorch LGG baseline."""

from __future__ import annotations

import json
import math
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

import numpy as np
import numpy.typing as npt
import torch
from PIL import Image
from torch import Tensor, nn
from torch.nn import functional as F
from torch.utils.checkpoint import checkpoint
from torch.utils.data import Dataset
from typing import cast

SEED = 42
IMAGE_SIZE = 256
FLAIR_CHANNEL_INDEX = 1
MASK_SUFFIX = "_mask"
SUPPORTED_EXTENSIONS = {".tif", ".tiff"}
NORMALIZATION_CONFIG = {
    "method": "per_slice_z_score",
    "input_channel": "FLAIR",
    "input_channel_index_zero_based": FLAIR_CHANNEL_INDEX,
    "source_dtype": "uint8",
    "source_scale": [0.0, 1.0],
    "resize": {"height": IMAGE_SIZE, "width": IMAGE_SIZE, "image_interpolation": "bilinear",
               "mask_interpolation": "nearest", "only_when_needed": True},
    "mean": "computed independently per 2D FLAIR slice after resize",
    "standard_deviation": "population standard deviation (ddof=0)",
    "epsilon": 1e-6,
    "zero_standard_deviation": "centered values divided by 1.0, resulting in zeros",
}


@dataclass(frozen=True)
class ImageMaskPair:
    image_path: Path
    mask_path: Path
    patient_id: str
    slice_id: str


def collect_pairs(data_dir: str | Path) -> list[ImageMaskPair]:
    """Find TIFF image-mask pairs and derive patient IDs from patient folders."""
    root = Path(data_dir)
    if not root.is_dir():
        raise FileNotFoundError(f"Dataset directory does not exist: {root}")
    pairs: list[ImageMaskPair] = []
    for mask_path in sorted(root.rglob("*_mask.*")):
        if mask_path.suffix.lower() not in SUPPORTED_EXTENSIONS:
            continue
        image_name = mask_path.name[: -len(MASK_SUFFIX + mask_path.suffix)] + mask_path.suffix
        image_path = mask_path.with_name(image_name)
        if not image_path.is_file():
            raise FileNotFoundError(f"Missing image paired with mask: {mask_path}")
        pairs.append(
            ImageMaskPair(
                image_path=image_path,
                mask_path=mask_path,
                patient_id=mask_path.parent.name,
                slice_id=mask_path.stem[: -len(MASK_SUFFIX)],
            )
        )
    if not pairs:
        raise FileNotFoundError(
            f"No TIFF image-mask pairs found beneath {root}; expected *_mask.tif[f]."
        )
    return pairs


def validate_pairs(pairs: Sequence[ImageMaskPair]) -> dict[str, Any]:
    """Read every pair and validate channels, spatial alignment, and binary masks."""
    if not pairs:
        raise ValueError("At least one image-mask pair is required.")
    image_shapes: set[tuple[int, ...]] = set()
    mask_shapes: set[tuple[int, ...]] = set()
    mask_values: set[int] = set()
    patients: set[str] = set()
    for pair in pairs:
        with Image.open(pair.image_path) as source:
            image = np.asarray(source)
        with Image.open(pair.mask_path) as source:
            mask = np.asarray(source)
        if image.ndim != 3 or image.shape[2] < 3 or image.dtype != np.uint8:
            raise ValueError(
                f"Expected uint8 RGB MRI in {pair.image_path}, got {image.shape} {image.dtype}."
            )
        if mask.ndim != 2 or mask.shape != image.shape[:2]:
            raise ValueError(
                f"Image-mask alignment error for {pair.image_path} and {pair.mask_path}: "
                f"{image.shape[:2]} vs {mask.shape}."
            )
        unique_values = np.unique(mask)
        if not set(unique_values.tolist()).issubset({0, 1, 255}):
            raise ValueError(
                f"Mask contains non-binary values in {pair.mask_path}: {unique_values[:16]}."
            )
        image_shapes.add(image.shape)
        mask_shapes.add(mask.shape)
        mask_values.update(int(value) for value in unique_values)
        patients.add(pair.patient_id)
    return {
        "pair_count": len(pairs),
        "patient_count": len(patients),
        "image_shapes": [list(shape) for shape in sorted(image_shapes)],
        "mask_shapes": [list(shape) for shape in sorted(mask_shapes)],
        "mask_values": sorted(mask_values),
    }


def split_patient_ids(
    patient_ids: Sequence[str], seed: int = SEED
) -> dict[str, list[str]]:
    """Deterministically assign patients to 70/15/15 splits using largest remainders."""
    unique_ids = sorted(set(patient_ids))
    if len(unique_ids) < 3:
        raise ValueError("At least three unique patients are required for three splits.")
    rng = random.Random(seed)
    rng.shuffle(unique_ids)
    raw_counts = [0.70 * len(unique_ids), 0.15 * len(unique_ids), 0.15 * len(unique_ids)]
    counts = [math.floor(value) for value in raw_counts]
    remainder = len(unique_ids) - sum(counts)
    order = sorted(
        range(3),
        key=lambda index: (raw_counts[index] - counts[index], -index),
        reverse=True,
    )
    for index in order[:remainder]:
        counts[index] += 1
    if any(count == 0 for count in counts):
        raise ValueError("The patient count is too small to populate all splits.")
    train_end = counts[0]
    validation_end = train_end + counts[1]
    return {
        "train": sorted(unique_ids[:train_end]),
        "validation": sorted(unique_ids[train_end:validation_end]),
        "test": sorted(unique_ids[validation_end:]),
    }


def make_split_manifest(
    pairs: Sequence[ImageMaskPair], seed: int = SEED
) -> dict[str, Any]:
    patient_splits = split_patient_ids([pair.patient_id for pair in pairs], seed)
    manifest: dict[str, Any] = {
        "seed": seed,
        "method": "deterministic patient-folder split; largest-remainder allocation",
        "requested_proportions": {"train": 0.70, "validation": 0.15, "test": 0.15},
        "patient_splits": patient_splits,
        "splits": {},
        "overlap_check": {},
    }
    split_sets = {name: set(ids) for name, ids in patient_splits.items()}
    for name, patient_set in split_sets.items():
        subset = [pair for pair in pairs if pair.patient_id in patient_set]
        manifest["splits"][name] = {
            "patient_count": len(patient_set),
            "image_count": len(subset),
            "patients": patient_splits[name],
        }
    names = list(split_sets)
    overlaps = {
        f"{names[i]}_{names[j]}": sorted(split_sets[names[i]] & split_sets[names[j]])
        for i in range(len(names))
        for j in range(i + 1, len(names))
    }
    manifest["overlap_check"] = overlaps
    if any(overlaps.values()):
        raise RuntimeError(f"Patient leakage detected: {overlaps}")
    covered_patients: set[str] = set()
    for patient_set in split_sets.values():
        covered_patients.update(patient_set)
    if covered_patients != {pair.patient_id for pair in pairs}:
        raise RuntimeError("Patient split does not cover every patient.")
    return manifest


def load_flair_and_mask(
    pair: ImageMaskPair, image_size: int = IMAGE_SIZE
) -> tuple[npt.NDArray[np.float32], npt.NDArray[np.float32]]:
    """Load documented RGB channel 2 as normalized float32 FLAIR and binary mask."""
    if image_size < 1:
        raise ValueError("image_size must be a positive integer.")
    with Image.open(pair.image_path) as source:
        rgb = np.asarray(source.convert("RGB"))
    if rgb.ndim != 3 or rgb.shape[2] != 3:
        raise ValueError(f"Expected RGB image: {pair.image_path}")
    flair = rgb[:, :, FLAIR_CHANNEL_INDEX].astype(np.float32) / np.float32(255.0)
    with Image.open(pair.mask_path) as source:
        mask_image = source.convert("L")
        if mask_image.size != (image_size, image_size):
            mask_image = mask_image.resize((image_size, image_size), Image.Resampling.NEAREST)
        mask = np.asarray(mask_image, dtype=np.uint8)
    if flair.shape != (image_size, image_size):
        flair_image = Image.fromarray(flair, mode="F")
        flair = np.asarray(
            flair_image.resize((image_size, image_size), Image.Resampling.BILINEAR),
            dtype=np.float32,
        )
    mask = (mask > 0).astype(np.float32)
    return flair.astype(np.float32, copy=False), mask


def normalize_flair(
    flair: npt.NDArray[np.float32], epsilon: float = 1e-6
) -> tuple[npt.NDArray[np.float32], float, float]:
    """Apply per-slice population z-score normalization with safe constant handling."""
    image = np.asarray(flair, dtype=np.float32)
    if image.ndim != 2 or image.size == 0 or not np.isfinite(image).all():
        raise ValueError("FLAIR input must be a finite, nonempty two-dimensional array.")
    mean = float(image.mean(dtype=np.float64))
    std = float(image.std(dtype=np.float64))
    denominator = std if std >= epsilon else 1.0
    normalized = (image - np.float32(mean)) / np.float32(denominator)
    return normalized.astype(np.float32, copy=False), mean, std


def _apply_training_augmentation(image: Tensor, mask: Tensor, max_angle: float) -> tuple[Tensor, Tensor]:
    if torch.rand(()) < 0.5:
        image = torch.flip(image, dims=(-1,))
        mask = torch.flip(mask, dims=(-1,))
    angle = (torch.rand(()) * 2 - 1) * max_angle
    radians = angle * (math.pi / 180.0)
    cosine = torch.cos(radians)
    sine = torch.sin(radians)
    theta = torch.stack(
        (
            torch.stack((cosine, -sine, torch.zeros_like(angle))),
            torch.stack((sine, cosine, torch.zeros_like(angle))),
        )
    ).unsqueeze(0)
    grid = F.affine_grid(
        theta, [1, 1, image.shape[-2], image.shape[-1]], align_corners=False
    )
    image = F.grid_sample(
        image.unsqueeze(0), grid, mode="bilinear", padding_mode="zeros", align_corners=False
    ).squeeze(0)
    mask = F.grid_sample(
        mask.unsqueeze(0), grid, mode="nearest", padding_mode="zeros", align_corners=False
    ).squeeze(0)
    return image, (mask > 0.5).to(mask.dtype)


class LGGDataset(Dataset[tuple[Tensor, Tensor]]):
    """Single-channel FLAIR slices with paired binary masks."""

    def __init__(
        self,
        pairs: Sequence[ImageMaskPair],
        image_size: int = IMAGE_SIZE,
        augment: bool = False,
        max_rotation_degrees: float = 10.0,
    ) -> None:
        if not pairs:
            raise ValueError("Dataset split cannot be empty.")
        if not math.isfinite(max_rotation_degrees) or not 0 <= max_rotation_degrees <= 45:
            raise ValueError("max_rotation_degrees must be in [0, 45].")
        self.pairs = list(pairs)
        self.image_size = image_size
        self.augment = augment
        self.max_rotation_degrees = max_rotation_degrees

    def __len__(self) -> int:
        return len(self.pairs)

    def __getitem__(self, index: int) -> tuple[Tensor, Tensor]:
        flair, mask = load_flair_and_mask(self.pairs[index], self.image_size)
        normalized, _, _ = normalize_flair(flair)
        image_tensor = torch.from_numpy(normalized).unsqueeze(0)
        mask_tensor = torch.from_numpy(mask).unsqueeze(0)
        if self.augment:
            image_tensor, mask_tensor = _apply_training_augmentation(
                image_tensor, mask_tensor, self.max_rotation_degrees
            )
        return image_tensor.contiguous(), mask_tensor.contiguous()


class DoubleConv(nn.Module):
    def __init__(self, input_channels: int, output_channels: int) -> None:
        super().__init__()
        self.layers = nn.Sequential(
            nn.Conv2d(input_channels, output_channels, kernel_size=3, padding=1),
            nn.ReLU(inplace=True),
            nn.Conv2d(output_channels, output_channels, kernel_size=3, padding=1),
            nn.ReLU(inplace=True),
        )

    def forward(self, inputs: Tensor) -> Tensor:
        return self.layers(inputs)


class UNet(nn.Module):
    """Original four-level 2D U-Net with configurable base width for unit tests."""

    def __init__(self, in_channels: int = 1, base_channels: int = 64, use_checkpointing: bool = False):
        super().__init__()
        if in_channels != 1:
            raise ValueError("This baseline expects one FLAIR input channel.")
        if base_channels < 1:
            raise ValueError("base_channels must be positive.")
        self.in_channels = in_channels
        self.base_channels = base_channels
        self.use_checkpointing = use_checkpointing
        channels = [base_channels * (2**index) for index in range(5)]
        encoder_inputs = [in_channels, *channels[:-2]]
        encoder_outputs = channels[:-1]
        self.encoders = nn.ModuleList(
            [
                DoubleConv(input_channels, output_channels)
                for input_channels, output_channels in zip(encoder_inputs, encoder_outputs)
            ]
        )
        self.bottleneck = DoubleConv(channels[3], channels[4])
        self.pools = nn.ModuleList(nn.MaxPool2d(2) for _ in range(4))
        self.upconvs = nn.ModuleList(
            nn.ConvTranspose2d(channels[index + 1], channels[index], kernel_size=2, stride=2)
            for index in reversed(range(4))
        )
        self.decoders = nn.ModuleList(
            DoubleConv(channels[index] * 2, channels[index])
            for index in reversed(range(4))
        )
        self.output = nn.Conv2d(base_channels, 1, kernel_size=1)

    def _block(self, block: nn.Module, inputs: Tensor) -> Tensor:
        if self.use_checkpointing and self.training and torch.is_grad_enabled():
            return cast(Tensor, checkpoint(block, inputs, use_reentrant=False))
        return block(inputs)

    def forward(self, inputs: Tensor) -> Tensor:
        if inputs.ndim != 4 or inputs.shape[1] != 1:
            raise ValueError("Expected input tensor shaped [batch, 1, height, width].")
        if inputs.shape[-2] % 16 or inputs.shape[-1] % 16:
            raise ValueError("Input height and width must be divisible by 16.")
        skips: list[Tensor] = []
        current = inputs
        for pool, encoder in zip(self.pools, self.encoders):
            current = self._block(encoder, current)
            skips.append(current)
            current = pool(current)
        current = self._block(self.bottleneck, current)
        for upconv, decoder, skip in zip(self.upconvs, self.decoders, reversed(skips)):
            current = upconv(current)
            current = torch.cat((skip, current), dim=1)
            current = self._block(decoder, current)
        return torch.sigmoid(self.output(current))


def bce_dice_loss(probabilities: Tensor, targets: Tensor, smooth: float = 1.0) -> Tensor:
    """Binary cross entropy plus soft Dice loss."""
    if probabilities.shape != targets.shape:
        raise ValueError("Prediction and target tensors must have the same shape.")
    bce = F.binary_cross_entropy(probabilities, targets)
    intersection = torch.sum(probabilities * targets)
    dice = (2 * intersection + smooth) / (
        torch.sum(probabilities) + torch.sum(targets) + smooth
    )
    return bce + (1 - dice)


def binary_metrics(probabilities: Tensor, targets: Tensor, threshold: float = 0.5) -> dict[str, float]:
    """Compute pixel-pooled Dice, IoU, precision, and recall."""
    with torch.no_grad():
        if probabilities.shape != targets.shape:
            raise ValueError("Prediction and target tensors must have the same shape.")
        if not 0 <= threshold <= 1:
            raise ValueError("threshold must be in [0, 1].")
        predicted = probabilities >= threshold
        actual = targets >= 0.5
        tp = torch.logical_and(predicted, actual).sum().item()
        fp = torch.logical_and(predicted, ~actual).sum().item()
        fn = torch.logical_and(~predicted, actual).sum().item()
    dice = (2 * tp) / (2 * tp + fp + fn) if 2 * tp + fp + fn else 1.0
    iou = tp / (tp + fp + fn) if tp + fp + fn else 1.0
    precision = tp / (tp + fp) if tp + fp else 1.0
    recall = tp / (tp + fn) if tp + fn else 1.0
    return {
        "dice": float(dice),
        "iou": float(iou),
        "precision": float(precision),
        "recall": float(recall),
        "true_positive_pixels": int(tp),
        "false_positive_pixels": int(fp),
        "false_negative_pixels": int(fn),
    }


def save_json(path: str | Path, payload: dict[str, Any]) -> None:
    Path(path).write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")


def model_configuration(image_size: int = IMAGE_SIZE) -> dict[str, Any]:
    return {
        "architecture": "original_2d_unet",
        "input_channels": 1,
        "encoder_channels": [64, 128, 256, 512],
        "bottleneck_channels": 1024,
        "decoder_channels": [512, 256, 128, 64],
        "output_channels": 1,
        "output_activation": "sigmoid",
        "input_shape_nchw": [1, 1, image_size, image_size],
        "output_shape_nchw": [1, 1, image_size, image_size],
        "probability_threshold": 0.5,
    }
