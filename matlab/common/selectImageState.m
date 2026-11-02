function [image, state] = selectImageState(state, stateName)
%SELECTIMAGESTATE Select a populated source for the next compatible operation.
validateState(state);
stateName = lower(string(stateName));
switch stateName
    case "original"
        image = state.OriginalImage;
    case "enhanced"
        image = state.EnhancedImage;
    case "transformed"
        image = state.TransformedImage;
    otherwise
        error("MedicalImageToolbox:ImageStateName", ...
            "Selectable image states are original, enhanced, and transformed.");
end
if isempty(image)
    error("MedicalImageToolbox:EmptyImageState", ...
        "The selected image state has not been produced yet.");
end
state.CurrentInputName = stateName;
state.CurrentInput = image;
end

function validateState(state)
required = ["OriginalImage", "EnhancedImage", "TransformedImage", ...
    "ClassicalSegmentationMask", "AISegmentationInput", "AIProbabilityMap", ...
    "AIPredictedMask", "GroundTruthMask", ...
    "CurrentInputName", "CurrentInput", "ProcessingHistory"];
if ~isstruct(state) || ~isscalar(state) || ~all(isfield(state, required))
    error("MedicalImageToolbox:InvalidImageState", ...
        "State must be created by initializeImageState.");
end
end
