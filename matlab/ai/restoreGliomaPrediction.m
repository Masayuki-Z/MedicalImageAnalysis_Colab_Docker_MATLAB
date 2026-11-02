function [probabilityMap, predictionMask] = restoreGliomaPrediction(probabilities, originalSize, threshold)
%RESTOREGLIOMAPREDICTION Threshold and align a model probability map.
if nargin < 3 || isempty(threshold)
    threshold = 0.5;
end
if ~isnumeric(probabilities) || ~ismatrix(probabilities) || isempty(probabilities) || ...
        ~isreal(probabilities) || any(~isfinite(probabilities(:))) || ...
        any(probabilities(:) < 0 | probabilities(:) > 1)
    error("MedicalImageToolbox:ProbabilityMap", ...
        "Probabilities must be a finite two-dimensional array in [0, 1].");
end
validateOutputSize(originalSize);
if ~isnumeric(threshold) || ~isscalar(threshold) || ~isfinite(threshold) || ...
        threshold < 0 || threshold > 1
    error("MedicalImageToolbox:ProbabilityThreshold", ...
        "Probability threshold must be a finite scalar in [0, 1].");
end
probabilityMap = single(probabilities);
predictionMask = probabilityMap >= threshold;
if ~isequal(size(predictionMask), reshape(originalSize, 1, 2))
    predictionMask = nearestNeighborResize(predictionMask, originalSize);
end
predictionMask = logical(predictionMask);
end