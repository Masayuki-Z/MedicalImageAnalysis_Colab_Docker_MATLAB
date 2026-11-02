function distortedImage = simulateRadialDistortion(inputImage, k1, center, method)
%SIMULATERADIALDISTORTION Simulate positive radial barrel/pincushion coefficient.
if nargin < 3
    center = [];
end
if nargin < 4
    method = "bilinear";
end
if ~any(lower(string(method)) == ["nearest", "bilinear", "bicubic"])
    error("MedicalImageToolbox:InterpolationMethod", ...
        "Method must be 'nearest', 'bilinear', or 'bicubic'.");
end
validateRadialParameters(inputImage, k1, center);
image = toUnitDouble(inputImage);
[height, width] = size(image, 1:2);
if isempty(center)
    center = [(width + 1) / 2, (height + 1) / 2];
end
scale = max(height, width) / 2;
[xDistorted, yDistorted] = meshgrid(1:width, 1:height);
xd = (xDistorted - center(1)) ./ scale;
yd = (yDistorted - center(2)) ./ scale;
rd = hypot(xd, yd);
ru = rd;
for iteration = 1:12
    denominator = 1 + 3 * k1 .* ru .^ 2;
    ru = max(0, ru - (ru .* (1 + k1 .* ru .^ 2) - rd) ./ denominator);
end
factor = ones(size(rd));
nonzero = rd > 0;
factor(nonzero) = ru(nonzero) ./ rd(nonzero);
xSource = center(1) + (xDistorted - center(1)) .* factor;
ySource = center(2) + (yDistorted - center(2)) .* factor;
distortedImage = sampleImage(image, xSource, ySource, method);
end
