function [outputImage, spectrum] = fourierHighPass(inputImage, cutoff)
%FOURIERHIGHPASS Ideal circular Fourier high-pass filter.
[outputImage, spectrum] = fourierFilter(inputImage, "high", cutoff, []);
end
