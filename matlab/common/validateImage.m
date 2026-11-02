function validateImage(image, allowRGB)
%VALIDATEIMAGE Validate a grayscale or RGB image accepted by this toolbox.
if nargin < 2
    allowRGB = true;
end
if ~(isnumeric(image) || islogical(image)) || isempty(image)
    error("MedicalImageToolbox:InvalidImage", ...
        "Image must be a nonempty numeric or logical array.");
end
if ~isreal(image)
    error("MedicalImageToolbox:InvalidImage", ...
        "Complex-valued images are not supported.");
end
if ~(ismatrix(image) || (allowRGB && ndims(image) == 3 && size(image, 3) == 3))
    error("MedicalImageToolbox:InvalidImageDimensions", ...
        "Image must be grayscale or an RGB array with three channels.");
end
if isfloat(image) && any(~isfinite(image(:)))
    error("MedicalImageToolbox:NonfiniteImage", ...
        "Floating-point image values must be finite.");
end
end
