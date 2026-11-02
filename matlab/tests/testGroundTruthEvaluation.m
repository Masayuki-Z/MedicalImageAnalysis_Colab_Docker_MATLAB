function tests = testGroundTruthEvaluation
%TESTGROUNDTRUTHEVALUATION Tests for ground-truth alignment and pixel metrics.
tests = functiontests(localfunctions);
end

function testBinaryConversionAndNearestNeighborAlignment(testCase)
grayMask = uint8([0 0 255 255; 0 255 255 0]);
[mask, wasResized] = prepareGroundTruthMask(grayMask, [4 8]);
verifyTrue(testCase, wasResized);
verifyClass(testCase, mask, "logical");
verifyEqual(testCase, size(mask), [4 8]);
verifyEqual(testCase, unique(mask), [false; true]);
verifyEqual(testCase, mask(1:2:end, 1:2:end), grayMask > 0);
end

function testFloatingMaskUsesOtsuAndRejectsUnsupportedInput(testCase)
grayMask = [0 0 0.1 0.2; 0 0.8 0.9 1];
[mask, wasResized] = prepareGroundTruthMask(grayMask, size(grayMask));
verifyFalse(testCase, wasResized);
verifyClass(testCase, mask, "logical");
verifyTrue(testCase, all(mask(grayMask >= 0.8)));
verifyError(testCase, @() prepareGroundTruthMask(zeros(4, 4, 3), [4 4]), ...
    "MedicalImageToolbox:GroundTruthDimensions");
verifyError(testCase, @() prepareGroundTruthMask(ones(4) .* 2, [4 4]), ...
    "MedicalImageToolbox:GroundTruthRange");
verifyError(testCase, @() prepareGroundTruthMask( ...
    [0 NaN; 1 0], [2 2]), "MedicalImageToolbox:GroundTruthValues");
end

function testOverlapCountsAndMetrics(testCase)
groundTruth = logical([1 1; 0 0]);
prediction = logical([1 0; 1 0]);
metrics = evaluateSegmentationMasks(groundTruth, prediction);
verifyEqual(testCase, metrics.TruePositive, 1);
verifyEqual(testCase, metrics.FalsePositive, 1);
verifyEqual(testCase, metrics.FalseNegative, 1);
verifyEqual(testCase, metrics.Dice, 0.5);
verifyEqual(testCase, metrics.IoU, 1 / 3);
verifyEqual(testCase, metrics.Precision, 0.5);
verifyEqual(testCase, metrics.Recall, 0.5);
overlap = createSegmentationOverlap(groundTruth, prediction);
verifyEqual(testCase, reshape(overlap(1, 1, :), 1, 3), [0 1 0]);
verifyEqual(testCase, reshape(overlap(2, 1, :), 1, 3), [1 0 0]);
verifyEqual(testCase, reshape(overlap(1, 2, :), 1, 3), [0 0 1]);
verifyEqual(testCase, reshape(overlap(2, 2, :), 1, 3), [0 0 0]);
end

function testEmptyMaskAndZeroDenominatorConventions(testCase)
emptyMask = false(3, 5);
bothEmpty = evaluateSegmentationMasks(emptyMask, emptyMask);
verifyEqual(testCase, bothEmpty.Dice, 1);
verifyEqual(testCase, bothEmpty.IoU, 1);
verifyEqual(testCase, bothEmpty.Precision, 1);
verifyEqual(testCase, bothEmpty.Recall, 1);

missed = evaluateSegmentationMasks(logical([1 0]), false(1, 2));
verifyEqual(testCase, missed.Dice, 0);
verifyEqual(testCase, missed.IoU, 0);
verifyEqual(testCase, missed.Precision, 1);
verifyEqual(testCase, missed.Recall, 0);

spurious = evaluateSegmentationMasks(false(1, 2), logical([0 1]));
verifyEqual(testCase, spurious.Dice, 0);
verifyEqual(testCase, spurious.IoU, 0);
verifyEqual(testCase, spurious.Precision, 0);
verifyEqual(testCase, spurious.Recall, 1);
end

function testMaskDimensionsAndBinaryValidation(testCase)
verifyError(testCase, @() evaluateSegmentationMasks(false(2), false(3)), ...
    "MedicalImageToolbox:MaskSpatialDimensions");
verifyError(testCase, @() evaluateSegmentationMasks( ...
    [0 1; 2 0], false(2)), "MedicalImageToolbox:BinaryMask");
end

function testGroundTruthHasIndependentImageState(testCase)
state = initializeImageState(zeros(8, 10, "uint8"));
[groundTruth, wasResized] = prepareGroundTruthMask( ...
    uint8([0 255; 255 0]), [8 10]);
state.GroundTruthMask = groundTruth;
state.ClassicalSegmentationMask = false(8, 10);
state.AIPredictedMask = true(8, 10);
state.AIProbabilityMap = single(ones(256) .* 0.25);
verifyTrue(testCase, wasResized);
verifyEqual(testCase, state.GroundTruthMask, groundTruth);
verifyFalse(testCase, state.ClassicalSegmentationMask(1));
verifyTrue(testCase, state.AIPredictedMask(1));
verifyEqual(testCase, state.AIProbabilityMap(1), single(0.25));
end
