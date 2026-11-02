function outputImage = applyLuminanceTransform(inputImage, operation, parameters)
%APPLYLUMINANCETRANSFORM Apply an intensity mapping without changing RGB chroma.
validateImage(inputImage);
image = toUnitDouble(inputImage);
if ismatrix(image)
    outputImage = mapIntensity(image, operation, parameters);
    return;
end

ycbcr = rgb2ycbcr(image);
ycbcr(:, :, 1) = mapIntensity(ycbcr(:, :, 1), operation, parameters);
outputImage = min(max(ycbcr2rgb(ycbcr), 0), 1);
end

function output = mapIntensity(input, operation, parameters)
switch operation
    case "equalize"
        output = histeq(input);
    case "brightness"
        output = min(max(input + parameters(1), 0), 1);
    case "contrast"
        output = min(max((input - 0.5) .* parameters(1) + 0.5, 0), 1);
    otherwise
        error("MedicalImageToolbox:UnknownIntensityOperation", ...
            "Unsupported luminance operation: %s.", operation);
end
end
