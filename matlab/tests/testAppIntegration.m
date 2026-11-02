function tests = testAppIntegration
%TESTAPPINTEGRATION Exercise the integrated MATLAB GUI workflows.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
matlabRoot = fileparts(fileparts(mfilename("fullpath")));
projectRoot = fileparts(matlabRoot);
addpath(genpath(matlabRoot));
testCase.TestData.ProjectRoot = projectRoot;
testCase.TestData.ModelPath = fullfile(projectRoot, "model_output", ...
    "colab_runs", "20261101_205443", "unet_model.onnx");
testCase.TestData.SampleImage = fullfile(projectRoot, "model_output", ...
    "colab_runs", "20261101_205443", "MATLAB_Export", "images", ...
    "TCGA_CS_4944_20010208_TCGA_CS_4944_20010208_1.png");
end

function setup(testCase)
app = MedicalImageAnalysisApp();
app.UIFigure.Visible = "off";
testCase.TestData.App = app;
testCase.addTeardown(@() delete(app));
end

function testClassicalGeometryAndSaveWorkflow(testCase)
app = testCase.TestData.App;
image = makeTestImage();
app.loadImageData(image, "synthetic MRI");
original = app.State.OriginalImage;

selectOperation(app, "Image Enhancement", "Brightness");
app.Parameter1Field.Value = 0.1;
app.applySelectedOperation();
verifyNotEmpty(testCase, app.State.EnhancedImage);
verifyEqual(testCase, app.State.OriginalImage, original);
verifyNotEmpty(testCase, app.OriginalAxes.Children);
verifyNotEmpty(testCase, app.OriginalHistogramAxes.Children);

selectOperation(app, "Segmentation and Edges", "Otsu threshold");
app.InputStateDropDown.Value = "enhanced";
app.applySelectedOperation();
verifyClass(testCase, app.State.ClassicalSegmentationMask, "logical");
verifyEqual(testCase, size(app.State.ClassicalSegmentationMask), size(original, 1:2));

selectOperation(app, "Geometric Transformations", "Scaling");
app.Parameter1Field.Value = 0.5;
app.applySelectedOperation();
verifyEqual(testCase, size(app.State.TransformedImage, 1:2), [32 32]);
verifyEqual(testCase, size(app.State.ClassicalSegmentationMask), [32 32]);
verifyEqual(testCase, app.State.ProcessingHistory(end).Parameters.maskInterpolation, ...
    "nearest");
verifyEqual(testCase, app.State.OriginalImage, original);

selectOperation(app, "Geometric Transformations", "Radial distortion");
app.InputStateDropDown.Value = "transformed";
app.Parameter1Field.Value = 0.1;
app.applySelectedOperation();
verifyEqual(testCase, size(app.State.ClassicalSegmentationMask), [32 32]);
verifyClass(testCase, app.State.ClassicalSegmentationMask, "logical");

selectOperation(app, "Segmentation and Edges", "Dilation");
app.Parameter1Field.Value = 1;
app.applySelectedOperation();
verifyEqual(testCase, size(app.State.ClassicalSegmentationMask), [32 32]);
verifyNotEmpty(testCase, app.ClassicalMaskAxes.Children);

outputPath = string(tempname) + ".png";
cleanup = onCleanup(@() deleteIfPresent(outputPath));
app.saveCurrentResult(outputPath);
verifyTrue(testCase, isfile(outputPath));
app.resetImage();
verifyEqual(testCase, app.State.OriginalImage, original);
verifyEmpty(testCase, app.State.EnhancedImage);
verifyEmpty(testCase, app.State.TransformedImage);
verifyEmpty(testCase, app.State.ClassicalSegmentationMask);
clear cleanup
end

function testAIWorkflowUsesOriginalAndDisplaysOverlay(testCase)
app = testCase.TestData.App;
assumeTrue(testCase, isfile(testCase.TestData.ModelPath), ...
    "Audited ONNX model is required for GUI AI integration.");
assumeTrue(testCase, isfile(testCase.TestData.SampleImage), ...
    "Fixed unseen-test MRI is required for GUI AI integration.");
