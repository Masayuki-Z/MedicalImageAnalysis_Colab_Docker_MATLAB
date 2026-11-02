# PyTorch LGG Segmentation Migration

This is the new PyTorch implementation path. It does not replace or rewrite the
legacy Keras Notebook, `python/train.py`, `python/visual_evaluate.py`, FastAPI
service, or `models/tumor_unet.keras`. Historical Keras outputs are not used as
PyTorch training evidence.

## Dataset audit and preprocessing

The loader uses `data/lgg-mri-segmentation/kaggle_3m` and its checked-in
`README.md`. That documentation specifies RGB channel order as pre-contrast,
FLAIR, post-contrast, with missing sequences replaced by FLAIR. The loader
selects channel index 1 (the second channel), not a guessed channel.

Before training, `validate_pairs` opens every paired TIFF and checks uint8 RGB,
2-D binary mask values, and spatial alignment. The local audit found 110
patient folders, 3,929 pairs, all MRI dimensions 256×256×3, all masks 256×256,
and no missing pairs or alignment mismatches.

Preprocessing:

1. Read RGB TIFF; select `image[:, :, 1]`.
2. Convert uint8 FLAIR values to float32 `[0,1]`.
3. Resize to 256×256 only if required (bilinear for image).
4. Compute per-slice mean and population standard deviation (`ddof=0`) and
   apply `(x - mean) / max(std, 1e-6)`. A zero-variance slice is centered and
   divided by 1.0, yielding zeros.
5. Convert paired masks to float32 `{0,1}`; resize only when needed with nearest
   neighbor.
6. During training only, randomly apply a horizontal flip and an in-plane
   rotation within ±10 degrees. The same transform is applied to image and
   mask, bilinear interpolation is used for image, and nearest-neighbor is used
   for mask. Mask values are thresholded back to binary.

The same per-slice normalization is required at inference; do not apply
histogram equalization or other MATLAB enhancement before AI inference unless
that distribution is separately validated. The original MRI remains available
as a direct model input source.

## Patient-level split

`patient_split.json` records sorted patient IDs, image counts, proportions,
seed, and overlap checks. The split uses patient folder IDs, fixed seed 42 by
default, and deterministic largest-remainder allocation. For 110 patients the
counts are 77 training, 17 validation, and 16 unseen-test patients (nearest
whole-patient allocation to 70/15/15). Current audited slice counts are 2,719,
641, and 569 respectively. No patient is shared across subsets.

The test subset is not loaded by the training loop. Evaluation and ONNX parity
are separate commands and are guarded against smoke-test checkpoints.

## Install and smoke test

```powershell
python -m pip install -r python\requirements-pytorch.txt
python -m unittest discover -s python -p "test_pytorch_pipeline.py" -v
python python\train_pytorch.py --data-dir data\lgg-mri-segmentation\kaggle_3m --output-dir model_output --smoke-test
```

The smoke test forces 2 epochs, batch size 1, and one positive training plus
one positive validation slice. It verifies the full specified U-Net forward
and backward passes, BCE+Dice loss, validation Dice, checkpoint save, and
training history. It writes into `model_output/smoke_test/`. It does not evaluate
the unseen test set and is not a final model. CPU activation checkpointing is
enabled to reduce memory use.

For the GPU smoke gate and full Colab workflow, open
[`notebooks/Train_UNet_PyTorch_Colab.ipynb`](../notebooks/Train_UNet_PyTorch_Colab.ipynb).
Copy the project folder to Google Drive, set its `PROJECT_ROOT`, select a Colab
GPU, and run cells in order. The notebook verifies the CUDA placement and
forward/backward dimensions, then runs this existing smoke-test script before
enabling the separate full-training cell. It saves logs and artifacts in a
timestamped folder under `model_output/colab_runs/`. If the dataset is missing
from Drive, the notebook can use `KAGGLE_USERNAME` and `KAGGLE_KEY` Colab
Secrets; secret values and command output are not displayed. The final cell
prints the Drive run folder and instructs you to right-click it in Drive and
choose **Download** (Drive packages the folder as a ZIP), or download individual
artifacts. The run captures its actual GPU/runtime metadata in
`colab_environment.json`.

