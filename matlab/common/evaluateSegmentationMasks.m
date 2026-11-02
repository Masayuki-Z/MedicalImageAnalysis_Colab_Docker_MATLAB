function metrics = evaluateSegmentationMasks(groundTruthMask, predictionMask)
%EVALUATESEGMENTATIONMASKS Calculate pixel-level overlap metrics for binary masks.
validateBinaryMask(groundTruthMask, "ground-truth");
validateBinaryMask(predictionMask, "prediction");
if ~isequal(size(groundTruthMask), size(predictionMask))
    error("MedicalImageToolbox:MaskSpatialDimensions", ...
        "Ground-truth and prediction masks must have identical dimensions.");
end

groundTruthMask = logical(groundTruthMask);
predictionMask = logical(predictionMask);
truePositive = nnz(groundTruthMask & predictionMask);
falsePositive = nnz(~groundTruthMask & predictionMask);
falseNegative = nnz(groundTruthMask & ~predictionMask);
predictedPositive = truePositive + falsePositive;
actualPositive = truePositive + falseNegative;
unionCount = truePositive + falsePositive + falseNegative;

if unionCount == 0
    dice = 1;
    intersectionOverUnion = 1;
else
    dice = 2 * truePositive / (2 * truePositive + falsePositive + falseNegative);
    intersectionOverUnion = truePositive / unionCount;
end
if predictedPositive == 0
    precision = 1;
else
    precision = truePositive / predictedPositive;
end
if actualPositive == 0
    recall = 1;
else
    recall = truePositive / actualPositive;
end

metrics = struct( ...
    "Dice", dice, ...
    "IoU", intersectionOverUnion, ...
    "Precision", precision, ...
    "Recall", recall, ...
    "TruePositive", truePositive, ...
    "FalsePositive", falsePositive, ...
    "FalseNegative", falseNegative);
end

function validateBinaryMask(mask, description)
if ~ismatrix(mask) || isempty(mask) || ...
        (~islogical(mask) && (~isnumeric(mask) || ~isreal(mask) || ...
        any(~isfinite(mask(:))) || any(mask(:) ~= 0 & mask(:) ~= 1)))
    error("MedicalImageToolbox:BinaryMask", ...
        "%s mask must be a nonempty two-dimensional binary array.", description);
end
end