image = imread(testCase.TestData.SampleImage);
app.loadImageData(image, "fixed unseen-test MRI");
original = app.State.OriginalImage;
groundTruth = false(size(original, 1:2));
groundTruth(40:70, 50:90) = true;
app.setGroundTruthMask(groundTruth, "synthetic truth");
verifyEmpty(testCase, app.State.AIPredictedMask);
verifyEmpty(testCase, app.State.AIProbabilityMap);
selectOperation(app, "Image Enhancement", "Brightness");
app.Parameter1Field.Value = 0.1;
app.applySelectedOperation();
app.setModelPath(testCase.TestData.ModelPath);

[probabilityMap, predictionMask] = app.runAISegmentation();
unconditionedState = initializeImageState(original);
[~, expectedProbability, expectedPrediction] = ...
    runGliomaONNX(unconditionedState, testCase.TestData.ModelPath);
verifyEqual(testCase, app.State.OriginalImage, original);
verifyEqual(testCase, size(app.State.AISegmentationInput), [256 256]);
verifyEqual(testCase, size(probabilityMap), [256 256]);
verifyEqual(testCase, probabilityMap, expectedProbability, "AbsTol", 1e-7);
verifyEqual(testCase, predictionMask, expectedPrediction);
verifyEqual(testCase, size(predictionMask), size(original, 1:2));
verifyTrue(testCase, all(isfinite(probabilityMap(:))));
verifyGreaterThanOrEqual(testCase, min(probabilityMap(:)), 0);
verifyLessThanOrEqual(testCase, max(probabilityMap(:)), 1);
verifyNotEmpty(testCase, app.AIOverlayAxes.Children);
verifyNotEmpty(testCase, app.AIPredictionAxes.Children);
verifyNotEmpty(testCase, app.AIProbabilityAxes.Children);
verifyNotEmpty(testCase, app.GroundTruthAxes.Children);
verifyNotEmpty(testCase, app.OverlapAxes.Children);
verifyTrue(testCase, any(contains(app.EvaluationMetricsArea.Value, "Dice:")));
verifyTrue(testCase, any(contains(app.EvaluationSummaryArea.Value, "Dice:")));
verifyEqual(testCase, app.State.ProcessingHistory(end).InputState, "aiinput");
end

function testGroundTruthLoadResizePreservationAndMRIReplacement(testCase)
app = testCase.TestData.App;
image = makeTestImage();
app.loadImageData(image, "synthetic MRI");
app.State.ClassicalSegmentationMask = false(64, 64);
app.State.AIPredictedMask = true(64, 64);
app.State.AIProbabilityMap = single(ones(256) .* 0.4);
sourceMask = uint8([0 0 255; 0 255 255]);
wasResized = app.setGroundTruthMask(sourceMask, "small mask");
verifyTrue(testCase, wasResized);
verifyEqual(testCase, size(app.State.GroundTruthMask), [64 64]);
verifyClass(testCase, app.State.GroundTruthMask, "logical");
verifyFalse(testCase, app.State.ClassicalSegmentationMask(1));
verifyTrue(testCase, app.State.AIPredictedMask(1));
verifyEqual(testCase, app.State.AIProbabilityMap(1), single(0.4));
verifyError(testCase, @() app.setGroundTruthMask(zeros(8, 8, 3), "RGB"), ...
    "MedicalImageToolbox:GroundTruthDimensions");

app.resetImage();
verifyEqual(testCase, app.State.GroundTruthMask, ...
    prepareGroundTruthMask(sourceMask, [64 64]));
app.loadImageData(makeTestImage(), "replacement MRI");
verifyEmpty(testCase, app.State.GroundTruthMask);
verifyTrue(testCase, any(contains(app.StatusArea.Value, "cleared")));
end

function testImageStatesAndMaskSourceRemainIndependent(testCase)
app = testCase.TestData.App;
app.loadImageData(makeTestImage(), "synthetic MRI");
selectOperation(app, "Image Enhancement", "Histogram equalization");
app.applySelectedOperation();
enhanced = app.State.EnhancedImage;

app.InputStateDropDown.Value = "enhanced";
selectOperation(app, "Image Enhancement", "Median filter");
app.Parameter1Field.Value = 3;
expectedMedian = medianFilter(enhanced, 3);
app.applySelectedOperation();
verifyEqual(testCase, app.State.EnhancedImage, expectedMedian);
verifyEqual(testCase, app.State.ProcessingHistory(end).InputState, "enhanced");
verifyEqual(testCase, string(app.InputStateDropDown.Value), "enhanced");

