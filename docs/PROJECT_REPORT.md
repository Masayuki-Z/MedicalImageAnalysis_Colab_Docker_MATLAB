# Project Report — Integrated Medical Image Processing Toolbox

**Repository:** `Masayuki-Z/MedicalImageAnalysis_Colab_Docker_MATLAB`  
**Report scope:** Implemented functions, technical foundations, MATLAB/Python structure, observed results, testing, and documentation  
**Verification snapshot:** 2 November 2026 (MATLAB R2026b)  
**Project type:** Academic/research image-processing and MRI segmentation software; not a clinical product

## Abstract

This project combines three classical medical-image-processing modules in MATLAB with an independently controlled deep-learning segmentation path. Module 1 enhances image appearance using intensity, spatial-filtering, sharpening, and Fourier-domain operations. Module 2 detects edges and creates/refines masks using thresholding, region growing, color segmentation, morphology, and shape filtering. Module 3 performs spatial transformations and interpolation. A MATLAB AppBase GUI exposes the operations through separate workflow sections and keeps original, enhanced, transformed, classical-mask, AI, and ground-truth data distinct.

The AI path uses a single-channel 2-D U-Net trained for FLAIR glioma segmentation, exported to ONNX and invoked from MATLAB through Python 3.11 and ONNX Runtime on CPU. Verification records 34/34 MATLAB tests passed, 7/7 Python pipeline tests passed, and a real-image classical demo on a 256×256×3 LGG MRI TIFF. The audited held-out AI test report covers 569 slices from 16 patients. These engineering and pixel-level results are not clinical validation.

## 1. Project goals and scope

The project aims to:

- Implement reusable MATLAB functions for image enhancement, segmentation/edge detection, and geometric processing.
- Provide a GUI for selecting inputs, operations, parameters, and displaying results.
- Preserve the source MRI and keep intermediate outputs and masks in independent states.
- Provide an AI segmentation route whose preprocessing matches the trained model pipeline.
- Support comparison of a prediction with a separately loaded ground-truth mask.

The primary data example is the LGG MRI Segmentation Dataset. For the audited RGB TIFF files, the dataset documentation identifies channel order as pre-contrast, FLAIR, and post-contrast; therefore channel 2 in MATLAB (one-based indexing) is used as FLAIR. This assumption must not be applied to arbitrary RGB images without modality metadata.

## 2. System structure and code organization

| Path | Responsibility |
|---|---|
| `matlab/MedicalImageAnalysisApp.m` | Current MATLAB AppBase GUI; builds the workspace, enhancement, segmentation, geometric, AI, and evaluation sections and dispatches operations. |
| `matlab/common/` | Shared image state, input selection, result/history recording, FLAIR input preparation, ground-truth preparation, and evaluation helpers. |
| `matlab/enhancement/` | Module 1 intensity, histogram, spatial, sharpening, and Fourier-domain functions. |
| `matlab/segmentation/` | Module 2 edge, threshold, region-growing, color, morphology, and shape-based functions. |
| `matlab/geometric/` | Module 3 spatial transformations, mapping, interpolation, resizing, and radial-distortion functions. |
| `matlab/ai/` | MATLAB-side model input and ONNX inference integration. |
| `matlab/tests/` | MATLAB regression and integration tests, run through `runModuleTests`. |
| `python/pytorch_pipeline.py` | Shared PyTorch training/evaluation and FLAIR preprocessing implementation. |
| `python/matlab_onnx_bridge.py` | Python bridge for preprocessing and ONNX Runtime inference initiated from MATLAB. |
| `notebooks/` | Google Colab U-Net training notebooks, including the current PyTorch workflow and historical material. |
| `docs/` | Installation, user, architecture, status, test, audit, handover, and evidence documentation. |

