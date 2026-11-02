# Integrated Medical Image Processing Toolbox

**MATLAB Image Processing Modules 1–3 with independent U-Net brain glioma segmentation for MRI FLAIR**

This university project combines a MATLAB GUI for classical image processing with a separately controlled PyTorch U-Net inference path. The current MATLAB application uses Python ONNX Runtime through MATLAB's Python interface. It is an educational/research tool, not a medical device or diagnostic system.

## Project objectives

- Implement image enhancement, segmentation/edge detection, and geometric transformation/interpolation requirements as reusable MATLAB functions.
- Provide one navigable GUI for workspace, enhancement, segmentation, transformations, AI segmentation, and ground-truth evaluation.
- Preserve the original MRI and separate enhanced, transformed, classical-mask, AI-input, AI-probability, AI-prediction, and ground-truth states.
- Reproduce the trained model preprocessing for inference without requiring classical operations before AI.

## Features

- **Module 1 — Enhancement:** histogram equalization/matching; brightness, contrast and gray-level transforms; mean/median filtering; Laplacian/high-pass sharpening; Fourier low-/high-/band-pass filtering.
- **Module 2 — Segmentation and edges:** Sobel, Prewitt, Canny, Otsu, region growing, RGB/HSV segmentation, morphology, and shape-based filtering.
- **Module 3 — Geometric processing:** translation, scaling, rotation, affine and forward/inverse mapping, radial distortion/correction, and nearest/bilinear/bicubic interpolation.
- **AI segmentation:** original single-channel 2-D U-Net exported to ONNX; FLAIR preprocessing is delegated to the shared Python implementation.
- **Evaluation:** independent ground-truth mask, TP/FP/FN overlap, and per-image pixel metrics.

The GUI's Enhancement, Segmentation, and Geometric Transformation sections have independent controls, input/output views, and scoped resets. Classical processing and AI inference remain separate. The AI path uses Original MRI directly.

## GUI

Launch from MATLAB R2026b in the project root:

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
app = MedicalImageAnalysisApp;
app.setModelPath(fullfile(pwd, "model_output", "colab_runs", ...
    "20261101_205443", "unet_model.onnx"));
```

See the step-by-step [User Guide](docs/USER_GUIDE.md). The GUI is a MATLAB AppBase `.m` application, not an App Designer-authored `.mlapp`.

## Architecture and technology

- MATLAB R2026b (26.2) + Image Processing Toolbox.
- Python 3.11 configured through MATLAB `pyenv`.
- NumPy, Pillow, PyTorch shared preprocessing module, and ONNX Runtime 1.31.1.
- MATLAB-to-Python ONNX inference using `CPUExecutionProvider`; native MATLAB ONNX import and GPU inference through this bridge are not used/verified.
- Google Colab GPU for the recorded full training experiment.

The current system uses [`matlab/MedicalImageAnalysisApp.m`](matlab/MedicalImageAnalysisApp.m), MATLAB helpers under `matlab/{common,ai,enhancement,segmentation,geometric}`, and the bridge at `python/matlab_onnx_bridge.py`. See [Architecture](docs/ARCHITECTURE.md).

## Installation

Follow [docs/INSTALLATION_GUIDE.md](docs/INSTALLATION_GUIDE.md) for MATLAB toolbox verification, Python 3.11 virtual environment setup, ONNX Runtime pinning, MATLAB `pyenv` configuration, first-run tests, and troubleshooting.

## Testing

From MATLAB in the project root:

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
results = runModuleTests;
assert(all([results.Passed]));
```

**Milestone 5.3.6 verification (2026-11-02): MATLAB R2026b, 34 passed, 0 failed, 0 incomplete; all 7 current Python files compiled, Python tests passed 7/7, and synthetic FLAIR ONNX inference plus MATLAB bridge import passed with CPUExecutionProvider.** See [the Test Report](docs/TEST_REPORT.md) and [Legacy Cleanup Report](docs/LEGACY_CLEANUP_REPORT.md). The project owner confirmed manual presentation-resolution GUI acceptance; clean-machine installation remains untested.

