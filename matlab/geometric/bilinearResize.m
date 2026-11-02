function outputImage = bilinearResize(inputImage, outputSize)
%BILINEARRESIZE Resize image to [height width] using bilinear sampling.
outputImage = resizeImage(inputImage, outputSize, "bilinear");
end
