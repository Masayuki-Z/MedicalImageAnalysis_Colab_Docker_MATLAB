function outputImage = forwardMapping(inputImage, transformMatrix, outputSize, fillValue)
%FORWARDMAPPING Scatter input pixels through a source-to-output 3-by-3 matrix.
validateImage(inputImage);
validateTransform(transformMatrix);
if nargin < 3 || isempty(outputSize)
    outputSize = size(inputImage, 1:2);
end
validateOutputSize(outputSize);
if nargin < 4
    fillValue = 0;
end
if ~isscalar(fillValue) || ~isfinite(fillValue) || fillValue < 0 || fillValue > 1
    error("MedicalImageToolbox:FillValue", ...
        "Fill value must be a finite scalar in [0, 1].");
end
image = toUnitDouble(inputImage);
[xInput, yInput] = meshgrid(1:size(image, 2), 1:size(image, 1));
mapped = transformMatrix * [xInput(:)'; yInput(:)'; ones(1, numel(xInput))];
x = round(mapped(1, :) ./ mapped(3, :));
y = round(mapped(2, :) ./ mapped(3, :));
valid = x >= 1 & x <= outputSize(2) & y >= 1 & y <= outputSize(1);
outputImage = repmat(fillValue, [outputSize size(image, 3)]);
for channel = 1:size(image, 3)
    plane = outputImage(:, :, channel);
    sourcePlane = image(:, :, channel);
    plane(sub2ind(outputSize, y(valid), x(valid))) = sourcePlane(valid);
    outputImage(:, :, channel) = plane;
end
if ismatrix(image)
    outputImage = outputImage(:, :, 1);
end
end
