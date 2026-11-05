# Group Project Report — MATLAB Image Processing Toolbox

> **Course-project version.** This report follows the group assignment and is separate from `docs/PROJECT_REPORT.md`; that comprehensive report is unchanged. Replace text in **[square brackets]** with your group's details, screenshots, and results from your own demonstration. The model-training section documents the repository's existing PyTorch/U-Net workflow; identify the member responsible for training and add your actual contribution details.

## Project information

| Item | Details |
|---|---|
| Course / class | [Course name and class] |
| Group name / number | [Group name or number] |
| Student 1 | [Name] — image enhancement and filtering |
| Student 2 | [Name] — segmentation, edge detection, morphology |
| Student 3 | [Name] — geometric transforms, interpolation, integration/testing |
| Student 4 | [Name] — tumor-segmentation model training and AI evaluation |
| Presentation date | [Date] |
| MATLAB version | MATLAB R2026b (project's recorded test environment) |

## 1. Project overview

Our group developed a MATLAB-based toolbox for experimenting with common image-processing techniques and brain-tumor segmentation. Users can load an image, select a processing operation, adjust parameters, and compare the input and result in a graphical interface. The toolbox includes three classical image-processing modules and an AI workflow: image enhancement; segmentation and edge detection; geometric transformations and interpolation; and training/inference/evaluation of a U-Net model for MRI tumor segmentation.

The project is intended as a learning and demonstration tool. The functions can be tried on general grayscale or RGB images, while the AI workflow is designed for FLAIR MRI from the documented LGG dataset. Results depend on input data and parameter choices. This software is not clinically validated and must not be used to diagnose or treat patients.

### Project aims

- Implement the course-required image-processing techniques as reusable MATLAB functions.
- Provide a GUI for loading images, selecting operations, and viewing results.
- Develop/train a U-Net tumor-segmentation model using the project's PyTorch training pipeline and demonstrate its inference from the toolbox.
- Keep classical processing, AI prediction, and ground-truth masks distinct and compare results where appropriate.
- Test the functions and document the techniques, code organization, and observed results.

## 2. Team structure and collaboration

| Member | Assigned focus | Main contributions | Evidence / files |
|---|---|---|---|
| Student 1: [Name] | Enhancement and spatial/frequency filtering | [List implemented functions, tests, screenshots, or documentation.] | `matlab/enhancement/` — [specific files or evidence] |
| Student 2: [Name] | Classical segmentation, edge detection, morphology | [List implemented functions, tests, screenshots, or documentation.] | `matlab/segmentation/` — [specific files or evidence] |
| Student 3: [Name] | Geometric transformations, interpolation, GUI integration/testing | [List implemented functions, tests, screenshots, and integration work.] | `matlab/geometric/`, `matlab/tests/`, `matlab/MedicalImageAnalysisApp.m` — [specific work] |
| Student 4: [Name] | U-Net training for tumor segmentation, AI inference/evaluation | [Describe dataset preparation, training, validation, model export, and evaluation actually completed.] | `notebooks/`, `python/pytorch_pipeline.py`, `python/matlab_onnx_bridge.py`, `matlab/ai/` — [specific work] |

**How we coordinated:** [Briefly describe how the group shared code, reviewed each other's work, agreed on interfaces, and combined the modules and model workflow.]

**Challenges and how we addressed them:** [For example: image ranges, RGB versus grayscale handling, selecting parameters, mask interpolation, connecting the GUI to Python, model preprocessing consistency, or agreeing on test images. Describe only challenges your group actually encountered.]

## 3. Toolbox organization and workflow

The project separates processing functions by topic so operations can be tested and reused without relying on the GUI. The MATLAB application provides a user-facing way to load images, select operations, set parameters, and view results. Shared image state keeps the original image, processed outputs, and different mask sources available separately.

```text
matlab/
  MedicalImageAnalysisApp.m   GUI and operation dispatch
  common/                     shared image state and helper functions
  enhancement/                Module 1 functions
  segmentation/               Module 2 functions
  geometric/                  Module 3 functions
  ai/                         MATLAB-side tumor model integration
  tests/                      regression and integration tests
  README.md                   MATLAB function reference
python/
  pytorch_pipeline.py         shared model training/evaluation/preprocessing
  matlab_onnx_bridge.py       MATLAB-to-ONNX Runtime inference bridge
notebooks/
  Train_UNet_PyTorch_Colab.ipynb  Colab training workflow
```

**Typical classical workflow:** load an image → choose a module/operation → set parameters → apply the operation → compare input and output → optionally save the result. **Typical AI workflow:** load the supported MRI → configure the model path/runtime → select the documented FLAIR channel → preprocess and infer → inspect the predicted mask/probability map → compare with a separately loaded ground truth if available. For geometric operations on a binary mask, use nearest-neighbor interpolation so the output remains a label mask.

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

The implementation accepts grayscale or RGB images for supported operations. The project documentation describes normalized intensity handling and supported parameter ranges. Fourier filters use ideal masks; a possible side effect is ringing near sharp edges.

### 4.3 Results and comparison

Use the same input image for a clear side-by-side comparison. Include parameter values so the result can be reproduced.

| Experiment | Input image | Operation / parameters | What we observed |
|---|---|---|---|
| A | [Image name / source] | Histogram equalization | [Describe contrast/detail changes.] |
| B | [Image name / source] | Mean filter, window size [ ] | [Describe smoothing and any detail loss.] |
| C | [Image name / source] | Median filter, window size [ ] | [Describe noise reduction and edge preservation.] |
| D | [Image name / source] | Sharpening or Fourier filter: [method/parameters] | [Describe visible change and any artifacts.] |

**Insert comparison figure:** [Add a screenshot/image with original and enhanced outputs. Caption the input, operation, parameters, and main visible result.]

## 5. Module 2 — Classical segmentation and edge detection (Student 2)

### 5.1 Purpose and basic theory

Edge detection highlights boundaries where intensity changes quickly. Sobel and Prewitt estimate local gradients with small neighborhood masks. Canny smooths the image and uses gradient suppression and thresholding to identify thin, connected edges. Segmentation assigns pixels to groups: Otsu selects a global threshold based on the image histogram; region growing expands from a seed through connected pixels with sufficiently similar intensity; RGB/HSV methods select pixels by color ranges. Morphological operations change binary regions using a structuring element and can help refine a mask.

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

The region-growing function supports 4- or 8-connectivity. Morphological structuring elements include disk, square, and diamond shapes. These are general-purpose techniques; their outputs depend on the image, seed, thresholds, and shape settings. Classical segmentation is distinct from the learned tumor model described in Module 4.

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

**Optional recorded project example:** The repository's classical MRI demo reports an Otsu threshold of 0.774510 for one 256×256×3 dataset TIFF. Its mask area was 14,582 pixels before and 15,642 pixels after the recorded closing/shape-filter step. These are single-run mask sizes, not accuracy measures or ground-truth tumor labels.

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
| Optional image registration | Not included in the current project milestone. | [If implemented, describe the method and add function/tests here.] |

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

**Integration/testing work by Student 3:** [Describe how operations were connected to the GUI, the shared input/output conventions, and the tests or integration checks actually performed.]

## 7. Module 4 — Tumor-segmentation model training and AI workflow (Student 4)

### 7.1 Purpose and basic theory

Unlike thresholding or region growing, a trained segmentation model learns image-to-mask patterns from labeled examples. The project uses a 2-D U-Net, a convolutional encoder-decoder network with skip connections that combine coarse contextual features with finer spatial details. It predicts a probability for each pixel; applying a threshold converts the probability map into a binary mask. Training uses MRI slices and corresponding tumor masks, while evaluation uses held-out data to estimate how well predictions overlap the labels.

### 7.2 Training and inference implementation

The repository provides a PyTorch Colab notebook and Python pipeline for dataset preparation, model training/evaluation, preprocessing, and export. The trained network is exported to ONNX for use from the MATLAB application. The MATLAB-side AI code selects the documented FLAIR channel from the **original MRI** and calls `python/matlab_onnx_bridge.py` through MATLAB's configured Python environment. The shared preprocessing converts the image to float32 `[0,1]`, resizes to 256×256 with bilinear interpolation when needed, and applies per-slice population Z-score normalization with epsilon `1e-6`. ONNX Runtime runs with `CPUExecutionProvider`; the model input/output shape is `[1,1,256,256]`. MATLAB thresholds probabilities at 0.5 and uses nearest-neighbor resizing if the binary mask must be restored to the original dimensions.

**Student 4 training responsibilities:** document which dataset split and preprocessing were used, configure and run the training, monitor training/validation behavior, select a checkpoint based on the project's validation procedure, export or use the ONNX model, and report evaluation on held-out data. Fill in the actual work performed below; do not state that training was repeated unless your group actually ran it.

| Training item | Group details |
|---|---|
| Dataset and license/source | [Dataset name/source and applicable terms] |
| Patient-level or other split | [Describe train/validation/test split; avoid data leakage] |
| Input modality and image size | [For example, FLAIR and 256×256; confirm actual setup] |
| Model and loss/optimizer | [Fill in actual U-Net configuration, loss, optimizer, and key settings] |
| Training environment and epochs | [Fill in actual environment and completed epochs] |
| Selected checkpoint and selection rule | [Fill in] |
| Export/inference format | [For example, ONNX; fill in what you used] |
| Student 4 contribution | [Describe actual individual contribution] |

### 7.3 Results and evaluation

When ground-truth masks are available, compare predicted and reference masks using pixel counts and overlap metrics. The project GUI can show TP/FP/FN overlap and report Dice, IoU, precision, and recall. Report the test split and calculation method with any numbers.

The repository's recorded experiment—not necessarily a new run by this course group—used a fixed 0.5 threshold and reports pooled pixel metrics for 569 unseen-test slices from 16 patients:

| Metric | Recorded project value | Our group's result (if rerun) |
|---|---:|---:|
| Dice | 0.781607 | [Fill in or write “not rerun”] |
| IoU | 0.641507 | [Fill in or write “not rerun”] |
| Precision | 0.772103 | [Fill in or write “not rerun”] |
| Recall | 0.791348 | [Fill in or write “not rerun”] |

The recorded training stopped after 19 epochs, with the best validation checkpoint at epoch 7; the reported training curve collapsed after epoch 7 for an unknown reason. ONNX parity was checked on five slices from one test patient only. Include this context when discussing the metrics, and do not present them as clinical performance or claim that the group reproduced them without running the experiment.

**Insert AI results figure:** [Show an MRI input, ground-truth mask if available, predicted mask, and overlay/probability map. State the subject/split, threshold, and whether this is a repository example or your group's new result.]

**What we observed:** [Describe visible successes and errors, such as missed small regions or false positives. Do not infer clinical significance.]

## 8. GUI and integrated toolbox

The MATLAB GUI is the common entry point to the modules. It provides sections for the image workspace, enhancement, segmentation, geometric transformation, AI segmentation, and evaluation. For the course demonstration, show loading an image, selecting a Module 1–3 operation, applying it, and comparing the displayed input and result. If model artifacts and Python dependencies are available, also demonstrate tumor inference and evaluation. The AI and evaluation sections complement the three classical course modules.

**GUI demonstration steps:**

1. Start MATLAB in the project root and add the MATLAB folders to the path.
2. Launch `MedicalImageAnalysisApp`.
3. Load a sample image and demonstrate at least one operation from each classical module.
4. Show the original/input and output views and describe the selected parameters.
5. If the ONNX model/runtime are set up, run AI segmentation on a supported MRI and display the prediction separately from any classical mask.
6. Demonstrate reset or switching operations if time allows.

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
app = MedicalImageAnalysisApp;
```

**GUI screenshot/evidence:** [Insert screenshot of the toolbox with a loaded image and representative result.]

## 9. Testing and observed overall results

The project includes MATLAB tests for image operations, invalid parameters, geometric mappings/interpolation, image state, GUI workflows, ONNX integration, and ground-truth evaluation. The repository's recorded MATLAB R2026b verification reported **34 passed, 0 failed, 0 incomplete**. Its Python pipeline unit suite reported **7/7 passed**. These are existing project verification results; if your group changes the code or runs a different environment, record the new run below rather than implying it was rerun for this report.

| Your group's test run | Result |
|---|---|
| Date and MATLAB version | [Fill in] |
| MATLAB command used | `results = runModuleTests;` [or your actual command] |
| MATLAB tests passed / failed / incomplete | [Fill in actual output] |
| Python/model tests actually run | [Fill in actual output or “not run”] |
| Images/operations manually checked | [Fill in] |
| Issues found and fixes | [Fill in] |

**Overall result summary:** [Summarize what worked well, which techniques/models were easiest or hardest to compare, and any limitations observed on your chosen images.]

## 10. Code documentation

The MATLAB function reference is in `matlab/README.md`; it lists available functions, input conventions, outputs, parameters, and examples. Architecture and usage documentation are in `docs/ARCHITECTURE.md` and `docs/USER_GUIDE.md`. The training and inference code is in the `python/`, `notebooks/`, and `matlab/ai/` directories. Function names and folders are organized by module, and tests help verify expected behavior.

For this course submission, make sure that:

- Each function has a clear name and a short description of its purpose and inputs/outputs.
- Comments explain non-obvious steps, parameter choices, coordinate conventions, model preprocessing, or image assumptions.
- GUI controls and parameter names are understandable to a user who did not write the code.
- Screenshots and result captions identify the method/model and parameters used.
- Model results state the data split and whether they are repository-recorded or newly produced by your group.
- Limitations or unfinished optional features (such as image registration) are stated honestly.

**Documentation/comments completed by the group:** [Describe any documentation or inline comments your group added or reviewed.]

## 11. Real-world applications and limitations

Image enhancement, edge detection, segmentation, and geometric transformation are useful building blocks in microscopy, radiology research, industrial inspection, remote sensing, and image restoration. A learned model can provide an additional way to propose regions from examples, but its results depend on representative training data and careful validation. This toolbox demonstrates techniques and supports experimentation; it is not clinically validated and must not be used to diagnose or treat patients.

**Application example discussed by the group:** [Choose an appropriate research or educational example and explain which module could help and why.]

## 12. Group presentation plan (5–10 minutes)

Suggested 8-minute structure; adjust to the actual presentation length:

| Time | Presenter / content |
|---|---|
| 0:00–0:40 | Introduce the project goal and the four student roles. |
| 0:40–1:50 | Student 1 demonstrates enhancement/filtering and compares outputs. |
| 1:50–3:00 | Student 2 demonstrates edge detection, classical segmentation, and morphology. |
| 3:00–4:10 | Student 3 demonstrates transformations/interpolation and explains GUI integration/testing. |
| 4:10–5:40 | Student 4 explains the tumor-segmentation dataset/model workflow and shows prediction/evaluation results. |
| 5:40–6:50 | Demonstrate the integrated GUI workflow and summarize test evidence. |
| 6:50–8:00 | Discuss teamwork, one challenge, applications, limitations, and conclusion. |

**Presentation notes:** [Write a few speaking points, select a demonstration image, confirm model/runtime availability, and decide who controls the GUI. Avoid spending most of the presentation on setup.]

## 13. Conclusion

The group project brings together three classical MATLAB image-processing modules and a trained-model tumor-segmentation workflow. The enhancement module changes intensity and spatial/frequency content; the classical segmentation module detects edges and creates/refines masks; the geometric module transforms images and compares interpolation methods; and the AI work trains or uses a U-Net to predict tumor masks from MRI. The final demonstration should show the functions working on selected images, explain each member's contribution, and discuss results and limitations. Fill in the experiment tables, training details, and screenshot placeholders with your group's own evidence before submission.

## References and project documentation

- [MATLAB function reference](../matlab/README.md)
- [Architecture](ARCHITECTURE.md)
- [User guide](USER_GUIDE.md)
- [Test report](TEST_REPORT.md)
- [Comprehensive project report](PROJECT_REPORT.md) — retained separately and unchanged
