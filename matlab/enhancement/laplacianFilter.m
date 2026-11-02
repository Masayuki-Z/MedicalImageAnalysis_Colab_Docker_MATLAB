function outputImage = laplacianFilter(inputImage, amount)
%LAPLACIANFILTER Sharpen using I - amount * Laplacian(I).
if nargin < 2
    amount = 1;
end
if ~isscalar(amount) || ~isfinite(amount) || amount < 0
    error("MedicalImageToolbox:LaplacianAmount", ...
        "Amount must be a finite, nonnegative scalar.");
end
validateImage(inputImage);
image = toUnitDouble(inputImage);
kernel = [0 1 0; 1 -4 1; 0 1 0];
outputImage = zeros(size(image));
for channel = 1:size(image, 3)
    plane = image(:, :, channel);
    laplacian = imfilter(plane, kernel, "symmetric", "same", "conv");
    outputImage(:, :, channel) = min(max(plane - amount .* laplacian, 0), 1);
end
end
