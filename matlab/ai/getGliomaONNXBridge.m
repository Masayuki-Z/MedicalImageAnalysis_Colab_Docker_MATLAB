function bridge = getGliomaONNXBridge()
%GETGLIOMAONNXBRIDGE Import the project's Python ONNX Runtime bridge.
try
    environment = pyenv;
catch exception
    error("MedicalImageToolbox:PythonUnavailable", ...
        "MATLAB Python support is required for ONNX Runtime inference: %s", ...
        exception.message);
end
pythonDirectory = fullfile(fileparts(fileparts(fileparts(mfilename("fullpath")))), ...
    "python");
if ~isfolder(pythonDirectory)
    error("MedicalImageToolbox:PythonBridgeMissing", ...
        "Project Python bridge directory was not found: %s", pythonDirectory);
end
try
    py.sys.path().insert(int32(0), pythonDirectory);
    py.importlib.invalidate_caches();
    bridge = py.importlib.import_module("matlab_onnx_bridge");
    py.importlib.import_module("onnxruntime");
catch exception
    message = "Unable to load ONNX Runtime from MATLAB's configured Python " + ...
        "environment (" + string(environment.Executable) + ...
        "). Install onnxruntime for that interpreter. Details: " + ...
        string(exception.message);
    error("MedicalImageToolbox:ONNXRuntimeUnavailable", ...
        "%s", char(message));
end
end
