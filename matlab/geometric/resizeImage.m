function outputImage = resizeImage(inputImage, outputSize, method)
%RESIZEIMAGE Resize image to [height width] using center-aligned sampling.
validateImage(inputImage);
validateOutputSize(outputSize);
image = toUnitDouble(inputImage);
height = outputSize(1);
width = outputSize(2);
[xOutput, yOutput] = meshgrid(1:width, 1:height);
xInput = (xOutput - 0.5) .* size(image, 2) ./ width + 0.5;
yInput = (yOutput - 0.5) .* size(image, 1) ./ height + 0.5;
xInput = min(max(xInput, 1), size(image, 2));
yInput = min(max(yInput, 1), size(image, 1));
outputImage = sampleImage(image, xInput, yInput, method);
end
