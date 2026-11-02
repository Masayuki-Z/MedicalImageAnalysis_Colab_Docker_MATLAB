# Project Status

Updated: 2026-11-02

## Current Status — Milestone 5.3.5: Final Acceptance, Reproducibility & Release Readiness

### Completed

- Reviewed current source, documentation, Git state, and Milestone 5.3.4 evidence. MATLAB modules, AppBase GUI, Python ONNX bridge, dataset, Keras/ONNX/PyTorch artifacts, experiment results, and historical API/Docker assets remain preserved.
- Re-ran final MATLAB and Python suites, Python syntax compilation, MATLAB Code Analyzer, MATLAB `pyenv` inspection, CPU ONNX bridge smoke inference, repository ignore/size checks, and read-only model hash checks.
- Added the status-classified [final release report](FINAL_RELEASE_REPORT.md) and fresh Milestone 5.3.5 runtime, test, and Code Analyzer evidence. Existing historical test output was preserved.
- Reviewed the indexed GUI captures for the six workflow sections. Automated checks remain distinct from human desktop acceptance.

### Tested

- MATLAB R2026b: **34 passed, 0 failed, 0 incomplete**.
- Python 3.11: **7/7 pipeline tests passed**, all 10 Python source files compiled, bridge import passed, and synthetic ONNX inference returned finite probabilities in `[0,1]` at `[1,1,256,256]`.
- Runtime: MATLAB `pyenv` reports Python 3.11 at `C:\Users\ACER\AppData\Local\Programs\Python\Python311\python.EXE` in `InProcess` mode. Python reports NumPy 1.26.4, Pillow 11.0.0, PyTorch 2.9.1+cpu, Matplotlib 3.9.2, and ONNX Runtime 1.31.1; bridge explicitly selects `CPUExecutionProvider`.
- Code Analyzer inspected 69 MATLAB files; five advisory diagnostics remain only in the legacy `matlab/MedicalImageToolbox.m` prototype.
- Model and checkpoint hashes match the manifest; required local data/model/run assets are present and excluded from Git.

### Acceptance status and limitations

- **AUTOMATED TESTED:** six GUI sections, workflow operations, state separation, input/model errors, save/reset, and metrics/overlap paths via the 7 GUI integration tests.
- **MANUAL ACCEPTANCE PENDING:** a human desktop walkthrough, accessibility/usability review, and presentation-display scaling. Existing screenshots show scrollable content extending beyond the captured viewport; confirm layout on the target display.
- **NOT TESTED:** clean-machine installation, local ONNX export/graph validation (optional `onnx` package unavailable), MATLAB-bridge GPU inference, and external artifact delivery.
- **OUT OF SCOPE unless required:** App Designer `.mlapp` conversion/authoring; the current app remains an AppBase `.m` class.
- Training instability after epoch 7 remains unexplained. ONNX parity remains limited to five slices from one patient. No clinical validation is claimed.

### Files Changed

- Added `docs/FINAL_RELEASE_REPORT.md`.
- Updated `README.md`, `docs/PROJECT_STATUS.md`, `docs/PROJECT_HANDOVER.md`, `docs/TEST_REPORT.md`, `docs/evidence/SCREENSHOT_INDEX.md`, `matlab/README.md`, and `python/README_PYTORCH.md`.
- Added fresh Milestone 5.3.5 MATLAB, Python, runtime, and Code Analyzer evidence.
- No source algorithms, tests, GUI implementation, model, dataset, or experiment result was changed.

### Evidence

- [Final release report](FINAL_RELEASE_REPORT.md).
- [Fresh MATLAB suite](evidence/test-results/matlab-r2026b-milestone-5.3.5-full-suite.txt), [Python checks](evidence/test-results/python-r2026b-milestone-5.3.5.txt), [Code Analyzer](evidence/test-results/matlab-r2026b-milestone-5.3.5-code-analyzer.txt), and [MATLAB `pyenv`](evidence/test-results/matlab-r2026b-milestone-5.3.5-pyenv.txt).
- [Fresh Milestone 5.3.5 repository audit](evidence/test-results/repository-audit-milestone-5.3.5.txt), [model hashes](evidence/model-artifact-manifest.txt), and [screenshot index](evidence/SCREENSHOT_INDEX.md).

## Completed Milestone 5.3.4: Final Repository Audit and Cleanup

### Completed

