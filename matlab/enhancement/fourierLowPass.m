function [outputImage, spectrum] = fourierLowPass(inputImage, cutoff)
%FOURIERLOWPASS Ideal circular Fourier low-pass filter.
[outputImage, spectrum] = fourierFilter(inputImage, "low", cutoff, []);
end
