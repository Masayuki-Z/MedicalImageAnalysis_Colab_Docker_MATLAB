function mask = rgbSegmentation(inputImage, lowerBounds, upperBounds)
%RGBSEGMENTATION Select RGB pixels within inclusive per-channel [0,1] ranges.
validateImage(inputImage);
if ndims(inputImage) ~= 3
    error("MedicalImageToolbox:RGBInput", "RGB segmentation requires an RGB image.");
end
validateColorBounds(lowerBounds, upperBounds, "RGB");
image = toUnitDouble(inputImage);
mask = all(image >= reshape(lowerBounds, 1, 1, 3) & ...
    image <= reshape(upperBounds, 1, 1, 3), 3);
end
