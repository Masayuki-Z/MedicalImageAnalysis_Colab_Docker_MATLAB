classdef MedicalImageAnalysisApp < matlab.apps.AppBase
    %MEDICALIMAGEANALYSISAPP Integrated classical and ONNX MRI toolbox UI.

    properties (Access = public)
        UIFigure matlab.ui.Figure
        ModuleDropDown matlab.ui.control.DropDown
        OperationDropDown matlab.ui.control.DropDown
        InputStateDropDown matlab.ui.control.DropDown
        MaskSourceDropDown matlab.ui.control.DropDown
        InputStateLabel matlab.ui.control.Label
        MaskSourceLabel matlab.ui.control.Label
        Parameter1Field matlab.ui.control.NumericEditField
        Parameter2Field matlab.ui.control.NumericEditField
        Parameter3Field matlab.ui.control.NumericEditField
        Parameter1Label matlab.ui.control.Label
        Parameter2Label matlab.ui.control.Label
        Parameter3Label matlab.ui.control.Label
        ParameterDescriptionArea matlab.ui.control.TextArea
        SeedRowField matlab.ui.control.NumericEditField
        SeedColumnField matlab.ui.control.NumericEditField
        SeedRowLabel matlab.ui.control.Label
        SeedColumnLabel matlab.ui.control.Label
        InterpolationDropDown matlab.ui.control.DropDown
        InterpolationLabel matlab.ui.control.Label
        StructuringElementDropDown matlab.ui.control.DropDown
        StructuringElementLabel matlab.ui.control.Label
        LowerBoundsField matlab.ui.control.EditField
        UpperBoundsField matlab.ui.control.EditField
        LowerBoundsLabel matlab.ui.control.Label
        UpperBoundsLabel matlab.ui.control.Label
        AffineMatrixField matlab.ui.control.EditField
        AffineMatrixLabel matlab.ui.control.Label
        StatusArea matlab.ui.control.TextArea
        OriginalAxes matlab.ui.control.UIAxes
        ClassicalAxes matlab.ui.control.UIAxes
        ClassicalMaskAxes matlab.ui.control.UIAxes
        AIPredictionAxes matlab.ui.control.UIAxes
        AIOverlayAxes matlab.ui.control.UIAxes
        AIProbabilityAxes matlab.ui.control.UIAxes
        GroundTruthAxes matlab.ui.control.UIAxes
        OverlapAxes matlab.ui.control.UIAxes
        OriginalHistogramAxes matlab.ui.control.UIAxes
        EnhancedHistogramAxes matlab.ui.control.UIAxes
        EvaluationMetricsArea matlab.ui.control.TextArea
        EvaluationLegendLabel matlab.ui.control.Label
        EvaluationSummaryArea matlab.ui.control.TextArea
        SectionNavigation matlab.ui.control.ListBox
        SectionHost matlab.ui.container.Panel
        EnhancementOperationDropDown matlab.ui.control.DropDown
        SegmentationOperationDropDown matlab.ui.control.DropDown
        TransformationOperationDropDown matlab.ui.control.DropDown
        EnhancementInputDropDown matlab.ui.control.DropDown
        SegmentationInputDropDown matlab.ui.control.DropDown
        TransformationInputDropDown matlab.ui.control.DropDown
        EnhancementApplyButton matlab.ui.control.Button
        SegmentationApplyButton matlab.ui.control.Button
        TransformationApplyButton matlab.ui.control.Button
        EnhancementResetButton matlab.ui.control.Button
        SegmentationResetButton matlab.ui.control.Button
        TransformationResetButton matlab.ui.control.Button
        EnhancementInputAxes matlab.ui.control.UIAxes
        EnhancementOutputAxes matlab.ui.control.UIAxes
        EnhancementInputHistogramAxes matlab.ui.control.UIAxes
        EnhancementOutputHistogramAxes matlab.ui.control.UIAxes
        SegmentationInputAxes matlab.ui.control.UIAxes
        TransformationInputAxes matlab.ui.control.UIAxes
        TransformationOutputAxes matlab.ui.control.UIAxes
        TransformationDimensionsArea matlab.ui.control.TextArea
        AIInputAxes matlab.ui.control.UIAxes
        AISectionProbabilityAxes matlab.ui.control.UIAxes
        AISectionPredictionAxes matlab.ui.control.UIAxes
        EvaluationGroundTruthAxes matlab.ui.control.UIAxes
        EvaluationOverlapAxes matlab.ui.control.UIAxes
        State = []
        ModelPath = ""
        LastResult = []
        ActiveSection = "Image Workspace"
    end

    properties (Access = private)
        ProjectRoot string
        SectionPanels struct
        EnhancementControls struct
        SegmentationControls struct
        TransformationControls struct
        AIControls struct
        EvaluationControls struct
        LegacyControlsPanel matlab.ui.container.Panel
    end

    methods (Access = public)
        function app = MedicalImageAnalysisApp
            app.ProjectRoot = string(fileparts(fileparts(mfilename("fullpath"))));
            app.createComponents();
            registerApp(app, app.UIFigure);

            % Maximize only after the UIFigure is visible and registered.
            % Setting WindowState while Visible="off" may be ignored by
            % some MATLAB desktop/window-manager configurations.
            app.UIFigure.WindowState = "maximized";
            drawnow;

            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end

        function loadImageData(app, image, sourceName)
            if nargin < 3
                sourceName = "Loaded MRI";
            end
            validateImage(image);
            clearedGroundTruth = ~isempty(app.State) && ...
                ~isempty(app.State.GroundTruthMask);
            app.State = initializeImageState(image);
            app.LastResult = image;
            if clearedGroundTruth
                app.StatusArea.Value = ["Loaded: " + string(sourceName); ...
                    "Previous ground-truth mask cleared for the replaced MRI."];
            else
                app.StatusArea.Value = "Loaded: " + string(sourceName);
            end
            app.updateDisplays();
        end

        function wasResized = setGroundTruthMask(app, maskImage, sourceName)
            app.requireLoadedImage();
            if nargin < 3
                sourceName = "Ground-truth mask";
            end
            [mask, wasResized] = prepareGroundTruthMask( ...
                maskImage, size(app.State.OriginalImage, 1:2));
            app.State.GroundTruthMask = mask;
            app.updateDisplays();
            if wasResized
                app.StatusArea.Value = ["Loaded ground truth: " + string(sourceName); ...
                    "Dimensions aligned with MRI using nearest-neighbor resize."];
            else
                app.StatusArea.Value = "Loaded ground truth: " + string(sourceName);
            end
        end

        function clearGroundTruthMask(app)
            app.requireLoadedImage();
            app.State.GroundTruthMask = [];
            app.updateDisplays();
            app.StatusArea.Value = "Ground-truth mask cleared.";
        end

        function setModelPath(app, modelPath)
            if ~(ischar(modelPath) || (isstring(modelPath) && isscalar(modelPath))) || ...
                    strlength(string(modelPath)) == 0 || ~isfile(modelPath)
                error("MedicalImageToolbox:ONNXModelMissing", ...
                    "Select an existing ONNX model file.");
            end
            app.ModelPath = string(modelPath);
            app.StatusArea.Value = "ONNX model: " + app.ModelPath;
        end

        function [probabilityMap, predictionMask] = runAISegmentation(app)
            app.requireLoadedImage();
            if strlength(app.ModelPath) == 0
                error("MedicalImageToolbox:ONNXModelMissing", ...
                    "Load the trained ONNX model before running AI segmentation.");
            end
            [app.State, probabilityMap, predictionMask] = ...
                runGliomaONNX(app.State, app.ModelPath);
            app.LastResult = predictionMask;
            app.StatusArea.Value = "U-Net segmentation complete (threshold 0.5).";
            app.updateDisplays();
        end

        function result = applySelectedOperation(app)
            app.requireLoadedImage();
            module = string(app.ModuleDropDown.Value);
            operation = string(app.OperationDropDown.Value);
            p1 = app.Parameter1Field.Value;
            p2 = app.Parameter2Field.Value;
            p3 = app.Parameter3Field.Value;
            interpolation = string(app.InterpolationDropDown.Value);
            inputName = string(app.InputStateDropDown.Value);
            alignedMask = [];
            isMaskOperation = any(operation == [ ...
                "Dilation", "Erosion", "Opening", "Closing", "Shape-based segmentation"]);

            if isMaskOperation
                [source, inputName] = app.getSelectedMaskSource();
            else
                [source, app.State] = selectImageState(app.State, inputName);
            end
            app.validateOperationParameters(operation, p1, p2, p3, source);

            switch module
                case "Image Enhancement"
                    [result, outputState, parameters] = ...
                        app.applyEnhancement(operation, source, p1, p2, ...
                        app.State.OriginalImage);
                case "Segmentation and Edges"
                    [result, outputState, parameters] = ...
                        app.applySegmentation(operation, source, p1, p2, p3, inputName);
                case "Geometric Transformations"
                    [result, outputState, parameters, alignedMask] = ...
                        app.applyGeometry(operation, source, p1, p2, interpolation);
                otherwise
                    error("MedicalImageToolbox:UnknownModule", ...
                        "Select a supported toolbox module.");
            end

            app.State = recordImageResult(app.State, outputState, result, ...
                operation, parameters, inputName);
            if ~isempty(alignedMask)
                app.State.ClassicalSegmentationMask = alignedMask;
            end
            app.LastResult = result;
            if isMaskOperation
                app.StatusArea.Value = "Applied: " + operation + ...
                    " / mask source: " + app.maskSourceLabel(inputName) + ...
                    " / image state remains: " + app.InputStateDropDown.Value;
            else
                app.StatusArea.Value = "Applied: " + module + " / " + operation + ...
                    " / image input: " + inputName;
            end
            app.updateDisplays();
        end

        function resetImage(app)
            app.requireLoadedImage();
            original = app.State.OriginalImage;
            groundTruthMask = app.State.GroundTruthMask;
            app.State = initializeImageState(original);
            app.State.GroundTruthMask = groundTruthMask;
            app.LastResult = original;
            app.StatusArea.Value = ...
                "Processing states reset; original image and ground truth preserved.";
            app.updateDisplays();
        end

        function saveCurrentResult(app, outputPath)
            app.requireLoadedImage();
            if nargin < 2 || isempty(outputPath)
                outputPath = "";
            end
            if (isstring(outputPath) && ~isscalar(outputPath)) || ...
                    ~(ischar(outputPath) || isstring(outputPath))
                error("MedicalImageToolbox:InvalidOutputPath", ...
                    "Output path must be a character vector or scalar string.");
            end
            if strlength(string(outputPath)) == 0
                [file, folder] = uiputfile( ...
                    {"*.png";"*.tif";"*.jpg"}, "Save current result", ...
                    "medical_image_result.png");
                if isequal(file, 0)
                    return
                end
                outputPath = fullfile(folder, file);
            end
            if isempty(app.LastResult)
                error("MedicalImageToolbox:NoResult", ...
                    "There is no current result to save.");
            end
            imwrite(app.LastResult, char(outputPath));
            app.StatusArea.Value = "Saved: " + string(outputPath);
        end

        function refreshDisplays(app)
            app.updateDisplays();
        end
    end

    methods (Access = private)
        
        function createComponents(app)

            % Main application window
            app.UIFigure = uifigure( ...
                "Name", "Integrated Medical Image Processing Toolbox", ...
                "Position", [40 40 1400 700], ...
                "Visible", "off");

            % ==========================================
            % ROOT LAYOUT
            % ==========================================
            root = uigridlayout(app.UIFigure, [1 2]);

            root.RowHeight = {"1x"};
            root.ColumnWidth = {270, "1x"}; % right workspace takes all remaining width

            root.Padding = [10 10 10 10];
            root.ColumnSpacing = 12;

            % ==========================================
            % LEFT NAVIGATION PANEL
            % ==========================================
            navigationPanel = uipanel(root, ...
                "Title", "Project workflow");

            navigationPanel.Layout.Row = 1;
            navigationPanel.Layout.Column = 1;

            navigation = uigridlayout(navigationPanel, [2 1]);

            navigation.RowHeight = {"1x", 150};
            navigation.ColumnWidth = {"1x"};

            navigation.Padding = [8 8 8 8];
            navigation.RowSpacing = 8;

            app.SectionNavigation = uilistbox(navigation, ...
                "Items", ["Image Workspace", "Image Enhancement", ...
                "Image Segmentation", "Geometric Transformation", ...
                "AI Segmentation", "Evaluation"], ...
                "Value", "Image Workspace", ...
                "ValueChangedFcn", ...
                @(~, event) app.onSectionNavigation(event));

            app.SectionNavigation.Layout.Row = 1;
            app.SectionNavigation.Layout.Column = 1;

            app.StatusArea = uitextarea(navigation, ...
                "Editable", "off", ...
                "Value", ...
                "Load an MRI image to begin. Each section preserves its own results.");

            app.StatusArea.Layout.Row = 2;
            app.StatusArea.Layout.Column = 1;

            % ==========================================
            % RIGHT CONTENT LAYOUT
            % ==========================================
            content = uigridlayout(root, [2 1]);

            content.Layout.Row = 1;
            content.Layout.Column = 2;

            content.RowHeight = {55, "1x"};
            content.ColumnWidth = {"1x"};

            content.Padding = [0 0 0 0];
            content.RowSpacing = 10;

            % Application title
            titleLabel = uilabel(content, ...
                "Text", "Integrated Medical Image Processing Toolbox", ...
                "FontSize", 22, ...
                "FontWeight", "bold");

            titleLabel.Layout.Row = 1;
            titleLabel.Layout.Column = 1;

            % Main section container
            app.SectionHost = uipanel(content, ...
                "BorderType", "none");

            app.SectionHost.Layout.Row = 2;
            app.SectionHost.Layout.Column = 1;

            % SectionHost is managed by the parent grid layout.
            % Do not set Units/Position manually; the grid assigns its size.

            % ==========================================
            % SECTION PANELS
            % ==========================================

            sectionNames = ["Image Workspace", "Image Enhancement", ...
                "Image Segmentation", "Geometric Transformation", ...
                "AI Segmentation", "Evaluation"];

            app.SectionPanels = struct();

            % Use a dedicated 1-by-1 grid to size every section panel.
            % This is more reliable than normalized Position on panels
            % created while the UIFigure is hidden.
            sectionStack = uigridlayout(app.SectionHost, [1 1]);
            sectionStack.RowHeight = {"1x"};
            sectionStack.ColumnWidth = {"1x"};
            sectionStack.Padding = [0 0 0 0];
            sectionStack.RowSpacing = 0;
            sectionStack.ColumnSpacing = 0;

            for index = 1:numel(sectionNames)

                field = matlab.lang.makeValidName(sectionNames(index));

                panel = uipanel(sectionStack, ...
                    "Title", sectionNames(index), ...
                    "Visible", "off");
                panel.Layout.Row = 1;
                panel.Layout.Column = 1;

                app.SectionPanels.(field) = panel;

            end

            % ==========================================
            % CREATE ALL SECTIONS
            % ==========================================

            app.createWorkspaceSection(app.SectionPanels.ImageWorkspace);

            app.EnhancementControls = app.createOperationSection( ...
                app.SectionPanels.ImageEnhancement, "enhancement");

            app.SegmentationControls = app.createOperationSection( ...
                app.SectionPanels.ImageSegmentation, "segmentation");

            app.TransformationControls = app.createOperationSection( ...
                app.SectionPanels.GeometricTransformation, "transformation");

            app.createAISection(app.SectionPanels.AISegmentation);

            app.createEvaluationSection(app.SectionPanels.Evaluation);

            app.createLegacyControls();

            app.updateSectionParameterMetadata("enhancement");
            app.updateSectionParameterMetadata("segmentation");
            app.updateSectionParameterMetadata("transformation");

            app.navigateToSection("Image Workspace");

            app.UIFigure.Visible = "on";

            drawnow;

        end


        function createWorkspaceSection(app, parent)
            grid = uigridlayout(parent, [5 3]);
            grid.RowHeight = {55, "1x", "1x", "1x", 130};
            grid.ColumnWidth = {"1x", "1x", "1x"};

            grid.Padding = [12 12 12 12];
            grid.ColumnSpacing = 12;
            grid.RowSpacing = 10;
            app.OriginalAxes = uiaxes(grid);
            app.OriginalAxes.Layout.Row = 2;
            app.OriginalAxes.Layout.Column = 1;
            title(app.OriginalAxes, "Original MRI");
            app.ClassicalAxes = uiaxes(grid);
            app.ClassicalAxes.Layout.Row = 2;
            app.ClassicalAxes.Layout.Column = 2;
            title(app.ClassicalAxes, "Enhanced / transformed");
            app.ClassicalMaskAxes = uiaxes(grid);
            app.ClassicalMaskAxes.Layout.Row = 2;
            app.ClassicalMaskAxes.Layout.Column = 3;
            title(app.ClassicalMaskAxes, "Classical mask / edges");
            app.AIPredictionAxes = uiaxes(grid);
            app.AIPredictionAxes.Layout.Row = 3;
            app.AIPredictionAxes.Layout.Column = 1;
            title(app.AIPredictionAxes, "AI prediction mask");
            app.AIOverlayAxes = uiaxes(grid);
            app.AIOverlayAxes.Layout.Row = 3;
            app.AIOverlayAxes.Layout.Column = 2;
            title(app.AIOverlayAxes, "AI overlay");
            app.AIProbabilityAxes = uiaxes(grid);
            app.AIProbabilityAxes.Layout.Row = 3;
            app.AIProbabilityAxes.Layout.Column = 3;
            title(app.AIProbabilityAxes, "AI probability map");
            app.GroundTruthAxes = uiaxes(grid);
            app.GroundTruthAxes.Layout.Row = 4;
            app.GroundTruthAxes.Layout.Column = 1;
            title(app.GroundTruthAxes, "Ground-truth mask");
            app.OverlapAxes = uiaxes(grid);
            app.OverlapAxes.Layout.Row = 4;
            app.OverlapAxes.Layout.Column = 2;
            title(app.OverlapAxes, "Ground truth vs AI");
            app.OriginalHistogramAxes = uiaxes(grid);
            app.OriginalHistogramAxes.Layout.Row = 4;
            app.OriginalHistogramAxes.Layout.Column = 3;
            title(app.OriginalHistogramAxes, "Original histogram");
            app.EnhancedHistogramAxes = uiaxes(grid);
            app.EnhancedHistogramAxes.Layout.Row = 5;
            app.EnhancedHistogramAxes.Layout.Column = 1;
            title(app.EnhancedHistogramAxes, "Processed histogram");
            app.EvaluationMetricsArea = uitextarea(grid, "Editable", "off", ...
                "Value", ["Load ground truth and run AI to calculate pixel metrics."; ...
                "Green TP | Red FP | Blue FN"; ...
                "Educational comparison only; not clinical validation."]);
            app.EvaluationMetricsArea.Layout.Row = 5;
            app.EvaluationMetricsArea.Layout.Column = 2;
            app.EvaluationLegendLabel = uilabel(grid, ...
                "Text", ["Overlap legend:"; "Green = TP"; "Red = FP"; ...
                "Blue = FN"], "VerticalAlignment", "top");
            app.EvaluationLegendLabel.Layout.Row = 5;
            app.EvaluationLegendLabel.Layout.Column = 3;
            app.createWorkspaceActions(grid);
            axesList = [app.OriginalAxes, app.ClassicalAxes, ...
                app.ClassicalMaskAxes, app.AIPredictionAxes, app.AIOverlayAxes, ...
                app.AIProbabilityAxes, app.GroundTruthAxes, app.OverlapAxes, ...
                app.OriginalHistogramAxes, app.EnhancedHistogramAxes];
            for index = 1:numel(axesList)
                axesList(index).XTick = [];
                axesList(index).YTick = [];
            end
        end

        function createWorkspaceActions(app, parent)
            actions = uigridlayout(parent, [1 4]);
            actions.Layout.Row = 1;
            actions.Layout.Column = [1 3];
            actions.ColumnWidth = {"1x", "1x", "1x", "1x"};
            uibutton(actions, "Text", "Load MRI", ...
                "ButtonPushedFcn", @(~, ~) app.onLoadImage());
            uibutton(actions, "Text", "Reset processing", ...
                "ButtonPushedFcn", @(~, ~) app.onReset());
            uibutton(actions, "Text", "Save current result", ...
                "ButtonPushedFcn", @(~, ~) app.onSaveResult());
            uilabel(actions, "Text", ...
                "Educational / research use only — not a diagnosis.", ...
                "HorizontalAlignment", "center");
        end

        function controls = createOperationSection(app, parent, sectionKey)
            layout = uigridlayout(parent, [2 3]);

            layout.RowHeight = {"1x", 140};
            layout.ColumnWidth = {330, "2x", "2x"};

            layout.Padding = [12 12 12 12];
            layout.ColumnSpacing = 12;
            layout.RowSpacing = 10;

            controlsPanel = uipanel(layout, "Title", "Independent operation controls");

            % Stretch the controls panel across BOTH layout rows.
            % This gives the controls the full available height instead of
            % restricting them to the upper row beside the image axes.
            controlsPanel.Layout.Row = [1 2];
            controlsPanel.Layout.Column = 1;

            controlGrid = uigridlayout(controlsPanel, [17 2]);

            % Compact row sizing: all 17 control rows fit in the full-height
            % panel on a typical maximized desktop window.
            controlGrid.RowHeight = { ...
                22, 22, 22, 22, 22, 22, 22, 22, ...
                22, 22, 22, 22, 22, 48, 40, 42, 26};

            controlGrid.ColumnWidth = {"1x", "1x"};
            controlGrid.Padding = [8 8 8 8];
            controlGrid.RowSpacing = 2;

            % All controls should be visible without a vertical scrollbar.
            controlGrid.Scrollable = "off";

            if sectionKey == "enhancement"
                moduleName = "Image Enhancement";
                inputChoices = ["original", "enhanced", "transformed"];
            elseif sectionKey == "segmentation"
                moduleName = "Segmentation and Edges";
                inputChoices = ["original", "enhanced", "transformed"];
            else
                moduleName = "Geometric Transformations";
                inputChoices = ["original", "enhanced", "transformed"];
            end

            controls.ModuleName = moduleName;
            controls.Operation = uidropdown(controlGrid, ...
                "Items", app.operationsForModule(moduleName));
            controls.Operation.Layout.Row = 1;
            controls.Operation.Layout.Column = 2;
            label = uilabel(controlGrid, "Text", "Operation");
            label.Layout.Row = 1;
            controls.Operation.ValueChangedFcn = ...
                @(~, ~) app.updateSectionParameterMetadata(sectionKey);

            controls.InputLabel = uilabel(controlGrid, "Text", "Image input");
            controls.InputLabel.Layout.Row = 2;
            controls.Input = uidropdown(controlGrid, ...
                "Items", inputChoices, "Value", "original");
            controls.Input.Layout.Row = 2;
            controls.Input.Layout.Column = 2;
            controls.Input.Tooltip = ...
                "Select the image state to process; original MRI is never overwritten.";

            controls.MaskSourceLabel = uilabel(controlGrid, "Text", "Mask source");
            controls.MaskSourceLabel.Layout.Row = 3;
            controls.MaskSource = uidropdown(controlGrid, ...
                "Items", ["Classical mask", "AI prediction", "Ground truth mask"], ...
                "Value", "Classical mask");
            controls.MaskSource.Layout.Row = 3;
            controls.MaskSource.Layout.Column = 2;
            controls.MaskSource.Tooltip = ...
                "Used only by morphology and shape-based segmentation.";

            controls.ParameterLabels = cell(1, 3);
            controls.ParameterFields = cell(1, 3);
            for parameter = 1:3
                controls.ParameterLabels{parameter} = uilabel(controlGrid, ...
                    "Text", "Parameter " + parameter);
                controls.ParameterLabels{parameter}.Layout.Row = 3 + parameter;
                controls.ParameterFields{parameter} = uieditfield(controlGrid, ...
                    "numeric", "Value", 0);
                controls.ParameterFields{parameter}.Layout.Row = 3 + parameter;
                controls.ParameterFields{parameter}.Layout.Column = 2;
            end
            controls.SeedRowLabel = uilabel(controlGrid, "Text", "Seed row");
            controls.SeedRowLabel.Layout.Row = 7;
            controls.SeedRow = uieditfield(controlGrid, "numeric", "Value", 1);
            controls.SeedRow.Layout.Row = 7;
            controls.SeedRow.Layout.Column = 2;
            controls.SeedColumnLabel = uilabel(controlGrid, "Text", "Seed column");
            controls.SeedColumnLabel.Layout.Row = 8;
            controls.SeedColumn = uieditfield(controlGrid, "numeric", "Value", 1);
            controls.SeedColumn.Layout.Row = 8;
            controls.SeedColumn.Layout.Column = 2;

            controls.InterpolationLabel = uilabel(controlGrid, ...
                "Text", "Interpolation");
            controls.InterpolationLabel.Layout.Row = 9;
            controls.Interpolation = uidropdown(controlGrid, ...
                "Items", ["nearest", "bilinear", "bicubic"], ...
                "Value", "bilinear");
            controls.Interpolation.Layout.Row = 9;
            controls.Interpolation.Layout.Column = 2;
            controls.StructuringElementLabel = uilabel(controlGrid, ...
                "Text", "Structuring element");
            controls.StructuringElementLabel.Layout.Row = 10;
            controls.StructuringElement = uidropdown(controlGrid, ...
                "Items", ["disk", "square", "diamond"], "Value", "disk");
            controls.StructuringElement.Layout.Row = 10;
            controls.StructuringElement.Layout.Column = 2;

            controls.LowerBoundsLabel = uilabel(controlGrid, ...
                "Text", "RGB/HSV lower");
            controls.LowerBoundsLabel.Layout.Row = 11;
            controls.LowerBounds = uieditfield(controlGrid, "text", ...
                "Value", "0,0,0");
            controls.LowerBounds.Layout.Row = 11;
            controls.LowerBounds.Layout.Column = 2;
            controls.UpperBoundsLabel = uilabel(controlGrid, ...
                "Text", "RGB/HSV upper");
            controls.UpperBoundsLabel.Layout.Row = 12;
            controls.UpperBounds = uieditfield(controlGrid, "text", ...
                "Value", "1,1,1");
            controls.UpperBounds.Layout.Row = 12;
            controls.UpperBounds.Layout.Column = 2;
            controls.AffineLabel = uilabel(controlGrid, ...
                "Text", "Affine matrix (3x3)");
            controls.AffineLabel.Layout.Row = 13;
            controls.Affine = uieditfield(controlGrid, "text", ...
                "Value", "1,0,0;0,1,0;0,0,1");
            controls.Affine.Layout.Row = 13;
            controls.Affine.Layout.Column = 2;

            controls.ParameterDescription = uitextarea(controlGrid, ...
                "Editable", "off", "Value", "Select an operation.");
            controls.ParameterDescription.Layout.Row = 14;
            controls.ParameterDescription.Layout.Column = [1 2];
            % Apply button
            applyButton = uibutton(controlGrid, ...
                "Text", "Apply operation", ...
                "FontSize", 13, ...
                "FontWeight", "bold", ...
                "ButtonPushedFcn", @(~, ~) app.onApplySection(sectionKey));

            applyButton.Layout.Row = 15;
            applyButton.Layout.Column = 1;

            % Reset button
            resetButton = uibutton(controlGrid, ...
                "Text", "Reset section", ...
                "FontSize", 13, ...
                "ButtonPushedFcn", @(~, ~) app.onResetSection(sectionKey));

            resetButton.Layout.Row = 15;
            resetButton.Layout.Column = 2;
            controls.ApplyButton = applyButton;
            controls.ResetButton = resetButton;
            controls.Status = uitextarea(controlGrid, "Editable", "off", ...
                "Value", "Results appear separately from the input image.");
            controls.Status.Layout.Row = 16;
            controls.Status.Layout.Column = [1 2];
            controls.ModuleNameLabel = uilabel(controlGrid, ...
                "Text", moduleName, "HorizontalAlignment", "center");
            controls.ModuleNameLabel.Layout.Row = 17;
            controls.ModuleNameLabel.Layout.Column = [1 2];

            controls.MaskSourceLabel.Visible = "off";
            controls.MaskSource.Visible = "off";

            controls.InputAxes = uiaxes(layout);
            controls.InputAxes.Layout.Row = 1;
            controls.InputAxes.Layout.Column = 2;
            controls.OutputAxes = uiaxes(layout);
            controls.OutputAxes.Layout.Row = 1;
            controls.OutputAxes.Layout.Column = 3;
            title(controls.InputAxes, "Selected input");
            title(controls.OutputAxes, "Operation output");
            controls.HistogramAxes = [];
            controls.DimensionsArea = [];
            if sectionKey == "enhancement"
                app.EnhancementOperationDropDown = controls.Operation;
                app.EnhancementInputDropDown = controls.Input;
                app.EnhancementApplyButton = applyButton;
                app.EnhancementResetButton = resetButton;
                controls.HistogramAxes = uiaxes(layout);
                controls.HistogramAxes.Layout.Row = 2;
                controls.HistogramAxes.Layout.Column = [2 3];
                title(controls.HistogramAxes, "Input and output histograms");
                app.EnhancementInputAxes = controls.InputAxes;
                app.EnhancementOutputAxes = controls.OutputAxes;
                app.EnhancementInputHistogramAxes = controls.HistogramAxes;
            elseif sectionKey == "transformation"
                app.TransformationOperationDropDown = controls.Operation;
                app.TransformationInputDropDown = controls.Input;
                app.TransformationApplyButton = applyButton;
                app.TransformationResetButton = resetButton;
                controls.DimensionsArea = uitextarea(layout, ...
                    "Editable", "off", "Value", "Input/output dimensions appear here.");
                controls.DimensionsArea.Layout.Row = 2;
                controls.DimensionsArea.Layout.Column = [2 3];
                app.TransformationInputAxes = controls.InputAxes;
                app.TransformationOutputAxes = controls.OutputAxes;
                app.TransformationDimensionsArea = controls.DimensionsArea;
            else
                app.SegmentationOperationDropDown = controls.Operation;
                app.SegmentationInputDropDown = controls.Input;
                app.SegmentationApplyButton = applyButton;
                app.SegmentationResetButton = resetButton;
                controls.DescriptionLabel = uilabel(layout, ...
                    "Text", "Image input and binary mask source are independent.", ...
                    "HorizontalAlignment", "center");
                controls.DescriptionLabel.Layout.Row = 2;
                controls.DescriptionLabel.Layout.Column = [2 3];
                app.SegmentationInputAxes = controls.InputAxes;
            end
            app.setSectionOptionalVisibility(controls, false, false, ...
                false, false, false, false);
        end

        function createAISection(app, parent)
            grid = uigridlayout(parent, [2 3]);
            grid.RowHeight = {55, "1x"};
            grid.ColumnWidth = {"1x", "1x", "1x"};

            grid.Padding = [12 12 12 12];
            grid.ColumnSpacing = 15;
            grid.RowSpacing = 12;
            toolbar = uigridlayout(grid, [1 4]);
            toolbar.Layout.Row = 1;
            toolbar.Layout.Column = [1 3];
            toolbar.ColumnWidth = {"1x", "1x", "1x", "2x"};
            uibutton(toolbar, "Text", "Load original MRI", ...
                "ButtonPushedFcn", @(~, ~) app.onLoadImage());
            uibutton(toolbar, "Text", "Load ONNX model", ...
                "ButtonPushedFcn", @(~, ~) app.onLoadModel());
            uibutton(toolbar, "Text", "Run U-Net on original FLAIR", ...
                "ButtonPushedFcn", @(~, ~) app.onRunAI());
            uilabel(toolbar, "Text", ...
                "Independent path: original MRI → model preprocessing → prediction.");
            app.AIInputAxes = uiaxes(grid);
            app.AIInputAxes.Layout.Row = 2;
            app.AIInputAxes.Layout.Column = 1;
            app.AISectionProbabilityAxes = uiaxes(grid);
            app.AISectionProbabilityAxes.Layout.Row = 2;
            app.AISectionProbabilityAxes.Layout.Column = 2;
            app.AISectionPredictionAxes = uiaxes(grid);
            app.AISectionPredictionAxes.Layout.Row = 2;
            app.AISectionPredictionAxes.Layout.Column = 3;
            title(app.AIInputAxes, "Original MRI (not overwritten)");
            title(app.AISectionProbabilityAxes, "AI probability map");
            title(app.AISectionPredictionAxes, "AI prediction mask");
            app.AIControls = struct("Toolbar", toolbar, "Axes", ...
                [app.AIInputAxes, app.AISectionProbabilityAxes, ...
                app.AISectionPredictionAxes]);
        end

        function createEvaluationSection(app, parent)
            grid = uigridlayout(parent, [3 2]);
            grid.RowHeight = {60, "1x", 130};
            grid.ColumnWidth = {"1x", "1x"};

            grid.Padding = [12 12 12 12];
            grid.ColumnSpacing = 15;
            grid.RowSpacing = 12;
            toolbar = uigridlayout(grid, [1 3]);
            toolbar.Layout.Row = 1;
            toolbar.Layout.Column = [1 2];
            toolbar.ColumnWidth = {"1x", "1x", "1x"};
            uibutton(toolbar, "Text", "Load ground truth", ...
                "ButtonPushedFcn", @(~, ~) app.onLoadGroundTruth());
            uibutton(toolbar, "Text", "Clear ground truth", ...
                "ButtonPushedFcn", @(~, ~) app.onClearGroundTruth());
            uibutton(toolbar, "Text", "Run AI inference", ...
                "ButtonPushedFcn", @(~, ~) app.onRunAI());
            app.EvaluationGroundTruthAxes = uiaxes(grid);
            app.EvaluationGroundTruthAxes.Layout.Row = 2;
            app.EvaluationGroundTruthAxes.Layout.Column = 1;
            app.EvaluationOverlapAxes = uiaxes(grid);
            app.EvaluationOverlapAxes.Layout.Row = 2;
            app.EvaluationOverlapAxes.Layout.Column = 2;
            title(app.EvaluationGroundTruthAxes, "Ground-truth mask");
            title(app.EvaluationOverlapAxes, "TP green / FP red / FN blue");
            app.EvaluationSummaryArea = uitextarea(grid, "Editable", "off", ...
                "Value", ["Load ground truth and run AI to calculate metrics."; ...
                "Pixel-level comparison; not clinical validation."]);
            app.EvaluationSummaryArea.Layout.Row = 3;
            app.EvaluationSummaryArea.Layout.Column = 1;
            evaluationLegend = uilabel(grid, ...
                "Text", ["Green = TP"; "Red = FP"; "Blue = FN"], ...
                "VerticalAlignment", "top");
            evaluationLegend.Layout.Row = 3;
            evaluationLegend.Layout.Column = 2;
            app.EvaluationControls = struct("Toolbar", toolbar, ...
                "SummaryArea", app.EvaluationSummaryArea);
        end

        function createLegacyControls(app)
            app.LegacyControlsPanel = uipanel(app.UIFigure, ...
                "Title", "Legacy compatibility controls", ...
                "Visible", "off");
            controls = uigridlayout(app.LegacyControlsPanel, [23 2]);
            controls.RowHeight = [repmat({30}, 1, 20), {76, 64, 34}];
            controls.ColumnWidth = {"1x", "1x"};
            app.ModuleDropDown = uidropdown(controls, ...
                "Items", ["Image Enhancement", "Segmentation and Edges", ...
                "Geometric Transformations"]);
            app.ModuleDropDown.Layout.Row = 1;
            app.ModuleDropDown.Layout.Column = 1;
            app.OperationDropDown = uidropdown(controls, ...
                "Items", app.operationsForModule("Image Enhancement"));
            app.OperationDropDown.Layout.Row = 1;
            app.OperationDropDown.Layout.Column = 2;
            app.ModuleDropDown.ValueChangedFcn = ...
                @(~, ~) app.updateOperationChoices();
            app.OperationDropDown.ValueChangedFcn = ...
                @(~, ~) app.updateOperationMetadata();
            app.InputStateDropDown = uidropdown(controls, ...
                "Items", ["original", "enhanced", "transformed"]);
            app.MaskSourceDropDown = uidropdown(controls, ...
                "Items", ["Classical mask", "AI prediction", "Ground truth mask"]);
            app.InputStateLabel = app.addLabel(controls, "Image input", 2);
            app.InputStateDropDown.Layout.Row = 2;
            app.InputStateDropDown.Layout.Column = 2;
            app.MaskSourceLabel = app.addLabel(controls, "Mask source", 3);
            app.MaskSourceDropDown.Layout.Row = 3;
            app.MaskSourceDropDown.Layout.Column = 2;
            [app.Parameter1Label, app.Parameter1Field] = ...
                app.addNumericControl(controls, "Parameter 1", 4, 0.1, "Parameter1Field");
            [app.Parameter2Label, app.Parameter2Field] = ...
                app.addNumericControl(controls, "Parameter 2", 5, 0.2, "Parameter2Field");
            [app.Parameter3Label, app.Parameter3Field] = ...
                app.addNumericControl(controls, "Parameter 3", 6, 0, "Parameter3Field");
            [app.SeedRowLabel, app.SeedRowField] = ...
                app.addNumericControl(controls, "Seed row", 7, 1, "SeedRowField");
            [app.SeedColumnLabel, app.SeedColumnField] = ...
                app.addNumericControl(controls, "Seed column", 8, 1, "SeedColumnField");
            app.InterpolationLabel = app.addLabel(controls, "Interpolation", 9);
            app.InterpolationDropDown = uidropdown(controls, ...
                "Items", ["nearest", "bilinear", "bicubic"]);
            app.InterpolationDropDown.Layout.Row = 9;
            app.InterpolationDropDown.Layout.Column = 2;
            app.StructuringElementLabel = app.addLabel(controls, ...
                "Structuring element", 10);
            app.StructuringElementDropDown = uidropdown(controls, ...
                "Items", ["disk", "square", "diamond"]);
            app.StructuringElementDropDown.Layout.Row = 10;
            app.StructuringElementDropDown.Layout.Column = 2;
            app.LowerBoundsLabel = app.addLabel(controls, "Lower bounds", 11);
            app.LowerBoundsField = uieditfield(controls, "text", "Value", "0,0,0");
            app.LowerBoundsField.Layout.Row = 11;
            app.LowerBoundsField.Layout.Column = 2;
            app.UpperBoundsLabel = app.addLabel(controls, "Upper bounds", 12);
            app.UpperBoundsField = uieditfield(controls, "text", "Value", "1,1,1");
            app.UpperBoundsField.Layout.Row = 12;
            app.UpperBoundsField.Layout.Column = 2;
            app.AffineMatrixLabel = app.addLabel(controls, "Affine matrix", 13);
            app.AffineMatrixField = uieditfield(controls, "text", ...
                "Value", "1,0,0;0,1,0;0,0,1");
            app.AffineMatrixField.Layout.Row = 13;
            app.AffineMatrixField.Layout.Column = 2;
            app.ParameterDescriptionArea = uitextarea(controls, ...
                "Editable", "off", "Value", "Legacy test compatibility.");
            app.ParameterDescriptionArea.Layout.Row = 14;
            app.ParameterDescriptionArea.Layout.Column = [1 2];
            applyButton = uibutton(controls, "Text", "Apply classical operation", ...
                "ButtonPushedFcn", @(~, ~) app.onApplyOperation());
            applyButton.Layout.Row = 15;
            applyButton.Layout.Column = [1 2];
            uibutton(controls, "Text", "Run AI U-Net (original FLAIR)", ...
                "ButtonPushedFcn", @(~, ~) app.onRunAI());
            uibutton(controls, "Text", "Reset", ...
                "ButtonPushedFcn", @(~, ~) app.onReset());
            uibutton(controls, "Text", "Save result", ...
                "ButtonPushedFcn", @(~, ~) app.onSaveResult());
        end

        function onSectionNavigation(app, event)
            app.navigateToSection(string(event.Value));
        end

        function navigateToSection(app, sectionName)
            app.ActiveSection = string(sectionName);
            fields = fieldnames(app.SectionPanels);
            for index = 1:numel(fields)
                app.SectionPanels.(fields{index}).Visible = "off";
            end
            field = matlab.lang.makeValidName(sectionName);
            app.SectionPanels.(field).Visible = "on";
        end

        function updateSectionParameterMetadata(app, sectionKey)
            controls = app.getSectionControls(sectionKey);
            metadata = app.operationMetadata( ...
                controls.ModuleName, controls.Operation.Value);
            defaults = [metadata.P1Default metadata.P2Default metadata.P3Default];
            labels = [metadata.P1Label metadata.P2Label metadata.P3Label];
            helps = [metadata.P1Help metadata.P2Help metadata.P3Help];
            shown = [metadata.ShowP1 metadata.ShowP2 metadata.ShowP3];
            for index = 1:3
                controls.ParameterLabels{index}.Text = labels(index);
                controls.ParameterLabels{index}.Tooltip = helps(index);
                controls.ParameterFields{index}.Tooltip = helps(index);
                controls.ParameterLabels{index}.Visible = onOff(shown(index));
                controls.ParameterFields{index}.Visible = onOff(shown(index));
                if shown(index)
                    controls.ParameterFields{index}.Value = defaults(index);
                end
            end
            app.setSectionOptionalVisibility(controls, metadata.ShowSeed, ...
                metadata.ShowInterpolation, metadata.ShowStructuringElement, ...
                metadata.ShowColorBounds, metadata.ShowAffineMatrix, ...
                metadata.IsMaskOperation);
            controls.SeedRowLabel.Visible = onOff(metadata.ShowSeed);
            controls.SeedRow.Visible = onOff(metadata.ShowSeed);
            controls.SeedColumnLabel.Visible = onOff(metadata.ShowSeed);
            controls.SeedColumn.Visible = onOff(metadata.ShowSeed);
            controls.ParameterDescription.Value = metadata.Description;
        end

        function setSectionOptionalVisibility(~, controls, showSeed, ...
                showInterpolation, showStructuringElement, showColorBounds, ...
                showAffine, showMaskSource)
            controls.InterpolationLabel.Visible = onOff(showInterpolation);
            controls.Interpolation.Visible = onOff(showInterpolation);
            controls.StructuringElementLabel.Visible = onOff(showStructuringElement);
            controls.StructuringElement.Visible = onOff(showStructuringElement);
            controls.LowerBoundsLabel.Visible = onOff(showColorBounds);
            controls.LowerBounds.Visible = onOff(showColorBounds);
            controls.UpperBoundsLabel.Visible = onOff(showColorBounds);
            controls.UpperBounds.Visible = onOff(showColorBounds);
            controls.AffineLabel.Visible = onOff(showAffine);
            controls.Affine.Visible = onOff(showAffine);
            controls.MaskSourceLabel.Visible = onOff(showMaskSource);
            controls.MaskSource.Visible = onOff(showMaskSource);
            controls.SeedRowLabel.Visible = onOff(showSeed);
            controls.SeedRow.Visible = onOff(showSeed);
            controls.SeedColumnLabel.Visible = onOff(showSeed);
            controls.SeedColumn.Visible = onOff(showSeed);
        end

        function controls = getSectionControls(app, sectionKey)
            switch string(sectionKey)
                case "enhancement"
                    controls = app.EnhancementControls;
                case "segmentation"
                    controls = app.SegmentationControls;
                case "transformation"
                    controls = app.TransformationControls;
                otherwise
                    error("MedicalImageToolbox:UnknownSection", ...
                        "Unknown processing section: %s", sectionKey);
            end
        end

        function onApplySection(app, sectionKey)
            try
                controls = app.getSectionControls(sectionKey);
                app.requireLoadedImage();
                imageInput = app.getImageForState(controls.Input.Value);
                imshow(imageInput, "Parent", controls.InputAxes);
                title(controls.InputAxes, ...
                    "Input state: " + string(controls.Input.Value));
                app.ModuleDropDown.Value = controls.ModuleName;
                app.OperationDropDown.Items = app.operationsForModule(controls.ModuleName);
                app.OperationDropDown.Value = controls.Operation.Value;
                app.InputStateDropDown.Value = controls.Input.Value;
                app.MaskSourceDropDown.Value = controls.MaskSource.Value;
                app.Parameter1Field.Value = controls.ParameterFields{1}.Value;
                app.Parameter2Field.Value = controls.ParameterFields{2}.Value;
                app.Parameter3Field.Value = controls.ParameterFields{3}.Value;
                app.SeedRowField.Value = controls.SeedRow.Value;
                app.SeedColumnField.Value = controls.SeedColumn.Value;
                app.InterpolationDropDown.Value = controls.Interpolation.Value;
                app.StructuringElementDropDown.Value = controls.StructuringElement.Value;
                app.LowerBoundsField.Value = controls.LowerBounds.Value;
                app.UpperBoundsField.Value = controls.UpperBounds.Value;
                app.AffineMatrixField.Value = controls.Affine.Value;
                result = app.applySelectedOperation();
                imshow(result, "Parent", controls.OutputAxes);
                title(controls.OutputAxes, ...
                    "Result: " + string(controls.Operation.Value));
                controls.Status.Value = "Applied " + string(controls.Operation.Value) + ...
                    " using " + string(controls.Input.Value) + " input.";
                app.updateSectionResultViews(sectionKey, imageInput, result);
            catch exception
                app.showError("Processing failed", exception);
            end
        end

        function updateSectionResultViews(app, sectionKey, inputImage, outputImage)
            controls = app.getSectionControls(sectionKey);
            if sectionKey == "enhancement"
                cla(controls.HistogramAxes);
                hold(controls.HistogramAxes, "on");
                histogram(controls.HistogramAxes, toGrayUnitDouble(inputImage), ...
                    64, "DisplayStyle", "stairs", "DisplayName", "Input");
                histogram(controls.HistogramAxes, toGrayUnitDouble(outputImage), ...
                    64, "DisplayStyle", "stairs", "DisplayName", "Output");
                hold(controls.HistogramAxes, "off");
                legend(controls.HistogramAxes, "show");
                title(controls.HistogramAxes, "Input and output histogram");
            elseif sectionKey == "transformation"
                controls.DimensionsArea.Value = [ ...
                    "Input dimensions: " + mat2str(size(inputImage)); ...
                    "Output dimensions: " + mat2str(size(outputImage)); ...
                    "Mask interpolation: nearest-neighbor when a mask is transformed."];
            end
        end

        function onResetSection(app, sectionKey)
            try
                app.requireLoadedImage();
                controls = app.getSectionControls(sectionKey);
                switch string(sectionKey)
                    case "enhancement"
                        app.State.EnhancedImage = [];
                        outputState = "enhanced";
                    case "segmentation"
                        app.State.ClassicalSegmentationMask = [];
                        outputState = "classicalmask";
                    case "transformation"
                        app.State.TransformedImage = [];
                        outputState = "transformed";
                end
                app.State.ProcessingHistory = app.State.ProcessingHistory( ...
                    ~strcmp({app.State.ProcessingHistory.OutputState}, outputState));
                app.LastResult = app.State.OriginalImage;
                app.updateDisplays();
                cla(controls.OutputAxes);
                title(controls.OutputAxes, "Operation output");
                controls.Status.Value = ...
                    "This section was reset; other workflow states were preserved.";
                if sectionKey == "enhancement"
                    cla(controls.HistogramAxes);
                elseif sectionKey == "transformation"
                    controls.DimensionsArea.Value = ...
                        "Input/output dimensions appear here.";
                end
            catch exception
                app.showError("Reset failed", exception);
            end
        end

        function [label, field] = addNumericControl(app, parent, labelText, row, value, propertyName)
            label = app.addLabel(parent, labelText, row);
            field = uieditfield(parent, "numeric", "Value", value);
            field.Layout.Row = row;
            field.Layout.Column = 2;
            app.(propertyName) = field;
        end

        function label = addLabel(~, parent, text, row)
            label = uilabel(parent, "Text", text);
            label.Layout.Row = row;
        end

        function choices = operationsForModule(~, module)
            switch string(module)
                case "Image Enhancement"
                    choices = ["Histogram equalization", "Histogram matching", ...
                        "Brightness", "Contrast", "Gamma transform", ...
                        "Mean filter", "Median filter", "Laplacian sharpen", ...
                        "High-pass sharpen", "Fourier low-pass", ...
                        "Fourier high-pass", "Fourier band-pass"];
                case "Segmentation and Edges"
                    choices = ["Sobel edges", "Prewitt edges", "Canny edges", ...
                        "Otsu threshold", "Region growing", "RGB segmentation", ...
                        "HSV segmentation", "Dilation", "Erosion", "Opening", ...
                        "Closing", "Shape-based segmentation"];
                otherwise
                    choices = ["Translation", "Scaling", "Rotation", ...
                        "Affine transform", "Forward mapping", "Inverse mapping", ...
                        "Resize nearest", "Resize bilinear", "Resize bicubic", ...
                        "Radial distortion", "Radial correction"];
            end
        end

        function updateOperationChoices(app)
            app.OperationDropDown.Items = ...
                app.operationsForModule(app.ModuleDropDown.Value);
            app.OperationDropDown.Value = app.OperationDropDown.Items(1);
            app.updateOperationMetadata();
        end

        function updateOperationMetadata(app)
            if isempty(app.OperationDropDown) || isempty(app.Parameter1Field)
                return
            end
            metadata = app.operationMetadata( ...
                app.ModuleDropDown.Value, app.OperationDropDown.Value);
            app.setParameterControl(1, metadata.P1Label, metadata.P1Help, ...
                metadata.ShowP1, metadata.P1Default);
            app.setParameterControl(2, metadata.P2Label, metadata.P2Help, ...
                metadata.ShowP2, metadata.P2Default);
            app.setParameterControl(3, metadata.P3Label, metadata.P3Help, ...
                metadata.ShowP3, metadata.P3Default);
            app.setVisible(app.SeedRowLabel, app.SeedRowField, metadata.ShowSeed);
            app.setVisible(app.SeedColumnLabel, app.SeedColumnField, metadata.ShowSeed);
            app.setVisible(app.InterpolationLabel, app.InterpolationDropDown, ...
                metadata.ShowInterpolation);
            app.setVisible(app.StructuringElementLabel, ...
                app.StructuringElementDropDown, metadata.ShowStructuringElement);
            app.setVisible(app.LowerBoundsLabel, app.LowerBoundsField, ...
                metadata.ShowColorBounds);
            app.setVisible(app.UpperBoundsLabel, app.UpperBoundsField, ...
                metadata.ShowColorBounds);
            app.setVisible(app.AffineMatrixLabel, app.AffineMatrixField, ...
                metadata.ShowAffineMatrix);
            app.setVisible(app.MaskSourceLabel, app.MaskSourceDropDown, ...
                metadata.IsMaskOperation);
            app.ParameterDescriptionArea.Value = metadata.Description;
        end

        function setParameterControl(app, index, labelText, helpText, visible, defaultValue)
            label = app.(char("Parameter" + index + "Label"));
            field = app.(char("Parameter" + index + "Field"));
            label.Text = labelText;
            label.Tooltip = helpText;
            field.Tooltip = helpText;
            field.Value = defaultValue;
            app.setVisible(label, field, visible);
        end

        function setVisible(~, label, field, visible)
            if visible
                label.Visible = "on";
                field.Visible = "on";
            else
                label.Visible = "off";
                field.Visible = "off";
            end
        end

        function metadata = operationMetadata(~, module, operation)
            metadata = struct( ...
                "P1Label", "Not applicable", "P2Label", "Not applicable", ...
                "P3Label", "Not applicable", "P1Help", "", "P2Help", "", ...
                "P3Help", "", "P1Default", 0.1, "P2Default", 0.2, ...
                "P3Default", 0, "ShowP1", false, "ShowP2", false, ...
                "ShowP3", false, "ShowSeed", false, ...
                "ShowInterpolation", false, "ShowStructuringElement", false, ...
                "ShowColorBounds", false, "ShowAffineMatrix", false, ...
                "IsMaskOperation", false, "Description", ...
                "No manual parameters are required.");
            operation = string(operation);
            module = string(module);
            switch operation
                case "Brightness"
                    metadata = defineParameter(metadata, 1, "Brightness offset", ...
                        "Additive intensity offset in normalized units [-1,1].", 0);
                    metadata.Description = "Brightness offset controls the intensity shift.";
                case "Contrast"
                    metadata = defineParameter(metadata, 1, "Contrast factor", ...
                        "Nonnegative multiplier around mid-gray; 1 leaves contrast unchanged.", 1);
                    metadata.Description = "Contrast factor controls the intensity spread.";
                case "Gamma transform"
                    metadata = defineParameter(metadata, 1, "Gamma", ...
                        "Positive exponent for the gamma gray-level transform.", 1);
                    metadata.Description = "Gamma must be positive.";
                case {"Mean filter", "Median filter"}
                    filterName = "mean";
                    if operation == "Median filter"
                        filterName = "median";
                    end
                    metadata = defineParameter(metadata, 1, "Kernel size", ...
                        "Positive integer width of the square filter neighborhood.", ...
                        3);
                    metadata.Description = filterName + " filter neighborhood size.";
                case {"Laplacian sharpen", "High-pass sharpen"}
                    metadata = defineParameter(metadata, 1, "Sharpening amount", ...
                        "Nonnegative multiplier for the sharpening response.", ...
                        1);
                    metadata.Description = "Controls sharpening strength.";
                case {"Fourier low-pass", "Fourier high-pass"}
                    metadata = defineParameter(metadata, 1, "Cutoff frequency", ...
                        "Cutoff in cycles per pixel.", 0.1);
                    metadata.Description = "Frequency cutoff in cycles per pixel.";
                case "Fourier band-pass"
                    metadata = defineParameter(metadata, 1, "Low cutoff", ...
                        "Lower cutoff in cycles per pixel; must be below the high cutoff.", ...
                        0.05);
                    metadata = defineParameter(metadata, 2, "High cutoff", ...
                        "Upper cutoff in cycles per pixel.", 0.2);
                    metadata.Description = "Lower frequency cutoff must be below the upper cutoff.";
                case {"Sobel edges", "Prewitt edges"}
                    metadata = defineParameter(metadata, 1, "Threshold", ...
                        "Edge magnitude threshold in [0,1].", ...
                        0.1);
                    metadata.Description = "Threshold for the selected edge detector.";
                case "Canny edges"
                    metadata = defineParameter(metadata, 2, "Gaussian sigma", ...
                        "Standard deviation of Canny smoothing in pixels.", 1);
                    metadata.Description = ...
                        "Canny chooses thresholds automatically; sigma controls smoothing.";
                case "Otsu threshold"
                    metadata.Description = ...
                        "Threshold is calculated automatically by Otsu; no manual threshold is required.";
                case "Region growing"
                    metadata = defineParameter(metadata, 1, "Intensity tolerance", ...
                        "Absolute intensity difference allowed from the seed in [0,1].", ...
                        0.1);
                    metadata.ShowSeed = true;
                    metadata.Description = ...
                        "Seed coordinates are row and column indices in the selected image.";
                case {"RGB segmentation", "HSV segmentation"}
                    metadata.ShowColorBounds = true;
                    metadata.Description = ...
                        "Enter lower and upper three-channel bounds in [0,1].";
                case {"Dilation", "Erosion", "Opening", "Closing"}
                    metadata = defineParameter(metadata, 1, "Structuring element size", ...
                        "Positive integer radius/size used by the selected morphology.", ...
                        1);
                    metadata.ShowStructuringElement = true;
                    metadata.IsMaskOperation = true;
                    metadata.Description = ...
                        "Select the mask source explicitly; the image input selection is unchanged.";
                case "Shape-based segmentation"
                    metadata = defineParameter(metadata, 1, "Minimum area", ...
                        "Minimum connected-component area in pixels.", ...
                        0);
                    metadata = defineParameter(metadata, 2, "Maximum area", ...
                        "Maximum connected-component area in pixels.", 1000000);
                    metadata = defineParameter(metadata, 3, "Minimum circularity", ...
                        "Minimum component circularity in [0,1].", 0);
                    metadata.IsMaskOperation = true;
                    metadata.Description = ...
                        "Filters the explicitly selected mask source by component area and circularity.";
                case "Translation"
                    metadata = defineParameter(metadata, 1, "X offset (pixels)", ...
                        "Horizontal displacement; positive values move right.", ...
                        0);
                    metadata = defineParameter(metadata, 2, "Y offset (pixels)", ...
                        "Vertical displacement; positive values move down.", ...
                        0);
                    metadata.Description = "Horizontal and vertical image translation.";
                case "Scaling"
                    metadata = defineParameter(metadata, 1, "Scale factor", ...
                        "Finite positive resizing multiplier.", ...
                        1);
                    metadata.ShowInterpolation = true;
                    metadata.Description = "Image scale multiplier.";
                case "Rotation"
                    metadata = defineParameter(metadata, 1, "Rotation angle (degrees)", ...
                        "Rotation about image center; positive angle is counterclockwise.", ...
                        0);
                    metadata.ShowInterpolation = true;
                    metadata.Description = "Image rotation angle.";
                case {"Affine transform", "Forward mapping", "Inverse mapping"}
                    metadata.ShowAffineMatrix = true;
                    metadata.ShowInterpolation = operation ~= "Forward mapping";
                    metadata.Description = ...
                        "Matrix maps source [x;y;1] coordinates to output coordinates.";
                case {"Resize nearest", "Resize bilinear", "Resize bicubic"}
                    metadata = defineParameter(metadata, 1, "Scale factor", ...
                        "Finite positive resizing multiplier.", ...
                        1);
                    metadata.Description = "Interpolation is specified by the selected resize operation.";
                case {"Radial distortion", "Radial correction"}
                    metadata = defineParameter(metadata, 1, "Radial coefficient k1", ...
                        "Distortion coefficient in [0,1].", ...
                        0.1);
                    metadata.ShowInterpolation = true;
                    metadata.Description = "Radial distortion model coefficient.";
                otherwise
                    metadata.Description = "Operation: " + operation + ...
                        " (no user-adjustable parameters).";
            end
            if module == "Segmentation and Edges" && ...
                    any(operation == ["Dilation", "Erosion", "Opening", ...
                    "Closing", "Shape-based segmentation"])
                metadata.IsMaskOperation = true;
            end
        end

        function validateOperationParameters(app, operation, p1, p2, p3, source)
            requireScalar(p1, "Parameter 1");
            requireScalar(p2, "Parameter 2");
            requireScalar(p3, "Parameter 3");
            switch string(operation)
                case "Brightness"
                    validateRange(p1, -1, 1, "Brightness offset");
                case "Contrast"
                    validateMinimum(p1, 0, "Contrast factor");
                case "Gamma transform"
                    validatePositive(p1, "Gamma");
                case {"Mean filter", "Median filter"}
                    validatePositiveInteger(p1, "Kernel size");
                case {"Laplacian sharpen", "High-pass sharpen"}
                    validateMinimum(p1, 0, "Sharpening amount");
                case {"Fourier low-pass", "Fourier high-pass"}
                    validateRange(p1, 0, sqrt(0.5), "Cutoff frequency");
                case "Fourier band-pass"
                    validateRange(p1, 0, sqrt(0.5), "Low cutoff");
                    validateRange(p2, 0, sqrt(0.5), "High cutoff");
                    if p1 >= p2
                        error("MedicalImageToolbox:BandCutoff", ...
                            "Low cutoff must be below high cutoff.");
                    end
                case {"Sobel edges", "Prewitt edges"}
                    validateRange(p1, 0, 1, "Edge threshold");
                case "Canny edges"
                    validatePositive(p2, "Canny sigma");
                case "Region growing"
                    validateRange(p1, 0, 1, "Region-growing tolerance");
                    validatePositiveInteger(app.SeedRowField.Value, "Seed row");
                    validatePositiveInteger(app.SeedColumnField.Value, "Seed column");
                    if app.SeedRowField.Value > size(source, 1) || ...
                            app.SeedColumnField.Value > size(source, 2)
                        error("MedicalImageToolbox:SeedBounds", ...
                            "Region-growing seed must lie inside the selected image.");
                    end
                case {"Dilation", "Erosion", "Opening", "Closing"}
                    validatePositiveInteger(p1, "Structuring-element size");
                case "Shape-based segmentation"
                    validateMinimum(p1, 0, "Minimum area");
                    validateMinimum(p2, 0, "Maximum area");
                    validateRange(p3, 0, 1, "Minimum circularity");
                    if p2 < p1
                        error("MedicalImageToolbox:ShapeAreaRange", ...
                            "Maximum area must be at least minimum area.");
                    end
                case "Scaling"
                    validatePositive(p1, "Scale factor");
                case {"Radial distortion", "Radial correction"}
                    validateRange(p1, 0, 1, "Radial coefficient");
            end
        end

        function [mask, stateName] = getSelectedMaskSource(app)
            switch string(app.MaskSourceDropDown.Value)
                case "Classical mask"
                    stateName = "classicalmask";
                case "AI prediction"
                    stateName = "aipredictedmask";
                case "Ground truth mask"
                    stateName = "groundtruthmask";
                otherwise
                    error("MedicalImageToolbox:MaskSource", ...
                        "Select a supported binary mask source.");
            end
            mask = app.State.(app.maskStateField(stateName));
            if isempty(mask)
                error("MedicalImageToolbox:MissingMaskSource", ...
                    "The selected %s is not available.", ...
                    app.maskSourceLabel(stateName));
            end
        end

        function fieldName = maskStateField(~, stateName)
            switch string(stateName)
                case "classicalmask"
                    fieldName = "ClassicalSegmentationMask";
                case "aipredictedmask"
                    fieldName = "AIPredictedMask";
                case "groundtruthmask"
                    fieldName = "GroundTruthMask";
                otherwise
                    error("MedicalImageToolbox:MaskSource", ...
                        "Unsupported binary mask source.");
            end
        end

        function label = maskSourceLabel(~, stateName)
            switch string(stateName)
                case "classicalmask"
                    label = "Classical mask";
                case "aipredictedmask"
                    label = "AI prediction";
                case "groundtruthmask"
                    label = "Ground truth mask";
                otherwise
                    label = string(stateName);
            end
        end

        function updateInputStateStatus(app)
            if isempty(app.State)
                app.StatusArea.Value = ...
                    "Selected image input: " + app.InputStateDropDown.Value;
            else
                app.StatusArea.Value = "Image input selection: " + ...
                    app.InputStateDropDown.Value + ...
                    " (applies to image operations; AI always uses Original MRI).";
            end
        end

        function updateMaskSourceStatus(app)
            app.StatusArea.Value = "Mask source selection: " + ...
                app.MaskSourceDropDown.Value + ...
                " (used only by morphology and shape-based filtering).";
        end

        function [result, outputState, parameters] = ...
                applyEnhancement(~, operation, source, p1, p2, originalImage)
            parameters = struct("parameter1", p1, "parameter2", p2);
            outputState = "enhanced";
            switch operation
                case "Histogram equalization"
                    result = histogramEqualization(source);
                case "Histogram matching"
                    if ndims(source) == 3
                        reference = originalImage;
                    else
                        reference = toGrayUnitDouble(originalImage);
                    end
                    result = histogramMatching(source, reference);
                    parameters.reference = "original image";
                case "Brightness"
                    result = adjustBrightness(source, p1);
                case "Contrast"
                    result = adjustContrast(source, p1);
                case "Gamma transform"
                    result = grayLevelTransform(source, "gamma", max(p1, eps));
                case "Mean filter"
                    result = meanFilter(source, max(1, round(p1)));
                case "Median filter"
                    result = medianFilter(source, max(1, round(p1)));
                case "Laplacian sharpen"
                    result = laplacianFilter(source, p1);
                case "High-pass sharpen"
                    result = highPassFilter(source, p1);
                case "Fourier low-pass"
                    result = fourierLowPass(source, p1);
                case "Fourier high-pass"
                    result = fourierHighPass(source, p1);
                case "Fourier band-pass"
                    result = fourierBandPass(source, [p1 p2]);
                otherwise
                    error("MedicalImageToolbox:UnknownOperation", ...
                        "Unsupported enhancement operation: %s", operation);
            end
        end

        function [result, outputState, parameters] = ...
                applySegmentation(app, operation, source, p1, p2, p3, inputName)
            parameters = struct("parameter1", p1, "parameter2", p2);
            outputState = "classicalMask";
            switch operation
                case "Sobel edges"
                    result = sobelEdge(source, p1);
                case "Prewitt edges"
                    result = prewittEdge(source, p1);
                case "Canny edges"
                    result = cannyEdge(source, [], max(p2, eps));
                case "Otsu threshold"
                    [result, parameters.threshold] = otsuSegmentation(source);
                case "Region growing"
                    seed = [round(app.SeedRowField.Value), ...
                        round(app.SeedColumnField.Value)];
                    result = regionGrowing(source, seed, p1, 8);
                    parameters.seedRowColumn = seed;
                    parameters.connectivity = 8;
                case "RGB segmentation"
                    result = rgbSegmentation(source, ...
                        app.parseBounds(app.LowerBoundsField.Value), ...
                        app.parseBounds(app.UpperBoundsField.Value));
                case "HSV segmentation"
                    result = hsvSegmentation(source, ...
                        app.parseBounds(app.LowerBoundsField.Value), ...
                        app.parseBounds(app.UpperBoundsField.Value));
                case {"Dilation", "Erosion", "Opening", "Closing"}
                    shape = app.StructuringElementDropDown.Value;
                    radius = max(1, round(p1));
                    switch operation
                        case "Dilation"
                            result = morphologicalDilation(source, shape, radius);
                        case "Erosion"
                            result = morphologicalErosion(source, shape, radius);
                        case "Opening"
                            result = morphologicalOpening(source, shape, radius);
                        otherwise
                            result = morphologicalClosing(source, shape, radius);
                    end
                    parameters.shape = shape;
                    parameters.radius = radius;
                case "Shape-based segmentation"
                    [result, components] = shapeBasedSegmentation( ...
                        source, max(0, round(p1)), max(round(p2), round(p1)), ...
                        min(max(p3, 0), 1));
                    parameters.componentCount = numel(components);
                otherwise
                    error("MedicalImageToolbox:UnknownOperation", ...
                        "Unsupported segmentation operation: %s", operation);
            end
            parameters.inputState = inputName;
        end

        function [result, outputState, parameters, alignedMask] = ...
                applyGeometry(app, operation, source, p1, p2, interpolation)
            outputState = "transformed";
            parameters = struct("parameter1", p1, "parameter2", p2, ...
                "interpolation", interpolation);
            matrix = eye(3);
            if any(operation == ["Affine transform", "Forward mapping", "Inverse mapping"])
                matrix = app.parseAffineMatrix(app.AffineMatrixField.Value);
            end
            alignedMask = [];
            switch operation
                case "Translation"
                    result = translateImage(source, round(p1), round(p2), interpolation);
                case "Scaling"
                    result = scaleImage(source, max(p1, eps), interpolation);
                case "Rotation"
                    result = rotateImage(source, p1, interpolation);
                case "Affine transform"
                    result = affineTransform(source, matrix, interpolation);
                case "Forward mapping"
                    result = forwardMapping(source, matrix, size(source, 1:2));
                case "Inverse mapping"
                    result = inverseMapping(source, matrix, size(source, 1:2), interpolation);
                case {"Resize nearest", "Resize bilinear", "Resize bicubic"}
                    factor = max(p1, eps);
                    outputSize = max(1, round(size(source, 1:2) .* factor));
                    method = lower(extractAfter(operation, "Resize "));
                    result = resizeImage(source, outputSize, method);
                    parameters.outputSize = outputSize;
                case "Radial distortion"
                    result = simulateRadialDistortion(source, p1, [], interpolation);
                case "Radial correction"
                    result = radialDistortionCorrection(source, p1, [], interpolation);
                otherwise
                    error("MedicalImageToolbox:UnknownOperation", ...
                        "Unsupported geometric operation: %s", operation);
            end
            parameters.affineMatrix = matrix;
            mask = app.State.ClassicalSegmentationMask;
            if ~isempty(mask) && isequal(size(mask), size(source, 1:2))
                alignedMask = app.transformClassicalMask( ...
                    operation, mask, p1, p2, matrix);
                parameters.maskInterpolation = "nearest";
            end
        end

        function result = transformClassicalMask(~, operation, mask, p1, p2, matrix)
            switch operation
                case "Translation"
                    result = translateImage(mask, round(p1), round(p2), "nearest");
                case "Scaling"
                    result = scaleImage(mask, max(p1, eps), "nearest");
                case "Rotation"
                    result = rotateImage(mask, p1, "nearest");
                case "Affine transform"
                    result = affineTransform(mask, matrix, "nearest");
                case "Forward mapping"
                    result = forwardMapping(mask, matrix, size(mask, 1:2));
                case "Inverse mapping"
                    result = inverseMapping(mask, matrix, size(mask, 1:2), "nearest");
                case {"Resize nearest", "Resize bilinear", "Resize bicubic"}
                    factor = max(p1, eps);
                    outputSize = max(1, round(size(mask, 1:2) .* factor));
                    result = resizeImage(mask, outputSize, "nearest");
                case "Radial distortion"
                    result = simulateRadialDistortion(mask, p1, [], "nearest");
                case "Radial correction"
                    result = radialDistortionCorrection(mask, p1, [], "nearest");
                otherwise
                    error("MedicalImageToolbox:UnknownOperation", ...
                        "Unsupported geometric operation: %s", operation);
            end
            result = result >= 0.5;
        end

        function bounds = parseBounds(~, value)
            values = sscanf(strrep(char(value), ",", " "), "%f");
            if numel(values) ~= 3
                error("MedicalImageToolbox:ColorBounds", ...
                    "Enter exactly three comma-separated color bounds.");
            end
            bounds = reshape(values, 1, 3);
        end

        function matrix = parseAffineMatrix(~, value)
            values = sscanf(strrep(strrep(char(value), ",", " "), ";", " "), "%f");
            if numel(values) ~= 9
                error("MedicalImageToolbox:TransformMatrix", ...
                    "Enter nine affine values separated by commas and semicolons.");
            end
            matrix = reshape(values, 3, 3).';
        end

        function requireLoadedImage(app)
            if isempty(app.State) || isempty(app.State.OriginalImage)
                error("MedicalImageToolbox:NoImageLoaded", ...
                    "Load an MRI image before processing.");
            end
        end

        function image = getImageForState(app, stateName)
            [image, app.State] = selectImageState(app.State, stateName);
        end

        function image = getDisplayImageForState(app, stateName)
            switch string(stateName)
                case "enhanced"
                    image = app.State.EnhancedImage;
                case "transformed"
                    image = app.State.TransformedImage;
                otherwise
                    image = app.State.OriginalImage;
            end
            if isempty(image)
                image = app.State.OriginalImage;
            end
        end

        function updateDisplays(app)
            if isempty(app.State)
                return
            end
            original = app.State.OriginalImage;
            imshow(original, "Parent", app.OriginalAxes);
            cla(app.ClassicalAxes);
            if ~isempty(app.State.EnhancedImage)
                imshow(app.State.EnhancedImage, "Parent", app.ClassicalAxes);
                title(app.ClassicalAxes, "Enhanced image");
            elseif ~isempty(app.State.TransformedImage)
                imshow(app.State.TransformedImage, "Parent", app.ClassicalAxes);
                title(app.ClassicalAxes, "Transformed image");
            else
                title(app.ClassicalAxes, "Enhanced / transformed");
            end
            cla(app.ClassicalMaskAxes);
            if ~isempty(app.State.ClassicalSegmentationMask)
                imshow(app.State.ClassicalSegmentationMask, ...
                    "Parent", app.ClassicalMaskAxes);
                title(app.ClassicalMaskAxes, "Classical mask / edges");
            else
                title(app.ClassicalMaskAxes, "Classical mask / edges");
            end
            cla(app.AIPredictionAxes);
            cla(app.AIOverlayAxes);
            cla(app.AIProbabilityAxes);
            if ~isempty(app.State.AIPredictedMask)
                imshow(app.colorizeMask(app.State.AIPredictedMask, [1 0 0]), ...
                    "Parent", app.AIPredictionAxes);
                title(app.AIPredictionAxes, "AI prediction (red)");
                imshow(app.makeOverlay(original, app.State.AIPredictedMask), ...
                    "Parent", app.AIOverlayAxes);
                title(app.AIOverlayAxes, "AI prediction overlay");
            else
                title(app.AIPredictionAxes, "AI prediction mask");
                title(app.AIOverlayAxes, "AI prediction overlay");
            end
            if ~isempty(app.State.AIProbabilityMap)
                imshow(app.State.AIProbabilityMap, [], ...
                    "Parent", app.AIProbabilityAxes);
                title(app.AIProbabilityAxes, "AI probability map");
            else
                title(app.AIProbabilityAxes, "AI probability map");
            end
            cla(app.GroundTruthAxes);
            if ~isempty(app.State.GroundTruthMask)
                imshow(app.colorizeMask(app.State.GroundTruthMask, [0 1 1]), ...
                    "Parent", app.GroundTruthAxes);
                title(app.GroundTruthAxes, "Ground truth (cyan)");
            else
                title(app.GroundTruthAxes, "Ground-truth mask");
            end
            cla(app.OverlapAxes);
            if ~isempty(app.State.GroundTruthMask) && ...
                    ~isempty(app.State.AIPredictedMask)
                metrics = evaluateSegmentationMasks( ...
                    app.State.GroundTruthMask, app.State.AIPredictedMask);
                overlap = createSegmentationOverlap(app.State.GroundTruthMask, ...
                    app.State.AIPredictedMask);
                imshow(overlap, "Parent", app.OverlapAxes);
                title(app.OverlapAxes, "Overlap: TP green / FP red / FN blue");
                app.EvaluationMetricsArea.Value = app.formatMetrics(metrics);
                app.EvaluationSummaryArea.Value = app.formatMetrics(metrics);
            else
                title(app.OverlapAxes, "Ground truth vs AI");
                app.EvaluationMetricsArea.Value = [ ...
                    "Load ground truth and run AI to calculate pixel metrics."; ...
                    "Green TP | Red FP | Blue FN"; ...
                    "Educational comparison only; not clinical validation."];
                app.EvaluationSummaryArea.Value = [ ...
                    "Load ground truth and run AI to calculate metrics."; ...
                    "Pixel-level comparison; not clinical validation."];
            end
            app.plotHistogram(app.OriginalHistogramAxes, original, "Original histogram");
            if ~isempty(app.State.EnhancedImage)
                histogramImage = app.State.EnhancedImage;
            elseif ~isempty(app.State.TransformedImage)
                histogramImage = app.State.TransformedImage;
            else
                histogramImage = original;
            end
            app.plotHistogram(app.EnhancedHistogramAxes, histogramImage, ...
                "Processed histogram");
            app.updateSectionDisplays(original);
            drawnow limitrate;
        end

        function updateSectionDisplays(app, original)
            if ~isempty(app.EnhancementControls)
                inputImage = app.getDisplayImageForState( ...
                    app.EnhancementControls.Input.Value);
                imshow(inputImage, "Parent", app.EnhancementControls.InputAxes);
                title(app.EnhancementControls.InputAxes, "Selected image input");
                if ~isempty(app.State.EnhancedImage)
                    imshow(app.State.EnhancedImage, ...
                        "Parent", app.EnhancementControls.OutputAxes);
                    title(app.EnhancementControls.OutputAxes, "Enhanced image state");
                else
                    cla(app.EnhancementControls.OutputAxes);
                    title(app.EnhancementControls.OutputAxes, "Enhanced image state");
                end
                cla(app.EnhancementControls.HistogramAxes);
                hold(app.EnhancementControls.HistogramAxes, "on");
                histogram(app.EnhancementControls.HistogramAxes, ...
                    toGrayUnitDouble(inputImage), 64, ...
                    "DisplayStyle", "stairs", "DisplayName", "Input");
                if ~isempty(app.State.EnhancedImage)
                    histogram(app.EnhancementControls.HistogramAxes, ...
                        toGrayUnitDouble(app.State.EnhancedImage), 64, ...
                        "DisplayStyle", "stairs", "DisplayName", "Enhanced");
                end
                hold(app.EnhancementControls.HistogramAxes, "off");
                legend(app.EnhancementControls.HistogramAxes, "show");
            end
            if ~isempty(app.SegmentationControls)
                imageInput = app.getDisplayImageForState( ...
                    app.SegmentationControls.Input.Value);
                imshow(imageInput, "Parent", app.SegmentationControls.InputAxes);
                title(app.SegmentationControls.InputAxes, "Selected image input");
                if ~isempty(app.State.ClassicalSegmentationMask)
                    imshow(app.State.ClassicalSegmentationMask, ...
                        "Parent", app.SegmentationControls.OutputAxes);
                    title(app.SegmentationControls.OutputAxes, ...
                        "Classical segmentation mask");
                else
                    cla(app.SegmentationControls.OutputAxes);
                    title(app.SegmentationControls.OutputAxes, ...
                        "Classical mask / edge map");
                end
            end
            if ~isempty(app.TransformationControls)
                inputImage = app.getDisplayImageForState( ...
                    app.TransformationControls.Input.Value);
                imshow(inputImage, "Parent", app.TransformationControls.InputAxes);
                title(app.TransformationControls.InputAxes, "Selected image input");
                if ~isempty(app.State.TransformedImage)
                    imshow(app.State.TransformedImage, ...
                        "Parent", app.TransformationControls.OutputAxes);
                    title(app.TransformationControls.OutputAxes, ...
                        "Transformed image state");
                else
                    cla(app.TransformationControls.OutputAxes);
                    title(app.TransformationControls.OutputAxes, ...
                        "Transformed image state");
                end
                app.TransformationControls.DimensionsArea.Value = [ ...
                    "Input dimensions: " + mat2str(size(inputImage)); ...
                    "Output dimensions: " + mat2str(size(app.State.TransformedImage))];
            end
            imshow(original, "Parent", app.AIInputAxes);
            if ~isempty(app.State.AIProbabilityMap)
                imshow(app.State.AIProbabilityMap, [], ...
                    "Parent", app.AISectionProbabilityAxes);
            else
                cla(app.AISectionProbabilityAxes);
            end
            if ~isempty(app.State.AIPredictedMask)
                imshow(app.State.AIPredictedMask, ...
                    "Parent", app.AISectionPredictionAxes);
            else
                cla(app.AISectionPredictionAxes);
            end
            if ~isempty(app.State.GroundTruthMask)
                imshow(app.State.GroundTruthMask, ...
                    "Parent", app.EvaluationGroundTruthAxes);
            else
                cla(app.EvaluationGroundTruthAxes);
            end
            if ~isempty(app.State.GroundTruthMask) && ...
                    ~isempty(app.State.AIPredictedMask)
                imshow(createSegmentationOverlap(app.State.GroundTruthMask, ...
                    app.State.AIPredictedMask), ...
                    "Parent", app.EvaluationOverlapAxes);
            else
                cla(app.EvaluationOverlapAxes);
            end
        end

        function plotHistogram(~, axesHandle, image, plotTitle)
            gray = toGrayUnitDouble(image);
            histogram(axesHandle, gray(:), 64, "FaceColor", [0.2 0.45 0.75]);
            title(axesHandle, plotTitle);
            xlabel(axesHandle, "Intensity");
            ylabel(axesHandle, "Pixels");
        end

        function overlay = makeOverlay(~, image, mask)
            if ismatrix(image)
                overlay = repmat(im2double(image), 1, 1, 3);
            else
                overlay = im2double(image(:, :, 1:3));
            end
            red = overlay(:, :, 1);
            red(mask) = 0.55 .* red(mask) + 0.45;
            overlay(:, :, 1) = red;
            green = overlay(:, :, 2);
            green(mask) = 0.55 .* green(mask);
            overlay(:, :, 2) = green;
            blue = overlay(:, :, 3);
            blue(mask) = 0.55 .* blue(mask);
            overlay(:, :, 3) = blue;
        end

        function colored = colorizeMask(~, mask, color)
            colored = zeros([size(mask) 3]);
            for channel = 1:3
                plane = colored(:, :, channel);
                plane(mask) = color(channel);
                colored(:, :, channel) = plane;
            end
        end

        function lines = formatMetrics(~, metrics)
            lines = [
                "Pixel-level comparison (not clinical validation)"
                "Dice: " + compose("%.4f", metrics.Dice)
                "IoU: " + compose("%.4f", metrics.IoU)
                "Precision: " + compose("%.4f", metrics.Precision)
                "Recall: " + compose("%.4f", metrics.Recall)
                "TP: " + string(metrics.TruePositive)
                "FP: " + string(metrics.FalsePositive)
                "FN: " + string(metrics.FalseNegative)];
        end

        function onLoadImage(app)
            [file, folder] = uigetfile( ...
                {"*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp", "Image files"});
            if isequal(file, 0)
                return
            end
            try
                app.loadImageData(imread(fullfile(folder, file)), file);
            catch exception
                app.showError("Image load failed", exception);
            end
        end

        function onLoadGroundTruth(app)
            if isempty(app.State)
                exception = MException("MedicalImageToolbox:NoImageLoaded", ...
                    "Load an MRI image before loading its ground-truth mask.");
                app.showError("Ground truth unavailable", exception);
                return
            end
            [file, folder] = uigetfile( ...
                {"*.png;*.tif;*.tiff;*.jpg;*.jpeg", "Ground-truth mask images"});
            if isequal(file, 0)
                return
            end
            try
                app.setGroundTruthMask(imread(fullfile(folder, file)), file);
            catch exception
                app.showError("Ground-truth mask load failed", exception);
            end
        end

        function onClearGroundTruth(app)
            try
                app.clearGroundTruthMask();
            catch exception
                app.showError("Ground-truth mask clear failed", exception);
            end
        end

        function onLoadModel(app)
            [file, folder] = uigetfile("*.onnx", "Select trained U-Net ONNX model");
            if isequal(file, 0)
                return
            end
            try
                app.setModelPath(fullfile(folder, file));
            catch exception
                app.showError("ONNX model unavailable", exception);
            end
        end

        function onApplyOperation(app)
            try
                app.applySelectedOperation();
            catch exception
                app.showError("Processing failed", exception);
            end
        end

        function onRunAI(app)
            try
                app.runAISegmentation();
            catch exception
                app.showError("AI inference failed", exception);
            end
        end

        function onReset(app)
            try
                app.resetImage();
            catch exception
                app.showError("Reset failed", exception);
            end
        end

        function onSaveResult(app)
            try
                app.saveCurrentResult();
            catch exception
                app.showError("Save failed", exception);
            end
        end

        function showError(app, titleText, exception)
            app.StatusArea.Value = ["Failed"; string(exception.message)];
            uialert(app.UIFigure, exception.message, titleText);
        end
    end

