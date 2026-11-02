import tempfile
import unittest
from pathlib import Path

import numpy as np
import torch
from PIL import Image

from pytorch_pipeline import (
    ImageMaskPair,
    LGGDataset,
    UNet,
    bce_dice_loss,
    binary_metrics,
    collect_pairs,
    load_flair_and_mask,
    make_split_manifest,
    normalize_flair,
    split_patient_ids,
    validate_pairs,
)


class PyTorchPipelineTests(unittest.TestCase):
    def test_patient_split_is_deterministic_disjoint_and_70_15_15(self):
        patient_ids = [f"patient-{index:03d}" for index in range(110)]
        first = split_patient_ids(patient_ids, seed=42)
        second = split_patient_ids(patient_ids, seed=42)
        self.assertEqual(first, second)
        self.assertEqual([len(first[key]) for key in ("train", "validation", "test")], [77, 17, 16])
        sets = [set(first[key]) for key in ("train", "validation", "test")]
        self.assertFalse(sets[0] & sets[1])
        self.assertFalse(sets[0] & sets[2])
        self.assertFalse(sets[1] & sets[2])
        self.assertEqual(set.union(*sets), set(patient_ids))

    def test_split_manifest_counts_images_and_checks_overlap(self):
        pairs = [
            ImageMaskPair(
                image_path=Path(f"{patient}-{slice}.tif"),
                mask_path=Path(f"{patient}-{slice}_mask.tif"),
                patient_id=f"p{patient}",
                slice_id=str(slice),
            )
            for patient in range(20)
            for slice in range(2)
        ]
        manifest = make_split_manifest(pairs, seed=7)
        self.assertEqual(sum(manifest["splits"][name]["image_count"] for name in manifest["splits"]), 40)
        self.assertTrue(all(not values for values in manifest["overlap_check"].values()))

    def test_dataset_uses_flair_channel_and_binary_mask(self):
        with tempfile.TemporaryDirectory() as temporary:
            patient = Path(temporary) / "patient-1"
            patient.mkdir()
            image = np.zeros((32, 32, 3), dtype=np.uint8)
            image[:, :, 0] = 10
            image[:, :, 1] = 80
            image[:, :, 2] = 200
            mask = np.zeros((32, 32), dtype=np.uint8)
            mask[8:24, 9:20] = 255
            Image.fromarray(image, mode="RGB").save(patient / "slice_1.tif")
            Image.fromarray(mask, mode="L").save(patient / "slice_1_mask.tif")
            pairs = collect_pairs(temporary)
            report = validate_pairs(pairs)
            flair, binary = load_flair_and_mask(pairs[0], image_size=32)
            self.assertEqual(report["pair_count"], 1)
            self.assertEqual(flair.dtype, np.float32)
            self.assertTrue(np.allclose(flair, 80 / 255))
            self.assertEqual(set(np.unique(binary)), {0.0, 1.0})
            self.assertEqual(binary.shape, (32, 32))

    def test_zero_variance_normalization_is_finite_and_zero(self):
        normalized, mean, standard_deviation = normalize_flair(np.full((16, 16), 0.25, dtype=np.float32))
        self.assertTrue(np.isfinite(normalized).all())
        self.assertTrue(np.all(normalized == 0))
        self.assertAlmostEqual(mean, 0.25)
        self.assertEqual(standard_deviation, 0.0)

    def test_training_augmentation_keeps_mask_binary_and_aligned(self):
        with tempfile.TemporaryDirectory() as temporary:
            patient = Path(temporary) / "patient-1"
            patient.mkdir()
            image = np.zeros((64, 64, 3), dtype=np.uint8)
            image[16:48, 16:48, 1] = 200
            mask = np.zeros((64, 64), dtype=np.uint8)
            mask[16:48, 16:48] = 255
            Image.fromarray(image).save(patient / "slice.tif")
            Image.fromarray(mask).save(patient / "slice_mask.tif")
            dataset = LGGDataset(collect_pairs(temporary), image_size=64, augment=True)
            torch.manual_seed(3)
            input_tensor, mask_tensor = dataset[0]
            self.assertEqual(tuple(input_tensor.shape), (1, 64, 64))
            self.assertEqual(tuple(mask_tensor.shape), (1, 64, 64))
            self.assertTrue(torch.isfinite(input_tensor).all())
            self.assertTrue(torch.all((mask_tensor == 0) | (mask_tensor == 1)))
            self.assertGreater(torch.count_nonzero(mask_tensor).item(), 0)

    def test_unet_forward_backward_and_loss(self):
        model = UNet(base_channels=4)
        inputs = torch.randn(2, 1, 64, 64)
        targets = (torch.rand(2, 1, 64, 64) > 0.8).float()
        predictions = model(inputs)
        loss = bce_dice_loss(predictions, targets)
        loss.backward()
        self.assertEqual(tuple(predictions.shape), tuple(targets.shape))
        self.assertTrue(torch.isfinite(loss))
        self.assertIsNotNone(model.output.weight.grad)
        self.assertGreaterEqual(float(predictions.detach().min()), 0)
        self.assertLessEqual(float(predictions.detach().max()), 1)

    def test_metrics_use_fixed_threshold(self):
        targets = torch.tensor([[[[0.0, 1.0], [1.0, 0.0]]]])
        probabilities = torch.tensor([[[[0.1, 0.9], [0.8, 0.6]]]])
        metrics = binary_metrics(probabilities, targets, threshold=0.5)
        self.assertEqual(metrics["dice"], 0.8)
        self.assertAlmostEqual(metrics["iou"], 2 / 3)
        self.assertEqual(metrics["precision"], 2 / 3)
        self.assertEqual(metrics["recall"], 1.0)


if __name__ == "__main__":
    unittest.main()
