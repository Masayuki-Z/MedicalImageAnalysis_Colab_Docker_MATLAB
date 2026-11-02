function outputImage = scaleImage(inputImage, scaleFactor, method)
%SCALEIMAGE Resize an image with nearest, bilinear, or bicubic interpolation.
validateImage(inputImage);
if ~isscalar(scaleFactor) || ~isfinite(scaleFactor) || scaleFactor <= 0
    error("MedicalImageToolbox:ScaleFactor", ...
        "Scale factor must be a finite positive scalar.");
end
if nargin < 3
    method = "bilinear";
end
if ~any(lower(string(method)) == ["nearest", "bilinear", "bicubic"])
    error("MedicalImageToolbox:InterpolationMethod", ...
        "Method must be 'nearest', 'bilinear', or 'bicubic'.");
end
image = toUnitDouble(inputImage);
outputSize = max(1, round(size(image, 1:2) .* scaleFactor));
[xOutput, yOutput] = meshgrid(1:outputSize(2), 1:outputSize(1));
xInput = (xOutput - 0.5) ./ scaleFactor + 0.5;
yInput = (yOutput - 0.5) ./ scaleFactor + 0.5;
xInput = min(max(xInput, 1), size(image, 2));
yInput = min(max(yInput, 1), size(image, 1));
outputImage = sampleImage(image, xInput, yInput, method);
end
