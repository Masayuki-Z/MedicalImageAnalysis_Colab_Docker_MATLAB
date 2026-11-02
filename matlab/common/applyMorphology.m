function outputMask = applyMorphology(inputMask, operation, shape, radius)
%APPLYMORPHOLOGY Validate and run one binary morphological operation.
if ~islogical(inputMask) && (~isnumeric(inputMask) || ...
        any(~isfinite(inputMask(:))) || any(inputMask(:) ~= 0 & inputMask(:) ~= 1))
    error("MedicalImageToolbox:BinaryMask", ...
        "Input mask must contain only logical or binary values.");
end
if isempty(inputMask) || ~ismatrix(inputMask)
    error("MedicalImageToolbox:BinaryMaskDimensions", ...
        "Input mask must be a nonempty two-dimensional array.");
end
if nargin < 3 || isempty(shape)
    shape = "disk";
end
if nargin < 4 || isempty(radius)
    radius = 1;
end
if ~isscalar(radius) || ~isfinite(radius) || radius < 1 || radius ~= floor(radius)
    error("MedicalImageToolbox:StructuringElementRadius", ...
        "Structuring element radius must be a positive integer.");
end
switch lower(string(shape))
    case "disk"
        element = strel("disk", radius, 0);
    case "square"
        element = strel("square", 2 * radius + 1);
    case "diamond"
        element = strel("diamond", radius);
    otherwise
        error("MedicalImageToolbox:StructuringElementShape", ...
            "Shape must be 'disk', 'square', or 'diamond'.");
end
mask = logical(inputMask);
switch lower(string(operation))
    case "dilate"
        outputMask = imdilate(mask, element);
    case "erode"
        outputMask = imerode(mask, element);
    case "open"
        outputMask = imopen(mask, element);
    case "close"
        outputMask = imclose(mask, element);
    otherwise
        error("MedicalImageToolbox:MorphologyOperation", ...
            "Unsupported morphology operation.");
end
end
