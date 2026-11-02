function validateRadialParameters(inputImage, k1, center)
%VALIDATERADIALPARAMETERS Validate image, distortion coefficient, and center.
validateImage(inputImage);
if ~isscalar(k1) || ~isfinite(k1) || k1 < 0 || k1 > 1
    error("MedicalImageToolbox:RadialCoefficient", ...
        "k1 must be a finite scalar in [0, 1].");
end
if nargin >= 3 && ~isempty(center) && ...
        (~isnumeric(center) || numel(center) ~= 2 || any(~isfinite(center)))
    error("MedicalImageToolbox:RadialCenter", ...
        "Center must be empty or finite [x y] coordinates.");
end
end
