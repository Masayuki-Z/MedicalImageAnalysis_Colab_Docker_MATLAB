function overlap = createSegmentationOverlap(groundTruthMask, predictionMask)
%CREATESEGMENTATIONOVERLAP Color TP green, FP red, and FN blue.
evaluateSegmentationMasks(groundTruthMask, predictionMask);
groundTruthMask = logical(groundTruthMask);
predictionMask = logical(predictionMask);
truePositive = groundTruthMask & predictionMask;
falsePositive = ~groundTruthMask & predictionMask;
falseNegative = groundTruthMask & ~predictionMask;
overlap = zeros([size(groundTruthMask) 3]);
overlap(:, :, 1) = falsePositive;
overlap(:, :, 2) = truePositive;
overlap(:, :, 3) = falseNegative;
end
