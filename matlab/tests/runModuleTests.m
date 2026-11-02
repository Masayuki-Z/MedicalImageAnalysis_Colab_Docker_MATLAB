function results = runModuleTests
%RUNMODULETESTS Run toolbox unit tests and print a concise result summary.
testDirectory = fileparts(mfilename("fullpath"));
matlabRoot = fileparts(testDirectory);
addpath(genpath(matlabRoot));
results = runtests(testDirectory, "IncludeSubfolders", false);
disp(table(results));
assert(all([results.Passed]), "MedicalImageToolbox:TestsFailed", ...
    "One or more MATLAB module tests failed.");
end
