function outputImage = rotateImage(inputImage, angleDegrees, method)
%ROTATEIMAGE Rotate about the image center; positive angle is counterclockwise.
validateImage(inputImage);
if ~isscalar(angleDegrees) || ~isfinite(angleDegrees)
    error("MedicalImageToolbox:RotationAngle", ...
        "Rotation angle must be a finite scalar in degrees.");
end
if nargin < 3
    method = "bilinear";
end
height = size(inputImage, 1);
width = size(inputImage, 2);
centerX = (width + 1) / 2;
centerY = (height + 1) / 2;
theta = deg2rad(angleDegrees);
rotation = [cos(theta) sin(theta) 0; -sin(theta) cos(theta) 0; 0 0 1];
toOrigin = [1 0 -centerX; 0 1 -centerY; 0 0 1];
toCenter = [1 0 centerX; 0 1 centerY; 0 0 1];
outputImage = inverseMapping(inputImage, ...
    toCenter * rotation * toOrigin, [height width], method);
end