- Audited the source tree, historical and current project components, Git history/status/remotes, ignore rules, and locally preserved datasets and experiment outputs. No source cache directories or empty project directories were present; no project files were removed.
- Confirmed all required source, MATLAB tests, current and legacy notebooks, API/Docker assets, Keras model, dataset, and audited experiment outputs remain present. Prompt/output files and credentials were left local and ignored rather than deleted.
- Verified `.gitignore` excludes Python bytecode/caches, MATLAB temporary/build output, OS metadata, notebook checkpoints, local credentials, dataset files, and generated model runs. No tracked file exceeds 50 MB; no remote is configured.
- Verified the checkpoint and ONNX SHA-256 values against the artifact manifest without modifying either model or any experiment result.
- Updated the project handover and status with this audit, fresh test evidence, repository classification, and current limitations. Preserved historical milestone records and results.
- Removed only the transient `python/__pycache__` generated during MATLAB/Python verification; no source, test, dataset, model, or historical project asset was removed.

### Tested

- MATLAB R2026b full suite: **34 passed, 0 failed, 0 incomplete** (15 Module 1–3, 6 ONNX integration, 7 GUI integration, 6 ground-truth evaluation).
- MATLAB Code Analyzer inspected 69 `.m` files. The app and test files have no diagnostics; five advisory diagnostics remain in the legacy `matlab/MedicalImageToolbox.m` prototype. No algorithm or test was changed to suppress them.
- Python 3.11 syntax compilation passed for all 10 source files; all 7 Python pipeline unit tests passed.
- Imported the MATLAB bridge and executed a fresh synthetic-input ONNX smoke inference with ONNX Runtime 1.31.1 using `CPUExecutionProvider`; tensor dimensions and finite probability range were valid.
- Confirmed the required local dataset (7,860 files), legacy Keras model, final model/checkpoint, metrics, split, training history, ONNX parity report, and Colab environment report remain present.
- Model and checkpoint hashes match the manifest; local credential-pattern scan and Git exclusion checks are recorded in the handover evidence.

### Not Tested

- Clean-machine installation, manual desktop acceptance, accessibility, and layout at other display scales.
- ONNX export from this local Python interpreter; the optional `onnx` export/graph-validation package is not installed here. The preserved ONNX artifact and MATLAB inference path were tested.
- Model retraining, GPU inference through the MATLAB bridge, expanded ONNX parity, clinical evaluation, or external dataset/model distribution.

### Files Changed

- Updated root `README.md`, `python/README_PYTORCH.md`, `docs/PROJECT_STATUS.md`, `docs/PROJECT_HANDOVER.md`, `docs/TEST_REPORT.md`, and installation/reproducibility notes.
- Preserved the historical MATLAB runner log and added fresh Milestone 5.3.4 suite output, Python audit, MATLAB Code Analyzer, and repository audit evidence.
- Preserved all MATLAB algorithms, GUI behavior, Python bridge, tests, dataset, Keras/ONNX/PyTorch artifacts, experiment reports, notebooks, and legacy API/Docker assets.

### Known Issues and Next Actions

- Five advisory Code Analyzer diagnostics remain in the legacy `matlab/MedicalImageToolbox.m` prototype; they are not test failures and were not changed during this audit.
- Manual desktop acceptance, clean-machine installation, external distribution of ignored dataset/model artifacts, and any required App Designer `.mlapp` authoring remain project-owner actions.
- ONNX export tools require the optional `onnx` package; the runtime bridge itself and saved-model inference were verified without it.

### Evidence

- [Fresh MATLAB suite output](evidence/test-results/matlab-r2026b-milestone-5.3.4-full-suite.txt), [Python audit output](evidence/test-results/python-r2026b-audit.txt), and [MATLAB Code Analyzer output](evidence/test-results/matlab-r2026b-code-analyzer.txt).
- [Repository audit evidence](evidence/test-results/repository-audit.txt) records Git exclusions, local artifact presence and hashes, and the tracked-source token scan.
- [Test report](TEST_REPORT.md), [handover checklist](PROJECT_HANDOVER.md), [artifact manifest](evidence/model-artifact-manifest.txt), and [screenshot index](evidence/SCREENSHOT_INDEX.md).
- Git remains local on `main`, with no remote. The final audit commit is recorded after verification.

## Completed Milestone 5.3.3: Finalization and Project Handover

### Completed

