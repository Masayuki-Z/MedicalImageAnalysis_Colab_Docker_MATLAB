# Milestone 5.3.6 — Legacy Cleanup Report

**Date:** 2026-11-02
**Scope:** Retire obsolete Keras/FastAPI/Docker runtime components while preserving the current MATLAB/Python/ONNX application, PyTorch reproducibility pipeline, and historical experiment evidence.

## Cleanup outcome

The current application inference route remains:

```text
MATLAB MedicalImageAnalysisApp
  -> MATLAB ONNX integration
  -> python/matlab_onnx_bridge.py
  -> ONNX Runtime CPUExecutionProvider
  -> unet_model.onnx
```

The PyTorch training, evaluation, and ONNX export pipeline remains available. No Modules 1–3 algorithms, current app, Python bridge/pipeline, dataset, PyTorch checkpoint, ONNX model, patient split, training history, test metrics, or parity report were changed.

## Files removed

| Removed path | Reason |
|---|---|
| `Dockerfile` | Built the retired TensorFlow/FastAPI service. |
| `Dockerfile_jupy` | Retired TensorFlow/Jupyter container configuration; no current workflow depended on it. |
| `docker-compose.yml` | Launched the retired API and mounted the old Keras model. |
| `jupyter_req.txt` | Root-level TensorFlow/FastAPI/Uvicorn/Jupyter dependencies used only by the retired container workflow. |
| `api/app.py` | FastAPI inference endpoint loaded `tumor_unet.keras`; no current MATLAB or Python workflow imported it. |
| `api/requirements.txt` | TensorFlow/FastAPI/Uvicorn/Pydantic dependencies used only by `api/app.py`. |
| `python/train.py` | TensorFlow/Keras training implementation superseded by `python/train_pytorch.py`. |
| `python/visual_evaluate.py` | TensorFlow/Keras visualization and inference script superseded by the saved PyTorch evaluation and current MATLAB/ONNX GUI. |
| `models/tumor_unet.keras` (local ignored file) | Retired Keras model had no current workflow consumer. It was not Git-tracked; removed locally after recording its prior size (23,649,459 bytes) and SHA-256 (`D7A259D8CBB1C859A895B7307F242FD0394952DF0BFA32A1CB76FEC017680FF2`). |

Empty `api/` and `models/` directories were removed. The model path remains excluded by `.gitignore` so an unrequested local Keras artifact cannot be staged accidentally.

The Keras API integration was also removed from `matlab/MedicalImageToolbox.m`. That file is explicitly labeled as a legacy classic-only prototype; its remaining classical demo operations were not changed. The current app remains `matlab/MedicalImageAnalysisApp.m`.

## Legacy dependency classification

| Legacy component/dependency | Classification | Decision |
|---|---|---|
| TensorFlow/Keras runtime | Obsolete for current runtime | Removed from API, Python scripts, and Docker requirements. |
| FastAPI, Uvicorn, Pydantic | Obsolete API-only dependencies | Removed with `api/` and root legacy requirements. |
| Docker and Compose | Obsolete deployment workflow | Removed; current app is local MATLAB with Python ONNX Runtime. |
| `python/train.py`, `python/visual_evaluate.py` | Obsolete TensorFlow/Keras scripts | Removed; PyTorch equivalents remain. |
| `notebooks/V1Train_UNet_LGG_Colab_with_visual_export.ipynb` | Historical academic experiment/evidence | Preserved as an archived notebook; not a current dependency or supported workflow. Its saved cells are not regenerated. |
| `notebooks/Train_UNet_PyTorch_Colab.ipynb` | Current reproducibility workflow | Preserved. |
| `models/tumor_unet.keras` | Obsolete ignored local model | Removed locally after recording its metadata; never tracked by Git. |
| `python/requirements-pytorch.txt`, `python/requirements-pytorch-onnx.txt` | Current dependencies | Preserved; no TensorFlow/Keras/API packages are declared there. |

Historical milestone documents, test logs, notebooks, screenshot evidence, and experiment reports remain intact. Historical mentions of Keras/API/Docker are retained only where they describe the earlier project state; current installation instructions do not require those components.

## Preserved current components

- All MATLAB Modules 1–3, common helpers, and regression tests.
- `matlab/MedicalImageAnalysisApp.m` and MATLAB ONNX integration.
- `python/matlab_onnx_bridge.py`, `python/pytorch_pipeline.py`, `python/train_pytorch.py`, `python/evaluate_pytorch.py`, `python/export_pytorch_onnx.py`, and `python/test_pytorch_pipeline.py`.
- PyTorch dependency manifests and the current PyTorch Colab notebook.
- Local dataset and final run directory, including checkpoint, ONNX model, test metrics, patient split, training history, parity report, and exports.
- Historical Keras Colab notebook and existing milestone/evidence history.
- Root user-created prompts and outputs; credentials were not opened.

## Verification results

- **MATLAB R2026b:** 34 passed, 0 failed, 0 incomplete. See [full-suite output](evidence/test-results/matlab-r2026b-milestone-5.3.6-full-suite.txt).
- **Python 3.11:** all 7 current Python files syntax-compiled; `test_pytorch_pipeline.py` passed 7/7. See [Python output](evidence/test-results/python-r2026b-milestone-5.3.6.txt).
- **MATLAB Code Analyzer:** 69 `.m` files inspected; three advisory findings remain in the legacy classic-only `matlab/MedicalImageToolbox.m` prototype. See [Code Analyzer output](evidence/test-results/matlab-r2026b-milestone-5.3.6-code-analyzer.txt).
- **ONNX smoke test:** Python bridge import and synthetic FLAIR inference passed with ONNX Runtime 1.31.1 and `CPUExecutionProvider`; input and output were `[1,1,256,256]`, and probability values were finite and in `[0,1]`. MATLAB's full ONNX integration suite also passed. See [smoke-test output](evidence/test-results/onnx-milestone-5.3.6-smoke-test.txt).
- **Artifact integrity:** checkpoint and ONNX SHA-256 values match the existing [artifact manifest](evidence/model-artifact-manifest.txt). Neither artifact was modified.
- **Repository audit:** removed-component references were checked against current runtime source and installation instructions; no current path depends on the retired service. See [repository audit](evidence/test-results/repository-audit-milestone-5.3.6.txt).

## Remaining limitations

- Clean-machine installation has not been tested.
- MATLAB inference is CPU-only; GPU inference through the bridge is not verified.
- ONNX parity evidence remains limited to five slices from one patient.
- The recorded training collapse after epoch 7 remains unexplained; no retraining or metric regeneration was performed.
- No clinical validity or diagnostic performance is claimed.
- The MATLAB suite emitted a Windows warning that accessibility text size above 100% forces figures to be scrollable. The project owner confirmed presentation-resolution GUI acceptance on 2026-11-02; that manual acceptance was not independently witnessed during this cleanup.
- The project owner confirmed recipient artifact transfer and hash verification on 2026-11-02; that transfer was not independently repeated during this cleanup.

## Git commit

Commit hash and final working-tree status are recorded in the Milestone 5.3.6 completion entry in [Project Status](PROJECT_STATUS.md).
