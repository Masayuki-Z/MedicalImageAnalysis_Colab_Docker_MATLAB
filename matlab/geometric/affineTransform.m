function outputImage = affineTransform(inputImage, transformMatrix, method, outputSize)
%AFFINETRANSFORM Apply an affine source-to-output matrix using inverse sampling.
if nargin < 3
    method = "bilinear";
end
if nargin < 4
    outputSize = size(inputImage, 1:2);
end
outputImage = inverseMapping(inputImage, transformMatrix, outputSize, method);
end