- Audited the source tree, MATLAB/Python bridge, runtime environment, test fixtures, model artifacts, Git history, ignore rules, and known clutter before cleanup.
- Verified MATLAB R2026b (26.2.0.3386108), Image Processing Toolbox, configured Python 3.11, NumPy 1.26.4, Pillow 11.0.0, PyTorch 2.9.1+cpu, Matplotlib 3.9.2, and ONNX Runtime 1.31.1. The bridge explicitly selects `CPUExecutionProvider`; no native MATLAB ONNX import or GPU inference is claimed.
- Added installation, usage, architecture, test-report, and handover documents. Updated the root README, MATLAB/PyTorch documentation, this status, and the historical experiment audit with a current runtime confirmation.
- Captured and indexed 11 genuine MATLAB app screenshots using `exportapp` with the preserved run MRI/ground-truth sample and ONNX model.
- Captured full MATLAB test output under `docs/evidence/test-results/` and recorded model sizes/SHA-256 values in `docs/evidence/model-artifact-manifest.txt`.
- Updated `.gitignore` for Python/MATLAB caches, OS metadata, notebook checkpoints, local credentials, dataset, and large run outputs. Removed only the identified `python/__pycache__` and empty notebook checkpoint directory; preserved user prompt/output files, Keras model, notebooks, Docker/API assets, dataset, and all experiment artifacts.
- Fixed the Evaluation section to show computed pixel metrics instead of a static “metrics shown in workspace” message; added a regression assertion. Reduced the GUI startup dimensions so the window is less likely to exceed the current display.
- Prepared the local `main` branch for handover. No Git remote is configured; no publishing was performed. The large models and dataset remain local and excluded from the source commit.

### Tested

- Final MATLAB R2026b suite: **34 passed, 0 failed, 0 incomplete** (15 Module 1–3, 6 ONNX integration, 7 GUI integration, 6 ground-truth evaluation).
- MATLAB Code Analyzer returned no diagnostics for `MedicalImageAnalysisApp.m` and `testAppIntegration.m`.
- MATLAB Python imports verified exact local versions; full suite executed inference using the preserved ONNX model.
- Screenshot exports verified as 11 PNG files in `docs/evidence/screenshots/`.
- Model/checkpoint SHA-256 values were computed read-only and recorded; neither final model was modified.
- A source scan for common embedded credential patterns returned no matching files. The `.kaggle` directory was not read and is now ignored by Git.

### Not Tested

- Manual desktop usability acceptance, accessibility, and layout at different display scales. App screenshots are real UI captures, but do not constitute user acceptance.
- A clean-machine installation from scratch or Python package installation in a newly created virtual environment.
- GPU inference through MATLAB, local full training, or any follow-up training stability experiment.
- External distribution/download of the ignored dataset/model artifacts. The manifest provides integrity checks only.

### Files Changed

- Updated `.gitignore`, root `README.md`, `matlab/MedicalImageAnalysisApp.m`, and `matlab/tests/testAppIntegration.m`.
- Updated `matlab/README.md`, `python/README_PYTORCH.md`, `docs/PROJECT_STATUS.md`, and `docs/MILESTONE3_FINAL_AUDIT.md`.
- Added `docs/INSTALLATION_GUIDE.md`, `docs/USER_GUIDE.md`, `docs/ARCHITECTURE.md`, `docs/TEST_REPORT.md`, and `docs/PROJECT_HANDOVER.md`.
- Added `docs/evidence/SCREENSHOT_INDEX.md`, the captured test output, the model artifact manifest, and 11 screenshots under `docs/evidence/`.
- Did not modify Modules 1–3 algorithms, the trained checkpoint, ONNX model, test metrics, patient split, training history, or historical Keras/Docker assets.

### Known Issues

- The model and checkpoint are each larger than 100 MB and are ignored by Git along with `model_output/`; obtain the complete run directory separately or use Git LFS for hosted distribution. The local files are preserved and hash-listed.
- The local dataset is about 1.06 GB and excluded from Git. It must be obtained separately under its CC BY-NC-SA 4.0 terms.
- Training collapsed after epoch 7 and the cause remains unknown; five-sample, one-patient ONNX parity is limited.
- The MATLAB GUI remains an AppBase `.m` class, not an App Designer `.mlapp`. Manual desktop acceptance remains outstanding.
- Docker/FastAPI and the legacy Keras workflow remain reference assets and are not the current verified MATLAB inference route.

### Next Milestone

Complete manual desktop acceptance on the presentation machine. If required by the instructor, author and validate an App Designer `.mlapp` using supported App Designer workflows. Arrange authorized external delivery for the dataset and final run directory.

### Evidence

- [Test report](TEST_REPORT.md) and [captured MATLAB runner output](evidence/test-results/matlab-r2026b-full-suite.txt).
- [Screenshot index](evidence/SCREENSHOT_INDEX.md) and genuine screenshots in `evidence/screenshots/`.
- [Artifact sizes and SHA-256 digests](evidence/model-artifact-manifest.txt).
- [Installation](INSTALLATION_GUIDE.md), [user](USER_GUIDE.md), [architecture](ARCHITECTURE.md), and [handover](PROJECT_HANDOVER.md) guides.
- Git history was inspected before editing: branch `main`, two existing commits, only `.gitignore` previously tracked, and no configured remote.

