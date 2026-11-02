function outputImage = highPassFilter(inputImage, amount)
%HIGHPASSFILTER Sharpen using the normalized 3-by-3 high-pass kernel.
if nargin < 2
    amount = 1;
end
if ~isscalar(amount) || ~isfinite(amount) || amount < 0
    error("MedicalImageToolbox:HighPassAmount", ...
        "Amount must be a finite, nonnegative scalar.");
end
validateImage(inputImage);
image = toUnitDouble(inputImage);
kernel = [-1 -1 -1; -1 8 -1; -1 -1 -1] ./ 8;
outputImage = zeros(size(image));
for channel = 1:size(image, 3)
    plane = image(:, :, channel);
    detail = imfilter(plane, kernel, "symmetric", "same", "conv");
    outputImage(:, :, channel) = min(max(plane + amount .* detail, 0), 1);
end
end
