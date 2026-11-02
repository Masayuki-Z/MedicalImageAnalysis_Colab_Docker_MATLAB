function state = recordImageResult(state, outputState, result, operation, parameters, inputStateName)
%RECORDIMAGERESULT Store a processing result without changing original input.
validateState(state);
outputState = lower(string(outputState));
if nargin < 5
    parameters = struct();
end
if nargin < 6
    inputStateName = state.CurrentInputName;
else
    inputStateName = lower(string(inputStateName));
    if ~isscalar(inputStateName) || ...
            ~any(inputStateName == ...
            ["original", "enhanced", "transformed", "aiinput", ...
            "classicalmask", "aipredictedmask", "groundtruthmask"])
        error("MedicalImageToolbox:InputStateName", ...
            "Input state must be original, enhanced, transformed, or aiInput.");
    end
end
if nargin < 4 || ~(ischar(operation) || isstring(operation)) || ...
        strlength(string(operation)) == 0
    error("MedicalImageToolbox:OperationName", ...
        "Operation must be a nonempty name.");
end
switch outputState
    case {"enhanced", "transformed", "aiinput"}
        validateImage(result);
        switch outputState
            case "enhanced"
                state.EnhancedImage = result;
                stateField = "EnhancedImage";
            case "transformed"
                state.TransformedImage = result;
                stateField = "TransformedImage";
            otherwise
                state.AISegmentationInput = result;
                stateField = "AISegmentationInput";
        end
    case {"classicalmask", "aipredictedmask"}
        if ~ismatrix(result) || isempty(result) || ...
                (~islogical(result) && (~isnumeric(result) || ...
                any(~isfinite(result(:))) || any(result(:) ~= 0 & result(:) ~= 1)))
            error("MedicalImageToolbox:BinaryMask", ...
                "Segmentation results must be two-dimensional binary masks.");
        end
        if ~isequal(size(result), size(state.OriginalImage, 1:2)) && ...
                ~isequal(size(result), size(state.CurrentInput, 1:2))
            error("MedicalImageToolbox:MaskSpatialDimensions", ...
                "Mask dimensions must match the original image or current input.");
        end
        result = logical(result);
        if outputState == "classicalmask"
            state.ClassicalSegmentationMask = result;
            stateField = "ClassicalSegmentationMask";
        else
            state.AIPredictedMask = result;
            stateField = "AIPredictedMask";
        end
    case "aiprobabilitymap"
        if ~ismatrix(result) || isempty(result) || ~isnumeric(result) || ...
                ~isreal(result) || any(~isfinite(result(:))) || ...
                any(result(:) < 0 | result(:) > 1)
            error("MedicalImageToolbox:ProbabilityMap", ...
                "AI probability maps must be finite two-dimensional values in [0, 1].");
        end
        state.AIProbabilityMap = single(result);
        stateField = "AIProbabilityMap";
    otherwise
        error("MedicalImageToolbox:OutputStateName", ...
            "Output state must be enhanced, transformed, classicalMask, aiInput, or aiPredictedMask.");
end
entry = struct("Operation", string(operation), ...
    "InputState", string(inputStateName), ...
    "OutputState", stateField, "Parameters", parameters);
state.ProcessingHistory(end + 1) = entry;
if any(outputState == ["enhanced", "transformed"])
    state.CurrentInputName = outputState;
    state.CurrentInput = result;
end
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