## Completed Milestone 5.3.2: Independent GUI Workflow Redesign

### Completed

- Replaced the shared module/operation panel as the visible workflow with six navigable sections: Image Workspace, Image Enhancement, Image Segmentation, Geometric Transformation, AI Segmentation, and Evaluation.
- Added independent operation and image-input selectors, parameter controls, apply/reset actions, descriptions, and input/output views for enhancement, segmentation, and transformation. The three workflows continue to use the established shared-state dispatch and algorithms.
- Kept image-state selection independent from mask-source selection. Binary morphology and shape-based processing still select from classical, AI, or ground-truth masks without changing the image input.
- Added dedicated enhancement histogram and transformation dimension views. Workspace, AI, and evaluation views use separate axes, while displaying the same preserved image state.
- Made section reset scoped: resetting enhancement, for example, clears only enhanced output and its associated history entries while preserving classical masks and transformed output.
- Kept AI inference tied to the original MRI and retained the existing ONNX inference function and model preprocessing.

### Tested

- MATLAB R2026b full regression suite: **34 passed, 0 failed, 0 incomplete** (15 Module 1–3, 6 ONNX integration, 7 app integration, and 6 ground-truth evaluation tests).
- Added an automated workflow redesign test covering all six navigation entries, independent operation selectors, section switching, enhancement/Otsu/scaling application through their respective UI callbacks, and scoped enhancement reset.
- Existing GUI, ground-truth, image-processing, and ONNX regression tests continue to pass.

### Not Tested

- Manual desktop visual acceptance, including layout behavior at different display scales and live user interaction. Tests created the GUI and exercised its callbacks programmatically.
- App Designer `.mlapp` authoring; the current application remains the existing AppBase `.m` class.

### Files Changed

- Updated `matlab/MedicalImageAnalysisApp.m`.
- Expanded `matlab/tests/testAppIntegration.m` with workflow navigation, operation dispatch, and scoped-reset coverage.
- Updated `matlab/README.md`, root `README.md`, and this status document.
- Preserved Modules 1–3 algorithms, ONNX inference and model artifacts, legacy Keras/API assets, and existing image-state conventions.

### Known Issues

- Desktop visual usability is not confirmed; the automated tests run without manual visual inspection.
- The GUI is a programmatic AppBase class, not an App Designer `.mlapp`.
- Users should load/produce an image state before selecting it as a processing input; processing reports an error for an unavailable state.

### Next Milestone

Perform manual desktop acceptance for all six sections and window/display scaling. If the course requires an App Designer file, author and validate the `.mlapp` using supported App Designer workflows. Keep AI inference and classical processing paths separate.

### Evidence

- Executed `runModuleTests` from MATLAB R2026b after adding the MATLAB source tree to the path; all 34 tests passed.
- Focused `testAppIntegration.m` run passed 7/7 app integration tests, including the newly added redesign test.
- Programmatic callback test applied histogram equalization, Otsu segmentation, and scaling through their distinct section controls; resetting enhancement left the classical mask and transformed image intact.
- MATLAB Code Analyzer returned no diagnostics for `MedicalImageAnalysisApp.m` or `testAppIntegration.m`.

## Completed Milestone 5.2: GUI Usability Improvements & Ground Truth Evaluation

### Completed

- Added independent ground-truth mask loading for 2-D PNG, TIFF, and grayscale JPG/JPEG images. Inputs are validated and converted to binary; grayscale masks with more than two intensity levels use Otsu binarization. Dimension mismatches are aligned with nearest-neighbor interpolation and reported in the GUI.
- Added `GroundTruthMask` to shared image state. Ground truth remains separate from the classical mask, AI prediction, and AI probability map; loading it does not trigger or affect inference. Replacing an MRI clears any previous ground truth, explicit clearing is available, and Reset preserves the annotation.
- Added dedicated ground-truth and AI-prediction views, an overlap image, probability-map display, and an evaluation panel. Overlap colors are green TP, red FP, and blue FN.
- Added pixel-level Dice, IoU, precision, recall, and TP/FP/FN counts. Empty-mask conventions are explicit: Dice/IoU are 1 when both masks are empty; precision is 1 when no pixels are predicted positive; recall is 1 when the ground truth has no positive pixels.
- Split image input selection (Original/Enhanced/Transformed) from mask source selection (Classical/AI/Ground Truth). Morphology and shape filtering process the selected mask source, record that source in history/status, and do not silently change the image input selection.
- Added operation-specific parameter labels, tooltips, descriptions, defaults, visibility, and validation, including Otsu's automatic threshold, Canny sigma, transformation inputs, morphology size, region-growing seed, color bounds, and shape filters.
- Updated [matlab/README.md](../matlab/README.md), root [README.md](../README.md), and this status document. Existing Modules 1–3, the ONNX bridge, Keras assets, and audited model artifacts remain preserved.

