"""Export test-set predicted masks and comparison panels without retraining.
Run from project root:
python python/visual_evaluate.py --data-dir PATH_TO_DATA --model model_output/tumor_unet.keras
"""
import argparse, json
from pathlib import Path
import numpy as np
import tensorflow as tf
from PIL import Image
from sklearn.model_selection import GroupShuffleSplit
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

SEED = 42
EXTS = {".tif", ".tiff", ".png", ".jpg", ".jpeg"}

def collect_pairs(root):
    pairs = []
    for m in sorted(Path(root).rglob("*_mask.*")):
        if m.suffix.lower() not in EXTS:
            continue
        image = m.with_name(m.name[:-len("_mask" + m.suffix)] + m.suffix)
        if image.exists():
            pairs.append((str(image), str(m), m.parent.name))
    if not pairs:
        raise FileNotFoundError(f"No image/mask pairs under {root}")
    return pairs

def split_groups(pairs):
    groups = np.array([p[2] for p in pairs])
    ids = np.arange(len(pairs))
    tr, tmp = next(GroupShuffleSplit(n_splits=1, test_size=.2, random_state=SEED).split(ids, groups=groups))
    va_rel, te_rel = next(GroupShuffleSplit(n_splits=1, test_size=.5, random_state=SEED+1).split(tmp, groups=groups[tmp]))
    return tr, tmp[va_rel], tmp[te_rel]

def load_pair(image_path, mask_path, size):
    with Image.open(image_path) as im:
        image = np.asarray(im.convert("RGB").resize((size, size), Image.Resampling.BILINEAR), dtype=np.float32) / 255.0
    with Image.open(mask_path) as im:
        mask = (np.asarray(im.convert("L").resize((size, size), Image.Resampling.NEAREST)) > 0).astype(np.uint8)
    return image, mask

def dice_iou(gt, pred):
    gt, pred = gt.astype(bool), pred.astype(bool)
    inter = np.logical_and(gt, pred).sum()
    dice = (2 * inter + 1) / (gt.sum() + pred.sum() + 1)
    union = np.logical_or(gt, pred).sum()
    iou = (inter + 1) / (union + 1)
    return float(dice), float(iou)

def save_panel(image, gt, pred, path, title):
    gray = image.mean(axis=2)
    overlay = np.repeat(gray[..., None], 3, axis=2)
    gt_only = gt.astype(bool) & ~pred.astype(bool)
    pred_only = pred.astype(bool) & ~gt.astype(bool)
    overlap = gt.astype(bool) & pred.astype(bool)
    overlay[gt_only] = [0, 1, 0]      # green: ground truth only
    overlay[pred_only] = [1, 0, 0]     # red: prediction only
    overlay[overlap] = [1, 1, 0]      # yellow: overlap
    fig, ax = plt.subplots(1, 4, figsize=(15, 4))
    ax[0].imshow(gray, cmap="gray", vmin=0, vmax=1); ax[0].set_title("Original MRI")
    ax[1].imshow(gt, cmap="gray", vmin=0, vmax=1); ax[1].set_title("Ground Truth")
    ax[2].imshow(pred, cmap="gray", vmin=0, vmax=1); ax[2].set_title("Predicted Mask")
    ax[3].imshow(overlay); ax[3].set_title("Overlay: GT green / Pred red / overlap yellow")
    for a in ax: a.axis("off")
    fig.suptitle(title, fontsize=9); fig.tight_layout()
    fig.savefig(path, dpi=150, bbox_inches="tight"); plt.close(fig)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--data-dir", required=True)
    p.add_argument("--model", default="model_output/tumor_unet.keras")
    p.add_argument("--output-dir", default="model_output/visual_evaluation")
    p.add_argument("--image-size", type=int, default=256)
    p.add_argument("--threshold", type=float, default=0.5)
    p.add_argument("--num-samples", type=int, default=20, help="0 exports every test image")
    a = p.parse_args()
    
    out = Path(a.output_dir); out.mkdir(parents=True, exist_ok=True)
    pairs = collect_pairs(a.data_dir)
    _, _, test_idx = split_groups(pairs)
    test_pairs = [pairs[i] for i in test_idx]
    if a.num_samples > 0: test_pairs = test_pairs[:a.num_samples]
    
    # โหลดโมเดลพร้อมรองรับ Custom Layers (กรณีใช้ Attention U-Net หรือ ResU-Net)
    model = tf.keras.models.load_model(a.model, compile=False)
    
    rows = []
    for n, (img_path, mask_path, patient) in enumerate(test_pairs, 1):
        image, gt = load_pair(img_path, mask_path, a.image_size)
        prob = model.predict(image[None, ...], verbose=0)[0, ..., 0]
        pred = (prob >= a.threshold).astype(np.uint8)
        d, j = dice_iou(gt, pred)
        stem = f"{n:03d}_{Path(img_path).stem}"
        Image.fromarray(gt * 255).save(out / f"{stem}_ground_truth.png")
        Image.fromarray(pred * 255).save(out / f"{stem}_predicted_mask.png")
        save_panel(image, gt, pred, out / f"{stem}_comparison.png",
                   f"{Path(img_path).stem} | patient={patient} | Dice={d:.3f} | IoU={j:.3f}")
        rows.append({"image": img_path, "mask": mask_path, "patient_id": patient, "dice": d, "iou": j})
        
    summary = {
        "model": a.model, "test_samples_exported": len(rows), "threshold": a.threshold,
        "image_size": a.image_size,
        "mean_dice_exported_samples": float(np.mean([r["dice"] for r in rows])) if rows else None,
        "mean_iou_exported_samples": float(np.mean([r["iou"] for r in rows])) if rows else None,
        "note": "Means cover exported samples only if num-samples is less than the full test set.",
        "samples": rows
    }
    (out / "visual_evaluation_metrics.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({k:v for k,v in summary.items() if k != "samples"}, indent=2))
    print(f"Saved to {out.resolve()}")

if __name__ == "__main__":
    main()