# Milestone 3 Final Audit

Audit date: 2026-11-02  
Audited run: `model_output/colab_runs/20261101_205443/`

## Evidence and preserved artifacts

The run directory contains `best_unet.pth`, `unet_model.onnx`,
`test_metrics.json`, `training_history.json`, `training_history.png`,
`patient_split.json`, `model_config.json`, `normalization_config.json`,
`onnx_parity.json`, `colab_environment.json`, the smoke-test artifacts, logs,
and unseen-test example exports. These files were inspected read-only. No model
checkpoint, ONNX model, test metric, or prediction was modified or overwritten
during this audit.

The separate run `model_output/colab_runs/20261101_192943/` is incomplete and
does not contain final evaluation/ONNX reports; it is not the final run.

## Training environment and protocol

- Colab environment record: Python 3.13.16, PyTorch 2.11.0+cu130, CUDA 13.0,
  Tesla T4 (15,637,086,208 bytes reported GPU memory, 40 multiprocessors).
- The two-epoch GPU smoke log confirms `device: cuda`, completed training and
  validation, and saved its checkpoint. This is distinct from the earlier
  local CPU smoke test.
- Full run used seed 42, batch size 8, 100-epoch maximum, and stopped after 19
  epochs. Recorded elapsed time is 4,016.55 seconds (about 66.9 minutes).
- Architecture metadata matches the original one-channel 2-D U-Net:
  encoder 64/128/256/512, bottleneck 1024, decoder 512/256/128/64, sigmoid
  one-channel output, 256×256 input, 31,030,593 parameters.
- Adam learning rate is 0.0001; loss is binary cross entropy plus soft Dice.
  The selected checkpoint records epoch 7 and validation Dice 0.784357.
- The patient split is seed-42 deterministic 70/15/15 with train 77 patients /
  2,719 slices, validation 17 / 641, and test 16 / 569. All recorded pairwise
  patient intersections are empty. The notebook and evaluator exclude the test
  subset from training and checkpoint selection.

## Preprocessing audit

The saved config records channel index 1 (the second RGB channel, FLAIR),
uint8-to-float32 scaling to [0,1], per-slice population Z-score after resize,
epsilon 1e-6, bilinear image resize only when needed, and nearest-neighbor
mask resize. Constant slices are centered and divided by 1.0, yielding zeros.
These settings match `python/pytorch_pipeline.py`.

## Training instability after epoch 7

The history shows training/validation improving through epoch 7, with the
best validation Dice of 0.784357. At epoch 8, training loss rises from
0.436367 to 1.380219 and validation Dice falls to 0; epochs 9–19 retain zero
training and validation Dice, with training loss around 1.94–1.98 and
validation loss around 1.555. Early stopping follows 12 epochs without a new
validation best. The saved checkpoint and test report both point to epoch 7.

The checkpoint has 46 state-dict tensors, 31,030,593 parameters, and no
non-finite tensor values. Its metadata and architecture are consistent with
the saved model config. The checkpoint stores no optimizer state, per-step
gradient norms, activation statistics, or epoch-8 parameters. Therefore the
artifacts establish a training collapse but do **not** establish its cause or
the gradient behavior. Potential factors such as update magnitude, sigmoid /
BCE saturation, augmentation interaction, or numerical behavior are
hypotheses, not confirmed defects.

**Non-destructive recommendation:** retain epoch 7 as the selected artifact;
do not overwrite it or retune against the test set. If stability needs
investigation, conduct a separate, explicitly diagnostic run in a new output
directory, logging gradient norms, parameter finiteness, prediction ranges,
and optimizer state per epoch. Candidate changes such as logit-based
`BCEWithLogitsLoss`, a lower learning rate, gradient clipping, or a scheduler
must be evaluated in that separate run using the same fixed patient split and
validation-only selection. Do not claim those changes improve results without
running them.

## Test metrics audit

The final report evaluates 569 slices belonging to the 16 held-out test
patients at the fixed threshold 0.5. It aggregates pixel-level TP/FP/FN over
all slices (pixel-pooled, not a mean of slice or patient scores):

| Metric | Value |
|---|---:|
| Dice | 0.781607 |
| IoU | 0.641507 |
| Precision | 0.772103 |
| Recall | 0.791348 |

Saved counts are TP 289,408, FP 85,423, FN 76,307. Recomputing all four
metrics from those counts reproduces every saved metric exactly to the
recorded precision. The checkpoint epoch and validation Dice in the test
report match the saved best checkpoint. Threshold selection is recorded as
not using test data.

