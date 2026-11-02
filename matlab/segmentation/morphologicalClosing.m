function outputMask = morphologicalClosing(inputMask, shape, radius)
%MORPHOLOGICALCLOSING Close a binary mask with a selectable structuring element.
outputMask = applyMorphology(inputMask, "close", shape, radius);
end
