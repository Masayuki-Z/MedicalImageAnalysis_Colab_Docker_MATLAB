# Project Handover

## Project overview

The Integrated Medical Image Processing Toolbox combines three course-required MATLAB modules with an independent U-Net glioma segmentation inference path for MRI FLAIR. The application is intended for academic and research demonstration, not clinical use.

## Final features

- MATLAB GUI with Image Workspace, Image Enhancement, Image Segmentation, Geometric Transformation, AI Segmentation, and Evaluation sections.
- Histogram and intensity processing, spatial filtering/sharpening, and Fourier filtering.
- Sobel/Prewitt/Canny edge maps; Otsu, region-growing, RGB/HSV, morphology, and shape-based segmentation.
- Translation, scaling, rotation, affine/forward/inverse mapping, radial distortion/correction, and nearest/bilinear/bicubic interpolation.
- Separate original, enhanced, transformed, classical-mask, AI-input, AI-probability, AI-prediction, and ground-truth states.
- Python ONNX Runtime inference through MATLAB `pyenv`; AI inference starts directly from the original MRI.
- Ground-truth comparison with pixel-level Dice, IoU, precision/recall, and TP/FP/FN overlap.
- Regression suite and genuine MATLAB GUI screenshots.

## Technology

- MATLAB R2026b (26.2) and Image Processing Toolbox.
- Python 3.11 for the verified MATLAB bridge.
- PyTorch original single-channel 2-D U-Net baseline and ONNX model.
- ONNX Runtime 1.31.1; the MATLAB bridge selects CPUExecutionProvider.
- MATLAB-Python integration via `pyenv`.
- Google Colab GPU for the recorded final training run; no local GPU training is implied.

## Installation and launch

Follow [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md), then start MATLAB in the project root:

```matlab
addpath(genpath(fullfile(pwd, "matlab")));
app = MedicalImageAnalysisApp;
app.setModelPath(fullfile(pwd, "model_output", "colab_runs", ...
    "20261101_205443", "unet_model.onnx"));
```

Use [USER_GUIDE.md](USER_GUIDE.md) for GUI steps and [ARCHITECTURE.md](ARCHITECTURE.md) for implementation details.

## Testing

Final repository audit on 2026-11-02: **MATLAB R2026b, 34 passed, 0 failed, 0 incomplete**; Python syntax compilation passed 10/10 files, the Python pipeline suite passed 7/7, and a synthetic-input ONNX smoke inference ran with CPUExecutionProvider. Detailed results and the five advisory diagnostics in the legacy prototype are recorded in [TEST_REPORT.md](TEST_REPORT.md) and its linked evidence. Automated GUI callbacks are not a substitute for manual desktop acceptance.

## Repository audit classification

- **Current demo workflow:** `matlab/MedicalImageAnalysisApp.m`, the shared-state/helpers and Modules 1–3 under `matlab/`, the Python ONNX bridge and shared preprocessing under `python/`, plus the MATLAB/Python tests.
- **AI experiment assets:** the local LGG dataset and complete final run under `data/` and `model_output/`; these are present locally and intentionally excluded from Git.
- **Historical/reference assets:** the Keras-era Colab notebook and its saved output cells remain as an archive only. Its local Keras model, Python Keras scripts, FastAPI service, Docker/Compose files, and API-only dependencies were removed in Milestone 5.3.6.
- **Documentation/evidence:** the project guides and status under `docs/`, including indexed real UI captures, MATLAB/Python test logs, Code Analyzer output, and model SHA-256 manifest.
- **Local-only files:** root prompt/continuation files and generated `processed_result.png` are ignored and were preserved. The ignored Kaggle credential directory was not opened.
- The Milestone 5.3.4 audit found no empty project directories or Python/MATLAB cache/checkpoint directories. The Milestone 5.3.6 cleanup removed only the listed retired runtime assets and the ignored legacy Keras model; dataset, current model run, historical notebook/evidence, and user prompt/output files remain preserved.

## Model and experiment artifacts

The final run is `model_output/colab_runs/20261101_205443/`. It contains:

