# Architecture

## Runtime overview

```text
User
  |
  v
MedicalImageAnalysisApp (MATLAB AppBase GUI)
  |-- Image Workspace
  |-- Enhancement ------> matlab/enhancement/*
  |-- Segmentation -----> matlab/segmentation/*
  |-- Transformation ---> matlab/geometric/*
  |                          |
  |                          v
  |                    Shared image state + processing history
  |
  |-- AI Segmentation: Original MRI only
  |       |
  |       v
  |   prepareFlairONNXInput (MATLAB channel selection)
  |       |
  |       v
  |   getGliomaONNXBridge -> MATLAB pyenv -> python/matlab_onnx_bridge.py
  |       |                                         |
  |       |                                         v
  |       |                           pytorch_pipeline.normalize_flair
  |       |                                         |
  |       |                                         v
  |       +--------------------------------> ONNX Runtime CPU session
  |                                                 |
  |                                                 v
  |                                  probability -> threshold -> aligned mask
  |
  |-- Evaluation: Ground Truth + AI prediction -> metrics and overlap
```

The current MATLAB inference implementation does not import ONNX natively. It calls ONNX Runtime from the Python interpreter configured by MATLAB.

## GUI and dispatch

[`MedicalImageAnalysisApp.m`](../matlab/MedicalImageAnalysisApp.m) is a MATLAB `matlab.apps.AppBase` class. It creates six navigation sections, with separate controls and displays for Enhancement, Segmentation, and Geometric Transformation. UI callbacks gather controls and call the existing `applySelectedOperation` dispatcher; algorithms remain in independent module functions.

The app also keeps legacy public controls and `applySelectedOperation()` for tests and compatibility. Section-specific controls copy their selections into this common dispatch interface. AI inference is a separate callback and does not go through the classical dispatcher.

## Shared image state

[`initializeImageState.m`](../matlab/common/initializeImageState.m) defines the state:

- `OriginalImage`
- `EnhancedImage`
- `TransformedImage`
- `ClassicalSegmentationMask`
- `AISegmentationInput`
- `AIProbabilityMap`
- `AIPredictedMask`
- `GroundTruthMask`
- `CurrentInputName`, `CurrentInput`, and `ProcessingHistory`

[`selectImageState.m`](../matlab/common/selectImageState.m) selects original/enhanced/transformed inputs. [`recordImageResult.m`](../matlab/common/recordImageResult.m) validates and writes operation outputs and parameters into state/history. The original image is preserved. Reset operations either clear all derived processing states while preserving Original/Ground Truth, or clear a single section's output and corresponding history entries.

## Classical modules

All three course modules are independent functions:

- **Enhancement:** [enhancement functions](../matlab/enhancement/) contain histogram, intensity, spatial-filter, sharpening, and Fourier operations.
- **Segmentation and edges:** [segmentation functions](../matlab/segmentation/) contain edge detectors, Otsu, region growing, RGB/HSV segmentation, morphology, and shape filtering.
- **Geometric processing:** [geometric functions](../matlab/geometric/) contain affine and coordinate mappings, resizing/interpolation, transforms, and radial distortion correction.

See the consolidated [MATLAB function documentation](../matlab/README.md) for the complete implemented interfaces. Every geometric mask transform uses nearest-neighbor interpolation to retain binary values.

## FLAIR preprocessing and inference

1. [`runGliomaONNX.m`](../matlab/ai/runGliomaONNX.m) always begins with `state.OriginalImage`.
2. [`prepareFlairONNXInput.m`](../matlab/ai/prepareFlairONNXInput.m) selects channel 2 (zero-based channel index 1) from documented RGB input; grayscale is interpreted as the selected FLAIR plane.
3. [`getGliomaONNXBridge.m`](../matlab/ai/getGliomaONNXBridge.m) obtains the configured Python environment, adds the project `python/` directory to the Python path, and imports the bridge/ONNX Runtime.
4. [`preprocess_flair_plane`](../python/matlab_onnx_bridge.py) converts to float32 `[0,1]`, bilinearly resizes only if needed, applies per-slice population Z-score normalization with epsilon `1e-6`, and returns NCHW `[1,1,256,256]`.
5. The bridge loads the ONNX session with `providers=["CPUExecutionProvider"]`. The model expects and returns float32 `[1,1,256,256]`.
6. MATLAB validates finite output probabilities in `[0,1]`, thresholds at `0.5`, and restores the binary mask using nearest-neighbor interpolation if the original image size differs.

The audited current Python environment is 3.11 with ONNX Runtime 1.31.1. The inference session explicitly uses CPU even when the runtime reports other available providers.

## Ground-truth evaluation

[`prepareGroundTruthMask.m`](../matlab/common/prepareGroundTruthMask.m) validates/converts the annotation and aligns it by nearest-neighbor resizing. [`evaluateSegmentationMasks.m`](../matlab/common/evaluateSegmentationMasks.m) calculates pixel-level TP/FP/FN and Dice, IoU, precision, and recall. [`createSegmentationOverlap.m`](../matlab/common/createSegmentationOverlap.m) renders TP green, FP red, and FN blue. Ground Truth, Classical Mask, AI Probability, and AI Prediction are separate states.

Evaluation is an interactive per-image comparison; it is not clinical validation and does not replace the fixed held-out test evaluation in the experiment output.

## Processing history and interfaces

Each processing operation records its operation name, input state, output state, and parameters in `ProcessingHistory`. AI history includes preprocessing metadata, model path, ONNX names/shapes, runtime/provider, architecture identifier, and threshold. Geometric transformations record nearest-neighbor mask interpolation where applicable.

Useful public app calls include:

```matlab
app.loadImageData(image, sourceName)
app.setGroundTruthMask(mask, sourceName)
app.setModelPath(modelPath)
app.runAISegmentation()
app.applySelectedOperation()
app.resetImage()
app.saveCurrentResult(outputPath)
```

See [MATLAB module documentation](../matlab/README.md), [user guide](USER_GUIDE.md), and [installation guide](INSTALLATION_GUIDE.md) for operation and runtime instructions.