### Tested

- MATLAB R2026b command `results = runModuleTests;`: **33 passed, 0 failed, 0 incomplete**. This includes 15 Module 1–3 tests, 6 ONNX tests, 6 GUI workflow tests, and 6 ground-truth/metric tests.
- Automated coverage includes binary conversion, Otsu mask conversion, nearest-neighbor resizing, invalid inputs, mask dimensionality, TP/FP/FN colors and counts, Dice/IoU/precision/recall, zero-denominator cases, and state separation.
- GUI tests cover mask loading/resizing/replacement/reset, ground-truth-independent ONNX inference, ground-truth evaluation displays, Enhanced/Transformed input propagation, explicit mask source with unchanged image selection, operation metadata and invalid parameters, existing processing operations, and missing model/image errors.
- MATLAB Code Analyzer reported no diagnostics for the changed GUI, ground-truth helpers, and new test files.

### Not Tested

- Manual desktop acceptance testing of the new ground-truth, overlap, metrics, and dynamic parameter UI. Automated tests instantiated the GUI and exercised its callbacks/data methods.
- Masks from a representative set of real JPG/TIFF/PNG annotation sources beyond the fixed and synthetic test inputs.
- Clinical utility, annotation quality, or replacing the audited held-out test-set evaluation with interactive GUI comparisons.

### Files Changed

- Updated `matlab/MedicalImageAnalysisApp.m`.
- Added `matlab/common/prepareGroundTruthMask.m`, `evaluateSegmentationMasks.m`, and `createSegmentationOverlap.m`.
- Updated `matlab/common/initializeImageState.m`, `selectImageState.m`, `recordImageResult.m`, and `matlab/ai/runGliomaONNX.m` to preserve the separate ground-truth state.
- Added `matlab/tests/testGroundTruthEvaluation.m`; expanded `matlab/tests/testAppIntegration.m`.
- Updated `matlab/README.md`, root `README.md`, and this status document.
- Did not modify Modules 1–3 algorithms, Keras/legacy API assets, or files under `model_output/colab_runs/20261101_205443/`.

### Known Issues

- The programmatic GUI remains a tested `.m` AppBase class, not an App Designer `.mlapp`. Manual desktop acceptance remains outstanding.
- JPG is lossy; binary masks should preferably be supplied as PNG or TIFF. Grayscale conversion uses Otsu for masks with more than two intensity values.
- GUI metrics are per-image pixel comparisons and are not clinical metrics or a replacement for the saved held-out test evaluation.
- Python ONNX Runtime remains CPU-based and requires the configured MATLAB Python environment as documented in Milestone 4.

### Next Milestone (as recorded at Milestone 5.2 completion)

This acceptance work was carried forward into Milestone 5.3.2. Manual desktop acceptance and any required App Designer `.mlapp` authoring remain outstanding.

### Evidence

- Full MATLAB R2026b run completed at 2026-11-02: 33/33 test methods passed; summary and diagnostic output were observed from `runModuleTests`.
- The overlap helper's deterministic 2×2 test confirmed TP green, FP red, FN blue, and true-negative black. Metric tests asserted exact counts and values, including all-empty and one-sided-empty cases.
- GUI inference test loaded a ground-truth mask before model execution, then compared the resulting probability map and prediction exactly against inference from a fresh original-image state; ground truth did not affect inference.
- Changed MATLAB source and test files passed Code Analyzer with zero diagnostics.

## Current Status — Milestone 4: MATLAB ONNX Integration and GUI

### Completed

- Completed the read-only final experiment audit and preserved every Colab artifact in `model_output/colab_runs/20261101_205443/`.
- Implemented the MATLAB-to-Python ONNX Runtime bridge and exact FLAIR preprocessing, probability-map inference, thresholding, nearest-neighbor mask restoration, separate state tracking, and processing history.
- Added `matlab/MedicalImageAnalysisApp.m`, a programmatic MATLAB AppBase GUI joining Modules 1–3 and keeping classical and AI paths separate.
- Geometric operations now apply nearest-neighbor transforms to an existing classical mask when its dimensions match the selected image, keeping that mask aligned with the transformed image.
- Added automated GUI workflow tests and updated the MATLAB, Python, root, audit, and status documentation. The trained checkpoint, ONNX model, test metrics, legacy Keras assets, and existing course-module files were preserved.

### Tested