- `best_unet.pth` and `unet_model.onnx`
- `test_metrics.json`, `training_history.json`, `training_history.png`
- `patient_split.json`, `model_config.json`, `normalization_config.json`
- `onnx_parity.json`, `colab_environment.json`
- MATLAB image, ground-truth, and prediction exports

Both principal model files exceed 100 MB and are intentionally excluded from the source Git commit, together with the local dataset and experiment directory. They remain present in the handover workspace; their verified sizes and SHA-256 digests are in [evidence/model-artifact-manifest.txt](evidence/model-artifact-manifest.txt). For a hosted repository, distribute the run directory separately or use Git LFS and ensure the data/model terms permit redistribution. Do not treat `.gitignore` as evidence that those files are included in Git.

## Repository map

```text
matlab/                     MATLAB app, shared-state helpers, Modules 1–3, tests
python/                     PyTorch pipeline, MATLAB bridge, requirements, tests
notebooks/                  Current PyTorch workflow and archived historical Keras notebook
api/, Docker, Keras scripts  Retired and removed in Milestone 5.3.6
model_output/                Local final training run, ignored by Git; distribute separately
data/                       Local dataset, ignored by Git; obtain under dataset license
docs/                        Installation, usage, architecture, status, audit, handover
docs/evidence/               Test output, model hashes, and GUI screenshots
```

## Known limitations

- MATLAB inference is CPU-only through ONNX Runtime; GPU execution from the bridge is not verified.
- The training history collapsed after epoch 7; the cause remains unknown. The validation-best epoch-7 checkpoint was preserved.
- ONNX parity covers five slices from one test patient; this is limited export consistency evidence.
- The app is a programmatic MATLAB AppBase `.m` class, not an App Designer-authored `.mlapp`.
- The project owner confirmed manual desktop usability acceptance on 2026-11-02; this was not independently witnessed during Milestone 5.3.6.
- No clinical validation, diagnostic performance, or treatment utility has been established.
- The dataset license is CC BY-NC-SA 4.0; inspect its terms before redistributing data or derived material.

## Future work (not completed)

- If required by the course, create an App Designer `.mlapp` with supported App Designer workflows.
- Investigate training stability in a separate diagnostic run, preserving the existing checkpoint and test metrics.
- Broaden ONNX parity sampling and validation without using test data for model selection.
- Package large models/dataset with an authorized, reproducible artifact distribution method.

## Handover checklist

- [x] MATLAB source modules, app, and tests are present.
- [x] Python bridge and dependency manifests are present.
- [x] Final training, evaluation, split, normalization, model, and parity artifacts are preserved locally and hash-listed.
- [x] Installation, user, architecture, test, status, audit, and handover documents are present.
- [x] Genuine app screenshots are indexed.
- [x] Kaggle credentials, local dataset, and large experiment artifacts are excluded from source Git.
- [x] Final repository audit, model integrity checks, MATLAB/Python test evidence, and local Git commit are recorded.
- [x] Project owner confirmed presentation-resolution GUI acceptance on 2026-11-02.
- [x] Project owner confirmed transfer of excluded dataset/model artifacts and hash verification on 2026-11-02.

The local Git repository has no remote configured. No content has been published. The project owner confirmed manual desktop acceptance and recipient artifact transfer/hash verification on 2026-11-02; these confirmations were not independently repeated in this session. Clean-machine installation remains unverified.

## Milestone 5.3.5 final acceptance

The Milestone 5.3.5 [Final Release Report](FINAL_RELEASE_REPORT.md) records its runtime verification and original handover evidence. The owner subsequently confirmed manual GUI acceptance and transfer/hash verification as noted above; clean-machine installation is still unverified.

## Milestone 5.3.6 legacy cleanup

The [Legacy Cleanup Report](LEGACY_CLEANUP_REPORT.md) lists the retired FastAPI/Docker/Keras files removed, retained PyTorch/ONNX architecture and historical notebook, fresh regression evidence, and final Git commit. Current AI inference is exclusively MATLAB → Python bridge → ONNX Runtime CPU → `unet_model.onnx`.
