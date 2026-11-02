function mask = hsvSegmentation(inputImage, lowerBounds, upperBounds)
%HSVSEGMENTATION Select RGB pixels by HSV ranges; hue may wrap across 1 to 0.
validateImage(inputImage);
if ndims(inputImage) ~= 3
    error("MedicalImageToolbox:HSVInput", "HSV segmentation requires an RGB image.");
end
validateColorBounds(lowerBounds, upperBounds, "HSV", true);
hsvImage = rgb2hsv(toUnitDouble(inputImage));
h = hsvImage(:, :, 1);
s = hsvImage(:, :, 2);
v = hsvImage(:, :, 3);
if lowerBounds(1) <= upperBounds(1)
    hueMatch = h >= lowerBounds(1) & h <= upperBounds(1);
else
    hueMatch = h >= lowerBounds(1) | h <= upperBounds(1);
end
mask = hueMatch & s >= lowerBounds(2) & s <= upperBounds(2) & ...
    v >= lowerBounds(3) & v <= upperBounds(3);
end
