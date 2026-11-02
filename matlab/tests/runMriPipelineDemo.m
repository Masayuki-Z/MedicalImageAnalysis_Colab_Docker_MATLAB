function result = runMriPipelineDemo(imagePath, outputDirectory)
%RUNMRIPIPELINEDEMO Run the classical workflow on a dataset MRI slice.
if nargin < 1 || isempty(imagePath)
    projectRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
    datasetRoot = fullfile(projectRoot, "data", "lgg-mri-segmentation", ...
        "kaggle_3m");
    candidates = dir(fullfile(datasetRoot, "**", "*.tif"));
    candidates = candidates(~contains({candidates.name}, "_mask"));
    if isempty(candidates)
        error("MedicalImageToolbox:DemoImageMissing", ...
            "No MRI TIFF found. Pass an explicit imagePath.");
    end
    imagePath = fullfile(candidates(1).folder, candidates(1).name);
end
if ~isfile(imagePath)
    error("MedicalImageToolbox:DemoImageMissing", ...
        "MRI file does not exist: %s.", imagePath);
end
original = imread(imagePath);
validateImage(original);
if ndims(original) ~= 3 || size(original, 3) ~= 3
    error("MedicalImageToolbox:DemoImageChannels", ...
        "The demo requires an RGB FLAIR-containing image.");
end

% The local LGG dataset README documents RGB order as pre-contrast, FLAIR, post-contrast.
flair = toUnitDouble(original(:, :, 2));
state = initializeImageState(original);
enhanced = histogramEqualization(flair);
state = recordImageResult(state, "enhanced", enhanced, ...
    "histogram equalization of documented FLAIR channel", struct("channel", 2));
[selected, state] = selectImageState(state, "enhanced");
[classicalMask, threshold] = otsuSegmentation(selected);
state = recordImageResult(state, "classicalMask", classicalMask, ...
    "Otsu threshold", struct("threshold", threshold));
refinedMask = morphologicalClosing(classicalMask, "disk", 1);
[refinedMask, components] = shapeBasedSegmentation(refinedMask, 8, inf, 0);
state = recordImageResult(state, "classicalMask", refinedMask, ...
    "morphological closing and shape filtering", ...
    struct("shape", "disk", "radius", 1, "minimumArea", 8));

result = struct("ImagePath", string(imagePath), "OriginalImage", original, ...
    "FlairImage", flair, "EnhancedImage", enhanced, ...
    "OtsuMask", classicalMask, "RefinedMask", refinedMask, ...
    "OtsuThreshold", threshold, "Components", components, "State", state);
if nargin >= 2 && ~isempty(outputDirectory)
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end
    imwrite(im2uint8(enhanced), fullfile(outputDirectory, "enhanced_flair.png"));
    imwrite(uint8(classicalMask) .* 255, ...
        fullfile(outputDirectory, "otsu_mask.png"));
    imwrite(uint8(refinedMask) .* 255, ...
        fullfile(outputDirectory, "refined_mask.png"));
end
end
