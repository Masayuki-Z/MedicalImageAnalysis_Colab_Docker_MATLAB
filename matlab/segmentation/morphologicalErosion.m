function outputMask = morphologicalErosion(inputMask, shape, radius)
%MORPHOLOGICALEROSION Erode a binary mask with a selectable structuring element.
outputMask = applyMorphology(inputMask, "erode", shape, radius);
end