selectOperation(app, "Geometric Transformations", "Scaling");
app.InputStateDropDown.Value = "enhanced";
app.Parameter1Field.Value = 0.5;
app.applySelectedOperation();
transformed = app.State.TransformedImage;
app.InputStateDropDown.Value = "transformed";
selectOperation(app, "Image Enhancement", "Brightness");
app.Parameter1Field.Value = 0.1;
app.applySelectedOperation();
verifyEqual(testCase, app.State.EnhancedImage, adjustBrightness(transformed, 0.1));
verifyEqual(testCase, app.State.ProcessingHistory(end).InputState, "transformed");

groundTruth = false(64, 64);
groundTruth(20:40, 20:40) = true;
app.setGroundTruthMask(groundTruth);
app.State.AIPredictedMask = false(64, 64);
app.State.AIProbabilityMap = single(zeros(256));
app.InputStateDropDown.Value = "transformed";
app.MaskSourceDropDown.Value = "Ground truth mask";
selectOperation(app, "Segmentation and Edges", "Opening");
app.Parameter1Field.Value = 1;
app.applySelectedOperation();
verifyEqual(testCase, string(app.InputStateDropDown.Value), "transformed");
verifyEqual(testCase, app.State.ProcessingHistory(end).InputState, "groundtruthmask");
verifyEqual(testCase, app.State.GroundTruthMask, groundTruth);
verifyFalse(testCase, app.State.AIPredictedMask(1));
verifyEqual(testCase, string(app.StatusArea.Value(1)), ...
    "Applied: Opening / mask source: Ground truth mask / image state remains: transformed");
end

function testDynamicParameterMetadataAndValidation(testCase)
app = testCase.TestData.App;
selectOperation(app, "Image Enhancement", "Median filter");
verifyEqual(testCase, string(app.Parameter1Label.Text), "Kernel size");
verifyEqual(testCase, string(app.Parameter1Field.Visible), "on");
verifyEqual(testCase, app.Parameter1Field.Value, 3);
verifyEqual(testCase, string(app.Parameter1Field.Tooltip), ...
    "Positive integer width of the square filter neighborhood.");
verifyEqual(testCase, string(app.Parameter2Field.Visible), "off");

selectOperation(app, "Geometric Transformations", "Rotation");
verifyEqual(testCase, string(app.Parameter1Label.Text), "Rotation angle (degrees)");
verifyEqual(testCase, string(app.Parameter1Field.Visible), "on");
verifyEqual(testCase, string(app.InterpolationDropDown.Visible), "on");
verifyEqual(testCase, string(app.AffineMatrixField.Visible), "off");

selectOperation(app, "Geometric Transformations", "Translation");
verifyEqual(testCase, string(app.Parameter1Label.Text), "X offset (pixels)");
verifyEqual(testCase, string(app.Parameter2Label.Text), "Y offset (pixels)");
verifyEqual(testCase, app.Parameter1Field.Value, 0);
verifyEqual(testCase, app.Parameter2Field.Value, 0);

selectOperation(app, "Segmentation and Edges", "Otsu threshold");
verifyEqual(testCase, string(app.Parameter1Field.Visible), "off");
verifyTrue(testCase, any(contains(app.ParameterDescriptionArea.Value, ...
    "calculated automatically")));

selectOperation(app, "Segmentation and Edges", "Canny edges");
verifyEqual(testCase, string(app.Parameter2Label.Text), "Gaussian sigma");
verifyEqual(testCase, string(app.Parameter2Field.Visible), "on");
verifyEqual(testCase, string(app.Parameter1Field.Visible), "off");

selectOperation(app, "Segmentation and Edges", "Region growing");
verifyEqual(testCase, string(app.SeedRowField.Visible), "on");
verifyEqual(testCase, string(app.SeedColumnField.Visible), "on");

selectOperation(app, "Segmentation and Edges", "RGB segmentation");
verifyEqual(testCase, string(app.LowerBoundsField.Visible), "on");
verifyEqual(testCase, string(app.UpperBoundsField.Visible), "on");

selectOperation(app, "Segmentation and Edges", "Opening");
verifyEqual(testCase, string(app.MaskSourceDropDown.Visible), "on");
verifyEqual(testCase, string(app.StructuringElementDropDown.Visible), "on");
verifyEqual(testCase, string(app.Parameter1Label.Text), "Structuring element size");
app.loadImageData(makeTestImage(), "synthetic MRI");
app.setGroundTruthMask(false(64, 64));
app.MaskSourceDropDown.Value = "Ground truth mask";
app.Parameter1Field.Value = 1.5;
verifyError(testCase, @() invalidMorphologyParameter(app), ...
    "MedicalImageToolbox:PositiveIntegerParameter");