## ONNX audit

The parity report identifies input `flair`, output `probability`, float32
dynamic-batch NCHW tensors `[N,1,256,256]`, and ONNX Runtime
`CPUExecutionProvider`. Five samples from one test patient were compared.
`assert_allclose` passed with atol 1e-5 and rtol 1e-4; maximum absolute
probability difference was 3.2783e-7; thresholded-mask mismatch count was
zero at threshold 0.5.

The reported maximum relative error (1.1467) is large because relative error
divides by probabilities near zero; the absolute error and exact thresholded
mask parity are more informative here. The parity sample count is small and
from one test patient, so it is an export consistency check, not a broad
runtime or clinical validation.

## MATLAB readiness and blockers

- Installed MATLAB is R2026b (26.2.0.3386108), with Computer Vision Toolbox,
  Image Processing Toolbox, and Medical Imaging Toolbox. Deep Learning Toolbox
  is not installed; `importNetworkFromONNX`, `importONNXNetwork`, and
  `importONNXFunction` are not found in the current MATLAB path.
- MATLAB's configured Python is 3.11 in-process. The local Python environment
  does not have `onnxruntime` installed, so a MATLAB-to-ONNX execution bridge
  is not currently available either.
- `matlab/ai/prepareFlairONNXInput.m`, `restoreGliomaPrediction.m`, and
  `runGliomaONNX.m` exist but are zero-byte files. There is no `.mlapp`.
- MATLAB Modules 1–3 remain intact. Existing state fields include original,
  enhanced, transformed, classical mask, AI input, and AI prediction, but no
  AI probability-map field yet.

Native MATLAB ONNX integration is blocked by the missing Deep Learning Toolbox
and ONNX importer. Before implementing the inference backend, choose either a
licensed/installed native MATLAB ONNX importer or an explicit MATLAB-to-Python
ONNX Runtime bridge. Neither backend is reported as tested or operational.

## MATLAB integration follow-up

After the audit above, the project selected the MATLAB-to-Python ONNX Runtime
bridge. ONNX Runtime 1.31.1 was installed in the Python 3.11 environment used
by MATLAB R2026b. This follow-up does not alter any files in the audited run.

- Added `python/matlab_onnx_bridge.py` and MATLAB helpers for channel selection,
  exact Python preprocessing, ONNX inference, probability validation,
  thresholding, and nearest-neighbor restoration.
- Added `AIProbabilityMap` to the shared image state. AI input, probability,
  and prediction remain separate; inference uses `OriginalImage` directly.
- Added the programmatic GUI class `matlab/MedicalImageAnalysisApp.m`.
  Automated tests exercised enhancement, classical segmentation, geometry,
  nearest-neighbor mask alignment, AI inference/overlay, save/reset, and error
  paths.
- MATLAB R2026b full suite passed **24/24**: 15 module tests, 6 ONNX tests,
  and 3 GUI workflow tests. Code Analyzer reported no issues in the GUI class.
  The fixed unseen-test sample's thresholded MATLAB/bridge output matched its
  saved Python prediction.
- The App Designer `.mlapp` is still not available. MATLAB's internal
  `MLAPPSerializer` warned that AppBase app-object save/load is unsupported;
  no `.mlapp` was added. The tested GUI deliverable is the `.m` AppBase class,
  and manual desktop acceptance remains outstanding.

## Final handover environment confirmation (2026-11-02)

The earlier MATLAB readiness section is a snapshot from before the bridge was
implemented. The current local MATLAB Python environment was verified
read-only: MATLAB R2026b (26.2.0.3386108), Python 3.11, NumPy 1.26.4,
Pillow 11.0.0, PyTorch 2.9.1+cpu, Matplotlib 3.9.2, and ONNX Runtime 1.31.1.
The runtime reported Azure and CPU providers; `matlab_onnx_bridge.py`
explicitly requests `CPUExecutionProvider`. Image Processing Toolbox is
required by the MATLAB modules; Deep Learning Toolbox and native ONNX import
are not required by the current bridge.

The ONNX model, checkpoint, metrics, and prediction exports were not changed.
Their principal model file sizes and SHA-256 digests are recorded in
[`evidence/model-artifact-manifest.txt`](evidence/model-artifact-manifest.txt).
The finalization regression run passed 34 MATLAB tests, including the
Milestone 5.3.2 GUI workflow test. See [`TEST_REPORT.md`](TEST_REPORT.md) for
test groups and captured runner output.