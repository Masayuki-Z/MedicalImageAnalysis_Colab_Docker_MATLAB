function MedicalImageToolbox
% Legacy classic-only GUI prototype. The current app is MedicalImageAnalysisApp.
% Requires Image Processing Toolbox. Run: addpath(fullfile(pwd,"matlab")); MedicalImageToolbox
original=[]; result=[];
f=uifigure("Name","Medical Image Analysis Toolbox (Legacy Prototype)","Position",[100 100 1150 700]);
g=uigridlayout(f,[3 4]); g.RowHeight={48,"1x",70}; g.ColumnWidth={"1x","1x",245,140}; g.Padding=[12 12 12 12];
h=uilabel(g,"Text","Medical Image Processing Toolbox (Legacy Prototype)","FontSize",18,"FontWeight","bold"); h.Layout.Row=1; h.Layout.Column=[1 4];
a1=uiaxes(g); a1.Layout.Row=2; a1.Layout.Column=1; title(a1,"Original"); a1.XTick=[]; a1.YTick=[];
a2=uiaxes(g); a2.Layout.Row=2; a2.Layout.Column=2; title(a2,"Result"); a2.XTick=[]; a2.YTick=[];
p=uipanel(g,"Title","Controls"); p.Layout.Row=2; p.Layout.Column=3; c=uigridlayout(p,[7 1]); c.RowHeight={35,75,35,35,"1x",25,25}; c.Padding=[8 8 8 8];
b= uibutton(c,"Text","Load MRI","ButtonPushedFcn",@loadImage); b.Layout.Row=1;
dd = uidropdown(c, "Items", ["Enhancement - CLAHE", "Noise Reduction - Median", "Edge Detection - Canny", "Segmentation - Otsu", "Transformation - Rotate 15 deg"], "Value", "Enhancement - CLAHE");
dd.Layout.Row = 2;
b=uibutton(c,"Text","Apply","ButtonPushedFcn",@apply); b.Layout.Row=3;
b=uibutton(c,"Text","Save Result","ButtonPushedFcn",@saveResult); b.Layout.Row=4;
status=uitextarea(c,"Editable","off","Value","Load an image."); status.Layout.Row=5;
b=uibutton(c,"Text","Reset","ButtonPushedFcn",@reset); b.Layout.Row=6;
lbl2=uilabel(c,"Text","Research/education only"); lbl2.Layout.Row=7;
foot=uilabel(g,"Text","Classical processing is for research/education and is not tumor-specific.","WordWrap","on"); foot.Layout.Row=3; foot.Layout.Column=[1 4];
    function loadImage(~,~)
        [file,path]=uigetfile({"*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp","Image files"});
        if isequal(file,0),return;end
        try, original=imread(fullfile(path,file)); result=original; imshow(original,"Parent",a1); imshow(result,"Parent",a2); status.Value="Loaded: "+string(file);
        catch ME,uialert(f,ME.message,"Load error");end
    end
    function apply(~,~)
        if isempty(original),uialert(f,"Load an image first.","No image");return;end
        try
            status.Value="Processing..."; drawnow; I=original; G=grayDouble(I);
            switch dd.Value
                case "Enhancement - CLAHE", result=adapthisteq(G);
                case "Noise Reduction - Median", result=medfilt2(G,[3 3]);
                case "Edge Detection - Canny", result=edge(G,"Canny");
                case "Segmentation - Otsu", result=imbinarize(G);
                case "Transformation - Rotate 15 deg", result=imrotate(I,15,"bilinear","crop");
            end
            imshow(result,"Parent",a2); title(a2,dd.Value,"Interpreter","none");
            status.Value=["Applied: "+string(dd.Value); "Classical result is not tumor-specific."];
        catch ME,status.Value=["Failed"; string(ME.message)];uialert(f,ME.message,"Operation error");end
    end
    function saveResult(~,~)
        if isempty(result),uialert(f,"No result to save.","No result");return;end
        [file,path]=uiputfile({"*.png","PNG";"*.jpg","JPEG";"*.tif","TIFF"},"Save result","processed_result.png");
        if isequal(file,0),return;end
        try,imwrite(result,fullfile(path,file));status.Value="Saved: "+string(fullfile(path,file));catch ME,uialert(f,ME.message,"Save error");end
    end
    function reset(~,~)
        if isempty(original),return;end; result=original; imshow(result,"Parent",a2);title(a2,"Original (Reset)");status.Value="Reset complete";
    end
end
function G = grayDouble(I)
if ndims(I) == 3 && size(I, 3) >= 2
    % Extract Channel 2 (FLAIR sequence) where the tumor abnormality is most visible
    G = I(:, :, 2);
elseif ndims(I) == 3
    % Fallback if only 1 or fewer channels are found
    G = I(:, :, 1);
else
    G = I;
end
G = im2double(G);
end
