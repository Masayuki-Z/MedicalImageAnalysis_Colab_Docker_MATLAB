function validateEdgeThreshold(threshold)
%VALIDATEEDGETHRESHOLD Validate an optional normalized edge threshold.
if isempty(threshold)
    return;
end
if ~isnumeric(threshold) || ~(isscalar(threshold) || numel(threshold) == 2) || ...
        any(~isfinite(threshold(:))) || any(threshold(:) < 0 | threshold(:) > 1)
    error("MedicalImageToolbox:EdgeThreshold", ...
        "Threshold must be empty or a scalar/two-element vector in [0, 1].");
end
if numel(threshold) == 2 && threshold(1) > threshold(2)
    error("MedicalImageToolbox:EdgeThresholdOrder", ...
        "Two-element threshold must be ordered [low high].");
end
end
