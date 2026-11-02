function tests = testImageModules
%TESTIMAGEMODULES Unit tests for the reusable MATLAB processing functions.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
matlabRoot = fileparts(fileparts(mfilename("fullpath")));
testCase.TestData.MatlabRoot = matlabRoot;
addpath(genpath(matlabRoot));
end

function testHistogramAndIntensityOperations(testCase)
image = repmat(linspace(0.2, 0.6, 32), 32, 1);
equalized = histogramEqualization(image);
matched = histogramMatching(image, flipud(image));
bright = adjustBrightness(image, 0.1);
contrast = adjustContrast(image, 1.5);
gamma = grayLevelTransform(image, "gamma", 2);
negative = grayLevelTransform(image, "negative");
verifyEqual(testCase, size(equalized), size(image));
verifyEqual(testCase, size(matched), size(image));
verifyEqual(testCase, bright, min(image + 0.1, 1), "AbsTol", 1e-12);
verifyEqual(testCase, contrast, min(max((image - 0.5) .* 1.5 + 0.5, 0), 1), ...
    "AbsTol", 1e-12);
verifyEqual(testCase, gamma, image .^ 2, "AbsTol", 1e-12);
verifyEqual(testCase, negative, 1 - image, "AbsTol", 1e-12);
verifyGreaterThan(testCase, std(equalized(:)), 0);
end

function testRgbLuminanceOperations(testCase)
image = zeros(24, 24, 3);
image(:, :, 1) = repmat(linspace(0.1, 0.7, 24), 24, 1);
image(:, :, 2) = 0.25;
image(:, :, 3) = 0.15;
equalized = histogramEqualization(image);
matched = histogramMatching(image, flip(image, 2));
bright = adjustBrightness(image, 0.05);
verifyEqual(testCase, size(equalized), size(image));
verifyEqual(testCase, size(matched), size(image));
verifyEqual(testCase, size(bright), size(image));
verifyGreaterThanOrEqual(testCase, min(equalized(:)), 0);
verifyLessThanOrEqual(testCase, max(equalized(:)), 1);
end

function testSpatialFiltersAndSharpening(testCase)
image = zeros(31, 31);
image(16, 16) = 1;
meanResult = meanFilter(image, 3);
medianResult = medianFilter(image, 3);
edgeImage = zeros(size(image));
edgeImage(:, 17:end) = 0.6;
laplacian = laplacianFilter(edgeImage, 0.5);
highPass = highPassFilter(edgeImage, 0.5);
verifyEqual(testCase, size(meanResult), size(image));
verifyEqual(testCase, meanResult(16, 16), 1 / 9, "AbsTol", 1e-12);
verifyEqual(testCase, medianResult, zeros(size(image)));
verifyEqual(testCase, size(laplacian), size(image));
verifyEqual(testCase, size(highPass), size(image));
verifyGreaterThan(testCase, norm(laplacian - edgeImage, "fro"), 0);
verifyGreaterThan(testCase, norm(highPass - edgeImage, "fro"), 0);
end

function testFourierFilters(testCase)
[x, ~] = meshgrid(1:64, 1:64);
image = 0.5 + 0.4 .* cos(pi .* x);
[low, spectrum] = fourierLowPass(image, 0.08);
[high, ~] = fourierHighPass(image, 0.08);
[band, ~] = fourierBandPass(image, [0.05 0.15]);
verifyEqual(testCase, size(low), size(image));
verifyEqual(testCase, size(spectrum), size(image));
verifyTrue(testCase, all(isfinite(spectrum(:))));
verifyLessThan(testCase, std(low(:)), std(image(:)));
verifyGreaterThan(testCase, std(high(:)), 0);
verifyEqual(testCase, size(band), size(image));
end

function testEdgeDetectorsAndOtsu(testCase)
image = zeros(64);
image(17:48, 17:48) = 1;
sobel = sobelEdge(image);
prewitt = prewittEdge(image);
canny = cannyEdge(image);
[mask, threshold] = otsuSegmentation(image);
verifyClass(testCase, sobel, "logical");
verifyClass(testCase, prewitt, "logical");
verifyClass(testCase, canny, "logical");
verifyEqual(testCase, size(sobel), size(image));
verifyGreaterThan(testCase, nnz(sobel), 0);
verifyGreaterThan(testCase, nnz(prewitt), 0);
verifyGreaterThan(testCase, nnz(canny), 0);
verifyClass(testCase, mask, "logical");
verifyTrue(testCase, isfinite(threshold));
verifyTrue(testCase, mask(32, 32));
verifyFalse(testCase, mask(1, 1));
end

function testRegionGrowing(testCase)
image = zeros(24);
image(6:18, 7:17) = 0.7;
mask = regionGrowing(image, [10 10], 0.01, 4);
verifyEqual(testCase, nnz(mask), 13 * 11);
verifyTrue(testCase, mask(10, 10));
verifyFalse(testCase, mask(1, 1));
verifyError(testCase, @() regionGrowing(image, [0 1], 0.1), ...
    "MedicalImageToolbox:RegionSeedBounds");
end

function testRgbAndHsvSegmentation(testCase)
image = zeros(20, 20, 3);
image(5:12, 6:14, 1) = 1;
rgbMask = rgbSegmentation(image, [0.9 0 0], [1 0.1 0.1]);
hsvMask = hsvSegmentation(image, [0.95 0.5 0.5], [0.05 1 1]);
verifyEqual(testCase, nnz(rgbMask), 8 * 9);
verifyEqual(testCase, nnz(hsvMask), 8 * 9);
verifyError(testCase, @() rgbSegmentation(image, [0 0 0], [1 1]), ...
    "MedicalImageToolbox:ColorBounds");
