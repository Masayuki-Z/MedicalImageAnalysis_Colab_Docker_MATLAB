# Final Release and Acceptance Report

**Milestone:** 5.3.5 — Final Acceptance, Reproducibility & Release Readiness
**Prepared for:** Jangjie Saejang
**Audit date:** 2026-11-02
**Release scope:** Local academic/research handover; no remote publication.

## Status key

- **VERIFIED** — directly confirmed by execution or inspection.
- **AUTOMATED TESTED** — exercised by the automated test suite.
- **MANUAL ACCEPTANCE PENDING** — requires human interaction or approval.
- **NOT TESTED** — no verification evidence exists.
- **OUT OF SCOPE** — not part of the current application.

## 1. Project overview

**VERIFIED** — The Integrated Medical Image Processing Toolbox combines the three required MATLAB image-processing modules with a distinct PyTorch U-Net/ONNX inference path for MRI FLAIR. It is an academic/research demonstration, not a medical device or diagnostic system.

## 2. Final system architecture

**VERIFIED** — The current app is a programmatic MATLAB AppBase `.m` class with six sections: Image Workspace, Image Enhancement, Image Segmentation, Geometric Transformation, AI Segmentation, and Evaluation. The classical enhancement, segmentation, and transformation paths have independent selectors and controls and share explicit image state; they are not forced into one sequence.

**VERIFIED** — AI inference starts from the preserved Original MRI. MATLAB selects the documented FLAIR channel for the audited LGG RGB dataset, then calls the Python bridge through MATLAB `pyenv`. Python performs the model preprocessing and ONNX Runtime inference with `CPUExecutionProvider`. AI input, probability map, prediction, classical mask, and Ground Truth remain separate states. Loading Ground Truth does not start inference.

**OUT OF SCOPE** — Native MATLAB ONNX import and GPU inference through the MATLAB bridge. FastAPI, Docker/Compose, Keras scripts, and the legacy Keras model were retired in Milestone 5.3.6; the Keras-era Colab notebook remains an archived historical experiment only.

## 3. Implemented features

**AUTOMATED TESTED** — Module 1 includes histogram/intensity processing, spatial filtering and sharpening, and Fourier low-/high-/band-pass filtering.

**AUTOMATED TESTED** — Module 2 includes Sobel, Prewitt, Canny, Otsu, region growing, RGB/HSV segmentation, morphology, and shape filtering.

**AUTOMATED TESTED** — Module 3 includes translation, scaling, rotation, affine and forward/inverse mapping, radial distortion/correction, and nearest/bilinear/bicubic interpolation. Binary masks use nearest-neighbor geometric resampling.

**AUTOMATED TESTED** — GUI workflows include operation selection, parameters, apply/reset, separate image/mask states, AI inference from Original MRI, Ground Truth loading/alignment, pixel metrics/overlap, save/reset actions, and missing-input/model error paths.

## 4. Verified runtime environment

**VERIFIED** — MATLAB R2026b (26.2.0.3386108) on Windows with Image Processing Toolbox. MATLAB `pyenv` reports Python 3.11 at `C:\Users\ACER\AppData\Local\Programs\Python\Python311\python.EXE`, `InProcess` execution. The isolated `pyenv` inspection recorded `Status: NotLoaded` before Python initialization; the integration suite subsequently initialized the bridge and ran ONNX inference. See [the MATLAB runtime evidence](evidence/test-results/matlab-r2026b-milestone-5.3.5-pyenv.txt).

**VERIFIED** — The configured Python 3.11 interpreter reports NumPy 1.26.4, Pillow 11.0.0, PyTorch 2.9.1+cpu, Matplotlib 3.9.2, and ONNX Runtime 1.31.1. The runtime exposes Azure and CPU providers; the bridge explicitly requests only `CPUExecutionProvider`. The Python audit output records versions, model signature, and smoke inference.

**NOT TESTED** — Installing these dependencies into a newly created environment or on a clean machine. The installation guide describes that setup but does not constitute a clean-install test. The optional `onnx` package for exporting/checking ONNX graphs is not installed in the audited interpreter; no export was run for this milestone.

## 5. MATLAB regression results

**AUTOMATED TESTED** — Fresh MATLAB R2026b run: **34 passed, 0 failed, 0 incomplete**.

| Test group | Result |
|---|---:|
| Modules 1–3 | 15 passed |
| ONNX integration | 6 passed |
| GUI integration | 7 passed |
| Ground Truth/evaluation | 6 passed |
| **Total** | **34 passed** |

