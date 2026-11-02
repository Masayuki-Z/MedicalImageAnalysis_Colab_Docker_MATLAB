function outputImage = histogramEqualization(inputImage)
%HISTOGRAMEQUALIZATION Equalize grayscale intensity or RGB luminance.
outputImage = applyLuminanceTransform(inputImage, "equalize", []);
end
