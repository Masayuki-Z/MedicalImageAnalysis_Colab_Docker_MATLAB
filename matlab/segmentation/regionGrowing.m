function mask = regionGrowing(inputImage, seedPoint, tolerance, connectivity)
%REGIONGROWING Grow a connected region within tolerance of the seed intensity.
gray = toGrayUnitDouble(inputImage);
if nargin < 3
    tolerance = 0.1;
end
if nargin < 4
    connectivity = 8;
end
if ~isnumeric(seedPoint) || numel(seedPoint) ~= 2 || ...
        any(~isfinite(seedPoint)) || any(seedPoint ~= floor(seedPoint))
    error("MedicalImageToolbox:RegionSeed", ...
        "Seed point must be integer [row column].");
end
if seedPoint(1) < 1 || seedPoint(1) > size(gray, 1) || ...
        seedPoint(2) < 1 || seedPoint(2) > size(gray, 2)
    error("MedicalImageToolbox:RegionSeedBounds", ...
        "Seed point lies outside the image.");
end
if ~isscalar(tolerance) || ~isfinite(tolerance) || tolerance < 0 || tolerance > 1
    error("MedicalImageToolbox:RegionTolerance", ...
        "Tolerance must be a finite scalar in [0, 1].");
end
if ~isscalar(connectivity) || ~any(connectivity == [4 8])
    error("MedicalImageToolbox:RegionConnectivity", ...
        "Connectivity must be 4 or 8.");
end

height = size(gray, 1);
width = size(gray, 2);
seedIndex = sub2ind([height width], seedPoint(1), seedPoint(2));
seedValue = gray(seedIndex);
mask = false(height, width);
mask(seedIndex) = true;
queue = zeros(numel(gray), 1);
queue(1) = seedIndex;
head = 1;
tail = 1;
if connectivity == 4
    offsets = [-1 0; 1 0; 0 -1; 0 1];
else
    [dr, dc] = ndgrid(-1:1, -1:1);
    offsets = [dr(:) dc(:)];
    offsets(all(offsets == 0, 2), :) = [];
end

while head <= tail
    current = queue(head);
    head = head + 1;
    [row, column] = ind2sub([height width], current);
    for k = 1:size(offsets, 1)
        nextRow = row + offsets(k, 1);
        nextColumn = column + offsets(k, 2);
        if nextRow < 1 || nextRow > height || nextColumn < 1 || nextColumn > width
            continue;
        end
        next = sub2ind([height width], nextRow, nextColumn);
        if ~mask(next) && abs(gray(next) - seedValue) <= tolerance
            tail = tail + 1;
            queue(tail) = next;
            mask(next) = true;
        end
    end
end
end
