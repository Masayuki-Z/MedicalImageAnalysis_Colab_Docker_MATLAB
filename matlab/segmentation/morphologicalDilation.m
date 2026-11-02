function outputMask = morphologicalDilation(inputMask, shape, radius)
%MORPHOLOGICALDILATION Dilate a binary mask with a selectable structuring element.
outputMask = applyMorphology(inputMask, "dilate", shape, radius);
end
