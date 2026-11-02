# MATLAB Image Processing Modules

The functions are independent of the GUI prototype in `MedicalImageToolbox.m`.
Add the MATLAB folder tree to the path with `addpath(genpath(fullfile(pwd,"matlab")))`.
Inputs may be grayscale or RGB numeric/logical images. Most image outputs are
`double` in `[0,1]`; edge maps and masks are logical. Functions reject empty,
nonfinite, or unsupported image values rather than silently normalizing arbitrary
floating-point data.

## Shared image state and pipeline

`initializeImageState(originalImage)` creates these fields:

- `OriginalImage` — preserved source reference; processing functions do not mutate it.
- `EnhancedImage`, `TransformedImage`
- `ClassicalSegmentationMask`, `AISegmentationInput`, `AIProbabilityMap`,
  `AIPredictedMask`, `GroundTruthMask`
- `CurrentInputName`, `CurrentInput`, and `ProcessingHistory`

`selectImageState(state, "original"|"enhanced"|"transformed")` explicitly selects
a populated input. Pass the selected image to any compatible function, then use
`recordImageResult(state, outputState, result, operation, parameters)` to record
the result and processing parameters. The classical path is intentionally separate from the AI path: inference
always uses the original image, not the current enhanced or transformed state.
The AI input, probability map, and thresholded prediction are stored separately.

Example:

```matlab
addpath(genpath(fullfile(pwd,"matlab")));
state = initializeImageState(mri);
flair = im2double(mri(:,:,2)); % only when source metadata confirms channel 2 is FLAIR
enhanced = histogramEqualization(flair);
state = recordImageResult(state,"enhanced",enhanced,"histogramEqualization",struct());
[inputImage,state] = selectImageState(state,"enhanced");
[mask,threshold] = otsuSegmentation(inputImage);
state = recordImageResult(state,"classicalMask",mask,"otsu",struct("threshold",threshold));
refined = morphologicalClosing(mask,"disk",1);
```

The sample channel selection above is suitable for the audited LGG TIFF files
because their dataset README documents RGB order as pre-contrast, FLAIR,
post-contrast. Do not apply it to arbitrary RGB images without modality
metadata. Otsu and classical results are general image-processing results, not
tumor-specific predictions.

## Module 1 — Image enhancement

| Function | Inputs | Output / behavior |
|---|---|---|
| `histogramEqualization(I)` | grayscale or RGB image | Equalized grayscale intensity or RGB luminance; returns double. |
| `histogramMatching(source, reference)` | both grayscale or both RGB | Matches source histogram to reference, on luminance for RGB. |
| `adjustBrightness(I, offset)` | offset in `[-1,1]` normalized intensity units | Adds offset; clips to `[0,1]`; RGB luminance is adjusted. |
| `adjustContrast(I, factor)` | finite factor `>= 0` | Scales intensity around 0.5; RGB luminance is adjusted. |
| `grayLevelTransform(I, method, parameter)` | `negative`, `log`, or `gamma`; positive parameter | Gray-level mapping; gamma defaults to 1. |
| `meanFilter(I, windowSize)` | positive integer square window size | Per-channel averaging with symmetric boundary extension. |
| `medianFilter(I, windowSize)` | positive integer square window size | Per-channel median filtering with symmetric boundary extension. |
| `laplacianFilter(I, amount)` | nonnegative sharpening amount (default 1) | `I - amount * Laplacian(I)` with clipping. |
| `highPassFilter(I, amount)` | nonnegative sharpening amount (default 1) | Adds the normalized 3×3 high-pass response; clips output. |
| `fourierLowPass(I, cutoff)` | cutoff in cycles/pixel, `[0,sqrt(0.5)]` | `[outputImage,spectrum]`; ideal circular low-pass. |
| `fourierHighPass(I, cutoff)` | same cutoff units | `[outputImage,spectrum]`; ideal circular high-pass. |
| `fourierBandPass(I, [low high])` | `0 <= low < high <= sqrt(0.5)` cycles/pixel | `[outputImage,spectrum]`; ideal circular band-pass. |

`spectrum` is `log(1 + abs(fftshift(fft2(grayImage))))`. The implementation
uses ideal masks; ringing near sharp edges is a known consequence. Frequency
filtering on RGB is performed per channel while the displayed spectrum is
grayscale.

## Module 2 — Segmentation and edge detection

