# Screenshot Index

All PNGs below were captured from the actual MATLAB R2026b `MedicalImageAnalysisApp` using MATLAB `exportapp`. They show a de-identified sample exported with the audited held-out run and its corresponding ground-truth mask. They are interface evidence, not synthetic model results. The AI screens use the preserved ONNX artifact; no screenshots were fabricated.

| Filename | Feature demonstrated | What it verifies | Milestone |
|---|---|---|---|
| [01-image-workspace.png](screenshots/01-image-workspace.png) | Main GUI / Image Workspace | Navigation and the original MRI workspace view. | 5.3.3 |
| [02-image-enhancement.png](screenshots/02-image-enhancement.png) | Image Enhancement | Independent enhancement selector, input display, description, and apply/reset controls. | 5.3.2 |
| [03-image-segmentation.png](screenshots/03-image-segmentation.png) | Image Segmentation | Independent segmentation selector and Otsu workflow controls. | 5.3.2 |
| [04-geometric-transformation.png](screenshots/04-geometric-transformation.png) | Geometric Transformation | Separate transformation selector and output/dimension interface. | 5.3.2 |
| [05-ai-segmentation.png](screenshots/05-ai-segmentation.png) | AI Segmentation controls | Original-image inference path and model/run controls before inference. | 4 / 5.3.3 |
| [06-ai-probability-map.png](screenshots/06-ai-probability-map.png) | AI probability map | AI section after successful inference, including probability map and predicted mask. | 4 / 5.3.3 |
| [07-ai-overlay.png](screenshots/07-ai-overlay.png) | AI prediction overlay | Workspace overlay after inference from Original MRI. | 4 / 5.3.3 |
| [08-ground-truth-loading.png](screenshots/08-ground-truth-loading.png) | Ground Truth loading | Ground-truth section before AI evaluation; annotation is loaded independently. | 5.2 / 5.3.3 |
| [09-segmentation-overlap.png](screenshots/09-segmentation-overlap.png) | Segmentation overlap | Workspace comparison of ground truth and AI after inference, alongside classical output. | 5.2 / 5.3.3 |
| [10-evaluation-metrics.png](screenshots/10-evaluation-metrics.png) | Evaluation metrics | Evaluation section after inference with pixel-level metrics and overlap. | 5.2 / 5.3.3 |
| [11-successful-workflow.png](screenshots/11-successful-workflow.png) | Complete workflow | Workspace after AI inference and classical enhancement, segmentation, and transformation callbacks. | 5.3.2 / 5.3.3 |

## Capture details

- MATLAB: R2026b, `exportapp` on the real app `UIFigure`.
- Test image and matching ground truth: `model_output/colab_runs/20261101_205443/MATLAB_Export/`.
- Model: `model_output/colab_runs/20261101_205443/unet_model.onnx`.
- The AI probability-map screen is a real inference output; it does not represent a new test-set experiment or metric report.
- Screenshots are direct GUI captures. They do not prove manual desktop acceptance.