Genuine MATLAB application screenshots and their feature descriptions are in [docs/evidence/SCREENSHOT_INDEX.md](docs/evidence/SCREENSHOT_INDEX.md).

## Audited experiment and artifacts

The final run is stored locally at `model_output/colab_runs/20261101_205443/`. It records a Tesla T4 / CUDA 13.0 / PyTorch 2.11.0+cu130 training environment. Training stopped after 19 epochs; the best validation checkpoint was epoch 7 (Dice 0.784357), with a recorded collapse from epoch 8 whose cause is unknown.

At the fixed 0.5 threshold, the saved unseen-test report covers 569 slices from 16 patients and pixel-pools counts: Dice 0.781607, IoU 0.641507, precision 0.772103, recall 0.791348. ONNX parity covers five slices from one test patient (maximum absolute probability error 3.2783e-7, zero thresholded-mask disagreements). These are reported experiment evidence, not clinical validation; limitations are detailed in [docs/MILESTONE3_FINAL_AUDIT.md](docs/MILESTONE3_FINAL_AUDIT.md).

The `.pth` and `.onnx` artifacts are each approximately 124 MB, and the local dataset is approximately 1.06 GB. `data/` and `model_output/` are excluded from Git. The model artifacts remain preserved in the working project; use [the SHA-256 manifest](docs/evidence/model-artifact-manifest.txt) to verify them. For distribution, provide the run folder separately or configure Git LFS; do not assume the source repository contains the models.

## Repository map

```text
matlab/                 App, shared state, Modules 1–3, tests, MATLAB–Python AI bridge
notebooks/              Current PyTorch Colab notebook and archived historical Keras notebook
python/                 PyTorch training/evaluation/export pipeline, MATLAB ONNX bridge, requirements, tests
data/                   Local dataset, excluded from Git
model_output/            Local experiment runs/artifacts, excluded from Git
docs/                   Installation, user, architecture, status, audit, handover, evidence
```

## Dataset and legacy assets

The local dataset is the [LGG MRI Segmentation Dataset](https://www.kaggle.com/datasets/mateuszbuda/lgg-mri-segmentation), with CC BY-NC-SA 4.0 terms shown on its dataset card. Review those terms before redistribution. Its documentation identifies the RGB channel order as pre-contrast, FLAIR, post-contrast; do not infer FLAIR for arbitrary RGB images.

**Current inference route:** MATLAB `MedicalImageAnalysisApp` → MATLAB ONNX integration → `python/matlab_onnx_bridge.py` → ONNX Runtime `CPUExecutionProvider` → `unet_model.onnx`. The PyTorch training, evaluation, and export pipeline remains available for reproducibility. FastAPI, Docker/Compose, Keras training/inference scripts, and the local Keras model were retired and removed in Milestone 5.3.6. `notebooks/V1Train_UNet_LGG_Colab_with_visual_export.ipynb` remains only as an archived historical experiment; it is not part of the current runtime or installation.

Historical Keras outputs have not been reproduced. The current artifacts and their evidence are the PyTorch/ONNX run listed above.

## Status and handover

The current finalization record is in [docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md), and the developer-oriented checklist is in [docs/PROJECT_HANDOVER.md](docs/PROJECT_HANDOVER.md). Manual presentation-resolution GUI acceptance and transfer of the excluded artifacts were confirmed by the project owner on 2026-11-02; clean-machine installation and any required App Designer `.mlapp` authoring remain unverified. No remote is configured, and no content has been published.

See the [Milestone 5.3.6 Legacy Cleanup Report](docs/LEGACY_CLEANUP_REPORT.md) for removals and fresh verification. The [Milestone 5.3.5 Final Release Report](docs/FINAL_RELEASE_REPORT.md) records its original evidence and subsequent owner-confirmed acceptance updates.
