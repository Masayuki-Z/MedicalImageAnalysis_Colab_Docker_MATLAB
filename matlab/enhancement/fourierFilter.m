function [outputImage, spectrum] = fourierFilter(inputImage, mode, cutoffLow, cutoffHigh)
%FOURIERFILTER Apply an ideal radial Fourier filter; cutoff units are cycles/pixel.
validateImage(inputImage);
if nargin < 4
    cutoffHigh = [];
end
if ~isscalar(cutoffLow) || ~isfinite(cutoffLow) || ...
        cutoffLow < 0 || cutoffLow > sqrt(0.5)
    error("MedicalImageToolbox:FourierCutoff", ...
        "Cutoff must be in [0, sqrt(0.5)] cycles/pixel.");
end
mode = lower(string(mode));
if mode == "band"
    if isempty(cutoffHigh) || ~isscalar(cutoffHigh) || ...
            ~isfinite(cutoffHigh) || cutoffHigh <= cutoffLow || ...
            cutoffHigh > sqrt(0.5)
        error("MedicalImageToolbox:FourierBandCutoffs", ...
            "Band-pass cutoffs must satisfy 0 <= low < high <= sqrt(0.5).");
    end
elseif ~any(mode == ["low", "high"])
    error("MedicalImageToolbox:FourierMode", ...
        "Mode must be 'low', 'high', or 'band'.");
end

image = toUnitDouble(inputImage);
[height, width, channels] = size(image);
fy = ifftshift((-floor(height / 2):ceil(height / 2) - 1) ./ height);
fx = ifftshift((-floor(width / 2):ceil(width / 2) - 1) ./ width);
[fxGrid, fyGrid] = meshgrid(fx, fy);
radius = hypot(fxGrid, fyGrid);
switch mode
    case "low"
        pass = radius <= cutoffLow;
    case "high"
        pass = radius >= cutoffLow;
    case "band"
        pass = radius >= cutoffLow & radius <= cutoffHigh;
end

outputImage = zeros(size(image));
for channel = 1:channels
    plane = image(:, :, channel);
    transformed = fft2(plane);
    outputImage(:, :, channel) = min(max(real(ifft2(transformed .* pass)), 0), 1);
end
gray = image;
if channels == 3
    gray = rgb2gray(image);
end
spectrum = log1p(abs(fftshift(fft2(gray))));
end
