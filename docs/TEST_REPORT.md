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

The full MATLAB runner output was captured at [matlab-r2026b-full-suite.txt](evidence/test-results/matlab-r2026b-full-suite.txt). The additional 34th test covers the six-section navigation, distinct operation selectors, section callback processing, and scoped reset. The AI workflow test also asserts that computed metrics appear in the Evaluation section.

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
