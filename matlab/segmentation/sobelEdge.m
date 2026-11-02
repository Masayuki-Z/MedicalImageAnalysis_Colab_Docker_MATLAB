function edgeMap = sobelEdge(inputImage, threshold)
%SOBELEDGE Detect edges with the Sobel gradient operator.
gray = toGrayUnitDouble(inputImage);
if nargin < 2
    threshold = [];
end
validateEdgeThreshold(threshold);
edgeMap = edge(gray, "sobel", threshold);
end