- The final Colab run used Python 3.13.16, PyTorch 2.11.0+cu130, CUDA 13.0, and a Tesla T4; 19 epochs completed in 4,016.55 seconds, with best validation Dice 0.784357 at epoch 7.
- Patient split is 77/17/16 patients and 2,719/641/569 slices, with no saved overlap. Pixel-pooled test metrics remain Dice 0.781607, IoU 0.641507, precision 0.772103, and recall 0.791348.
- The ONNX export report compared five test slices from one patient: max absolute probability difference 3.2783e-7 and zero thresholded-mask mismatches at 0.5.
- MATLAB R2026b full suite: **24/24 tests passed** (3 app workflows, 15 Module 1–3 tests, 6 ONNX integration tests). The suite exercised GUI construction, classical processing, geometric mask alignment, AI inference, display updates, save/reset, and missing-image/model errors.
- MATLAB preprocessing matched the Python pipeline within `1e-6`; the bridge executed the preserved ONNX model using ONNX Runtime 1.31.1 and `CPUExecutionProvider`. The fixed unseen-test prediction matched the saved Python prediction after thresholding.
- MATLAB Code Analyzer reported no issues in `MedicalImageAnalysisApp.m`. MATLAB's native ONNX importer remains unavailable; inference is performed by Python 3.11 through MATLAB's Python interface.

### Experiment Evidence

- Training collapsed beginning epoch 8: training loss increased and training/validation Dice became zero through epoch 19. Gradient norms, optimizer state, and epoch-8 weights were not saved; cause is unknown. The finite epoch-7 checkpoint was preserved and selected by validation Dice.
- The ONNX relative error report is 1.1467 due to near-zero denominator sensitivity despite 3.2783e-7 maximum absolute error and zero binary-mask mismatches. Only five samples from one test patient were checked.

### Not Tested

- An App Designer-authored `.mlapp` and manual desktop acceptance testing. MATLAB's internal serializer warned that save/load is unsupported for the programmatic `matlab.apps.AppBase` object; the temporary serialization probe could not reload its app object.
- The cause of training collapse after epoch 7; gradient norms, optimizer state, and epoch-8 weights were not recorded.
- Broad ONNX parity beyond the five slices from one patient in the saved experiment report, GPU inference through the MATLAB bridge, and clinical validity.
- Docker/FastAPI integration and end-to-end testing of the legacy Keras API.

### Files Changed

- Added `docs/MILESTONE3_FINAL_AUDIT.md` and `matlab/tests/testAppIntegration.m`.
- Added `python/matlab_onnx_bridge.py` and `matlab/MedicalImageAnalysisApp.m`.
- Implemented `matlab/ai/getGliomaONNXBridge.m`, `prepareFlairONNXInput.m`, `restoreGliomaPrediction.m`, and `runGliomaONNX.m`; extended shared image-state helpers to store AI probability maps.
- Updated `matlab/geometric/simulateRadialDistortion.m` with optional interpolation selection so masks use nearest-neighbor.
- Updated `matlab/README.md`, `python/README_PYTORCH.md`, root `README.md`, this status document, and the final audit report.
- All artifacts under `model_output/colab_runs/20261101_205443/` were read-only and preserved.

### Known Issues

- The App Designer `.mlapp` file remains incomplete. If mandatory, author/save the GUI in App Designer using its supported workflow; programmatic conversion of the AppBase class has not been verified.
- AI inference requires a compatible configured Python 3.11 environment. It uses CPUExecutionProvider, not MATLAB native inference or GPU acceleration.
- Training instability is confirmed, but cause is unconfirmed. Do not overwrite or retrain over the audited final artifacts; any diagnostic trial should use a new output directory.

### Evidence

- Executed `results = runModuleTests;` with MATLAB R2026b: 24 passed, 0 failed, 0 incomplete. The run includes `testImageModules`, `testONNXIntegration`, and `testAppIntegration`.
- Python/MATLAB input parity used the Python `normalize_flair` implementation; wrapped ONNX output was numerically compared against direct bridge output at absolute tolerance `1e-7`.
- GUI inference was tested against the saved unseen-test prediction PNG; original-image/state preservation, probability bounds, mask dimensions, display axes, save/reset, and missing-model handling were asserted.
- ONNX Runtime version/provider and the Colab experiment metadata were read from the configured Python environment and preserved run reports, respectively. No final model or test artifact was changed.

### Next Milestone

Complete the App Designer `.mlapp` conversion and manual interactive validation. Then package the required MATLAB/Python runtime setup for reproducible user installation; keep final experiment artifacts and the three mandatory MATLAB modules unchanged.

## Current Status — Milestone 3: PyTorch Migration and Smoke Test

### Completed