| Function | Inputs | Output / behavior |
|---|---|---|
| `sobelEdge(I, threshold)` | optional empty, scalar, or `[low high]` threshold in `[0,1]` | Logical Sobel edge map. |
| `prewittEdge(I, threshold)` | same threshold convention | Logical Prewitt edge map. |
| `cannyEdge(I, threshold, sigma)` | optional threshold; positive sigma (default 1) | Logical Canny edge map. |
| `otsuSegmentation(I)` | grayscale or RGB image | `[logicalMask, threshold]`; global Otsu threshold. |
| `regionGrowing(I, [row column], tolerance, connectivity)` | seed is integer pixel coordinates; tolerance `[0,1]`; connectivity 4 or 8 | Connected pixels within absolute intensity tolerance of the seed value. |
| `rgbSegmentation(I, lowerRGB, upperRGB)` | RGB and three normalized bounds | Inclusive per-channel logical mask. |
| `hsvSegmentation(I, lowerHSV, upperHSV)` | RGB and three HSV bounds | Logical mask; hue bounds may wrap across 1 to 0. |
| `morphologicalDilation(mask, shape, radius)` | binary mask; shape `disk`, `square`, or `diamond`; integer radius >=1 | Dilated logical mask. |
| `morphologicalErosion(mask, shape, radius)` | same | Eroded logical mask. |
| `morphologicalOpening(mask, shape, radius)` | same | Opened logical mask. |
| `morphologicalClosing(mask, shape, radius)` | same | Closed logical mask. |
| `shapeBasedSegmentation(mask,minArea,maxArea,minCircularity)` | binary mask; optional area and circularity limits | `[filteredMask, components]`; component properties include area, perimeter, eccentricity, solidity, pixel list, and circularity. |

RGB and HSV range bounds use `[0,1]`. Region growing compares each candidate
pixel to the seed intensity, then includes only 4- or 8-connected candidates;
this is an educational seed-based method, not tumor-specific.

## Module 3 — Geometric transformations and interpolation

Coordinate convention: **x is column, y is row**, pixel coordinates start at 1.
Affine matrices map source coordinates `[x;y;1]` to output coordinates.
Inverse mapping samples the source for every output pixel; forward mapping
scatters source pixels to rounded output coordinates and fills holes.

| Function | Inputs | Output / behavior |
|---|---|---|
| `translateImage(I, dx, dy, method)` | horizontal/vertical offsets; method `nearest`, `bilinear`, `bicubic` (default bilinear) | Same-size translation; positive dx/dy move right/down. |
| `scaleImage(I, factor, method)` | positive factor; supported interpolation | Resized output. |
| `rotateImage(I, angleDegrees, method)` | angle; supported interpolation | Same-size rotation about image center; positive angle is counterclockwise. |
| `affineTransform(I, matrix, method, outputSize)` | 3×3 homogeneous affine matrix | Inverse-sampled affine result. |
| `forwardMapping(I, matrix, outputSize, fillValue)` | source-to-output matrix; optional dimensions and fill | Forward scatter with nearest pixel assignment. |
| `inverseMapping(I, matrix, outputSize, method)` | source-to-output matrix; optional dimensions and interpolation | Inverse mapped result. |
| `nearestNeighborInterpolation(I,x,y)` | same-size query coordinate arrays | Nearest sampled image. |
| `bilinearInterpolation(I,x,y)` | same | Bilinear sampled image. |
| `bicubicInterpolation(I,x,y)` | same | Bicubic sampled image. |
| `nearestNeighborResize(I,[h w])` | target dimensions | Nearest-neighbor resize; use for binary masks. |
| `bilinearResize(I,[h w])` | target dimensions | Bilinear resize for intensity images. |
| `bicubicResize(I,[h w])` | target dimensions | Bicubic resize for intensity images. |
| `simulateRadialDistortion(I,k1,center,method)` | `0 <= k1 <= 1`; optional `[x y]` center and interpolation | Simulates radial distortion by inverse sampling; defaults to bilinear, masks can use nearest. |
| `radialDistortionCorrection(I,k1,center,method)` | same coefficient/center; interpolation | Corrects the simulated radial model by inverse mapping. |

All geometric methods that accept `method` support nearest, bilinear, and
bicubic. **Always use nearest-neighbor for binary masks** (for example,
`rotateImage(mask, angle, "nearest")`) and apply the same transform and output
dimensions to the image and mask to keep them aligned. Interpolation methods
take query coordinates in pixel units and use zero outside the input boundary.

Basic image registration is optional and is not included in this milestone.

## Dependencies and testing

Tested with MATLAB R2026b and Image Processing Toolbox. The implementation uses
Image Processing Toolbox functions including `histeq`, `imhistmatch`, `imfilter`,
`medfilt2`, `edge`, `graythresh`, `imbinarize`, morphology functions,
`regionprops`, `rgb2hsv`, and `rgb2ycbcr`.

