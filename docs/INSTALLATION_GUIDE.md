# Installation and Configuration Guide

This guide covers the verified MATLAB R2026b application and its MATLAB-to-Python ONNX Runtime bridge. The project is educational/research software, not a clinical diagnostic tool.

## 1. Requirements

### Required for the MATLAB application

- MATLAB R2026b (26.2) on a supported desktop operating system. The verified machine is Windows.
- Image Processing Toolbox. The MATLAB modules use functions including `histeq`, `imhistmatch`, `imfilter`, `medfilt2`, `edge`, `graythresh`, binary morphology, and `regionprops`.
- Python 3.11 configured through MATLAB `pyenv`.
- Python packages installed in that same interpreter:
  - NumPy
  - Pillow
  - ONNX Runtime 1.31.1
  - PyTorch, because the bridge imports the shared `pytorch_pipeline` module, which imports `torch`
- The supplied run artifacts, especially `unet_model.onnx`. Automated ONNX and GUI tests also use sample MRI and ground-truth exports from that run.

The current verified Python environment reports NumPy 1.26.4, Pillow 11.0.0, PyTorch 2.9.1+cpu, Matplotlib 3.9.2, and ONNX Runtime 1.31.1. The ONNX Runtime installation reports `AzureExecutionProvider` and `CPUExecutionProvider`; the project bridge explicitly creates inference sessions with **CPUExecutionProvider**.

Deep Learning Toolbox, Computer Vision Toolbox, and Medical Imaging Toolbox are **not required** by the current application. Inference is Python ONNX Runtime, not native MATLAB ONNX import. A GPU is not required for MATLAB inference. Full model training is a separate Colab workflow and is not part of application installation.

**Reproducibility status:** These versions and the MATLAB-to-Python bridge were verified on the existing Windows development machine. The virtual-environment setup below is provided for new installations but has not been executed on a clean machine; dependency installation from scratch and clean-machine setup are not claimed as tested. The `onnx` Python package is needed for ONNX export/graph validation, not for the saved-model MATLAB inference bridge; it was not installed in the audited local interpreter.

### Optional components

- PyTorch training, evaluation, and ONNX-export dependencies in `python/requirements-pytorch.txt` and `python/requirements-pytorch-onnx.txt`.
- Docker/FastAPI and Jupyter assets are retained as legacy/reference project components; they are not required to run the current MATLAB ONNX workflow.
- The LGG dataset is required only for dataset training and the classical MRI demonstration. It is not required for the saved-sample regression suite, provided the final run artifacts are present.

The local dataset audited for this project occupies about 1.06 GB. The preserved final checkpoint and ONNX model are each about 124 MB. Reserve additional space for the Python environment and temporary files; no minimum RAM or disk specification has been benchmarked.

## 2. Obtain project inputs

Obtain the project source and, separately, the large experiment artifacts under:

```text
model_output/colab_runs/20261101_205443/
```

The source repository excludes `data/` and `model_output/` to avoid committing the dataset and two model files larger than 100 MB. The artifact manifest at [evidence/model-artifact-manifest.txt](evidence/model-artifact-manifest.txt) records expected sizes and SHA-256 digests. The directory must include `unet_model.onnx`, `best_unet.pth`, and the `MATLAB_Export` sample/ground-truth folders for the full MATLAB regression suite. Do not replace these files with an unverified model or historical prediction.

The dataset is available from the source listed in the root README. Review its CC BY-NC-SA 4.0 terms before using or redistributing it. Do not put Kaggle credentials in the repository.

## 3. Install Python 3.11 and dependencies

From the project root, create an isolated environment. These commands use the actual project requirements; the final command selects the tested ONNX Runtime release.

### Windows PowerShell

```powershell
py -3.11 --version
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r python\requirements-pytorch-onnx.txt
.\.venv\Scripts\python.exe -m pip install "onnxruntime==1.31.1"
```

### Linux/macOS shell

```bash
python3.11 --version
python3.11 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r python/requirements-pytorch-onnx.txt
.venv/bin/python -m pip install "onnxruntime==1.31.1"
```

`requirements-pytorch-onnx.txt` includes the shared PyTorch requirements plus ONNX and ONNX Runtime minimum versions. The final install pins ONNX Runtime to the version verified with this bridge. It does not configure GPU inference.

Verify the environment with the platform-specific interpreter:

```powershell
.\.venv\Scripts\python.exe -c "import sys, numpy, PIL, torch, onnxruntime as ort; print(sys.version); print(sys.executable); print(numpy.__version__, PIL.__version__, torch.__version__, ort.__version__); print(ort.get_available_providers())"
```

Expected for the tested bridge is Python 3.11 and ONNX Runtime 1.31.1. Available providers vary by installation; the bridge requests CPU explicitly.

## 4. Configure MATLAB to use that Python

MATLAB must be pointed at the same Python environment where the dependencies above were installed. Configure Python **before any MATLAB code initializes Python**. Run this in a fresh MATLAB session:

```matlab
projectRoot = pwd;  % Start MATLAB in the project root
pythonExe = fullfile(projectRoot, ".venv", "Scripts", "python.exe"); % Windows
% On Linux/macOS use fullfile(projectRoot, ".venv", "bin", "python")

pyenv(Version=pythonExe, ExecutionMode="InProcess");
pyenv
```

`pyenv` is process-scoped. If Python has already initialized in the current MATLAB process, close MATLAB, restart it, and configure the interpreter before running tests or inference. Do not attempt to switch a loaded interpreter in place.

Verify imports from MATLAB:

```matlab
ort = py.importlib.import_module("onnxruntime");
numpy = py.importlib.import_module("numpy");
PIL = py.importlib.import_module("PIL");
disp(pyenv)
disp(py.getattr(ort, "__version__"))
disp(ort.get_available_providers())
```

For the bridge, the relevant current source interfaces are:

- [`getGliomaONNXBridge`](../matlab/ai/getGliomaONNXBridge.m) obtains `pyenv`, adds the project `python/` folder to `py.sys.path`, and imports `matlab_onnx_bridge` and `onnxruntime`.
- [`preprocess_flair_plane`](../python/matlab_onnx_bridge.py) selects no channel itself; it accepts an already selected 2-D FLAIR plane, resizes if needed, normalizes, and returns NCHW float32.
- [`prepareFlairONNXInput`](../matlab/ai/prepareFlairONNXInput.m) selects MATLAB channel 2 from RGB input (zero-based channel 1), then delegates to the Python preprocessing function.
- [`runGliomaONNX`](../matlab/ai/runGliomaONNX.m) runs the imported bridge, validates output shape/range, restores the mask, and records the model/preprocessing information.

## 5. Add MATLAB paths and verify toolboxes

Start MATLAB in the project root, then:

```matlab
version
ver
addpath(genpath(fullfile(pwd, "matlab")));
```

Confirm MATLAB reports version 26.2 / R2026b and Image Processing Toolbox. `savepath` is not necessary; the command above only affects the current MATLAB session. If you choose to use `savepath`, it changes your MATLAB search path persistently and should be done only if desired.

## 6. Run tests and launch

The tests use the saved final ONNX model and sample exports. Ensure the artifact directory described above is present.

```matlab
results = runModuleTests;
assert(all([results.Passed]));
```

Launch the GUI and set the model path:

```matlab
app = MedicalImageAnalysisApp;
app.setModelPath(fullfile(pwd, "model_output", "colab_runs", ...
    "20261101_205443", "unet_model.onnx"));
```

Use **Load MRI** or the Image Workspace controls to load a supported image. Use **Load ONNX model** or the `setModelPath` call to select the model. Select **AI Segmentation** and run inference; then select **Evaluation** to load a corresponding ground-truth mask and view overlap/metrics.

## 7. Inference contract

- Input: one grayscale FLAIR plane; for documented RGB LGG input, MATLAB selects channel 2 (zero-based index 1).
- Resize: 256 × 256 only when needed; bilinear interpolation.
- Normalize: per-slice population Z-score after conversion to float32 `[0,1]`, epsilon `1e-6`; constant slices produce zeros.
- Tensor: float32 NCHW `[1,1,256,256]`.
- Output: float32 probability tensor `[1,1,256,256]`, validated to `[0,1]`.
- Threshold: `probability >= 0.5`.
- Alignment: prediction is restored to the original MRI dimensions with nearest-neighbor interpolation. Row/column orientation is preserved.
- Provider: Python ONNX Runtime through MATLAB's Python interface, explicitly `CPUExecutionProvider`.

The preprocessing and inference behavior is implemented in the linked source files above. Do not apply a MATLAB enhancement before AI inference unless its compatibility with the trained model has been separately demonstrated; the app's AI route always begins from the original MRI.

## 8. Troubleshooting

| Symptom | Check |
|---|---|
| Python version is not 3.11 | Inspect `pyenv`. Configure the desired interpreter in a fresh MATLAB process before Python initialization. |
| `ONNXRuntimeUnavailable` | In the interpreter shown by `pyenv`, run `python -m pip show onnxruntime`; install `onnxruntime==1.31.1` there and restart MATLAB. |
| `PythonBridgeMissing` or `ModuleNotFoundError` | Start MATLAB from the project root, ensure `python/matlab_onnx_bridge.py` exists, and confirm the configured interpreter has NumPy, Pillow, PyTorch, and ONNX Runtime. |
| Model missing | Confirm `model_output/colab_runs/20261101_205443/unet_model.onnx` exists and matches the SHA-256 manifest. |
| Input/output dimension error | Use the supplied ONNX artifact. The bridge expects float32 NCHW `[1,1,256,256]`. |
| Inference/provider error | The project requests CPU execution. Check imports and `ort.get_available_providers()` in the exact `pyenv` interpreter; GPU providers are not part of the verified MATLAB route. |
| Test cannot find fixture/model | Restore the `MATLAB_Export` folders and final ONNX artifact under the exact run directory. |
| Test failure on an unavailable toolbox | Confirm MATLAB R2026b and Image Processing Toolbox are licensed and available with `ver`. |

Never print or commit Kaggle credentials. Training and deployment credentials are not needed to run saved-model MATLAB inference.