The project uses MATLAB R2026b with Image Processing Toolbox for the classical GUI and modules. MATLAB calls Python 3.11 through `pyenv`; the bridge uses NumPy, Pillow, PyTorch shared preprocessing, and ONNX Runtime 1.31.1. The supported inference route explicitly requests `CPUExecutionProvider`; native MATLAB ONNX import and GPU inference through the MATLAB bridge are not verified.

### Shared state and processing flow

`initializeImageState` creates a state object holding `OriginalImage`, `EnhancedImage`, `TransformedImage`, `ClassicalSegmentationMask`, `AISegmentationInput`, `AIProbabilityMap`, `AIPredictedMask`, `GroundTruthMask`, and the selected input and `ProcessingHistory`. `selectImageState` chooses Original, Enhanced, or Transformed image data. `recordImageResult` records output state, operation, and parameters without overwriting the original.

The classical image operations can use a selected image state. AI inference is deliberately separate and always starts from the original MRI, so preceding enhancement or geometric operations do not silently alter model input. The AI input, probability map, binary prediction, and ground truth are separately stored. Section-level resets clear only the relevant output/history rather than unrelated masks or images.

## 3. Module 1 — Image enhancement

### 3.1 Theory

Image enhancement improves visual contrast or emphasizes structures; it does not add new anatomical information. Histogram methods redistribute intensity values. Point transforms map each pixel independently. Spatial filters combine neighboring pixels and therefore smooth noise or emphasize local changes. Fourier filters operate on spatial frequencies: low frequencies represent slowly varying image content, while high frequencies represent rapid intensity changes such as edges and fine detail.

### 3.2 MATLAB implementation

The module provides the following independent operations:

- **Histogram equalization and matching:** `histogramEqualization` redistributes grayscale intensity (or RGB luminance) to use the available range. `histogramMatching` maps a source intensity distribution toward that of a reference image.
- **Brightness, contrast, and gray-level mapping:** `adjustBrightness` adds a normalized offset and clips to `[0,1]`; `adjustContrast` scales around intensity 0.5. `grayLevelTransform` supports negative, logarithmic, and gamma mappings.
- **Smoothing:** `meanFilter` averages a square neighborhood; `medianFilter` selects its median and is less sensitive to isolated impulse noise. Both use symmetric boundary extension.
- **Sharpening:** `laplacianFilter` subtracts a scaled Laplacian response, while `highPassFilter` adds a normalized 3×3 high-pass response. Output is clipped to the normalized range.
- **Frequency filtering:** `fourierLowPass`, `fourierHighPass`, and `fourierBandPass` apply ideal circular masks in the Fourier domain and return the filtered image and a log-magnitude spectrum. Cutoffs are expressed in cycles per pixel. Ideal masks can produce ringing near sharp boundaries.

RGB histogram and point operations are applied through luminance where documented; spatial filters operate per channel. Functions accept grayscale or RGB numeric/logical inputs, validate inputs, and generally produce double-valued intensity images in `[0,1]`.

### 3.3 Representative use and result

The documented classical demonstration applies histogram equalization to the dataset-documented FLAIR channel before segmentation. The report does not claim that equalization improves a clinical diagnosis or AI performance; the operation demonstrates contrast enhancement for visualization and subsequent classical processing. Module 1 functions and parameter validation are included in the regression suite.

## 4. Module 2 — Segmentation and edge detection

### 4.1 Theory

Segmentation assigns pixels to regions of interest, while edge detection identifies locations of strong image-intensity change. Sobel and Prewitt estimate local gradients with small derivative kernels. Canny smooths before gradient detection and uses non-maximum suppression and hysteresis thresholding to produce thin, connected edges. Otsu's method chooses a global intensity threshold by maximizing between-class variance. Region growing expands from a seed through connected pixels meeting an intensity tolerance. RGB/HSV thresholding selects colors by channel ranges. Morphological operators use a structuring element to modify binary shapes; connected-component measurements can remove objects that do not meet size or shape constraints.

### 4.2 MATLAB implementation

