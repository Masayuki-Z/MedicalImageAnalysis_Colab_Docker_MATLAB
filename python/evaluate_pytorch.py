"""Evaluate one validation-selected PyTorch checkpoint on the unseen test split."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import torch
from PIL import Image
from torch.utils.data import DataLoader

from pytorch_pipeline import (
    LGGDataset,
    UNet,
    collect_pairs,
    model_configuration,
    validate_pairs,
    save_json,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-dir", type=Path, default=Path("data/lgg-mri-segmentation/kaggle_3m"))
    parser.add_argument("--output-dir", type=Path, default=Path("model_output/pytorch"))
    parser.add_argument("--checkpoint", type=Path, default=None)
    parser.add_argument("--split-file", type=Path, default=None)
    parser.add_argument("--threshold", type=float, default=0.5)
    parser.add_argument("--batch-size", type=int, default=4)
    parser.add_argument("--num-examples", type=int, default=6)
    return parser.parse_args()


def create_comparison_panel(
    flair: np.ndarray, ground_truth: np.ndarray, prediction: np.ndarray, output_path: Path
) -> None:
    background = np.clip(flair, 0, 1)
    overlay = np.repeat(background[..., None], 3, axis=2)
    gt = ground_truth.astype(bool)
    pred = prediction.astype(bool)
    overlay[gt & ~pred] = [0, 1, 0]
    overlay[pred & ~gt] = [1, 0, 0]
    overlay[gt & pred] = [1, 1, 0]
    figure, axes = plt.subplots(1, 4, figsize=(13, 3.5))
    axes[0].imshow(background, cmap="gray", vmin=0, vmax=1)
    axes[0].set_title("FLAIR MRI")
    axes[1].imshow(gt, cmap="gray", vmin=0, vmax=1)
    axes[1].set_title("Ground truth")
    axes[2].imshow(pred, cmap="gray", vmin=0, vmax=1)
    axes[2].set_title("U-Net prediction")
    axes[3].imshow(overlay)
    axes[3].set_title("Overlay (GT green / Pred red)")
    for axis in axes:
        axis.axis("off")
    figure.tight_layout()
    figure.savefig(output_path, dpi=150, bbox_inches="tight")
    plt.close(figure)


def main() -> None:
    arguments = parse_args()
    if not 0 <= arguments.threshold <= 1:
        raise ValueError("threshold must be in [0, 1].")
    if arguments.batch_size < 1:
        raise ValueError("batch-size must be positive.")
    if arguments.num_examples < 0:
        raise ValueError("num-examples cannot be negative.")
    output_dir = arguments.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    checkpoint_path = arguments.checkpoint or output_dir / "best_unet.pth"
    if not checkpoint_path.is_file():
        raise FileNotFoundError(f"Trained checkpoint not found: {checkpoint_path}")
    checkpoint = torch.load(checkpoint_path, map_location="cpu", weights_only=True)
    if checkpoint.get("smoke_test", False):
        raise ValueError(
            "Refusing to evaluate a smoke-test checkpoint on the unseen test set."
        )
    pairs = collect_pairs(arguments.data_dir)
    dataset_report = validate_pairs(pairs)
    split_file = arguments.split_file or output_dir / "patient_split.json"
    if not split_file.is_file():
        raise FileNotFoundError(
            f"Training patient split is required for evaluation: {split_file}"
        )
    manifest = json.loads(split_file.read_text(encoding="utf-8"))
    if manifest["seed"] != checkpoint.get("seed"):
        raise ValueError("Checkpoint seed does not match the saved patient split.")
    patient_splits = manifest["patient_splits"]
    allowed_test_patients = set(patient_splits["test"])
    if not allowed_test_patients:
        raise ValueError("Test split contains no patients.")
    if allowed_test_patients & set(patient_splits["train"] + patient_splits["validation"]):
        raise ValueError("Patient overlap detected in saved split manifest.")
    test_pairs = [pair for pair in pairs if pair.patient_id in allowed_test_patients]
    if {pair.patient_id for pair in test_pairs} != allowed_test_patients:
        raise ValueError("Dataset and saved test split patient IDs do not match.")
    covered_patients: set[str] = set()
    for patient_ids in patient_splits.values():
        covered_patients.update(patient_ids)
    if covered_patients != {pair.patient_id for pair in pairs}:
        raise ValueError("Saved patient splits do not cover the current dataset.")

    model = UNet(use_checkpointing=False)
    model.load_state_dict(checkpoint["model_state_dict"], strict=True)
    model.eval()
    model_config = checkpoint.get("architecture", model_configuration())
    image_size = int(model_config["input_shape_nchw"][-1])
    dataset = LGGDataset(test_pairs, image_size=image_size, augment=False)
    loader = DataLoader(dataset, batch_size=arguments.batch_size, shuffle=False, num_workers=0)

    export_dir = output_dir / "MATLAB_Export"
    image_dir = export_dir / "images"
    ground_truth_dir = export_dir / "ground_truth"
    prediction_dir = export_dir / "predictions"
    for directory in (image_dir, ground_truth_dir, prediction_dir):
        directory.mkdir(parents=True, exist_ok=True)
    metadata_path = export_dir / "metadata.csv"
    fieldnames = [
        "patient_id",
        "slice_id",
        "image_filename",
        "ground_truth_filename",
        "prediction_filename",
        "prediction_threshold",
    ]
    examples: list[dict[str, Any]] = []
    true_positive = false_positive = false_negative = 0
    with metadata_path.open("w", newline="", encoding="utf-8") as metadata_file:
        writer = csv.DictWriter(metadata_file, fieldnames=fieldnames)
        writer.writeheader()
        with torch.inference_mode():
            offset = 0
            for images, masks in loader:
                probabilities = model(images)
                predicted = probabilities >= arguments.threshold
                actual = masks >= 0.5
                true_positive += int(torch.logical_and(predicted, actual).sum().item())
                false_positive += int(torch.logical_and(predicted, ~actual).sum().item())
                false_negative += int(torch.logical_and(~predicted, actual).sum().item())
                for index in range(images.shape[0]):
                    pair = test_pairs[offset + index]
                    stem = f"{pair.patient_id}_{pair.slice_id}"
                    image_name = f"{stem}.png"
                    ground_truth_name = f"{stem}_ground_truth.png"
                    prediction_name = f"{stem}_prediction.png"
                    with Image.open(pair.image_path) as source:
                        flair = np.asarray(source.convert("RGB"))[:, :, 1]
                    Image.fromarray(flair.astype(np.uint8)).save(image_dir / image_name)
                    Image.fromarray(actual[index, 0].numpy().astype(np.uint8) * 255).save(
                        ground_truth_dir / ground_truth_name
                    )
                    Image.fromarray(predicted[index, 0].numpy().astype(np.uint8) * 255).save(
                        prediction_dir / prediction_name
                    )
                    writer.writerow(
                        {
                            "patient_id": pair.patient_id,
                            "slice_id": pair.slice_id,
                            "image_filename": image_name,
                            "ground_truth_filename": ground_truth_name,
                            "prediction_filename": prediction_name,
                            "prediction_threshold": arguments.threshold,
                        }
                    )
                    if len(examples) < arguments.num_examples:
                        examples.append(
                            {
                                "pair": pair,
                                "flair": images[index, 0].numpy(),
                                "ground_truth": actual[index, 0].numpy(),
                                "prediction": predicted[index, 0].numpy(),
                            }
                        )
                offset += images.shape[0]

    denominator = 2 * true_positive + false_positive + false_negative
    union = true_positive + false_positive + false_negative
    metrics = {
        "evaluation": "unseen patient-level test split only",
        "threshold": arguments.threshold,
        "threshold_selected_using_test_data": False,
        "test_patient_count": len(allowed_test_patients),
        "test_image_count": len(test_pairs),
        "device": "cpu",
        "metrics": {
            "dice": 2 * true_positive / denominator if denominator else 1.0,
            "iou": true_positive / union if union else 1.0,
            "precision": true_positive / (true_positive + false_positive)
            if true_positive + false_positive
            else 1.0,
            "recall": true_positive / (true_positive + false_negative)
            if true_positive + false_negative
            else 1.0,
        },
        "pixel_counts": {
            "true_positive": true_positive,
            "false_positive": false_positive,
            "false_negative": false_negative,
        },
        "checkpoint_epoch": checkpoint.get("epoch"),
        "checkpoint_validation_dice": checkpoint.get("validation_dice"),
        "dataset_validation": dataset_report,
    }
    save_json(output_dir / "test_metrics.json", metrics)
    example_dir = output_dir / "test_examples"
    example_dir.mkdir(parents=True, exist_ok=True)
    for index, example in enumerate(examples, start=1):
        pair = example["pair"]
        create_comparison_panel(
            example["flair"],
            example["ground_truth"],
            example["prediction"],
            example_dir / f"{index:02d}_{pair.patient_id}_{pair.slice_id}.png",
        )
    save_json(
        export_dir / "export_manifest.json",
        {
            "patient_count": len(allowed_test_patients),
            "image_count": len(test_pairs),
            "threshold": arguments.threshold,
            "source": "unseen test split only",
        },
    )
    print(json.dumps(metrics, indent=2))


if __name__ == "__main__":
    main()