For GPU training (after the smoke test passes), run on a GPU host such as
Colab:

```powershell
python python\train_pytorch.py --data-dir data\lgg-mri-segmentation\kaggle_3m --output-dir model_output\pytorch --epochs 50 --batch-size 8
```

The model is the original 1-channel 2-D U-Net: encoders 64/128/256/512,
bottleneck 1024, decoders 512/256/128/64, sigmoid one-channel output; Adam at
1e-4; BCE+soft-Dice loss; best checkpoint selected by validation Dice with
early stopping. Full training is not run automatically as part of the smoke
test.

## Full evaluation and MATLAB export

Only run these commands after full training produces a non-smoke
`model_output/pytorch/best_unet.pth`:

```powershell
python python\evaluate_pytorch.py --data-dir data\lgg-mri-segmentation\kaggle_3m --output-dir model_output\pytorch --threshold 0.5
```

This evaluates the fixed 0.5 threshold on the unseen test split only and
produces `test_metrics.json`, test comparison panels, and
`MATLAB_Export/{images,ground_truth,predictions,metadata.csv}`. It does not
tune a threshold on test data. Pixel-pooled Dice, IoU, precision, and recall
are saved with test patient/slice counts.

## ONNX export and parity

Install optional export dependencies and export only after full training:

```powershell
python -m pip install -r python\requirements-pytorch-onnx.txt
python python\export_pytorch_onnx.py --checkpoint model_output\pytorch\best_unet.pth --data-dir data\lgg-mri-segmentation\kaggle_3m --split-file model_output\pytorch\patient_split.json --output model_output\pytorch\unet_model.onnx
```

The exporter checks the ONNX graph and compares PyTorch and ONNX Runtime
probabilities using a few fixed unseen-test samples (`atol=1e-5`, `rtol=1e-4`).
It records dimensions, provider, sample count, and max absolute/relative error
in `onnx_parity.json`. It rejects smoke checkpoints.

## MATLAB inference contract and tested bridge

- Input to model: NCHW float32 `[N,1,256,256]`; single grayscale FLAIR channel.
- Source channel: second RGB channel (index 1/ MATLAB channel 2) only for the
  documented LGG TIFF format.
- Normalization: per-slice z-score `(x-mean)/std`, population std, epsilon
  `1e-6`, constant slices become zeros. Mean/std are computed per incoming
  image slice using the method in `normalization_config.json`.
- Output: NCHW float32 probability map `[N,1,256,256]` in `[0,1]`.
- Binary mask: `probability >= 0.5` unless a separately justified model
  configuration specifies otherwise.
- Orientation: row/column order is preserved; no transpose or rotation is
  applied by the model pipeline. Resize masks with nearest-neighbor.
- Model output is a research prediction, not a medical diagnosis.

The tested MATLAB path is `matlab/ai/runGliomaONNX.m` through the Python bridge
`python/matlab_onnx_bridge.py`. MATLAB R2026b calls the Python 3.11 interpreter
configured by `pyenv`; that same interpreter must have NumPy, Pillow, and
ONNX Runtime installed. The current environment uses ONNX Runtime 1.31.1 with
`CPUExecutionProvider`; MATLAB-native ONNX import is unavailable because the
Deep Learning Toolbox importer is not installed. Run the app from the project
root after adding the MATLAB tree:

```matlab
addpath(genpath(fullfile(pwd,"matlab")));
app = MedicalImageAnalysisApp;
app.setModelPath(fullfile(pwd,"model_output","colab_runs", ...
    "20261101_205443","unet_model.onnx"));
```

`matlab/tests/testONNXIntegration.m` checks preprocessing parity against the
Python training pipeline, dimensions, probability range, restored masks,
state/history preservation, and invalid input handling. The GUI workflow
tests are in `matlab/tests/testAppIntegration.m`. The integrated `.m` GUI and
bridge are tested; a MATLAB App Designer `.mlapp` file has not been produced.

