function [outputImage, spectrum] = fourierBandPass(inputImage, cutoffs)
%FOURIERBANDPASS Ideal circular Fourier band-pass filter [low high].
if ~isnumeric(cutoffs) || numel(cutoffs) ~= 2
    error("MedicalImageToolbox:BandPassCutoffs", ...
        "Cutoffs must be a two-element [low high] vector.");
end
[outputImage, spectrum] = fourierFilter( ...
    inputImage, "band", cutoffs(1), cutoffs(2));
end
