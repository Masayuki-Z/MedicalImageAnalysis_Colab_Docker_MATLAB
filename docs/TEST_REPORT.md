# Test and Verification Report

**Verification date:** 2026-11-02  
**MATLAB:** R2026b (26.2.0.3386108)  
**Operating system:** Windows  
**Configured MATLAB Python:** Python 3.11, in-process  
**Observed bridge packages:** NumPy 1.26.4; Pillow 11.0.0; PyTorch 2.9.1+cpu; ONNX Runtime 1.31.1; Matplotlib 3.9.2  
**ONNX Runtime providers reported:** AzureExecutionProvider and CPUExecutionProvider  
**Provider requested by the project bridge:** CPUExecutionProvider  
**MATLAB toolbox required:** Image Processing Toolbox

## Automated MATLAB regression suite

Command executed from the MATLAB directory:

```matlab
addpath(genpath(pwd));
results = runModuleTests;
```

**Actual result: 34 passed, 0 failed, 0 incomplete.**

| Test group | Passed |
|---|---:|
| Modules 1–3 (`testImageModules`) | 15 |
| ONNX integration (`testONNXIntegration`) | 6 |
| GUI integration (`testAppIntegration`) | 7 |
| Ground-truth evaluation (`testGroundTruthEvaluation`) | 6 |
| **Total** | **34** |

The full MATLAB runner output was captured at [the Milestone 5.3.4 test log](evidence/test-results/matlab-r2026b-milestone-5.3.4-full-suite.txt). The additional 34th test covers the six-section navigation, distinct operation selectors, section callback processing, and scoped reset. The AI workflow test also asserts that computed metrics appear in the Evaluation section.

Coverage exercised includes Module 1–3 function behavior and invalid parameters, Python/MATLAB preprocessing parity, ONNX model dimensions and inference, probability and mask validation, original-image preservation, mask alignment, GUI workflow/display, ground-truth handling, metrics and overlap colors, and missing-model/input errors.

## Additional checks

- MATLAB `pyenv` reported Python 3.11 at `C:\Users\ACER\AppData\Local\Programs\Python\Python311\python.EXE`.
- MATLAB Python imports reported ONNX Runtime 1.31.1 and NumPy 1.26.4. The integration suite executed the supplied ONNX model via CPU provider.
- MATLAB Code Analyzer returned no diagnostics for `MedicalImageAnalysisApp.m` and `testAppIntegration.m` after final GUI changes.
- Eleven app screenshots were exported from the running MATLAB application using `exportapp`; see [SCREENSHOT_INDEX.md](evidence/SCREENSHOT_INDEX.md). They use the preserved test example image, corresponding annotation, and trained model. Screenshots are genuine app output, not mockups.
- The two large final model files were hashed read-only. Their byte counts and SHA-256 values are in [model-artifact-manifest.txt](evidence/model-artifact-manifest.txt).

## Manual checks and limitations

- Automated GUI callback tests are **not** manual desktop acceptance. A person should still inspect all six sections, resize the window, and verify interaction at the intended presentation display scale.
- Screenshot export demonstrates the actual app GUI, but it does not certify screen-reader accessibility, usability, or clinical suitability.
- The final experiment's model, metrics, and ONNX parity limits are documented in [MILESTONE3_FINAL_AUDIT.md](MILESTONE3_FINAL_AUDIT.md). The cause of training collapse after epoch 7 remains unknown; ONNX parity evidence covers five slices from one test patient.
- The tests require the externally supplied final run folder because the model and `MATLAB_Export` examples are excluded from Git.
- No local full-training run or GPU inference through the MATLAB bridge was performed for this finalization.

## Milestone 5.3.4 repository audit (2026-11-02)

