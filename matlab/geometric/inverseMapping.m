function outputImage = inverseMapping(inputImage, transformMatrix, outputSize, method)
%INVERSEMAPPING Resample by mapping output [x;y;1] coordinates to input.
validateTransform(transformMatrix);
if nargin < 3 || isempty(outputSize)
    outputSize = size(inputImage, 1:2);
end
if nargin < 4
    method = "bilinear";
end
validateOutputSize(outputSize);
if ~any(lower(string(method)) == ["nearest", "bilinear", "bicubic"])
    error("MedicalImageToolbox:InterpolationMethod", ...
        "Method must be 'nearest', 'bilinear', or 'bicubic'.");
end
[xOutput, yOutput] = meshgrid(1:outputSize(2), 1:outputSize(1));
coordinates = transformMatrix \ [xOutput(:)'; yOutput(:)'; ones(1, numel(xOutput))];
outputImage = sampleImage(inputImage, ...
    reshape(coordinates(1, :), outputSize), ...
    reshape(coordinates(2, :), outputSize), method);
end