Raw output: [MATLAB Milestone 5.3.5 full-suite log](evidence/test-results/matlab-r2026b-milestone-5.3.5-full-suite.txt).

**VERIFIED** — MATLAB Code Analyzer inspected 69 `.m` files and reported five advisory diagnostics in the legacy `matlab/MedicalImageToolbox.m` prototype. No diagnostics were reported for the current app or test files. The legacy prototype and tests were not modified to suppress these findings. See [Code Analyzer output](evidence/test-results/matlab-r2026b-milestone-5.3.5-code-analyzer.txt).

## 6. Python and ONNX results

**AUTOMATED TESTED** — All 10 Python source files compiled; `python -m unittest discover -s python -p "test_pytorch_pipeline.py" -v` completed with **7 passed, 0 failed**.

**VERIFIED** — The MATLAB ONNX bridge imported successfully. A fresh synthetic uint8 FLAIR input was preprocessed and inferred with the preserved ONNX model using CPUExecutionProvider. Input and output were `[1,1,256,256]`; probability output was finite and within `[0,1]`. This smoke test did not evaluate a test patient or alter experiment results.

Evidence: [Python audit and test output](evidence/test-results/python-r2026b-milestone-5.3.5.txt).

## 7. GUI acceptance results

**AUTOMATED TESTED** — The 7 GUI integration tests exercised six-section navigation, independent selectors, parameter validation, apply/reset behavior, image and mask-state independence, original-image inference, Ground Truth separation, metrics/overlap display, save/reset, and missing-input/model errors.

**VERIFIED** — Eleven genuine MATLAB `exportapp` screenshots and their feature descriptions are present in the [screenshot index](evidence/SCREENSHOT_INDEX.md). They were generated from the actual app using preserved sample/model assets; they are not user-acceptance signatures.

**VERIFIED (owner-confirmed)** — The project owner confirmed the human presentation-resolution GUI walkthrough and acceptance on 2026-11-02. This confirmation was provided directly by the owner; it was not independently witnessed or separately captured as test evidence in this audit. The genuine screenshots show scrollable content beyond some captured viewports.

**MANUAL ACCEPTANCE PENDING only if required by the course** — The GUI is a programmatic AppBase `.m` class, not an App Designer `.mlapp`. If the instructor requires `.mlapp`, create and validate it separately using supported App Designer workflows; automatic conversion was not attempted.

## 8. Model artifact integrity

**VERIFIED** — The existing final artifacts remain present locally and match the existing SHA-256 manifest. No training, export, test-metric generation, threshold selection, or experiment rewrite was performed.

| Artifact | Size | SHA-256 |
|---|---:|---|
| `best_unet.pth` | 124,140,929 bytes | `88397DE274A8BC2D015DC35F658AE28F8B45A756852E3AD18D48EF1D6B53011E` |
| `unet_model.onnx` | 124,134,029 bytes | `1CDB60FF9ACBA8BFDDEB621A9BFEA82E41C8BA176F0694988AA7C2FC0F21A290` |

The complete final run also retains test metrics, training history, patient split, model and normalization configuration, ONNX parity report, Colab environment report, and MATLAB exports. See [the artifact manifest](evidence/model-artifact-manifest.txt).

**VERIFIED** — The recorded Colab training curve collapsed after epoch 7; the best validation checkpoint is epoch 7. The cause remains unknown. ONNX parity is limited to five slices from one test patient (maximum absolute probability difference `3.2783e-7`, zero thresholded-mask disagreements at 0.5); this is not broad validation or evidence of clinical performance.

## 9. Evidence inventory

**VERIFIED** — The repository contains:

- [11 genuine app screenshots and index](evidence/SCREENSHOT_INDEX.md).
- [Fresh MATLAB 34-test output](evidence/test-results/matlab-r2026b-milestone-5.3.5-full-suite.txt).
- [Python compilation, unit-test, runtime, and inference output](evidence/test-results/python-r2026b-milestone-5.3.5.txt).
- [MATLAB Code Analyzer output](evidence/test-results/matlab-r2026b-milestone-5.3.5-code-analyzer.txt).
- [MATLAB `pyenv` inspection](evidence/test-results/matlab-r2026b-milestone-5.3.5-pyenv.txt).
- [Fresh Milestone 5.3.5 repository audit output](evidence/test-results/repository-audit-milestone-5.3.5.txt); the [Milestone 5.3.4 audit log](evidence/test-results/repository-audit.txt) is retained as historical evidence.
- [Model artifact SHA-256 manifest](evidence/model-artifact-manifest.txt).
- [Installation](INSTALLATION_GUIDE.md), [user](USER_GUIDE.md), [architecture](ARCHITECTURE.md), [test](TEST_REPORT.md), [status](PROJECT_STATUS.md), and [handover](PROJECT_HANDOVER.md) documents.

