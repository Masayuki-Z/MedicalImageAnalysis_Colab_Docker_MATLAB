function outputImage = adjustBrightness(inputImage, offset)
%ADJUSTBRIGHTNESS Add an intensity offset in normalized units [-1, 1].
if nargin < 2 || ~isscalar(offset) || ~isfinite(offset) || ...
        offset < -1 || offset > 1
    error("MedicalImageToolbox:BrightnessOffset", ...
        "Offset must be a finite scalar in [-1, 1].");
end
outputImage = applyLuminanceTransform(inputImage, "brightness", offset);
end
