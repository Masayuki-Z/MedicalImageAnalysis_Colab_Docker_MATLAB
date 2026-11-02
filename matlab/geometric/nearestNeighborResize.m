function outputImage = nearestNeighborResize(inputImage, outputSize)
%NEARESTNEIGHBORRESIZE Resize image to [height width] using nearest sampling.
outputImage = resizeImage(inputImage, outputSize, "nearest");
end
