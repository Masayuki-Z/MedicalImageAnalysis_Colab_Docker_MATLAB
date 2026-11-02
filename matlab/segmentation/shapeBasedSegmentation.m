function [outputMask, components] = shapeBasedSegmentation(inputMask, minArea, maxArea, minCircularity)
%SHAPEBASEDSEGMENTATION Keep connected components filtered by area/circularity.
if ~islogical(inputMask) && (~isnumeric(inputMask) || ...
        any(~isfinite(inputMask(:))) || any(inputMask(:) ~= 0 & inputMask(:) ~= 1))
    error("MedicalImageToolbox:BinaryMask", ...
        "Input mask must contain only logical or binary values.");
end
if isempty(inputMask) || ~ismatrix(inputMask)
    error("MedicalImageToolbox:BinaryMaskDimensions", ...
        "Input mask must be a nonempty two-dimensional array.");
end
if nargin < 2 || isempty(minArea)
    minArea = 1;
end
if nargin < 3 || isempty(maxArea)
    maxArea = inf;
end
if nargin < 4 || isempty(minCircularity)
    minCircularity = 0;
end
if ~isscalar(minArea) || ~isfinite(minArea) || minArea < 0 || ...
        ~isscalar(maxArea) || isnan(maxArea) || maxArea < minArea
    error("MedicalImageToolbox:ShapeAreaRange", ...
        "Area bounds must satisfy 0 <= minArea <= maxArea.");
end
if ~isscalar(minCircularity) || ~isfinite(minCircularity) || ...
        minCircularity < 0 || minCircularity > 1
    error("MedicalImageToolbox:ShapeCircularity", ...
        "Minimum circularity must be in [0, 1].");
end

components = regionprops(logical(inputMask), "Area", "Perimeter", ...
    "Eccentricity", "Solidity", "PixelIdxList");
outputMask = false(size(inputMask));
for k = 1:numel(components)
    perimeter = components(k).Perimeter;
    if perimeter == 0
        circularity = 0;
    else
        circularity = min(1, 4 * pi * components(k).Area / perimeter ^ 2);
    end
    components(k).Circularity = circularity;
    keep = components(k).Area >= minArea && components(k).Area <= maxArea && ...
        circularity >= minCircularity;
    if keep
        outputMask(components(k).PixelIdxList) = true;
    end
end
end