end

function testMissingImageAndModelErrors(testCase)
app = testCase.TestData.App;
verifyError(testCase, @() app.applySelectedOperation(), ...
    "MedicalImageToolbox:NoImageLoaded");
verifyError(testCase, @() app.runAISegmentation(), ...
    "MedicalImageToolbox:NoImageLoaded");

app.loadImageData(makeTestImage(), "synthetic MRI");
verifyError(testCase, @() app.runAISegmentation(), ...
    "MedicalImageToolbox:ONNXModelMissing");
verifyError(testCase, @() app.setModelPath( ...
    fullfile(testCase.TestData.ProjectRoot, "missing_model.onnx")), ...
    "MedicalImageToolbox:ONNXModelMissing");
end

function testIndependentWorkflowSectionsAndSectionReset(testCase)
app = testCase.TestData.App;
expectedSections = ["Image Workspace", "Image Enhancement", ...
    "Image Segmentation", "Geometric Transformation", ...
    "AI Segmentation", "Evaluation"];
verifyEqual(testCase, string(app.SectionNavigation.Items), expectedSections);
verifyNotEqual(testCase, app.EnhancementOperationDropDown, ...
    app.SegmentationOperationDropDown);
verifyNotEqual(testCase, app.SegmentationOperationDropDown, ...
    app.TransformationOperationDropDown);
verifyEqual(testCase, string(app.EnhancementOperationDropDown.Items(1)), ...
    "Histogram equalization");
verifyEqual(testCase, string(app.SegmentationOperationDropDown.Items(1)), ...
    "Sobel edges");
verifyEqual(testCase, string(app.TransformationOperationDropDown.Items(1)), ...
    "Translation");

app.SectionNavigation.Value = "Image Enhancement";
app.SectionNavigation.ValueChangedFcn(app.SectionNavigation, ...
    struct("Value", "Image Enhancement"));
verifyEqual(testCase, app.ActiveSection, "Image Enhancement");

app.loadImageData(makeTestImage(), "synthetic MRI");
app.EnhancementOperationDropDown.Value = "Histogram equalization";
app.EnhancementOperationDropDown.ValueChangedFcn( ...
    app.EnhancementOperationDropDown, []);
app.EnhancementApplyButton.ButtonPushedFcn( ...
    app.EnhancementApplyButton, []);
verifyNotEmpty(testCase, app.State.EnhancedImage);

app.SegmentationOperationDropDown.Value = "Otsu threshold";
app.SegmentationOperationDropDown.ValueChangedFcn( ...
    app.SegmentationOperationDropDown, []);
app.SegmentationApplyButton.ButtonPushedFcn( ...
    app.SegmentationApplyButton, []);
verifyClass(testCase, app.State.ClassicalSegmentationMask, "logical");

app.TransformationOperationDropDown.Value = "Scaling";
app.TransformationOperationDropDown.ValueChangedFcn( ...
    app.TransformationOperationDropDown, []);
app.TransformationApplyButton.ButtonPushedFcn( ...
    app.TransformationApplyButton, []);
verifyNotEmpty(testCase, app.State.TransformedImage);

app.EnhancementResetButton.ButtonPushedFcn(app.EnhancementResetButton, []);
verifyEmpty(testCase, app.State.EnhancedImage);
verifyNotEmpty(testCase, app.State.ClassicalSegmentationMask);
verifyNotEmpty(testCase, app.State.TransformedImage);
end

function selectOperation(app, module, operation)
app.ModuleDropDown.Value = module;
callback = app.ModuleDropDown.ValueChangedFcn;
callback(app.ModuleDropDown, []);
app.OperationDropDown.Value = operation;
callback = app.OperationDropDown.ValueChangedFcn;
callback(app.OperationDropDown, []);
end

function invalidMorphologyParameter(app)
app.applySelectedOperation();
end

function image = makeTestImage
[rows, columns] = ndgrid(uint8(0:63), uint8(0:63));
image = cat(3, rows, columns, uint8(mod(double(rows) + double(columns), 256)));
end

function deleteIfPresent(path)
if isfile(path)
    delete(path);
end
end