Run the unit tests from the project root:

```matlab
addpath(genpath(fullfile(pwd,"matlab")));
results = runModuleTests;
```

Run the classical pipeline on the first local LGG TIFF (or pass an explicit
image path); optional output files can be written to a chosen folder:

```matlab
result = runMriPipelineDemo();
% result = runMriPipelineDemo("path/to/image.tif","path/to/output");
```

The demo processes the dataset-documented FLAIR channel through histogram
equalization, Otsu segmentation, morphological closing, and shape filtering.
Its Otsu mask is a classical comparison result, not a tumor-specific reference
or model prediction.

## Verification mapping

The test suite checks the functions in these groups:

| Test | Functions exercised |
|---|---|
| `testHistogramAndIntensityOperations` | `histogramEqualization`, `histogramMatching`, `adjustBrightness`, `adjustContrast`, `grayLevelTransform` |
| `testRgbLuminanceOperations` | RGB equalization, matching, and brightness handling |
| `testSpatialFiltersAndSharpening` | `meanFilter`, `medianFilter`, `laplacianFilter`, `highPassFilter` |
| `testFourierFilters` | `fourierLowPass`, `fourierHighPass`, `fourierBandPass`; spectrum dimensions and finiteness |
| `testEdgeDetectorsAndOtsu` | `sobelEdge`, `prewittEdge`, `cannyEdge`, `otsuSegmentation` |
| `testRegionGrowing` | `regionGrowing`, including seed bounds |
| `testRgbAndHsvSegmentation` | `rgbSegmentation`, `hsvSegmentation`, invalid bounds |
| `testMorphologyAndShapeFiltering` | dilation, erosion, opening, closing, and `shapeBasedSegmentation` |
| `testInterpolationFunctions` | nearest, bilinear, and bicubic coordinate sampling |
| `testGeometricMappings` | translation, scaling, rotation, affine, forward, and inverse mapping |
| `testResizeInterpolationPreservesBinaryMask` | nearest, bilinear, and bicubic resize; binary-mask nearest output |
| `testResizeExtendsBoundaryPixels` | resizing and scaling at the image boundary |
| `testRadialDistortionRoundTrip` | radial distortion simulation and correction |
| `testImageStateKeepsOriginalAndTracksPipeline` | original-image preservation, selectable enhanced input, mask/history state |
| `testInvalidParameters` | invalid brightness, filter-size, Fourier-cutoff, and translation inputs |

MATLAB R2026b execution: **15/15 test methods passed**. The local MRI demo also
ran on a real 256×256×3 dataset TIFF: the original was preserved; Otsu
threshold was 0.774510; mask areas were 14,582 pixels before and 15,642 after
the recorded closing/shape-filter step. These pixel counts describe that one
classical processing run only; they are not accuracy metrics or tumor labels.
MATLAB Code Analyzer reported no messages for new files. Existing messages in
the untouched GUI prototype were not changed as part of this milestone.

## Integrated GUI and ONNX inference

`MedicalImageAnalysisApp.m` is the tested programmatic AppBase GUI. It provides
image loading, Module 1–3 controls, classical mask refinement, AI inference,
histograms, image/mask/overlay views, reset, and result saving. Run it from the
project root:

```matlab
addpath(genpath(fullfile(pwd,"matlab")));
app = MedicalImageAnalysisApp;
app.setModelPath(fullfile(pwd,"model_output","colab_runs", ...
    "20261101_205443","unet_model.onnx"));
```

The AI button runs from the original MRI independently of classical processing.
For the audited LGG RGB dataset, it selects MATLAB channel 2 (documented FLAIR),
uses the Python preprocessing implementation for 256×256 bilinear resize when
needed and population Z-score normalization, and runs the ONNX model through
Python 3.11 / ONNX Runtime 1.31.1 (`CPUExecutionProvider`). The prediction
threshold is 0.5; restoration to original image dimensions uses nearest
neighbor. Install NumPy, Pillow, PyTorch, and ONNX Runtime in the exact Python
interpreter selected by MATLAB `pyenv`; the bridge imports the shared
`pytorch_pipeline` module, which imports PyTorch.

Automated GUI flows are in `testAppIntegration`; preprocessing and inference
tests are in `testONNXIntegration`. At the end of Milestone 4, that suite
contained 24 tests; the current 34-test suite is reported below.
The GUI is currently a `.m` AppBase class,
not an App Designer `.mlapp`. If an `.mlapp` is mandatory, author/save it from
App Designer using its supported workflow; programmatic conversion of this
AppBase class has not been verified. Do not construct an `.mlapp` archive with
internal serializer APIs.

