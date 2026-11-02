function [mask, threshold] = otsuSegmentation(inputImage)
%OTSUSEGMENTATION Segment bright foreground using Otsu's global threshold.
gray = toGrayUnitDouble(inputImage);
threshold = graythresh(gray);
mask = imbinarize(gray, threshold);
end
