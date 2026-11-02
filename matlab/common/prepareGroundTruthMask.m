function [binaryMask, wasResized] = prepareGroundTruthMask(maskImage, targetSize)
%PREPAREGROUNDTRUTHMASK Validate, binarize, and align a reference mask.
if ~(isnumeric(maskImage) || islogical(maskImage)) || isempty(maskImage) || ...
        ~ismatrix(maskImage) || ~isreal(maskImage)
    error("MedicalImageToolbox:GroundTruthDimensions", ...
        "Ground-truth mask must be a nonempty two-dimensional real image.");
end
if isnumeric(maskImage) && any(~isfinite(maskImage(:)))
    error("MedicalImageToolbox:GroundTruthValues", ...
        "Ground-truth mask values must be finite.");
end
if isnumeric(maskImage) && any(maskImage(:) < 0)
    error("MedicalImageToolbox:GroundTruthValues", ...
        "Ground-truth mask values must be nonnegative.");
end
if isfloat(maskImage) && any(maskImage(:) > 1)
    error("MedicalImageToolbox:GroundTruthRange", ...
        "Floating-point ground-truth masks must have values in [0, 1].");
end
validateOutputSize(targetSize);

if islogical(maskImage)
    binaryMask = maskImage;
else
    gray = im2double(maskImage);
    distinctValues = unique(gray(:));
    if numel(distinctValues) <= 2
        if isscalar(distinctValues)
            binaryMask = gray ~= 0;
        else
            binaryMask = gray > distinctValues(1);
        end
    else
        threshold = graythresh(gray);
        binaryMask = gray > threshold;
    end
end

wasResized = ~isequal(size(binaryMask), reshape(targetSize, 1, 2));
if wasResized
    binaryMask = nearestNeighborResize(binaryMask, targetSize);
end
binaryMask = logical(binaryMask);
end
