function outputImage = bicubicResize(inputImage, outputSize)
%BICUBICRESIZE Resize image to [height width] using bicubic sampling.
outputImage = resizeImage(inputImage, outputSize, "bicubic");
end
