function outputImage = translateImage(inputImage, dx, dy, method)
%TRANSLATEIMAGE Translate by dx columns and dy rows; positive values move right/down.
if nargin < 4
    method = "bilinear";
end
if ~isscalar(dx) || ~isfinite(dx) || ~isscalar(dy) || ~isfinite(dy)
    error("MedicalImageToolbox:Translation", ...
        "dx and dy must be finite scalars.");
end
matrix = [1 0 dx; 0 1 dy; 0 0 1];
outputImage = inverseMapping(inputImage, matrix, size(inputImage, 1:2), method);
end