- **Edges:** `sobelEdge`, `prewittEdge`, and `cannyEdge` return logical edge maps. Optional thresholds are validated; Canny also accepts a positive Gaussian scale (`sigma`).
- **Thresholding:** `otsuSegmentation` returns a logical binary mask and the computed threshold.
- **Seed-based segmentation:** `regionGrowing` uses integer `[row column]` seed coordinates, an intensity tolerance, and either 4- or 8-connectivity. Candidate pixels are compared with the seed intensity, then constrained by connectivity.
- **Color segmentation:** `rgbSegmentation` applies inclusive per-channel RGB bounds. `hsvSegmentation` applies HSV bounds and handles hue intervals that wrap around 1 to 0.
- **Mask refinement:** `morphologicalDilation`, `morphologicalErosion`, `morphologicalOpening`, and `morphologicalClosing` support disk, square, and diamond structuring elements. `shapeBasedSegmentation` filters connected components by area and optional circularity and returns component properties.

These are general-purpose image-processing methods. In particular, Otsu and region growing are not tumor-specific algorithms, and a classical mask must not be presented as a verified tumor annotation.

### 4.3 Sample classical MRI result

The recorded `runMriPipelineDemo` processing path uses a real 256×256×3 LGG TIFF and applies FLAIR selection, histogram equalization, Otsu segmentation, morphological closing, and shape filtering. In the verified run, the Otsu threshold was **0.774510**. The reported binary-mask area was **14,582 pixels before** and **15,642 pixels after** the recorded closing/shape-filter step. These values describe that image and that classical processing run only; they are neither accuracy metrics nor ground-truth tumor measurements.

## 5. Module 3 — Geometric transformations and interpolation

### 5.1 Theory

Geometric processing changes the coordinates at which image samples are represented. Translation, scaling, rotation, and general affine transformations can be expressed with homogeneous coordinate matrices. Forward mapping sends each source pixel to a destination coordinate, which can leave holes. Inverse mapping instead visits every output pixel and samples the corresponding source coordinate, avoiding unfilled output positions. Interpolation estimates intensities at non-integer coordinates: nearest neighbor selects one sample, bilinear interpolation blends four neighbors, and bicubic interpolation uses a larger neighborhood for a smoother estimate.

### 5.2 MATLAB implementation

- `translateImage`, `scaleImage`, and `rotateImage` implement translation, resizing by a positive scale factor, and rotation about the image center.
- `affineTransform` applies a homogeneous 3×3 affine matrix with inverse sampling. `forwardMapping` scatters source values to rounded output coordinates; `inverseMapping` samples source positions for output coordinates.
- `nearestNeighborInterpolation`, `bilinearInterpolation`, and `bicubicInterpolation` expose coordinate sampling. Their resize wrappers (`nearestNeighborResize`, `bilinearResize`, and `bicubicResize`) resize to requested dimensions.
- `simulateRadialDistortion` and `radialDistortionCorrection` implement inverse-sampled radial distortion and correction for the documented radial model.

The coordinate convention is **x = column, y = row**, with pixel coordinates starting at 1. Geometric methods support nearest, bilinear, and bicubic interpolation where applicable; samples outside the source image are zero. Positive translation offsets move right/down; positive rotation is counterclockwise. Binary masks should use nearest-neighbor interpolation to retain discrete labels, and the same transformation and output dimensions should be applied to an image and its mask to preserve alignment.

### 5.3 Representative result

Module tests exercise transformation dimensions, mapping behavior, interpolation, boundary handling, binary-mask resizing, and a radial-distortion round trip. The verified regression run passed these checks. The report does not claim a clinical registration or anatomical alignment evaluation; image registration is outside the current milestone.

## 6. AI segmentation module

### 6.1 Method and implementation

