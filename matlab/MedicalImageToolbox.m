function MedicalImageToolbox
% MATLAB GUI prototype. Requires Image Processing Toolbox for classic operations.
% Run: addpath(fullfile(pwd,"matlab")); MedicalImageToolbox
API="http://localhost:8000"; original=[]; result=[];
f=uifigure("Name","Medical Image Analysis Toolbox","Position",[100 100 1150 700]);
g=uigridlayout(f,[3 4]); g.RowHeight={48,"1x",70}; g.ColumnWidth={"1x","1x",245,140}; g.Padding=[12 12 12 12];
h=uilabel(g,"Text","Medical Image Analysis for Tumor Detection Using Keras","FontSize",18,"FontWeight","bold"); h.Layout.Row=1; h.Layout.Column=[1 4];
a1=uiaxes(g); a1.Layout.Row=2; a1.Layout.Column=1; title(a1,"Original"); a1.XTick=[]; a1.YTick=[];
a2=uiaxes(g); a2.Layout.Row=2; a2.Layout.Column=2; title(a2,"Result"); a2.XTick=[]; a2.YTick=[];
p=uipanel(g,"Title","Controls"); p.Layout.Row=2; p.Layout.Column=3; c=uigridlayout(p,[8 1]); c.RowHeight={35,75,35,35,35,"1x",25,25}; c.Padding=[8 8 8 8];
b= uibutton(c,"Text","Load MRI","ButtonPushedFcn",@loadImage); b.Layout.Row=1;
dd = uidropdown(c, "Items", ["Enhancement - CLAHE", "Noise Reduction - Median", "Edge Detection - Canny", "Segmentation - Otsu", "Transformation - Rotate 15 deg", "Keras U-Net Segmentation (Docker)"], "Value", "Enhancement - CLAHE");
dd.Layout.Row = 2;
b=uibutton(c,"Text","Apply","ButtonPushedFcn",@apply); b.Layout.Row=3;
b=uibutton(c,"Text","Check Docker API","ButtonPushedFcn",@checkAPI); b.Layout.Row=4;
b=uibutton(c,"Text","Save Result","ButtonPushedFcn",@saveResult); b.Layout.Row=5;
status=uitextarea(c,"Editable","off","Value","Load an MRI image."); status.Layout.Row=6;
b=uibutton(c,"Text","Reset","ButtonPushedFcn",@reset); b.Layout.Row=7;
lbl2=uilabel(c,"Text","Research/education only"); lbl2.Layout.Row=8;
foot=uilabel(g,"Text","Predicted masks are not medical diagnoses. Validate model outputs and report limitations.","WordWrap","on"); foot.Layout.Row=3; foot.Layout.Column=[1 4];
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
                case "Keras U-Net Segmentation (Docker)", result=runKeras(I);
            end
            imshow(result,"Parent",a2); title(a2,dd.Value,"Interpreter","none");
            if ~contains(dd.Value,"Keras U-Net"),status.Value=["Applied: "+string(dd.Value); "Classical result is not tumor-specific."];end
        catch ME,status.Value=["Failed"; string(ME.message)];uialert(f,ME.message,"Operation error");end
    end
    function out=runKeras(I)
        health=webread(API+"/health",weboptions("Timeout",5));
        if ~strcmp(health.status,"ok"),error("Docker model unavailable. Check models/tumor_unet.keras and docker logs.");end
        if ndims(I)==2, rgb=repmat(I,1,1,3); elseif size(I,3)>=3,rgb=I(:,:,1:3);else,rgb=repmat(I(:,:,1),1,1,3);end
        rgb=im2uint8(rgb); small=imresize(rgb,[256 256],"bilinear");
        response=webwrite(API+"/predict",struct("image",double(small)),weboptions("MediaType","application/json","Timeout",120));
        m=logical(response.mask); m=imresize(m,[size(rgb,1),size(rgb,2)],"nearest");
        out=im2double(rgb); for k=1:3, ch=out(:,:,k); if k==1, overlayValue=1; else, overlayValue=0; end; ch(m)=.58*ch(m)+.42*overlayValue; out(:,:,k)=ch; end
        out=im2uint8(out); status.Value=["Keras segmentation complete"; "Threshold: "+string(response.threshold); "Prediction is not a diagnosis."];
    end
    function checkAPI(~,~)
        try
            h=webread(API+"/health",weboptions("Timeout",5)); status.Value=["API: "+string(h.status); "Model: "+string(h.model_path)];
            if ~strcmp(h.status,"ok"),uialert(f,"API is running but model is unavailable.","Model missing");end
        catch ME,status.Value=["API not reachable"; string(ME.message)];uialert(f,"Run docker compose up --build from project root.","Docker API unavailable");end
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
