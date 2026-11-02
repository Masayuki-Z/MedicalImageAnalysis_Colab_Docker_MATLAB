function outputImage = grayLevelTransform(inputImage, method, parameter)
%GRAYLEVELTRANSFORM Apply negative, logarithmic, or gamma gray-level mapping.
validateImage(inputImage);
image = toUnitDouble(inputImage);
if nargin < 2 || ~(ischar(method) || isstring(method))
    error("MedicalImageToolbox:GrayLevelMethod", ...
        "Method must be 'negative', 'log', or 'gamma'.");
end
method = lower(string(method));
if nargin < 3
    parameter = 1;
end
if ~isscalar(parameter) || ~isfinite(parameter) || parameter <= 0
    error("MedicalImageToolbox:GrayLevelParameter", ...
        "Parameter must be a finite positive scalar.");
end

switch method
    case "negative"
        outputImage = 1 - image;
    case "log"
        outputImage = log1p((exp(1) - 1) .* image);
    case "gamma"
        outputImage = image .^ parameter;
    otherwise
        error("MedicalImageToolbox:GrayLevelMethod", ...
            "Method must be 'negative', 'log', or 'gamma'.");
end
end