end

function testMorphologyAndShapeFiltering(testCase)
mask = false(40);
mask(10:20, 10:20) = true;
mask(2, 2) = true;
dilated = morphologicalDilation(mask, "square", 1);
eroded = morphologicalErosion(mask, "disk", 1);
opened = morphologicalOpening(mask, "disk", 1);
closed = morphologicalClosing(mask, "disk", 1);
[filtered, components] = shapeBasedSegmentation(mask, 5, 200, 0);
verifyGreaterThan(testCase, nnz(dilated), nnz(mask));
verifyLessThan(testCase, nnz(eroded), nnz(mask));
verifyTrue(testCase, any(opened(:)));
verifyTrue(testCase, any(closed(:)));
verifyEqual(testCase, nnz(filtered), 121);
verifyEqual(testCase, numel(components), 2);
verifyError(testCase, @() morphologicalDilation(mask, "triangle", 1), ...
    "MedicalImageToolbox:StructuringElementShape");
end

function testInterpolationFunctions(testCase)
image = reshape(1:100, 10, 10) ./ 100;
[x, y] = meshgrid(2:2:8, 2:2:8);
nearest = nearestNeighborInterpolation(image, x, y);
linear = bilinearInterpolation(image, x + 0.25, y + 0.25);
cubic = bicubicInterpolation(image, x + 0.25, y + 0.25);
verifyEqual(testCase, size(nearest), size(x));
expected = reshape(image(sub2ind(size(image), y(:), x(:))), size(x));
verifyEqual(testCase, nearest, expected, "AbsTol", 1e-12);
verifyEqual(testCase, size(linear), size(x));
verifyEqual(testCase, size(cubic), size(x));
verifyTrue(testCase, all(isfinite(cubic(:))));
end

function testGeometricMappings(testCase)
image = zeros(32);
image(10:15, 11:16) = 1;
translated = translateImage(image, 3, 2, "nearest");
scaled = scaleImage(image, 1.5, "nearest");
rotated = rotateImage(image, 0, "nearest");
matrix = [1 0 0; 0 1 0; 0 0 1];
affine = affineTransform(image, matrix, "nearest");
forward = forwardMapping(image, [1 0 2; 0 1 1; 0 0 1], size(image));
inverse = inverseMapping(image, [1 0 0; 0 1 0; 0 0 1], size(image), "nearest");
verifyTrue(testCase, all(translated(12:17, 14:19), "all"));
verifyEqual(testCase, size(scaled), [48 48]);
verifyEqual(testCase, rotated, image);
verifyEqual(testCase, affine, image);
verifyEqual(testCase, inverse, image);
verifyTrue(testCase, all(forward(11:16, 13:18), "all"));
end

function testResizeInterpolationPreservesBinaryMask(testCase)
mask = false(16);
mask(4:12, 5:11) = true;
nearest = nearestNeighborResize(mask, [32 24]);
linear = bilinearResize(mask, [32 24]);
cubic = bicubicResize(mask, [32 24]);
verifyEqual(testCase, size(nearest), [32 24]);
verifyTrue(testCase, all(nearest(:) == 0 | nearest(:) == 1));
verifyEqual(testCase, size(linear), [32 24]);
verifyEqual(testCase, size(cubic), [32 24]);
end

function testResizeExtendsBoundaryPixels(testCase)
image = ones(12, 12);
resized = bilinearResize(image, [24 24]);
scaled = scaleImage(image, 2, "bilinear");
verifyEqual(testCase, resized, ones(24, 24), "AbsTol", 1e-12);
verifyEqual(testCase, scaled, ones(24, 24), "AbsTol", 1e-12);
end

function testRadialDistortionRoundTrip(testCase)
[x, y] = meshgrid(1:64, 1:64);
image = exp(-((x - 32) .^ 2 + (y - 32) .^ 2) ./ 300);
distorted = simulateRadialDistortion(image, 0.15);
corrected = radialDistortionCorrection(distorted, 0.15);
verifyEqual(testCase, size(distorted), size(image));
verifyEqual(testCase, size(corrected), size(image));
verifyLessThan(testCase, mean(abs(corrected(12:52, 12:52) - image(12:52, 12:52)), "all"), 0.04);
end

function testImageStateKeepsOriginalAndTracksPipeline(testCase)
original = reshape(linspace(0, 1, 64 * 64), 64, 64);
state = initializeImageState(original);
enhanced = adjustBrightness(original, 0.1);
state = recordImageResult(state, "enhanced", enhanced, "brightness", struct("offset", 0.1));
[selected, state] = selectImageState(state, "enhanced");
mask = otsuSegmentation(selected);
state = recordImageResult(state, "classicalMask", mask, "otsu");
verifyEqual(testCase, state.OriginalImage, original);
verifyEqual(testCase, state.CurrentInput, enhanced);
verifyEqual(testCase, state.ClassicalSegmentationMask, mask);
verifyEqual(testCase, numel(state.ProcessingHistory), 2);
verifyEqual(testCase, state.CurrentInputName, "enhanced");
end

function testInvalidParameters(testCase)
image = ones(10);
verifyError(testCase, @() adjustBrightness(image, 2), ...
    "MedicalImageToolbox:BrightnessOffset");
verifyError(testCase, @() meanFilter(image, 0), ...
    "MedicalImageToolbox:FilterSize");
verifyError(testCase, @() fourierLowPass(image, 1), ...
    "MedicalImageToolbox:FourierCutoff");
verifyError(testCase, @() translateImage(image, NaN, 0), ...
    "MedicalImageToolbox:Translation");
end
