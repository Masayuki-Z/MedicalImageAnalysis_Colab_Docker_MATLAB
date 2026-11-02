function outputImage = meanFilter(inputImage, windowSize)
%MEANFILTER Apply a square spatial averaging filter to each channel.
if nargin < 2 || ~isscalar(windowSize) || ~isfinite(windowSize) || ...
        windowSize < 1 || windowSize ~= floor(windowSize)
    error("MedicalImageToolbox:FilterSize", ...
        "Window size must be a positive integer.");
end
validateImage(inputImage);
image = toUnitDouble(inputImage);
kernel = ones(windowSize, windowSize) ./ (windowSize ^ 2);
outputImage = zeros(size(image));
for channel = 1:size(image, 3)
    outputImage(:, :, channel) = imfilter( ...
        image(:, :, channel), kernel, "symmetric", "same", "conv");
end
end