## Audited Colab experiment

The final audited run is `model_output/colab_runs/20261101_205443/`. Its
environment record reports Python 3.13.16, PyTorch 2.11.0+cu130, CUDA 13.0,
and a Tesla T4. The GPU smoke test completed on CUDA. Full training used batch
8 and stopped at epoch 19 after 12 epochs without validation improvement. It
took 4,016.55 seconds; the best checkpoint is epoch 7 with validation Dice
0.784357. Training and validation Dice collapsed to zero beginning at epoch 8.
The checkpoint is finite and corresponds to the best validation epoch, but
gradient norms and optimizer state were not saved, so the cause of the
collapse is unknown. See
[`docs/MILESTONE3_FINAL_AUDIT.md`](../docs/MILESTONE3_FINAL_AUDIT.md) for the
non-destructive audit and diagnostic recommendation.

Final test evaluation used the fixed 0.5 threshold on 569 slices from 16
unseen patients. Metrics are pixel-pooled from TP=289,408, FP=85,423,
FN=76,307: Dice 0.781607, IoU 0.641507, precision 0.772103, recall 0.791348.
They are not averages of per-slice or per-patient metrics. Recomputing from
the saved counts reproduces the saved values exactly. The report declares that
the threshold was not selected using test data.

ONNX parity was checked on five slices from one test patient using
`CPUExecutionProvider`: float32 NCHW input/output `[N,1,256,256]`, maximum
absolute probability difference 3.2783e-7, and zero thresholded-mask
mismatches at 0.5. Maximum relative error 1.1467 is sensitive to near-zero
denominators; use the absolute error and mask mismatch count in interpreting
this limited parity check.

All required run files are preserved under the run directory:
`best_unet.pth`, `unet_model.onnx`, `test_metrics.json`,
`training_history.json`, `training_history.png`, `patient_split.json`,
`model_config.json`, `normalization_config.json`, `onnx_parity.json`, and
`colab_environment.json`. No files in this directory should be overwritten by
diagnostic experiments; use a new output directory for any follow-up training.

MATLAB R2026b has Image Processing and Computer Vision Toolboxes but no native
ONNX importer. The Python 3.11 ONNX Runtime bridge is installed and has passed
the MATLAB integration suite. In the audited run, test-set ONNX probability
parity was evaluated on five samples from one test patient; this is a limited
export consistency check, not broad clinical or generalization validation.

## Final handover verification (2026-11-02)

The configured MATLAB Python interpreter was verified as Python 3.11 with
NumPy 1.26.4, Pillow 11.0.0, PyTorch 2.9.1+cpu, Matplotlib 3.9.2, and ONNX
Runtime 1.31.1. This local interpreter is for MATLAB integration and is
distinct from the Colab training environment above. The bridge explicitly
requests `CPUExecutionProvider`; the locally installed provider list also
reported `AzureExecutionProvider`, which the bridge does not select.

The bridge imports `normalize_flair` from `pytorch_pipeline.py`, which imports
PyTorch. Therefore PyTorch must be installed in the same interpreter configured
with MATLAB `pyenv`, in addition to NumPy, Pillow, and ONNX Runtime. See
[`docs/INSTALLATION_GUIDE.md`](../docs/INSTALLATION_GUIDE.md) for reproducible
environment setup and troubleshooting.

After the final GUI evaluation view change, the complete MATLAB R2026b suite
passed **34/34** methods: 15 module, 6 ONNX integration, 7 GUI integration,
and 6 ground-truth evaluation tests. Raw output is captured at
[`docs/evidence/test-results/matlab-r2026b-full-suite.txt`](../docs/evidence/test-results/matlab-r2026b-full-suite.txt).
The final model artifacts remain in the audited run and are intentionally not
retrained or modified during handover. Their sizes and SHA-256 values are in
[`docs/evidence/model-artifact-manifest.txt`](../docs/evidence/model-artifact-manifest.txt).