The AI component uses a single-channel 2-D U-Net for brain-glioma segmentation from MRI FLAIR. The training workflow is provided in the PyTorch Colab notebook and Python pipeline. The MATLAB application selects the documented FLAIR channel from the original image, then calls the Python bridge through MATLAB `pyenv`. Shared preprocessing converts the image to float32 in `[0,1]`, resizes to 256×256 with bilinear interpolation when required, and applies per-slice population Z-score normalization with epsilon `1e-6`. The bridge runs the ONNX model using ONNX Runtime with `CPUExecutionProvider`; the model input and output are `[1,1,256,256]`. MATLAB validates finite output probabilities in `[0,1]`, thresholds at 0.5, and restores a mask to the source dimensions with nearest-neighbor resizing if needed.

The model input is always the original MRI, independent of the classical enhancement and geometric states. The binary prediction and probability map are retained as separate outputs.

### 6.2 Recorded experiment and sample results

The audited final experiment is recorded as a Google Colab GPU run on a Tesla T4 with CUDA 13.0 and PyTorch 2.11.0+cu130. Training stopped after 19 epochs; the best validation checkpoint was epoch 7, and the recorded training curve collapsed after epoch 7 for an unknown reason. At a fixed 0.5 threshold, the saved unseen-test report covers **569 slices from 16 patients** and reports pooled pixel metrics:

| Metric | Reported value |
|---|---:|
| Dice | 0.781607 |
| IoU | 0.641507 |
| Precision | 0.772103 |
| Recall | 0.791348 |

The ONNX parity check is limited to five slices from one test patient. These experiment figures are reported from the saved test report; they should not be generalized beyond that test protocol. Training instability remains unexplained, and the project is not clinically validated.

## 7. Ground-truth evaluation

The GUI can load an independent 2-D ground-truth mask (PNG, TIFF, or grayscale JPG/JPEG). Binary masks retain their foreground/background values; grayscale masks with more than two levels are binarized with Otsu's threshold. When dimensions differ from the current MRI, the mask is aligned by nearest-neighbor resizing, and the GUI reports that resize. Loading a new MRI clears the prior ground truth to avoid accidental cross-subject comparison. Reset preserves a loaded mask; a separate action clears it.

When both the ground truth and AI prediction exist, the application displays the masks, prediction overlay, probability map, and TP/FP/FN overlap (green/red/blue, respectively). Pixel metrics are:

- Dice = `2 × TP / (2 × TP + FP + FN)`
- IoU = `TP / (TP + FP + FN)`
- Precision = `TP / (TP + FP)`
- Recall = `TP / (TP + FN)`

Empty-mask edge cases are handled explicitly. These per-image metrics are educational comparisons and do not replace the held-out model test report or constitute clinical validation.

## 8. GUI workflow and user-facing behavior

`MedicalImageAnalysisApp.m` is a programmatic MATLAB AppBase `.m` class, not an App Designer-authored `.mlapp`. Its six sections are Image Workspace, Image Enhancement, Image Segmentation, Geometric Transformation, AI Segmentation, and Evaluation. The classical processing sections have separate controls, selectors, parameters, input/output views, and scoped resets. The shared state provides traceable results and processing history without forcing an automatic sequential pipeline. The user can load an image, select an operation and its parameters, apply/reset it, review image and mask views, run AI inference, load ground truth, compare masks, and save results.

The interface distinguishes an image-input selector (Original/Enhanced/Transformed) from a mask-source selector (Classical/AI/Ground Truth). This prevents image processing and mask refinement from being conflated. AI inference remains tied to the original MRI.

## 9. Testing and verification results

The verification record is for MATLAB R2026b on Windows with Image Processing Toolbox, and the configured Python 3.11 environment. The full MATLAB regression suite reported:

| Test group | Passed |
|---|---:|
| Modules 1–3 | 15 |
| ONNX integration | 6 |
| GUI integration | 7 |
| Ground-truth evaluation | 6 |
| **Total** | **34/34** |

