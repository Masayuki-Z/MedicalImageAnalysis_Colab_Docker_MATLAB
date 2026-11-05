# Group Project Report — MATLAB Image Processing Toolbox

> **Course-project version.** This report is written for the group assignment and follows the requested student roles and deliverables. It is separate from `docs/PROJECT_REPORT.md`; the comprehensive project report is intentionally left unchanged. Replace text in **[square brackets]** with your group's details, screenshots, and any results you collect during your own demonstration.

## Project information

| Item | Details |
|---|---|
| Course / class | [Course name and class] |
| Group name / number | [Group name or number] |
| Student 1 | [Name] — image enhancement and filtering |
| Student 2 | [Name] — segmentation, edge detection, morphology |
| Student 3 | [Name] — geometric transforms, interpolation, integration/testing |
| Presentation date | [Date] |
| MATLAB version | MATLAB R2026b (project's recorded test environment) |

## 1. Project overview

Our group developed a MATLAB-based toolbox for experimenting with common image-processing techniques. Users can load an image, select a processing operation, adjust its parameters, and compare the input and result in a graphical interface. The toolbox is organized into three modules: image enhancement, segmentation and edge detection, and geometric transformations and interpolation.

The project is intended as a learning and demonstration tool. The functions can be tried on general grayscale or RGB images. Results depend on the input image and selected parameters, so users should inspect and compare outputs rather than assume that one setting is best for every image.

### Project aims

- Implement the image-processing techniques required for the course as reusable MATLAB functions.
- Provide a GUI that makes the modules easy to explore.
- Show original/input images alongside processed results where relevant.
- Test the functions and document the techniques, code organization, and observed results.

## 2. Team structure and collaboration

| Member | Assigned focus | Main contributions | Evidence / files |
|---|---|---|---|
| Student 1: [Name] | Enhancement and spatial/frequency filtering | [List implemented functions, tests, screenshots, or documentation.] | `matlab/enhancement/` — [specific files or evidence] |
| Student 2: [Name] | Segmentation, edge detection, morphology | [List implemented functions, tests, screenshots, or documentation.] | `matlab/segmentation/` — [specific files or evidence] |
| Student 3: [Name] | Geometric transformations, interpolation, integration/testing | [List implemented functions, GUI/integration/testing work.] | `matlab/geometric/`, `matlab/tests/`, `matlab/MedicalImageAnalysisApp.m` — [specific work] |

**How we coordinated:** [Briefly describe how the group shared code, reviewed each other's work, resolved interface decisions, and combined the modules.]

**Challenges and how we addressed them:** [For example: consistent image ranges, RGB versus grayscale handling, parameter choices, mask interpolation, GUI integration, or agreeing on test images. Describe only challenges your group actually encountered.]

## 3. Toolbox organization and workflow

The project separates processing functions by topic so individual operations can be tested and reused without relying on the GUI. The MATLAB application provides a user-facing way to load images, select operations, set parameters, and view results. Shared image state keeps the original image and processed outputs available for comparison.

```text
matlab/
  MedicalImageAnalysisApp.m   GUI and operation dispatch
  common/                     shared image state and helper functions
  enhancement/                Module 1 functions
  segmentation/               Module 2 functions
  geometric/                  Module 3 functions
  tests/                      regression and integration tests
  README.md                   MATLAB function reference
```

**Typical workflow:** load an image → choose a module/operation → set parameters → apply the operation → compare input and output → optionally save the result. For geometric operations on a binary mask, use nearest-neighbor interpolation so the output remains a label mask.

## 4. Module 1 — Image enhancement (Student 1)

### 4.1 Purpose and basic theory

Image enhancement changes image intensities to make details or contrast easier to see. Histogram methods redistribute or match intensity distributions. Gray-level transformations directly map each pixel value. Spatial filters combine values from nearby pixels to smooth noise or emphasize edges. Fourier filtering modifies selected spatial-frequency components: low frequencies correspond to slowly varying image content, while high frequencies include fine detail and edges.

### 4.2 Implemented techniques and MATLAB functions

| Technique | What it does | MATLAB function(s) |
|---|---|---|
| Histogram equalization | Redistributes intensity values to improve use of the available range. | `histogramEqualization` |
| Histogram matching | Adjusts a source image's histogram toward a reference image's distribution. | `histogramMatching` |
| Brightness and contrast | Adds a brightness offset or scales contrast around the middle intensity. | `adjustBrightness`, `adjustContrast` |
| Gray-level transforms | Applies negative, logarithmic, or gamma intensity mappings. | `grayLevelTransform` |
| Mean / median smoothing | Reduces local variation/noise; median filtering is useful for isolated outliers. | `meanFilter`, `medianFilter` |
| Laplacian / high-pass sharpening | Emphasizes local intensity changes and edges. | `laplacianFilter`, `highPassFilter` |
| Fourier low-/high-/band-pass | Keeps or suppresses selected ranges of spatial frequencies. | `fourierLowPass`, `fourierHighPass`, `fourierBandPass` |

The implementation accepts grayscale or RGB images for supported operations. The project documentation describes normalized intensity handling and the supported parameter ranges. Fourier filters use ideal masks; a possible side effect is ringing near sharp edges.

### 4.3 Results and comparison

Use the same input image for a clear side-by-side comparison. Include the parameter values so the result can be reproduced.

| Experiment | Input image | Operation / parameters | What we observed |
|---|---|---|---|
| A | [Image name / source] | Histogram equalization | [Describe contrast/detail changes.] |
| B | [Image name / source] | Mean filter, window size [ ] | [Describe smoothing and any detail loss.] |
| C | [Image name / source] | Median filter, window size [ ] | [Describe noise reduction and edge preservation.] |
| D | [Image name / source] | Sharpening or Fourier filter: [method/parameters] | [Describe visible change and any artifacts.] |

**Insert comparison figure:** [Add a screenshot or image with original and enhanced outputs. Caption: input image, selected operation, parameter values, and the main visible result.]

**Optional recorded project example:** The repository's classical MRI demo processes a dataset-documented FLAIR channel. In its recorded run, Otsu segmentation after enhancement produced a threshold of 0.774510; this is included in Module 2 as a single-image example, not a result attributable to every enhancement setting.

## 5. Module 2 — Image segmentation and edge detection (Student 2)

### 5.1 Purpose and basic theory

Edge detection highlights boundaries where intensity changes quickly. Sobel and Prewitt estimate local gradients with small neighborhood masks. Canny smooths the image and uses gradient suppression and thresholding to identify thin, connected edges. Segmentation assigns pixels to groups: Otsu selects a global threshold based on the image histogram; region growing expands from a seed through connected pixels with sufficiently similar intensity; RGB/HSV methods select pixels by color ranges. Morphological operations change binary regions using a structuring element, which can help refine a mask.

### 5.2 Implemented techniques and MATLAB functions

| Technique | What it does | MATLAB function(s) |
|---|---|---|
| Sobel / Prewitt / Canny | Creates logical edge maps using three common edge detectors. | `sobelEdge`, `prewittEdge`, `cannyEdge` |
| Otsu thresholding | Automatically chooses a global threshold and returns a binary mask. | `otsuSegmentation` |
| Region growing | Starts from a `[row column]` seed and includes connected pixels within an intensity tolerance. | `regionGrowing` |
| RGB / HSV color ranges | Selects pixels within user-provided color bounds. | `rgbSegmentation`, `hsvSegmentation` |
| Dilation / erosion | Expands or contracts foreground areas according to a structuring element. | `morphologicalDilation`, `morphologicalErosion` |
| Opening / closing | Combines erosion/dilation to remove small features or close small gaps. | `morphologicalOpening`, `morphologicalClosing` |
| Shape-based filtering | Filters connected components using area and optional circularity limits. | `shapeBasedSegmentation` |

The region-growing function supports 4- or 8-connectivity. Morphological structuring elements include disk, square, and diamond shapes. These are general-purpose techniques; their outputs depend on the image, seed, thresholds, and shape settings.

### 5.3 Results and visual comparison

For edge detection, compare outputs from the same input and similar threshold settings. For segmentation, include the selected threshold/seed/color bounds and show the mask before and after refinement.

| Experiment | Input image | Method / parameters | What we observed |
|---|---|---|---|
| A | [Image name / source] | Sobel / Prewitt / Canny: [settings] | [Compare edge continuity, thickness, or noise sensitivity.] |
| B | [Image name / source] | Otsu threshold | [Describe foreground/background separation.] |
| C | [Image name / source] | Region growing: seed [ ], tolerance [ ], connectivity [ ] | [Describe selected region and sensitivity to seed/tolerance.] |
| D | [Image name / source] | Color segmentation: [RGB or HSV bounds] | [Describe selected colors/regions.] |
| E | [Image name / source] | Morphology/shape filter: [operation and settings] | [Describe removed noise, filled gaps, or changed component shapes.] |

**Insert comparison figure:** [Add one screenshot showing the input and at least two edge or segmentation outputs. Caption each method and list settings.]

**Optional recorded project example:** In the repository's classical MRI demo, an Otsu mask had 14,582 foreground pixels before the recorded closing/shape-filter step and 15,642 afterward. These are mask areas for one image/run, not accuracy measures or ground-truth labels.

## 6. Module 3 — Geometric transformations and interpolation (Student 3)

### 6.1 Purpose and basic theory

Geometric transformations change where image samples appear. Translation moves pixels, scaling changes image size, rotation turns the image around a center, and affine transformation combines linear coordinate changes such as rotation, scaling, and shear with translation. Forward mapping sends source pixels to output locations and may leave holes; inverse mapping visits output locations and samples the corresponding source position. Interpolation estimates intensity values at non-integer coordinates. Nearest neighbor selects one pixel, bilinear blends nearby samples, and bicubic uses a larger neighborhood for a smoother estimate.

### 6.2 Implemented techniques and MATLAB functions

| Technique | What it does | MATLAB function(s) |
|---|---|---|
| Translation | Moves an image horizontally/vertically. | `translateImage` |
| Scaling / zooming | Resizes an image using a positive scale factor. | `scaleImage` |
| Rotation | Rotates around the image center. | `rotateImage` |
| Affine transformation | Applies a homogeneous 3×3 coordinate transformation. | `affineTransform` |
| Forward / inverse mapping | Demonstrates scatter mapping and inverse-sampled warping. | `forwardMapping`, `inverseMapping` |
| Interpolation | Samples image coordinates using nearest, bilinear, or bicubic methods. | `nearestNeighborInterpolation`, `bilinearInterpolation`, `bicubicInterpolation` |
| Resizing | Resizes to requested dimensions using each interpolation method. | `nearestNeighborResize`, `bilinearResize`, `bicubicResize` |
| Radial distortion and correction | Simulates and corrects a radial lens-distortion model. | `simulateRadialDistortion`, `radialDistortionCorrection` |
| Optional image registration | Not included in the current project milestone. | [If your group implements registration, describe the method and add function/tests here.] |

The coordinate convention is `x = column`, `y = row`, with pixel coordinates starting at 1. Positive translation offsets move right/down; positive rotation is counterclockwise. Use nearest-neighbor interpolation for binary masks; bilinear and bicubic methods can create non-binary values in a mask.

### 6.3 Results and comparison

| Experiment | Input image | Transform / interpolation | What we observed |
|---|---|---|---|
| A | [Image name / source] | Translation: dx [ ], dy [ ] | [Describe direction and boundary fill.] |
| B | [Image name / source] | Scale factor [ ]; interpolation [ ] | [Compare size/detail.] |
| C | [Image name / source] | Rotation [ ] degrees; interpolation [ ] | [Describe rotation and edge effects.] |
| D | [Image name / source] | Affine or radial correction: [settings] | [Describe geometric change.] |
| E | [Image name / source] | Nearest vs bilinear vs bicubic resize | [Compare blockiness/smoothness and any overshoot.] |

**Insert comparison figure:** [Add original and transformed images; for interpolation, show the same crop/region at the same display scale.]

**Integration/testing work by Student 3:** [Describe how operations were connected to the GUI, what shared input/output conventions were used, and which tests or integration checks were performed.]

## 7. GUI and integrated toolbox

The MATLAB GUI is the common entry point to the three modules. It provides separate sections for the image workspace, enhancement, segmentation, geometric transformation, AI segmentation, and evaluation. For the course deliverable, focus the demonstration on loading an image, selecting a Module 1–3 operation, applying it, and comparing the displayed input and result. The AI and evaluation sections are additional project features and are not required to explain the three classical course modules.

**GUI demonstration steps:**

1. Start MATLAB in the project root and add the MATLAB folders to the path.
2. Launch `MedicalImageAnalysisApp`.
3. Load a sample image.
4. Open each module section and demonstrate one or more operations.
5. Show the original/input and output views; describe the selected parameters.
6. Demonstrate reset or switching operations if time allows.

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
app = MedicalImageAnalysisApp;
```

**GUI screenshot/evidence:** [Insert screenshot of the toolbox with a loaded image and a representative result.]

## 8. Testing and observed overall results

The project includes MATLAB tests for image operations, invalid parameters, geometric mappings/interpolation, image state, GUI workflows, ONNX integration, and ground-truth evaluation. The repository's recorded MATLAB R2026b verification reported **34 passed, 0 failed, 0 incomplete**. Its Python pipeline test suite reported **7/7 passed**. These are existing project verification results; if your group changes the code or runs a different environment, record the new run below rather than implying it was rerun for this report.

| Your group's test run | Result |
|---|---|
| Date and MATLAB version | [Fill in] |
| MATLAB command used | `results = runModuleTests;` [or your actual command] |
| Tests passed / failed / incomplete | [Fill in actual output] |
| Images/operations manually checked | [Fill in] |
| Issues found and fixes | [Fill in] |

**Overall result summary:** [Summarize what worked well, which techniques were easiest/hardest to compare, and any limitations observed on your chosen images.]

## 9. Code documentation

The MATLAB function reference is in `matlab/README.md`; it lists the available functions, input conventions, outputs, parameters, and examples. The architecture and usage documentation are in `docs/ARCHITECTURE.md` and `docs/USER_GUIDE.md`. Function names and folders are organized by module, and the test suite helps verify expected behavior.

For this course submission, make sure that:

- Each function has a clear name and a short description of its purpose and inputs/outputs.
- Comments explain non-obvious steps, parameter choices, coordinate conventions, or image assumptions.
- GUI controls and parameter names are understandable to a user who did not write the code.
- Screenshots and result captions identify the method and parameters used.
- Any limitations or unfinished optional features (such as image registration) are stated honestly.

**Documentation/comments completed by the group:** [Describe any documentation or inline comments your group added or reviewed.]

## 10. Real-world applications and limitations

Image enhancement, edge detection, segmentation, and geometric transformation are useful building blocks in areas such as microscopy, radiology research, industrial inspection, remote sensing, and image restoration. In practical use, the best method depends on the imaging modality, noise, contrast, annotations, and the task. This toolbox demonstrates techniques and supports experimentation; its outputs are not medically validated and should not be used to diagnose or treat patients.

**Application example discussed by the group:** [Choose one suitable non-clinical or research example and explain which module could help and why.]

## 11. Group presentation plan (5–10 minutes)

Suggested 7-minute structure; adjust to your class and actual timing:

| Time | Presenter / content |
|---|---|
| 0:00–0:45 | Introduce the project goal and the three student roles. |
| 0:45–2:15 | Student 1 demonstrates enhancement/filtering and compares outputs. |
| 2:15–3:45 | Student 2 demonstrates edge detection, segmentation, and morphology. |
| 3:45–5:15 | Student 3 demonstrates transformations/interpolation and explains integration/testing. |
| 5:15–6:15 | Show the integrated GUI workflow and summarize test/results evidence. |
| 6:15–7:00 | Discuss one challenge, a real-world application, limitations, and conclusion. |

**Presentation notes:** [Write a few speaking points, select a demonstration image, and decide who controls the GUI. Avoid spending the whole presentation on setup.] 

## 12. Conclusion

The group project brings together three MATLAB image-processing modules in a toolbox with a graphical interface. The enhancement module changes intensity and spatial/frequency content; the segmentation module detects edges and creates/refines masks; and the geometric module transforms images and compares interpolation methods. The final demonstration should show the functions working on selected images, explain each member's contribution, and discuss results and limitations. Fill in the experiment tables and screenshot placeholders with your group's own evidence before submission.

## References and project documentation

- [MATLAB function reference](../matlab/README.md)
- [Architecture](ARCHITECTURE.md)
- [User guide](USER_GUIDE.md)
- [Test report](TEST_REPORT.md)
- [Comprehensive project report](PROJECT_REPORT.md) — retained separately and unchanged