- Audited the existing Keras notebook, training/evaluation scripts, FastAPI service, model artifact, dataset loader, and local dataset before implementation. Kept all legacy Keras and MATLAB assets intact.
- Confirmed the dataset documentation's RGB order (pre-contrast, FLAIR, post-contrast); the new loader selects channel index 1 as FLAIR, normalizes each slice with population Z-score, and converts masks to binary float32.
- Added a deterministic seed-42 patient-level split manifest with a largest-remainder 70/15/15 allocation and explicit overlap checks.
- Implemented the specified original single-channel 2D U-Net, BCE plus soft Dice loss, Adam at 1e-4, validation-Dice checkpoint selection, full-training early stopping, and training-only synchronized flip/rotation augmentation.
- Added separate full-training, unseen-test evaluation, and ONNX export/parity commands. Evaluation and export refuse checkpoints marked as smoke tests; evaluation requires the saved training split and checks its seed and dataset patient coverage.
- Added preprocessing, migration decisions, run instructions, current MATLAB inference contract, and resource limitations to the PyTorch documentation.

### Tested

- Dataset audit: 3,929 paired TIFF slices from 110 patients; all images were 256×256×3 uint8 and masks 256×256 with values 0/255; no missing pairs or alignment mismatches were found.
- Patient split: train 77 patients/2,719 images; validation 17/641; unseen test 16/569. All pairwise patient-overlap lists are empty.
- Python unit tests: **7/7 passed** with `python -m unittest discover -s python -p "test_pytorch_pipeline.py" -v`.
- Python syntax compilation: **passed** for the pipeline, training, evaluation, export, and test files.
- CPU smoke test: completed 2 epochs using the full 31,030,593-parameter U-Net, batch size 1, and one positive training plus one positive validation slice. Best validation Dice at fixed threshold 0.5 was **0.317389** at epoch 2. Checkpoint, training history, plot, configs, split, and run summary were written under `model_output/smoke_test/`.
- Guard verification: evaluation and ONNX export both rejected the marked smoke checkpoint before test evaluation or optional ONNX dependency loading. No smoke `test_metrics.json` was produced.

### Not Tested

- Full 50–100 epoch training and a final non-smoke checkpoint.
- Unseen-test Dice, IoU, precision, recall, and prediction examples; no test metrics are claimed.
- ONNX export, ONNX Runtime parity, and `unet_model.onnx`.
- MATLAB-to-PyTorch/ONNX inference integration, Docker/API changes, and final App Designer integration.
- Clinical validity; predictions are educational/research outputs, not diagnoses.

### Files Changed

- Added `python/pytorch_pipeline.py`, `python/train_pytorch.py`, `python/test_pytorch_pipeline.py`, `python/evaluate_pytorch.py`, and `python/export_pytorch_onnx.py`.
- Added `python/requirements-pytorch.txt`, `python/requirements-pytorch-onnx.txt`, and `python/README_PYTORCH.md`.
- Updated the root `README.md` and this status document.
- Generated smoke artifacts in `model_output/smoke_test/`: `best_unet.pth`, `model_config.json`, `normalization_config.json`, `patient_split.json`, `run_config.json`, `run_summary.json`, `training_history.json`, and `training_history.png`.
- MATLAB Modules 1–3, the Keras model/notebook, legacy API, and dataset files were not modified.

### Known Issues

- The available PyTorch runtime is CPU-only (`torch.cuda.is_available() == False`); full training was not started because of local compute/memory constraints.
- The smoke checkpoint validates pipeline execution only. It is explicitly marked and blocked from final evaluation/export.
- ONNX optional dependencies are declared but not installed, and ONNX export has not been run.
- Full-training and evaluation paths are implemented but have not yet been exercised on a suitable GPU environment.

### Next Milestone

Run full training on a suitable GPU runtime, select the checkpoint using validation Dice only, evaluate once on the held-out patient test set, export/compare ONNX predictions on fixed test samples, and then integrate the validated inference contract with MATLAB without changing the course modules.

### Evidence

- Smoke run summary: CPU; CUDA unavailable; 2 epochs; best epoch 2; validation Dice 0.317389; test evaluation not performed.
- Saved checkpoint metadata: `smoke_test: true`, seed 42, original U-Net configuration, 31,030,593 parameters.
- Saved split manifest: 77/17/16 patients and 2,719/641/569 slices; all overlap checks empty.
- Test run: 7 passed, 0 failed. Syntax compilation passed. Smoke-checkpoint guards both returned the expected refusal.

## Milestone 2 — Core MATLAB Toolbox Development

### Completed

