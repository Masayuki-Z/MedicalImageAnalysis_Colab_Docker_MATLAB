# Group Project Report — MATLAB Image Processing Toolbox

> **Course-project version.** This report follows the group assignment and is separate from `docs/PROJECT_REPORT.md`; that comprehensive report is unchanged. Replace the remaining square-bracket placeholders with your group's names, screenshots, and observations. Training details and experiment results below are taken from the repository's recorded PyTorch/ONNX experiment; do not describe them as a new training run unless you have rerun it.

## Project information

| Item | Details |
|---|---|
| Course / class | [Course name and class] |
| Group name / number | [Group name or number] |
| Student 1 | [Name] — image enhancement and filtering |
| Student 2 | [Name] — segmentation, edge detection, morphology |
| Student 3 | [Name] — geometric transforms, interpolation, integration/testing |
| Student 4 | Masayuki-Z (you) — tumor-segmentation model training and AI evaluation |
| Presentation date | [Date] |
| MATLAB version | MATLAB R2026b (project's recorded test environment) |

## 1. Project overview

Our group developed a MATLAB-based toolbox for experimenting with common image-processing techniques and brain-tumor segmentation. Users can load an image, select a processing operation, adjust its parameters, and compare the input and result in a graphical interface. The toolbox includes three classical image-processing modules and an AI workflow: image enhancement; segmentation and edge detection; geometric transformations and interpolation; and training/inference/evaluation of a U-Net model for MRI tumor segmentation.

The project is intended as a learning and demonstration tool. The classical functions can be tried on general grayscale or RGB images. The AI workflow is designed for FLAIR MRI from the documented LGG dataset. Results depend on input data and parameter choices. This software is not clinically validated and must not be used to diagnose or treat patients.

### Project aims

- Implement the course-required image-processing techniques as reusable MATLAB functions.
- Provide a GUI for loading images, selecting operations, and viewing results.
- Train/use a U-Net tumor-segmentation model with the project's PyTorch workflow and demonstrate inference from the toolbox.
- Keep classical processing, AI prediction, and ground-truth masks distinct and compare results where appropriate.
- Test the functions and document the techniques, code organization, and observed results.

## 2. Team structure and collaboration

| Member | Assigned focus | Main contributions | Evidence / files |
|---|---|---|---|
| Student 1: [Name] | Enhancement and spatial/frequency filtering | Implement and demonstrate histogram/intensity operations, smoothing, sharpening, and Fourier filters; document settings and compare input/output images. | `matlab/enhancement/` |
| Student 2: [Name] | Classical segmentation, edge detection, morphology | Implement and demonstrate edge detectors, threshold/region/color segmentation, and mask refinement; compare outputs and document parameter choices. | `matlab/segmentation/` |
| Student 3: [Name] | Geometric transformations, interpolation, GUI integration/testing | Implement and demonstrate transforms/interpolation; integrate module controls and views; coordinate shared image conventions and run integration/regression tests. | `matlab/geometric/`, `matlab/tests/`, `matlab/MedicalImageAnalysisApp.m` |
| Student 4: **Masayuki-Z (you)** | U-Net training for tumor segmentation, AI inference/evaluation | Prepare and validate the patient-level data split and preprocessing; run/record model training; review validation behavior and checkpoint selection; maintain the inference/export workflow; evaluate predictions and document limitations. | `notebooks/Train_UNet_PyTorch_Colab.ipynb`, `python/pytorch_pipeline.py`, `python/matlab_onnx_bridge.py`, `matlab/ai/` |

**How we coordinated:** The group divided the work by module and agreed on common image and mask conventions before integration. Each member developed or reviewed their assigned functions and recorded the operation inputs, parameters, and outputs. We used the shared repository and MATLAB function documentation to connect the modules to the GUI, then checked that the controls passed compatible image data to each function. The group compared representative outputs, discussed issues during integration, and used the available tests and review feedback to check that changes did not break other modules. Student 4 coordinated the model data/preprocessing and inference interface with Student 3 so that the trained model received the expected FLAIR input and returned a mask the GUI could display. [Add actual meeting/tool details if desired.]

**Challenges and how we addressed them:** One common challenge was that image functions can expect different input forms, such as grayscale versus RGB images, normalized intensities versus integer pixel values, or continuous intensity images versus binary masks. We used shared validation and documented input/output conventions to make these differences explicit. We kept original, enhanced, transformed, classical-mask, AI, and ground-truth states separate to avoid overwriting data. For geometric operations on masks, we used nearest-neighbor interpolation to retain binary labels. During integration, we used separate module controls and a shared dispatch/state flow, then checked representative operations and automated tests. For the AI workflow, we documented the FLAIR channel, resize and normalization steps, and fixed inference threshold so preprocessing was consistent between training and MATLAB inference. The recorded model training also showed a performance collapse after epoch 7; its cause was not established, so we retained the recorded checkpoint and reported this as a limitation rather than claiming a fix.

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

**Recorded classical MRI example:** The repository demo reports an Otsu threshold of 0.774510 for one 256×256×3 dataset TIFF. Its mask area was 14,582 pixels before and 15,642 pixels after the recorded closing/shape-filter step. These are single-run mask sizes, not accuracy measures or ground-truth tumor labels.

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

## 7. Module 4 — Tumor-segmentation model training and AI workflow (Student 4: Masayuki-Z)

### 7.1 Purpose and basic theory

Unlike thresholding or region growing, a trained segmentation model learns image-to-mask patterns from labeled examples. The project uses a 2-D U-Net, a convolutional encoder-decoder network with skip connections that combine coarse contextual features with finer spatial details. It predicts a probability for each pixel; applying a threshold converts the probability map into a binary mask. Training uses MRI slices and corresponding tumor masks, while evaluation on held-out patients estimates overlap with reference labels.

### 7.2 Dataset preparation and patient split

The recorded pipeline pairs TIFF MRI images with binary masks and validates that image/mask dimensions align and that masks contain binary foreground/background values. It selects the FLAIR channel from the documented three-channel MRI data. To reduce patient-level data leakage, images are split by patient folder rather than randomly by slice. The recorded split uses seed 42 and a 70/15/15 train/validation/test allocation:

| Split | Patients | Slices |
|---|---:|---:|
| Training | 77 | 2,719 |
| Validation | 17 | 641 |
| Held-out test | 16 | 569 |
| **Total** | **110** | **3,929** |

The saved split audit reports no patient overlap between subsets. The test set is excluded from training and checkpoint selection. The dataset is the LGG MRI Segmentation Dataset; its dataset-card terms are CC BY-NC-SA 4.0, so review those terms before sharing or redistributing data.

### 7.3 Preprocessing and augmentation

Each RGB slice is read as uint8 and the documented FLAIR channel (zero-based index 1, the second channel) is converted to float32 and scaled to `[0,1]`. Images are resized to 256×256 with bilinear interpolation only when needed; masks use nearest-neighbor interpolation to preserve binary labels. Each 2-D FLAIR slice is normalized independently using population Z-score normalization:

`normalized = (image - slice_mean) / max(slice_standard_deviation, epsilon)`

The configured epsilon is `1e-6`; constant slices are safely centered and produce zeros. Training-only augmentation includes random horizontal flips and rotations up to 10 degrees; the image uses bilinear sampling while its mask uses nearest-neighbor sampling. Validation and test data are not augmented.

### 7.4 U-Net architecture and training configuration

The model is a single-channel, four-level 2-D U-Net. Each encoder/decoder block uses two 3×3 convolutions with ReLU activations; max pooling reduces spatial resolution in the encoder, transposed convolutions upsample in the decoder, and skip connections concatenate encoder features with decoder features. A final 1×1 convolution and sigmoid produce a one-channel probability map.

Recorded training configuration:

| Setting | Recorded value |
|---|---|
| Input / output | One-channel 256×256 FLAIR image / per-pixel probability map |
| Encoder channels | 64, 128, 256, 512 |
| Bottleneck channels | 1024 |
| Decoder channels | 512, 256, 128, 64 |
| Parameters | 31,030,593 |
| Loss | Binary cross-entropy plus soft Dice loss |
| Optimizer / learning rate | Adam, 0.0001 |
| Random seed | 42 |
| Batch size | 8 |
| Maximum epochs | 100 |
| Completed epochs | 19 |
| Checkpoint selection | Best validation Dice; selected checkpoint is epoch 7 |
| Training environment | Google Colab, Tesla T4 GPU, CUDA 13.0, PyTorch 2.11.0+cu130 |
| Recorded full-run elapsed time | 4,016.55 seconds (about 66.9 minutes) |

The repository preserves the training notebook, pipeline, run configuration/history, and model artifacts outside Git. These values describe the audited run and are not a claim that the group repeated training during report preparation.

### 7.5 Model export and MATLAB inference

The selected PyTorch model was exported to ONNX. In the GUI, MATLAB starts with the original MRI, selects the documented FLAIR channel, and calls the Python bridge through MATLAB `pyenv`. The shared preprocessing implementation resizes and normalizes the FLAIR slice consistently with training. ONNX Runtime uses `CPUExecutionProvider`; the model tensor is `[1,1,256,256]`. The application validates that probabilities are finite and in `[0,1]`, thresholds them at 0.5, and restores a binary prediction to the original image dimensions with nearest-neighbor resizing when required. AI input, probability map, prediction, classical mask, and ground truth remain distinct states.

### 7.6 Results and evaluation

At a fixed probability threshold of 0.5, the recorded held-out evaluation pools pixel counts over 569 slices from 16 test patients. The metrics are computed from the aggregate true-positive, false-positive, and false-negative pixel counts; they are not an average of per-patient scores.

| Metric | Recorded held-out result |
|---|---:|
| Dice | 0.781607 |
| IoU | 0.641507 |
| Precision | 0.772103 |
| Recall | 0.791348 |
| True-positive pixels | 289,408 |
| False-positive pixels | 85,423 |
| False-negative pixels | 76,307 |

The ONNX parity report compared five test slices from one patient. Maximum absolute probability difference was `3.2783e-7`, and there were zero thresholded-mask mismatches at 0.5. This is a limited export-consistency check, not broad validation.

Training improved through epoch 7, with best validation Dice 0.784357. Starting at epoch 8, the recorded training loss increased and training/validation Dice collapsed to zero through epoch 19. The reason is unknown: the saved artifacts do not include the optimizer state, per-step gradient norms, or epoch-8 weights needed to establish a cause. The epoch-7 checkpoint was retained; do not present this instability as solved.

**AI result image still needed:** Add a screenshot/export from the actual application showing (1) the FLAIR input, (2) ground-truth mask if available, (3) predicted mask, and (4) overlay or probability map. Caption it with the test/validation split, threshold, and note that the quantitative values above come from the recorded held-out experiment. Do not invent a visual result if the local model/dataset artifacts are unavailable.

**What the recorded results suggest:** The pixel-pooled scores indicate overlap between predictions and annotations on this held-out split, while the nonzero false-positive and false-negative counts show that predictions are not identical to reference masks. The training collapse after epoch 7 and limited five-slice ONNX parity sample are important caveats. These results do not establish clinical usefulness.

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

The project includes MATLAB tests for image operations, invalid parameters, geometric mappings/interpolation, image state, GUI workflows, ONNX integration, and ground-truth evaluation. The repository's recorded MATLAB R2026b verification reported **34 passed, 0 failed, 0 incomplete**. Its Python pipeline unit suite reported **7/7 passed**. A synthetic FLAIR input was also tested through the MATLAB/ONNX CPU bridge. These are existing project verification results; if your group changes the code or runs a different environment, record the new run below rather than implying it was rerun for this report.

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

The group project brings together three classical MATLAB image-processing modules and a trained-model tumor-segmentation workflow. The enhancement module changes intensity and spatial/frequency content; the classical segmentation module detects edges and creates/refines masks; the geometric module transforms images and compares interpolation methods; and the AI work trains/uses a U-Net to predict tumor masks from MRI. The recorded experiment provides a patient-separated test evaluation and an ONNX consistency check, with training instability and limited parity testing clearly noted. The final demonstration should show the functions working on selected images, explain each member's contribution, and discuss results and limitations. Add the requested screenshots and any new group-run results before submission.

## References and project documentation

- [MATLAB function reference](../matlab/README.md)
- [Architecture](ARCHITECTURE.md)
- [User guide](USER_GUIDE.md)
- [Test report](TEST_REPORT.md)
- [Final experiment audit](MILESTONE3_FINAL_AUDIT.md)
- [Comprehensive project report](PROJECT_REPORT.md) — retained separately and unchanged
