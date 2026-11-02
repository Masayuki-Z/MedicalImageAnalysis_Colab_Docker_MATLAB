function edgeMap = cannyEdge(inputImage, threshold, sigma)
%CANNYEDGE Detect edges with Canny hysteresis thresholding.
gray = toGrayUnitDouble(inputImage);
if nargin < 2
    threshold = [];
end
if nargin < 3
    sigma = 1;
end
validateEdgeThreshold(threshold);
if ~isscalar(sigma) || ~isfinite(sigma) || sigma <= 0
    error("MedicalImageToolbox:CannySigma", ...
        "Sigma must be a finite positive scalar.");
end
edgeMap = edge(gray, "canny", threshold, sigma);
end