- Audited the existing MATLAB tree before editing. The original `matlab/MedicalImageToolbox.m` prototype was preserved unchanged.
- Confirmed MATLAB R2026b (26.2) and Image Processing Toolbox are installed and licensed.
- Added shared validation, normalization, image-state, morphology, color-range, interpolation, transform, and parameter-validation helpers under `matlab/common/`.
- Implemented Module 1 under `matlab/enhancement/`: histogram equalization/matching; brightness, contrast, and gray-level transforms; mean/median filtering; Laplacian/high-pass sharpening; Fourier low/high/band-pass filters with spectrum output.
- Implemented Module 2 under `matlab/segmentation/`: Sobel, Prewitt, Canny, Otsu, seeded region growing, RGB/HSV threshold segmentation, four morphological operations, and area/circularity-based connected-component filtering.
- Implemented Module 3 under `matlab/geometric/`: translation, scaling, rotation, affine transformation, forward/inverse mapping, coordinate-based nearest/bilinear/bicubic interpolation, three resize helpers, and radial-distortion simulation/correction.
- Added explicit image states for original, enhanced, transformed, classical mask, AI input, and AI prediction. Module functions do not mutate the source image; processing can select original/enhanced/transformed input and record parameters in history.
- Added MATLAB unit tests, a test runner, an MRI workflow demo, and function/interface documentation.
- Preserved Keras model, Notebook, API, and other AI assets; no training or Docker migration was started.

### Tested

- MATLAB R2026b unit tests: **15/15 test methods passed**, including invalid-input checks.
- Static Code Analyzer: **0 messages in new MATLAB code**. Existing diagnostics in the untouched `MedicalImageToolbox.m` prototype were not changed.
- MRI workflow demo ran on an actual local LGG TIFF (256×256×3). The original image was preserved. The documented FLAIR channel was enhanced, Otsu-segmented, and morphologically refined; observed Otsu threshold was 0.774510, initial mask area 14,582 pixels, refined mask area 15,642 pixels. These are one classical-processing run's pixel counts, not accuracy metrics or a claim that the masks identify tumor.

### Not Tested

- Final MATLAB App Designer `.mlapp` integration; the old programmatic UI was intentionally left unchanged.
- GUI responsiveness, histogram/comparison displays, save/reset callbacks, and user-interaction behavior.
- AI preprocessing, model inference, AI/ground-truth metrics, API, Docker, ONNX, and end-to-end integration.
- Basic image registration (optional requirement; deferred).
- The demo's optional output-file export argument.
- Clinical validity; the project is an educational image-processing exercise.

### Files Changed

- `matlab/common/`: input validation, grayscale/unit-range conversion, luminance processing, morphology/color validation, coordinate sampling and transform validation, image-state creation/selection/result recording.
- `matlab/enhancement/`: all Module 1 function implementations.
- `matlab/segmentation/`: all Module 2 function implementations.
- `matlab/geometric/`: all mandatory Module 3 implementations and radial-distortion simulation.
- `matlab/tests/testImageModules.m`, `matlab/tests/runModuleTests.m`, `matlab/tests/runMriPipelineDemo.m`.
- `matlab/README.md`: function interfaces, conventions, dependencies, tests, and limitations.
- `docs/PROJECT_STATUS.md`: this milestone record.
- Existing `matlab/MedicalImageToolbox.m`, AI source/assets, and dataset files were not modified.

### Known Issues

- The old GUI prototype has pre-existing Code Analyzer messages and exposes only a small subset of operations. It was preserved; these functions are not yet wired to its callbacks.
- Image Processing Toolbox is required.
- For binary masks, callers must explicitly choose nearest-neighbor interpolation and apply identical transformations/output dimensions to image and mask.
- Forward mapping uses rounded-pixel scatter; collisions overwrite earlier samples and uncovered output pixels use the configured fill value.
- Radial correction implements the same simplified radial model as the included simulator; it is not a calibrated lens correction.
- Optional image registration is deferred.
- Existing AI artifacts remain TensorFlow/Keras and are not part of this milestone.

### Next Milestone (as recorded at Milestone 2 completion)

Milestone 3 — audit and migrate the AI dataset/training workflow to the specified PyTorch baseline, including verified FLAIR selection, normalization, deterministic patient-level 70/15/15 splitting, and an initial smoke test. Keep Modules 1–3 as the course-priority deliverables and do not claim unrun model results.

### Evidence

- MATLAB version and Image Processing Toolbox license confirmed through MATLAB R2026b.
- Unit test summary: 15 passed, 0 failed, 0 incomplete.
- MRI demo evidence: 256×256×3 source; threshold 0.774510; source equality check true; 14,582 initial mask pixels; 15,642 refined mask pixels; 3 processing-history entries.
- New-code static-analysis summary: 0 Code Analyzer messages.
