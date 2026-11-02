function outputImage = sampleImage(inputImage, xCoordinates, yCoordinates, method)
%SAMPLEIMAGE Sample an image at x/column and y/row coordinates.
validateImage(inputImage);
if size(inputImage, 1) < 2 || size(inputImage, 2) < 2
    error("MedicalImageToolbox:SampleImageSize", ...
        "Interpolation requires at least two rows and two columns.");
end
if ~isnumeric(xCoordinates) || ~isnumeric(yCoordinates) || ...
        ~isequal(size(xCoordinates), size(yCoordinates)) || ...
        any(~isfinite(xCoordinates(:))) || any(~isfinite(yCoordinates(:)))
    error("MedicalImageToolbox:SampleCoordinates", ...
        "X and Y coordinate arrays must be finite numeric arrays of equal size.");
end
switch lower(string(method))
    case "nearest"
        interpolation = "nearest";
    case "bilinear"
        interpolation = "linear";
    case "bicubic"
        interpolation = "cubic";
    otherwise
        error("MedicalImageToolbox:InterpolationMethod", ...
            "Method must be 'nearest', 'bilinear', or 'bicubic'.");
end
image = toUnitDouble(inputImage);
outputImage = zeros([size(xCoordinates) size(image, 3)]);
for channel = 1:size(image, 3)
    outputImage(:, :, channel) = interp2( ...
        image(:, :, channel), xCoordinates, yCoordinates, interpolation, 0);
end
outputImage = min(max(outputImage, 0), 1);
if ismatrix(image)
    outputImage = outputImage(:, :, 1);
end
end
