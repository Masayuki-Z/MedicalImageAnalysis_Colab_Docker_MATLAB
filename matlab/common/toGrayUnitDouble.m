function grayImage = toGrayUnitDouble(inputImage)
%TOGRAYUNITDOUBLE Convert a grayscale/RGB image to normalized grayscale.
validateImage(inputImage);
image = toUnitDouble(inputImage);
if ndims(image) == 3
    grayImage = rgb2gray(image);
else
    grayImage = image;
end
end