### Workflow navigation (Milestone 5.3.2)

The app presents six independent navigation sections: **Image Workspace**,
**Image Enhancement**, **Image Segmentation**, **Geometric Transformation**,
**AI Segmentation**, and **Evaluation**. Enhancement, segmentation, and
transformation each have their own operation selector, image-state selector,
parameters, apply/reset controls, descriptions, and input/output views. The
image processing paths share the established image state; their selectors and
views are separate and do not impose an automatic sequential pipeline.

Section resets clear only that section's output and matching processing-history
entries. Resetting enhancement does not remove a classical mask or transformed
image. Mask source (Classical, AI, or Ground Truth) remains separate from the
image-state selector. AI inference still uses the original MRI independently
of enhancement or transformation.

The workspace provides the combined comparison, histograms, masks, and AI
overlay; the enhancement section compares input/output histograms, and the
transformation section reports input/output dimensions. The AI and Evaluation
sections retain their own views and actions.

## Ground-truth evaluation and GUI input behavior

The GUI loads a separate 2-D ground-truth mask using **Load ground truth**.
PNG, TIFF, and grayscale JPG/JPEG are accepted. Binary/logical masks retain
their foreground/background values; grayscale masks with more than two levels
are binarized using Otsu's threshold. If dimensions differ from the current MRI,
the mask is aligned with `nearestNeighborResize` (never bilinear/bicubic). The
GUI reports when this resize occurs. Loading a new MRI clears the prior mask
because it may refer to a different subject; **Reset** preserves the loaded
ground truth, while **Clear ground truth** removes it explicitly. Loading or
clearing it does not start inference or modify the AI/classical states.

When both ground truth and AI prediction exist, the GUI shows the separate
binary masks, prediction overlay, probability map, and a color-coded overlap:
green = true positive (TP), red = false positive (FP), blue = false negative
(FN). The metrics panel reports pixel-level counts and:

- Dice = `2*TP / (2*TP + FP + FN)`
- IoU = `TP / (TP + FP + FN)`
- Precision = `TP / (TP + FP)`
- Recall = `TP / (TP + FN)`

When both masks are empty, Dice and IoU are 1. Precision is 1 when no pixels
were predicted positive; recall is 1 when ground truth has no positive pixels.
These are safe pixel-level educational comparisons, not clinical validation
and not a replacement for the held-out test report.

Image operations use the **Image input state** selection (Original, Enhanced,
or Transformed). Morphology and shape-based filtering use the separate
**Mask source** selection (Classical mask, AI prediction, or Ground truth
mask); the app reports the selected source and leaves the image-state
selection unchanged. Mask-processing output is stored as the classical mask;
the AI prediction, probability map, and ground truth remain separate.

Changing the module or operation updates parameter labels, tooltips,
descriptions, defaults, and visibility. For example, Otsu has no manual
threshold field, Canny exposes sigma, translation exposes X/Y offsets, and
shape filtering exposes minimum/maximum area and minimum circularity. Inputs
are validated against the implemented function domains before execution.

Run all MATLAB tests, including module regression, ONNX integration,
ground-truth evaluation, and GUI workflow tests:

```matlab
addpath(genpath(fullfile(pwd,"matlab")));
results = runModuleTests;
```

MATLAB R2026b: **34/34 test methods passed**. Automated GUI tests cover ground
truth loading/resizing/replacement/reset, AI independence from ground truth,
input propagation, mask-source selection, dynamic parameters, display,
save/reset, errors, workflow navigation, independent selectors, section
operation dispatch, and scoped reset. Manual desktop acceptance of the
Milestone 5.3.2 layout and interactions remains outstanding.
## Milestone 5.3.5 verification

The fresh MATLAB R2026b regression run passed **34/34** tests (0 failed, 0
incomplete). The suite includes Modules 1–3, ONNX integration, GUI integration,
and Ground Truth evaluation. MATLAB Code Analyzer inspected 69 `.m` files; five
advisory findings remain in the legacy `MedicalImageToolbox.m` prototype, with
no diagnostics reported for the current app or tests.

See the [full test report](../docs/TEST_REPORT.md), [fresh MATLAB test output](../docs/evidence/test-results/matlab-r2026b-milestone-5.3.5-full-suite.txt),
and [Final Release Report](../docs/FINAL_RELEASE_REPORT.md). Automated GUI
tests do not constitute human desktop acceptance; target-display review remains
pending.
