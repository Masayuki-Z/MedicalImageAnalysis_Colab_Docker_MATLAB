function edgeMap = prewittEdge(inputImage, threshold)
%PREWITTEDGE Detect edges with the Prewitt gradient operator.
gray = toGrayUnitDouble(inputImage);
if nargin < 2
    threshold = [];
end
validateEdgeThreshold(threshold);
edgeMap = edge(gray, "prewitt", threshold);
end