## 10. Git repository status

**VERIFIED** — Branch `main`; the audit began from clean commit `81d0f677f04e50e6f39939c072ad8fbd676b1b5c`. No remote is configured. The dataset, credentials directory, and `model_output/` remain ignored; no tracked file exceeded 50 MiB. A limited high-confidence credential-token scan found no matches in tracked text source. The credential directory was not opened.

**VERIFIED** — The final documentation-only release commit is on `main`, uses the requested Milestone 5.3.5 message, and leaves a clean working tree. The repository has no remote and was not published. The pre-release baseline was `81d0f677f04e50e6f39939c072ad8fbd676b1b5c`.

## 11. Known limitations

- The bridge is CPU-only. GPU inference through MATLAB is not verified.
- The project is not clinically validated and must not be used for diagnosis or treatment.
- Training instability after epoch 7 has no verified cause.
- ONNX parity covers only five slices from one patient.
- The model and dataset are excluded from Git. The project owner confirmed recipient transfer and hash verification on 2026-11-02; that transfer was not independently repeated in this session. The dataset is distributed under CC BY-NC-SA 4.0; review its terms before redistribution.
- The optional local ONNX export/graph-validation dependency is absent.
- The Milestone 5.3.5 analyzer recorded five advisory findings in the then-current prototype; the Milestone 5.3.6 analyzer records three after retiring its Keras/API controls.
- The Python install steps have not been tested on a clean machine.

## 12. Owner-confirmed acceptance and remaining manual tasks

**VERIFIED (owner-confirmed, 2026-11-02)** — Presentation-resolution GUI review and acceptance, plus transfer and hash verification of the excluded artifacts, were confirmed by the project owner. They were not independently repeated during this audit.

**MANUAL ACCEPTANCE PENDING only if required by the course:** determine whether an App Designer `.mlapp` is mandatory; if yes, author and validate it separately.

**NOT TESTED:** Perform a clean-machine installation if reproducibility certification is required.

## 13. Installation and execution

**VERIFIED LOCALLY; CLEAN INSTALL NOT TESTED** — Use [the installation guide](INSTALLATION_GUIDE.md) for MATLAB R2026b, Image Processing Toolbox, Python 3.11, required packages, and `pyenv` setup. It documents ONNX Runtime 1.31.1 and Windows/Linux/macOS setup.

Obtain the project source and separately obtain:

- Dataset: `data/lgg-mri-segmentation/kaggle_3m/` (7,860 files locally audited; CC BY-NC-SA 4.0).
- Final run: `model_output/colab_runs/20261101_205443/`, including `unet_model.onnx`, checkpoint and test fixtures.

From the project root, configure the Python environment in a fresh MATLAB process before Python is initialized, then:

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
results = runModuleTests;
app = MedicalImageAnalysisApp;
app.setModelPath(fullfile(pwd, "model_output", "colab_runs", ...
    "20261101_205443", "unet_model.onnx"));
```

The actual active interpreter, executable and mode are recorded in the `pyenv` evidence linked above. Runtime imports and inference have been verified on the existing development machine only.

## 14. Final handover checklist

- [x] **VERIFIED** — Source modules, GUI, Python bridge, tests, historical assets and local experiment artifacts are preserved.
- [x] **AUTOMATED TESTED** — MATLAB 34/34 and Python 7/7 suites pass; Python source compiles.
- [x] **VERIFIED** — CPU ONNX bridge inference and model/checkpoint manifest hashes.
- [x] **VERIFIED** — Screenshot, test, analyzer, repository audit and documentation evidence is indexed.
- [x] **VERIFIED** — Local Git commit created with no remote; dataset and model outputs are excluded from tracking.
- [x] **VERIFIED (owner-confirmed)** — Presentation-resolution GUI review and human approval.
- [x] **VERIFIED (owner-confirmed)** — Excluded dataset/model artifact transfer and recipient hash verification.
- [ ] **NOT TESTED** — Clean-machine installation.
- [x] **OUT OF SCOPE unless required** — App Designer `.mlapp` authoring.

**Release disposition at Milestone 5.3.5:** Locally documented and technically verified, but not clean-machine reproducibility certified or clinically validated. The owner subsequently confirmed manual acceptance and artifact handover, as recorded above.
