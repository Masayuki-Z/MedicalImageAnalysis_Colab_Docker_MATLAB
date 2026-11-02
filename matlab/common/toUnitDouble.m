function image = toUnitDouble(inputImage)
%TOUNITDOUBLE Convert integer/logical images to double and validate float range.
validateImage(inputImage);
image = im2double(inputImage);
if any(image(:) < 0 | image(:) > 1)
    error("MedicalImageToolbox:ImageRange", ...
        "Floating-point image data must be in the range [0, 1].");
end
end
