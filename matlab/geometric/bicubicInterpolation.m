function outputImage = bicubicInterpolation(inputImage, xCoordinates, yCoordinates)
%BICUBICINTERPOLATION Sample image at coordinates using bicubic interpolation.
outputImage = sampleImage(inputImage, xCoordinates, yCoordinates, "bicubic");
end
