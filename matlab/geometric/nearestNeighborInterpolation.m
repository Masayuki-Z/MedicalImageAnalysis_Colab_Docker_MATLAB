function outputImage = nearestNeighborInterpolation(inputImage, xCoordinates, yCoordinates)
%NEARESTNEIGHBORINTERPOLATION Sample image at coordinates using nearest neighbor.
outputImage = sampleImage(inputImage, xCoordinates, yCoordinates, "nearest");
end