end

function metadata = defineParameter(metadata, index, label, helpText, defaultValue)
switch index
    case 1
        prefix = "P1";
    case 2
        prefix = "P2";
    case 3
        prefix = "P3";
    otherwise
        error("MedicalImageToolbox:ParameterIndex", ...
            "Parameter index must be 1, 2, or 3.");
end
metadata.(prefix + "Label") = string(label);
metadata.(prefix + "Help") = string(helpText);
metadata.(prefix + "Default") = defaultValue;
metadata.("ShowP" + index) = true;
end

function visibility = onOff(isVisible)
if isVisible
    visibility = "on";
else
    visibility = "off";
end
end

function requireScalar(value, parameterName)
if ~isnumeric(value) || ~isreal(value) || ~isscalar(value) || ~isfinite(value)
    error("MedicalImageToolbox:InvalidParameter", ...
        "%s must be a finite real scalar.", parameterName);
end
end

function validateRange(value, minimum, maximum, parameterName)
requireScalar(value, parameterName);
if value < minimum || value > maximum
    error("MedicalImageToolbox:ParameterRange", ...
        "%s must be in the range [%g, %g].", parameterName, minimum, maximum);
end
end

function validateMinimum(value, minimum, parameterName)
requireScalar(value, parameterName);
if value < minimum
    error("MedicalImageToolbox:ParameterMinimum", ...
        "%s must be greater than or equal to %g.", parameterName, minimum);
end
end

function validatePositive(value, parameterName)
requireScalar(value, parameterName);
if value <= 0
    error("MedicalImageToolbox:PositiveParameter", ...
        "%s must be greater than zero.", parameterName);
end
end

function validatePositiveInteger(value, parameterName)
requireScalar(value, parameterName);
if value < 1 || value ~= floor(value)
    error("MedicalImageToolbox:PositiveIntegerParameter", ...
        "%s must be a positive integer.", parameterName);
end
end
