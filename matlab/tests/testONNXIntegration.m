function tests = testONNXIntegration
%TESTONNXINTEGRATION Tests for MATLAB preprocessing and ONNX Runtime inference.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
matlabRoot = fileparts(fileparts(mfilename("fullpath")));
projectRoot = fileparts(matlabRoot);
addpath(genpath(matlabRoot));
testCase.TestData.ProjectRoot = projectRoot;
testCase.TestData.RunDirectory = fullfile(projectRoot, "model_output", ...
    "colab_runs", "20261101_205443");
testCase.TestData.ModelPath = fullfile(testCase.TestData.RunDirectory, ...
    "unet_model.onnx");
testCase.TestData.SampleImage = fullfile(testCase.TestData.RunDirectory, ...
    "MATLAB_Export", "images", ...
    "TCGA_CS_4944_20010208_TCGA_CS_4944_20010208_1.png");
testCase.TestData.SamplePrediction = fullfile(testCase.TestData.RunDirectory, ...
    "MATLAB_Export", "predictions", ...
    "TCGA_CS_4944_20010208_TCGA_CS_4944_20010208_1_prediction.png");
assumeTrue(testCase, isfile(testCase.TestData.ModelPath), ...
    "Audited ONNX artifact is required for integration tests.");
assumeTrue(testCase, isfile(testCase.TestData.SampleImage), ...
    "Fixed unseen-test sample is required for integration tests.");
end

function testPreprocessingMatchesPythonChannelAndZScore(testCase)
[row, column] = ndgrid(uint16(0:255), uint16(0:255));
rgb = zeros(256, 256, 3, "uint8");
rgb(:, :, 1) = uint8(mod(row + 29, 256));
rgb(:, :, 2) = uint8(mod(3 .* row + 5 .* column, 256));
rgb(:, :, 3) = uint8(mod(2 .* column + 117, 256));

[modelImage, metadata] = prepareFlairONNXInput(rgb);
pythonPipeline = py.importlib.import_module("pytorch_pipeline");
flair = single(rgb(:, :, 2)) ./ single(255);
normalized = cell(pythonPipeline.normalize_flair(py.numpy.asarray(flair)));
expected = single(normalized{1});

verifyEqual(testCase, modelImage, expected, "AbsTol", 1e-6);
verifyEqual(testCase, metadata.ChannelIndexZeroBased, 1);
verifyEqual(testCase, metadata.InputShapeNCHW, [1 1 256 256]);
verifyEqual(testCase, metadata.Normalization, ...
    "per-slice population z-score after float32 scale to [0,1]");
end

function testNonModelSizeUsesPythonResizeAndNormalization(testCase)
source = single(reshape(mod(0:95, 97), 8, 12)) ./ single(96);
[modelImage, metadata] = prepareFlairONNXInput(source);
bridge = getGliomaONNXBridge();
expected = cell(bridge.preprocess_flair_plane(py.numpy.asarray(source)));

verifyEqual(testCase, size(modelImage), [256 256]);
verifyEqual(testCase, modelImage, reshape(single(expected{1}), [256 256]), ...
    "AbsTol", 1e-6);
verifyEqual(testCase, metadata.OriginalSize, [8 12]);
end

function testFinalONNXInferencePreservesStateAndAlignment(testCase)
original = imread(testCase.TestData.SampleImage);
state = initializeImageState(original);
[state, probabilityMap, predictionMask, modelMetadata] = ...
    runGliomaONNX(state, testCase.TestData.ModelPath);

