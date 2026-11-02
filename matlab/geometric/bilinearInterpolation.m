function outputImage = bilinearInterpolation(inputImage, xCoordinates, yCoordinates)
%BILINEARINTERPOLATION Sample image at coordinates using bilinear interpolation.
outputImage = sampleImage(inputImage, xCoordinates, yCoordinates, "bilinear");
end
