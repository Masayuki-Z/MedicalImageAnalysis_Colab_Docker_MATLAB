function outputImage = histogramMatching(sourceImage, referenceImage)
%HISTOGRAMMATCHING Match source grayscale/luminance histogram to a reference.
validateImage(sourceImage);
validateImage(referenceImage);
source = toUnitDouble(sourceImage);
reference = toUnitDouble(referenceImage);

if ismatrix(source) && ismatrix(reference)
    outputImage = imhistmatch(source, reference);
    return;
end
if ismatrix(source)
    error("MedicalImageToolbox:HistogramMatchingChannels", ...
        "Source and reference must both be grayscale or both be RGB.");
end
if ismatrix(reference)
    error("MedicalImageToolbox:HistogramMatchingChannels", ...
        "Source and reference must both be grayscale or both be RGB.");
end

sourceYCbCr = rgb2ycbcr(source);
referenceYCbCr = rgb2ycbcr(reference);
sourceYCbCr(:, :, 1) = imhistmatch( ...
    sourceYCbCr(:, :, 1), referenceYCbCr(:, :, 1));
outputImage = min(max(ycbcr2rgb(sourceYCbCr), 0), 1);
end
