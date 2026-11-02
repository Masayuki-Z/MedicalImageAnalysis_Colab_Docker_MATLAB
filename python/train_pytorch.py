"""Train the specified patient-split single-channel PyTorch U-Net."""

from __future__ import annotations

import argparse
import json
import random
import time
from pathlib import Path
from typing import Any

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import torch
from torch.utils.data import DataLoader, Subset

from pytorch_pipeline import (
    IMAGE_SIZE,
    NORMALIZATION_CONFIG,
    SEED,
    LGGDataset,
    UNet,
    bce_dice_loss,
    collect_pairs,
    make_split_manifest,
    model_configuration,
    save_json,
    validate_pairs,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-dir", type=Path, default=Path("data/lgg-mri-segmentation/kaggle_3m"))
    parser.add_argument("--output-dir", type=Path, default=Path("model_output/pytorch"))
    parser.add_argument("--epochs", type=int, default=50)
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--patience", type=int, default=10)
    parser.add_argument("--seed", type=int, default=SEED)
    parser.add_argument("--image-size", type=int, default=IMAGE_SIZE)
    parser.add_argument("--num-workers", type=int, default=0)
    parser.add_argument("--cpu-threads", type=int, default=2)
    parser.add_argument("--smoke-test", action="store_true", help="Run two epochs on one training and one validation slice.")
    parser.add_argument("--max-rotation-degrees", type=float, default=10.0)
    return parser.parse_args()


def set_reproducible_seed(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)
        torch.backends.cudnn.deterministic = True
        torch.backends.cudnn.benchmark = False


def pick_smoke_indices(dataset: LGGDataset, maximum: int = 1) -> list[int]:
    """Choose positive-mask training examples for a short plumbing smoke test."""
    selected: list[int] = []
    for index in range(len(dataset)):
        _, mask = dataset[index]
        if torch.count_nonzero(mask).item() > 0:
            selected.append(index)
            if len(selected) == maximum:
                break
    if not selected:
        raise RuntimeError("Smoke-test split has no positive-mask examples.")
    return selected


def run_epoch(
    model: UNet,
    loader: DataLoader,
    optimizer: torch.optim.Optimizer | None,
    device: torch.device,
) -> dict[str, float]:
    training = optimizer is not None
    model.train(training)
    total_loss = 0.0
    samples = 0
    metric_counts = torch.zeros(3, dtype=torch.float64, device=device)
    with torch.set_grad_enabled(training):
        for images, masks in loader:
            images = images.to(device, dtype=torch.float32, non_blocking=device.type == "cuda")
            masks = masks.to(device, dtype=torch.float32, non_blocking=device.type == "cuda")
            if training:
                optimizer.zero_grad(set_to_none=True)
            probabilities = model(images)
            loss = bce_dice_loss(probabilities, masks)
            if training:
                loss.backward()
                optimizer.step()
            batch_size = images.shape[0]
            total_loss += float(loss.detach().item()) * batch_size
            samples += batch_size
            predictions = probabilities >= 0.5
            targets = masks >= 0.5
            metric_counts[0] += torch.logical_and(predictions, targets).sum()
            metric_counts[1] += torch.logical_and(predictions, ~targets).sum()
            metric_counts[2] += torch.logical_and(~predictions, targets).sum()
    if samples == 0:
        raise RuntimeError("DataLoader produced no samples.")
    tp, fp, fn = (float(value.item()) for value in metric_counts)
    denominator = 2 * tp + fp + fn
    return {
        "loss": total_loss / samples,
        "dice": 2 * tp / denominator if denominator else 1.0,
        "iou": tp / (tp + fp + fn) if tp + fp + fn else 1.0,
    }


def write_history_plot(history: list[dict[str, Any]], output_path: Path) -> None:
    if not history:
        raise ValueError("Cannot plot empty training history.")
    epochs = [entry["epoch"] for entry in history]
    figure, axes = plt.subplots(1, 2, figsize=(10, 4))
    axes[0].plot(epochs, [entry["train_loss"] for entry in history], label="Training")
    axes[0].plot(epochs, [entry["validation_loss"] for entry in history], label="Validation")
    axes[0].set_title("BCE + Dice Loss")
    axes[0].set_xlabel("Epoch")
    axes[0].legend()
    axes[1].plot(epochs, [entry["validation_dice"] for entry in history], label="Validation Dice")
    axes[1].set_title("Validation Dice (threshold 0.5)")
    axes[1].set_xlabel("Epoch")
    axes[1].set_ylim(0, 1)
    axes[1].legend()
    figure.tight_layout()
    figure.savefig(output_path, dpi=150)
    plt.close(figure)


def save_checkpoint(
    path: Path,
    model: UNet,
    epoch: int,
    validation_dice: float,
    arguments: argparse.Namespace,
) -> None:
    torch.save(
        {
            "model_state_dict": model.state_dict(),
            "epoch": epoch,
            "validation_dice": validation_dice,
            "architecture": model_configuration(arguments.image_size),
            "seed": arguments.seed,
            "optimizer": "Adam",
            "learning_rate": 1e-4,
            "smoke_test": arguments.smoke_test,
        },
        path,
    )


def main() -> None:
    arguments = parse_args()
    if arguments.smoke_test:
        arguments.epochs = 2
        arguments.batch_size = 1
        arguments.num_workers = 0
        arguments.output_dir = arguments.output_dir / "smoke_test"
    if arguments.epochs < 1 or arguments.batch_size < 1 or arguments.patience < 1:
        raise ValueError("Epochs, batch size, and patience must be positive.")
    if arguments.image_size % 16:
        raise ValueError("image-size must be divisible by 16 for the four-level U-Net.")

    set_reproducible_seed(arguments.seed)
    if arguments.cpu_threads < 1:
        raise ValueError("cpu-threads must be positive.")
    torch.set_num_threads(arguments.cpu_threads)
    arguments.output_dir.mkdir(parents=True, exist_ok=True)
    pairs = collect_pairs(arguments.data_dir)
    dataset_report = validate_pairs(pairs)
    split_manifest = make_split_manifest(pairs, arguments.seed)
    save_json(arguments.output_dir / "patient_split.json", split_manifest)
    print(json.dumps(dataset_report, indent=2))
    print(
        json.dumps(
            {
                name: {
                    "patients": split_manifest["splits"][name]["patient_count"],
                    "images": split_manifest["splits"][name]["image_count"],
                }
                for name in ("train", "validation", "test")
            },
            indent=2,
        )
    )

    splits = split_manifest["patient_splits"]
    split_pairs = {
        name: [pair for pair in pairs if pair.patient_id in set(splits[name])]
        for name in ("train", "validation", "test")
    }
    training_data = LGGDataset(
        split_pairs["train"],
        arguments.image_size,
        augment=True,
        max_rotation_degrees=arguments.max_rotation_degrees,
    )
    validation_data = LGGDataset(split_pairs["validation"], arguments.image_size, augment=False)
    if arguments.smoke_test:
        training_data = Subset(training_data, pick_smoke_indices(training_data))
        validation_data = Subset(validation_data, pick_smoke_indices(validation_data))

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    use_checkpointing = device.type == "cpu"
    model = UNet(use_checkpointing=use_checkpointing).to(device)
    train_generator = torch.Generator()
    train_generator.manual_seed(arguments.seed)
    training_loader = DataLoader(
        training_data,
        batch_size=arguments.batch_size,
        shuffle=True,
        num_workers=arguments.num_workers,
        generator=train_generator,
        pin_memory=device.type == "cuda",
    )
    validation_loader = DataLoader(
        validation_data,
        batch_size=arguments.batch_size,
        shuffle=False,
        num_workers=arguments.num_workers,
        pin_memory=device.type == "cuda",
    )
    optimizer = torch.optim.Adam(model.parameters(), lr=1e-4)
    save_json(
        arguments.output_dir / "model_config.json",
        {
            **model_configuration(arguments.image_size),
            "base_channels": 64,
            "parameter_count": sum(parameter.numel() for parameter in model.parameters()),
            "optimizer": "Adam",
            "learning_rate": 1e-4,
            "batch_size": arguments.batch_size,
            "loss": "binary_cross_entropy + soft_dice_loss",
            "seed": arguments.seed,
            "activation_checkpointing": use_checkpointing,
            "device": str(device),
        },
    )
    save_json(arguments.output_dir / "normalization_config.json", NORMALIZATION_CONFIG)
    save_json(
        arguments.output_dir / "run_config.json",
        {
            "mode": "smoke_test" if arguments.smoke_test else "training",
            "epochs_requested": arguments.epochs,
            "training_samples": len(training_data),
            "validation_samples": len(validation_data),
            "test_evaluation_performed": False,
            "augmentation": {
                "horizontal_flip_probability": 0.5,
                "rotation_degrees": [-arguments.max_rotation_degrees, arguments.max_rotation_degrees],
                "image_interpolation": "bilinear",
                "mask_interpolation": "nearest",
            },
            "seed": arguments.seed,
            "device": str(device),
        },
    )

    best_dice = -1.0
    stale_epochs = 0
    history: list[dict[str, Any]] = []
    checkpoint_path = arguments.output_dir / "best_unet.pth"
    started = time.monotonic()
    for epoch in range(1, arguments.epochs + 1):
        train_metrics = run_epoch(model, training_loader, optimizer, device)
        validation_metrics = run_epoch(model, validation_loader, None, device)
        entry = {
            "epoch": epoch,
            "train_loss": train_metrics["loss"],
            "train_dice": train_metrics["dice"],
            "validation_loss": validation_metrics["loss"],
            "validation_dice": validation_metrics["dice"],
            "validation_iou": validation_metrics["iou"],
        }
        history.append(entry)
        if validation_metrics["dice"] > best_dice:
            best_dice = validation_metrics["dice"]
            stale_epochs = 0
            save_checkpoint(checkpoint_path, model, epoch, best_dice, arguments)
        else:
            stale_epochs += 1
        save_json(arguments.output_dir / "training_history.json", {"epochs": history})
        write_history_plot(history, arguments.output_dir / "training_history.png")
        print(json.dumps(entry))
        if not arguments.smoke_test and stale_epochs >= arguments.patience:
            print(f"Early stopping after {epoch} epochs; best validation Dice={best_dice:.6f}.")
            break
    if not checkpoint_path.is_file():
        raise RuntimeError("Training completed without saving a validation-selected checkpoint.")

    run_summary = {
        "mode": "smoke_test" if arguments.smoke_test else "training",
        "device": str(device),
        "cuda_available": torch.cuda.is_available(),
        "epochs_completed": len(history),
        "best_validation_dice": best_dice,
        "checkpoint": str(checkpoint_path),
        "elapsed_seconds": time.monotonic() - started,
        "test_evaluation_performed": False,
    }
    save_json(arguments.output_dir / "run_summary.json", run_summary)
    print(json.dumps(run_summary, indent=2))


if __name__ == "__main__":
    main()
