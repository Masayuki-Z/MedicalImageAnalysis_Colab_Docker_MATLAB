# User Guide

The MATLAB GUI provides six separate workflow sections. Classical image operations and AI inference are independent paths; the app does not force enhancement or classical segmentation before AI.

## 1. Launch

Follow [Installation and Configuration](INSTALLATION_GUIDE.md). In MATLAB, from the project root:

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
app = MedicalImageAnalysisApp;
app.setModelPath(fullfile(pwd, "model_output", "colab_runs", ...
    "20261101_205443", "unet_model.onnx"));
```

Or use **Load ONNX model** in the AI Segmentation section. The expected model is the preserved run artifact, not the legacy Keras file.

## 2. Load an MRI

Use **Load MRI** in Image Workspace, Enhancement, or AI Segmentation. The GUI accepts image files supported by its file picker (PNG, JPEG, TIFF, BMP). For AI, use the expected MRI/FLAIR format. The supplied LGG RGB dataset documents channel order as pre-contrast, FLAIR, post-contrast; for that input the app selects MATLAB channel 2. Grayscale input is interpreted as the selected FLAIR plane.

The Original MRI is retained and is never replaced by the output of an operation.

## 3. Image Workspace

This section provides the combined comparison view: original image, enhanced/transformed image, classical mask/edge map, AI prediction and overlay, probability map, ground truth, overlap, histograms, and evaluation summary. It also provides **Load MRI**, **Reset processing**, and **Save current result**.

**Save current result** saves the last produced operation result or AI mask. It does not export every state as a bundle.

## 4. Image Enhancement

Choose the operation, then choose its image input (`original`, `enhanced`, or `transformed`). Set the operation-specific parameters and select **Apply operation**. The output is stored as the Enhanced Image; the Original Image remains unchanged. Input/output displays and histogram comparison are separate from the workspace views. **Reset section** clears the enhanced result and its history entries only.

Available operations include histogram equalization/matching, brightness/contrast/gamma, mean/median filtering, Laplacian/high-pass sharpening, and Fourier low-pass/high-pass/band-pass filtering. The controls and helper functions describe parameter ranges.

## 5. Image Segmentation

Select an image input separately from the mask source. Apply Sobel, Prewitt, Canny, Otsu, region growing, RGB/HSV segmentation, morphology, or shape-based filtering. The selected image input is used for image-based segmentation. Morphology/shape operations use the explicitly selected Classical, AI, or Ground Truth mask. For region growing, enter seed row and column coordinates in the selected image.

Classical Otsu and region-growing outputs are general image-processing results; they are not glioma-specific model predictions. The binary output is shown in this section and stored as the Classical Segmentation Mask.

## 6. Geometric Transformation

Select the image state, transformation, interpolation, and parameters. Operations include translation, scaling, rotation, affine transforms, forward/inverse mapping, resize variants, and radial distortion/correction. The transformed image is stored separately. When an existing classical mask aligns with the input, the app transforms it with nearest-neighbor interpolation to preserve binary values and spatial correspondence. Input/output dimensions are displayed. **Reset section** clears transformed output without clearing other paths.

## 7. AI Segmentation

1. Load the original MRI.
2. Load the supplied ONNX model if it is not already selected.
3. Select **Run U-Net on original FLAIR**.
4. Inspect the Original MRI, probability map, and thresholded prediction.

AI inference always starts from `OriginalImage` and uses the model preprocessing contract: FLAIR selection, resize to 256 × 256 only as needed, per-slice population Z-score normalization, and probability threshold 0.5. Classical enhancement or geometric transformation is not a required preprocessing step.

The inference route uses Python ONNX Runtime through MATLAB's Python interface and explicitly requests CPU execution.

## 8. Ground Truth

In Evaluation, select **Load ground truth** and choose the matching 2-D mask. Binary/logical masks remain binary. Grayscale masks with more than two intensity levels are binarized with Otsu. If the mask dimensions differ from the MRI, the app aligns it using nearest-neighbor resizing and reports that in status. Replacing the MRI clears the prior ground truth to prevent comparing a mask from a different image.

Ground Truth remains separate from the classical mask and AI prediction. Loading it does not run inference.

## 9. Evaluation

The Evaluation section shows Ground Truth, a color-coded overlap, pixel metrics, and actions to load/clear annotations and run AI. Overlap colors: green true positive (TP), red false positive (FP), blue false negative (FN); true negatives are black.

Metrics are pixel-level comparisons for the currently loaded image:

- Dice = `2*TP / (2*TP + FP + FN)`
- IoU = `TP / (TP + FP + FN)`
- Precision = `TP / (TP + FP)`
- Recall = `TP / (TP + FN)`

When both masks are empty, Dice and IoU are 1. Precision is 1 with no predicted positives; recall is 1 when the ground truth contains no positive pixels. These conventions are documented for numerical completeness and are not clinical performance claims. The saved held-out test report is a separate experiment artifact.

## 10. Reset and state reference

The global **Reset processing** returns processing outputs to the original image and preserves any loaded Ground Truth. The section reset buttons clear only their own output and associated history entries.

| State | Meaning |
|---|---|
| Original Image | Immutable loaded image; direct source for AI inference. |
| Enhanced Image | Result of an enhancement operation. |
| Transformed Image | Result of geometric processing. |
| Classical Segmentation Mask | Output of classical segmentation or mask refinement. |
| AI Input | FLAIR plane after the model-compatible preprocessing path. |
| AI Probability Map | Model probabilities, separate from the thresholded mask. |
| AI Predicted Mask | Binary result at threshold 0.5, aligned to the original image. |
| Ground Truth Mask | User-loaded annotation, independent of all prediction states. |

Compatible outputs can be selected as inputs in the enhancement, segmentation, and transformation sections. The AI path remains original-image-only.

## 11. Errors and support

- **No image loaded:** load an MRI before processing.
- **Selected state unavailable:** produce that Enhanced/Transformed state or select a populated input.
- **Missing ONNX model:** select the final `unet_model.onnx` from the audited run.
- **Python/ONNX Runtime import error:** verify MATLAB `pyenv` points to Python 3.11 with the required packages, then restart MATLAB if Python was initialized with a different interpreter.
- **Invalid mask source:** load or generate the selected mask first.
- **Inference dimensions/range error:** restore the supplied model artifact and check that it matches the manifest.

See the [installation troubleshooting table](INSTALLATION_GUIDE.md#8-troubleshooting). The software is for academic/research use only, not for diagnosis or treatment decisions.