verifyEqual(testCase, state.OriginalImage, original);
verifyEqual(testCase, size(state.AISegmentationInput), [256 256]);
verifyEqual(testCase, size(state.AIProbabilityMap), [256 256]);
verifyEqual(testCase, size(probabilityMap), [256 256]);
verifyEqual(testCase, size(predictionMask), size(original, 1:2));
verifyTrue(testCase, all(isfinite(probabilityMap(:))));
verifyGreaterThanOrEqual(testCase, min(probabilityMap(:)), 0);
verifyLessThanOrEqual(testCase, max(probabilityMap(:)), 1);
verifyClass(testCase, predictionMask, "logical");
verifyEqual(testCase, predictionMask, state.AIPredictedMask);
verifyEqual(testCase, string(modelMetadata.input_name), "flair");
verifyEqual(testCase, string(modelMetadata.output_name), "probability");
verifyEqual(testCase, modelMetadata.input_shape_nchw{2}, 1);
verifyEqual(testCase, modelMetadata.output_shape_nchw{2}, 1);
verifyEqual(testCase, numel(state.ProcessingHistory), 3);
verifyEqual(testCase, state.ProcessingHistory(1).InputState, "original");
verifyEqual(testCase, state.ProcessingHistory(2).InputState, "aiinput");
verifyEqual(testCase, state.ProcessingHistory(3).InputState, "aiinput");

pythonPrediction = imread(testCase.TestData.SamplePrediction);
verifyEqual(testCase, predictionMask, pythonPrediction > 0);
end

function testONNXSignatureAndPythonOutputParity(testCase)
bridge = getGliomaONNXBridge();
modelMetadata = jsondecode(char( ...
    bridge.get_model_metadata_json(testCase.TestData.ModelPath)));
source = imread(testCase.TestData.SampleImage);
[modelImage, ~] = prepareFlairONNXInput(source);
pythonOutput = single(bridge.run_onnx_inference( ...
    testCase.TestData.ModelPath, ...
    py.numpy.asarray(reshape(modelImage, [1 1 256 256]))));

verifyEqual(testCase, string(modelMetadata.input_name), "flair");
verifyEqual(testCase, string(modelMetadata.output_name), "probability");
inputShape = modelMetadata.input_shape_nchw;
outputShape = modelMetadata.output_shape_nchw;
verifyEqual(testCase, inputShape{2}, 1);
verifyEqual(testCase, inputShape{3}, 256);
verifyEqual(testCase, inputShape{4}, 256);
verifyEqual(testCase, outputShape{2}, 1);
verifyEqual(testCase, outputShape{3}, 256);
verifyEqual(testCase, outputShape{4}, 256);
verifyEqual(testCase, size(pythonOutput), [1 1 256 256]);

state = initializeImageState(source);
[~, matlabProbability] = runGliomaONNX(state, testCase.TestData.ModelPath);
verifyEqual(testCase, matlabProbability, ...
    reshape(pythonOutput, [256 256]), "AbsTol", 1e-7);
end

function testInvalidInputsAndMissingModelAreReported(testCase)
verifyError(testCase, @() prepareFlairONNXInput(zeros(16, 16, 4, "uint8")), ...
    "MedicalImageToolbox:InvalidImageDimensions");
verifyError(testCase, @() prepareFlairONNXInput(ones(16, 16) .* 2), ...
    "MedicalImageToolbox:FLAIRRange");
verifyError(testCase, @() runGliomaONNX(initializeImageState(zeros(8)), ...
    fullfile(testCase.TestData.ProjectRoot, "missing_model.onnx")), ...
    "MedicalImageToolbox:ONNXModelMissing");
verifyError(testCase, @() restoreGliomaPrediction( ...
    [0 0.2; 0.8 NaN], [8 8], 0.5), ...
    "MedicalImageToolbox:ProbabilityMap");
verifyError(testCase, @() restoreGliomaPrediction(zeros(8), [8 8], 1.1), ...
    "MedicalImageToolbox:ProbabilityThreshold");
end

function testStateStoresProbabilitySeparately(testCase)
original = uint8(zeros(10, 12, 3));
state = initializeImageState(original);
state = recordImageResult(state, "aiProbabilityMap", ...
    single(ones(256) .* 0.25), "runGliomaONNX", struct(), "aiInput");
verifyEqual(testCase, size(state.AIProbabilityMap), [256 256]);
verifyEqual(testCase, state.AIProbabilityMap(1), single(0.25));
verifyEqual(testCase, state.ProcessingHistory(1).InputState, "aiinput");
verifyEmpty(testCase, state.AIPredictedMask);
verifyEqual(testCase, state.OriginalImage, original);
end
