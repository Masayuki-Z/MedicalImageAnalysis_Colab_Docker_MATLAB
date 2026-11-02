function outputImage = medianFilter(inputImage, windowSize)
%MEDIANFILTER Apply a square median filter independently to each channel.
if nargin < 2 || ~isscalar(windowSize) || ~isfinite(windowSize) || ...
        windowSize < 1 || windowSize ~= floor(windowSize)
    error("MedicalImageToolbox:FilterSize", ...
        "Window size must be a positive integer.");
end
validateImage(inputImage);
image = toUnitDouble(inputImage);
outputImage = zeros(size(image));
for channel = 1:size(image, 3)
    outputImage(:, :, channel) = medfilt2( ...
        image(:, :, channel), [windowSize windowSize], "symmetric");
end
end
