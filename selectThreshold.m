function threshParams=selectThreshold(reader)

blobs = cell({});
frame = [];
img = [];

format compact;
scrsz = get(0,'ScreenSize');

images_fig = figure(1);

set(images_fig,'Name','Original Image', 'Position',[10 scrsz(4)*.05 scrsz(3)*1/3 scrsz(4)*.9]);
set(images_fig,'MenuBar','none');

imfig_size = get(images_fig, 'Position');

slider_video = uicontrol('Parent', images_fig, 'Style', 'slider', 'Position',...
                         [imfig_size(3)*0.1, imfig_size(4) - 50, imfig_size(3)*0.8 , 25],...
                           'value',0., 'min', 0., 'max', reader.Duration);  
uicontrol('Parent', images_fig, 'Style', 'text', 'Position',...
          [imfig_size(3)*0.5 imfig_size(4) - 25, 50 15], 'String','Video');
      
slider_video.Callback = @updateImages;

controls_fig = figure(2);

set(controls_fig,'Name','Controls', 'Position',[scrsz(3)*0.5 scrsz(4)*.5 200 400]);
set(controls_fig,'MenuBar','none');   %hide menu bars

fsize = get(controls_fig, 'Position');

color_popup = uicontrol('Style', 'popupmenu', 'String', 'default red', ...
                        'Position', [fsize(3)*0.1,fsize(4)*0.8, fsize(3)*0.8 , 50]);
color_add_btn = uicontrol('Style', 'pushbutton', 'String', 'New marker', ...
                        'Position', [fsize(3)*0.1,fsize(4)*0.8, 75 , 25]);
color_save_btn = uicontrol('Style', 'pushbutton', 'String', 'Save marker', ...
                        'Position', [fsize(3)*0.1 + 85,fsize(4)*0.8, 75 , 25]);
                    
color_add_btn.Callback = @addNewColor;
color_popup.Callback = @changeColor;
color_save_btn.Callback = @saveColor;

slider_red = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.65, fsize(3)*0.8 , 25],...
              'value',1, 'min',-1, 'max',1);        
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.65 + 25 50 15],...
                'String','red');
          
slider_green = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.525, fsize(3)*0.8 , 25],...
              'value',-0.5, 'min',-1, 'max',1);       
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.525 + 25 50 15],...
                'String','green');
            
slider_blue = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.4, fsize(3)*0.8 , 25],...
              'value',-0.5, 'min',-1, 'max',1);
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.4 + 25 50 15],...
                'String','blue');
            
slider_threshold = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.275, fsize(3)*0.8 , 25],...
              'value',40, 'min',0, 'max',100);
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.275 + 25 50 15],...
                'String','Threshold');

jRS = com.jidesoft.swing.RangeSlider;
[slider_size, handler_slider_size] = javacomponent(jRS,[], controls_fig);
% modify rangeslider position
set(handler_slider_size,'Position',[fsize(3)*0.1,fsize(4)*0.15, fsize(3)*0.8 , 25])
% modify range slider properties
set(slider_size,'Maximum',1500, 'Minimum',100,...
      'LowValue',200, 'HighValue',600,...
      'Name','Marker size',...
      'MajorTickSpacing',5,...
      'MinorTickSpacing',1, ...
      'PaintTicks',false,...
      'PaintLabels',false, ...
      'StateChangedCallback',@updateThreshold);
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.3 fsize(4)*0.15 + 25 100 15],...
                'String','Marker size');
            
ok_button = uicontrol('Parent',controls_fig,'Style','pushbutton', 'String','Apply', ...
                        'Position',[fsize(3)*0.1,10, fsize(3)*0.8 ,25]);
          
slider_red.Callback = @updateThreshold;
slider_green.Callback = @updateThreshold;
slider_blue.Callback = @updateThreshold;
slider_threshold.Callback = @updateThreshold;
ok_button.Callback = @applyParams;

threshParams{1} = getDefaultMarkerParams();
blobs{1} = createBlob(threshParams{1});

updateImages();

uiwait(images_fig);

    function updateImages(~, ~)
        reader.CurrentTime = slider_video.Value;
        frame = readFrame(reader);
        
        figure(1);
        subplot(2,1,1);
        image(frame);
        axis image;
        
        updateThreshold();
    end
          
    function updateThreshold(~, ~) 
        idx = get(color_popup, 'Value');
        
        r = double(frame(:,:,1));
        g = double(frame(:,:,2));
        b = double(frame(:,:,3));

        mask = (slider_red.Value*r + slider_green.Value*g + slider_blue.Value*b) > slider_threshold.Value;      
        
        mask = imopen(mask, strel('rectangle', [6, 6]));
        mask = imclose(mask, strel('rectangle', [50, 50]));
        mask = imfill(mask, 'holes');
        
        set(blobs{idx}, 'MinimumBlobArea', round(slider_size.LowValue));
        set(blobs{idx}, 'MaximumBlobArea', round(slider_size.HighValue));
       
        [~, ~, curr_bboxes] = blobs{idx}.step(mask);
        labels = cellstr(num2str((1:size(curr_bboxes, 1))'))';
        
        img =  insertObjectAnnotation(frame, 'rectangle', curr_bboxes, labels);
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;
        
        figure(1);
        
        subplot(2, 1, 1);
        image(img);        
        
        subplot(2,1,2)
        image(mask);
    end

    function addNewColor(~, ~)
        color_name = inputdlg('Enter new color name:');
        
        params = getDefaultMarkerParams();
        params.colorName = color_name{1};
        
        current_entries = cellstr(get(color_popup, 'String'));
        current_entries{end+1} = params.colorName;
        set(color_popup, 'String', current_entries);
          
        threshParams{end + 1} = params;
        blobs{end + 1} = createBlob(params);
        
        set(color_popup, 'Value', length(current_entries));
    end

    function changeColor(~, ~)
        idx = get(color_popup, 'Value');
        
        params = threshParams{idx};
        
        set(slider_red, 'Value', params.colorCoefs(1));
        set(slider_green, 'Value', params.colorCoefs(2));
        set(slider_blue, 'Value', params.colorCoefs(3));    
        set(slider_threshold, 'Value', params.colorThreshold);
        set(slider_size, 'LowValue', params.minBlobSize);
        set(slider_size, 'HighValue', params.maxBlobSize);
        
        updateThreshold();
    end

    function saveColor(~, ~)
        idx = get(color_popup, 'Value');
        
        threshParams{idx}.colorCoefs(1) = slider_red.Value;
        threshParams{idx}.colorCoefs(2) = slider_green.Value;
        threshParams{idx}.colorCoefs(3) = slider_blue.Value;
        threshParams{idx}.colorCoefs(3) = slider_blue.Value;   
        threshParams{idx}.colorThreshold = slider_threshold.Value;
        threshParams{idx}.minBlobSize = slider_size.LowValue;
        threshParams{idx}.maxBlobSize = slider_size.HighValue;
    end

    function applyParams(~, ~)
        uiresume(images_fig);

        close(images_fig);
        close(controls_fig);
    end

    function params=getDefaultMarkerParams()
        params = struct('colorCoefs', [slider_red.Value slider_green.Value slider_blue.Value], ...
                         'colorThreshold', slider_threshold.Value, ...
                         'colorName', 'default red', ...
                         'minBlobSize', 200, 'maxBlobSize', 600);
    end

    function blob=createBlob(params)
        blob = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
                                'AreaOutputPort', true, 'CentroidOutputPort', true, ...
                                'MinimumBlobArea', params.minBlobSize, ...
                                'MaximumBlobArea', params.maxBlobSize);
             
    end
end