- Re-ran the complete MATLAB suite: **34 passed, 0 failed, 0 incomplete**. The raw output is in [the Milestone 5.3.4 test log](evidence/test-results/matlab-r2026b-milestone-5.3.4-full-suite.txt); the previous milestone log remains unchanged.
- MATLAB Code Analyzer inspected **69 `.m` files**. It reported five advisory diagnostics, all in the legacy [`MedicalImageToolbox.m`](../matlab/MedicalImageToolbox.m) prototype (extra comma, indentation, and an `ismatrix` suggestion); the app and test files had no diagnostics. No source was changed to suppress these findings. Full output: [matlab-r2026b-code-analyzer.txt](evidence/test-results/matlab-r2026b-code-analyzer.txt).
- Python 3.11 syntax compilation passed for all **10** `.py` source files, and the Python pipeline unit suite passed **7/7** tests.
- Imported the bridge and ran a separate synthetic-input ONNX smoke inference with ONNX Runtime **1.31.1**, explicitly using `CPUExecutionProvider`. Input/output were `[1,1,256,256]`; output probabilities were finite and within `[0,1]`. This did not modify experiment metrics or evaluate a test sample. Output: [python-r2026b-audit.txt](evidence/test-results/python-r2026b-audit.txt).
- The inspected Python environment has NumPy 1.26.4, Pillow 11.0.0, PyTorch 2.9.1+cpu, and ONNX Runtime 1.31.1. The optional `onnx` exporter/graph-checking package is not installed; export tools were not run during this audit.
- Both model SHA-256 digests match [the artifact manifest](evidence/model-artifact-manifest.txt). The local dataset, legacy Keras model, and required final run files are present. No tracked file exceeds 50 MB; the dataset and run directory remain ignored by Git.
- No empty project directories or source cache/checkpoint directories were found. Existing root prompt/result files and the ignored Kaggle credential directory were retained; credential contents were not opened. A clean-machine installation and manual desktop acceptance remain unverified.
- [repository-audit.txt](evidence/test-results/repository-audit.txt) captures branch/remotes, tracked-file size and count, representative ignore checks, local dataset/model presence, hashes, and the limited high-confidence token-pattern scan of tracked source.

## Milestone 5.3.5 final acceptance verification (2026-11-02)

- Re-ran the MATLAB R2026b suite: **34 passed, 0 failed, 0 incomplete**. The fresh output is preserved at [matlab-r2026b-milestone-5.3.5-full-suite.txt](evidence/test-results/matlab-r2026b-milestone-5.3.5-full-suite.txt).
- Python syntax compilation passed for all **10** source files; `test_pytorch_pipeline.py` passed **7/7**. The MATLAB ONNX bridge imported and synthetic-input inference completed with `CPUExecutionProvider`; output shape was `[1,1,256,256]` with finite probabilities in `[0,1]`. See [the fresh Python evidence](evidence/test-results/python-r2026b-milestone-5.3.5.txt).
- MATLAB `pyenv` and Python package versions were inspected again. The exact runtime evidence is in [matlab-r2026b-milestone-5.3.5-pyenv.txt](evidence/test-results/matlab-r2026b-milestone-5.3.5-pyenv.txt); the failed initial combined diagnostic command is not evidence and is not retained.
- Code Analyzer inspected 69 MATLAB files and again found five advisory diagnostics, confined to legacy `matlab/MedicalImageToolbox.m`; the current app and test files had no reported diagnostics. See [the fresh analyzer output](evidence/test-results/matlab-r2026b-milestone-5.3.5-code-analyzer.txt).
- The checkpoint and ONNX SHA-256 values were checked read-only against the unchanged [artifact manifest](evidence/model-artifact-manifest.txt). Existing dataset, model, experiment, and historical evidence were preserved.
- The fresh [Milestone 5.3.5 repository audit](evidence/test-results/repository-audit-milestone-5.3.5.txt) records branch/baseline, no remote, tracked-file size and count, representative ignore checks, local dataset/model presence, and current artifact hashes. No credential contents were read.
- Automated GUI test coverage is not manual desktop acceptance. The clean-machine install, target-display walkthrough, and external artifact transfer remain pending. See the [Final Release Report](FINAL_RELEASE_REPORT.md) for the full acceptance classification and checklist.
