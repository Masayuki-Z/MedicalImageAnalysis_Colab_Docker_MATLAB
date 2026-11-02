function outputMask = morphologicalOpening(inputMask, shape, radius)
%MORPHOLOGICALOPENING Open a binary mask with a selectable structuring element.
outputMask = applyMorphology(inputMask, "open", shape, radius);
end
