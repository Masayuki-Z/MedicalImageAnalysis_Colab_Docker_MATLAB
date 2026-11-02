function correctedImage = radialDistortionCorrection(distortedImage, k1, center, method)
%RADIALDISTORTIONCORRECTION Undo a simulated radial distortion by inverse mapping.
if nargin < 3
    center = [];
end
if nargin < 4
    method = "bilinear";
end
validateRadialParameters(distortedImage, k1, center);
image = toUnitDouble(distortedImage);
[height, width] = size(image, 1:2);
if isempty(center)
    center = [(width + 1) / 2, (height + 1) / 2];
end
scale = max(height, width) / 2;
[xOutput, yOutput] = meshgrid(1:width, 1:height);
x = (xOutput - center(1)) ./ scale;
y = (yOutput - center(2)) ./ scale;
factor = 1 + k1 .* (x .^ 2 + y .^ 2);
xSource = center(1) + (xOutput - center(1)) .* factor;
ySource = center(2) + (yOutput - center(2)) .* factor;
correctedImage = sampleImage(image, xSource, ySource, method);
end