The Python PyTorch pipeline unit suite passed **7/7** tests; all seven remaining Python source files compiled in the post-cleanup audit. A synthetic FLAIR input was preprocessed and inferred through the MATLAB bridge with CPU ONNX Runtime. The ONNX smoke test verified input/output tensor dimensions and probability output validation. MATLAB Code Analyzer inspected 69 `.m` files; the final cleanup report notes three advisory findings in the legacy classic-only `MedicalImageToolbox.m` prototype, with no diagnostics reported for the current app or tests in the cited final acceptance audit.

These results confirm the documented automated tests and checks in the specified development environment. A clean-machine installation was not tested. Automated GUI tests and exported screenshots do not independently establish accessibility, usability, or clinical suitability.

Run the MATLAB test suite from the repository root:

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
results = runModuleTests;
assert(all([results.Passed]));
```

Run the classical MRI demonstration (requires local dataset files):

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
result = runMriPipelineDemo();
% Or provide an input TIFF and output directory:
% result = runMriPipelineDemo("path/to/image.tif", "path/to/output");
```

## 10. Code documentation and inline comments

The repository documents the system at several levels:

- `matlab/README.md` is the consolidated function reference. It lists inputs, output behavior, parameter domains, image-state semantics, coordinate conventions, dependencies, test coverage, and a usage example for every module group.
- `docs/ARCHITECTURE.md` explains component boundaries, data flow, preprocessing/inference, shared state, and evaluation.
- `docs/USER_GUIDE.md` and `docs/INSTALLATION_GUIDE.md` cover GUI use and environment setup.
- `docs/TEST_REPORT.md`, `docs/FINAL_RELEASE_REPORT.md`, and evidence under `docs/evidence/` record automated test results, runtime information, audits, and screenshots.
- MATLAB functions are split into focused files named for their operation, with shared validation/state helpers and regression tests. Function interfaces and behavior are described in the module reference; inline MATLAB comments should clarify non-obvious algorithm steps, coordinate conventions, boundary handling, or medical-data assumptions rather than merely restating code.

A useful documentation standard for future changes is to keep each public function's help text aligned with its interface: purpose, input ranges and types, output type/shape, boundary behavior, and a short example. Any new algorithm should add a focused test and update `matlab/README.md` and this report. The verification evidence reports clean analyzer output for the current app/tests, while remaining advisory findings are confined to the legacy prototype in the cited audit. This report does not claim that every line has exhaustive inline commentary.

## 11. Limitations and responsible use

- The system is an academic/research demonstration and is not clinically validated; it must not be used for diagnosis or treatment.
- The classical thresholding and region-growing outputs are generic image-processing results, not tumor-specific ground truth.
- AI evaluation is limited to the recorded split and metrics. The training curve collapsed after epoch 7 for an unknown reason; parity testing covered only five slices from one test patient.
- MATLAB-to-ONNX inference uses CPUExecutionProvider. GPU inference through this bridge and native MATLAB ONNX execution are not verified.
- Dataset and model artifacts are excluded from Git and must be obtained separately. Dataset terms should be reviewed before redistribution or use.
- The installation steps have not been independently verified on a clean machine.
- The current GUI is an AppBase `.m` class. If a course explicitly requires `.mlapp`, a separate App Designer implementation and validation would be needed.

## 12. Conclusion

The repository delivers three independently callable MATLAB image-processing modules, a six-section GUI, an isolated PyTorch U-Net/ONNX inference route, ground-truth comparison, and documented regression coverage. The representative classical demo records the Otsu threshold and mask areas for one real MRI image; the AI section reports the saved held-out test metrics with explicit dataset and parity limits. The documented suite passed 34 MATLAB tests and 7 Python pipeline tests in the audited environment. The implementation and results demonstrate a software engineering and image-processing project, not a clinically validated diagnostic system.

## References within this repository

- [MATLAB module documentation](../matlab/README.md)
- [Architecture](ARCHITECTURE.md)
- [User guide](USER_GUIDE.md)
- [Installation guide](INSTALLATION_GUIDE.md)
- [Test report](TEST_REPORT.md)
- [Final release report](FINAL_RELEASE_REPORT.md)
- [Project status](PROJECT_STATUS.md)
