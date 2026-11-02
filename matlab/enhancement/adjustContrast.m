function outputImage = adjustContrast(inputImage, factor)
%ADJUSTCONTRAST Scale luminance around 0.5 using a nonnegative factor.
if nargin < 2 || ~isscalar(factor) || ~isfinite(factor) || factor < 0
    error("MedicalImageToolbox:ContrastFactor", ...
        "Contrast factor must be a finite, nonnegative scalar.");
end
outputImage = applyLuminanceTransform(inputImage, "contrast", factor);
end
