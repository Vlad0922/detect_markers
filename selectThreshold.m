function threshParams=selectThreshold(reader)

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

set(controls_fig,'Name','Controls', 'Position',[scrsz(3)*0.5 scrsz(4)*.5 200 350]);
set(controls_fig,'MenuBar','none');   %hide menu bars

fsize = get(controls_fig, 'Position');

color_popup = uicontrol('Style', 'popupmenu', 'String', 'default red', ...
                        'Position', [fsize(3)*0.1,fsize(4)*0.8, fsize(3)*0.8 , 50]);
color_add_btn = uicontrol('Style', 'pushbutton', 'String', 'New color', ...
                        'Position', [fsize(3)*0.1,fsize(4)*0.75, 75 , 25]);
color_save_btn = uicontrol('Style', 'pushbutton', 'String', 'Save color', ...
                        'Position', [fsize(3)*0.1 + 85,fsize(4)*0.75, 75 , 25]);
                    
color_add_btn.Callback = @addNewColor;
color_popup.Callback = @changeColor;
color_save_btn.Callback = @saveColor;

slider_red = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.6, fsize(3)*0.8 , 25],...
              'value',1, 'min',-1, 'max',1);        
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.6 + 25 50 15],...
                'String','red');
          
slider_green = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.45, fsize(3)*0.8 , 25],...
              'value',-0.5, 'min',-1, 'max',1);       
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.45 + 25 50 15],...
                'String','green');
            
slider_blue = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.3, fsize(3)*0.8 , 25],...
              'value',-0.5, 'min',-1, 'max',1);
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.3 + 25 50 15],...
                'String','blue');
            
slider_threshold = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.15, fsize(3)*0.8 , 25],...
              'value',40, 'min',0, 'max',100);
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.15 + 25 50 15],...
                'String','Threshold');
         
ok_button = uicontrol('Parent',controls_fig,'Style','pushbutton', 'String','Apply', ...
                        'Position',[fsize(3)*0.1,10, fsize(3)*0.8 ,25]);
          
slider_red.Callback = @updateThreshold;
slider_green.Callback = @updateThreshold;
slider_blue.Callback = @updateThreshold;
slider_threshold.Callback = @updateThreshold;
ok_button.Callback = @applyParams;

updateImages();

threshParams{1} = getDefaultColorParams();

uiwait(images_fig);

    function updateImages(~, ~)
        reader.CurrentTime = slider_video.Value;
        img = readFrame(reader);
        
        figure(1);
        subplot(2,1,1);
        image(img);
        axis image;
        
        updateThreshold();
    end
          
    function updateThreshold(~, ~)        
        r = double(img(:,:,1));
        g = double(img(:,:,2));
        b = double(img(:,:,3));

        mask = (slider_red.Value*r + slider_green.Value*g + slider_blue.Value*b) > slider_threshold.Value;      
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;

        figure(1);
        subplot(2,1,2)
        image(mask);
    end

    function addNewColor(~, ~)
        color_name = inputdlg('Enter new color name:');
        
        params = getDefaultColorParams();
        params.colorName = color_name{1};
        
        current_entries = cellstr(get(color_popup, 'String'));
        current_entries{end+1} = params.colorName;
        set(color_popup, 'String', current_entries);
        
        set(slider_red, 'Value', params.colorCoefs(1));
        set(slider_green, 'Value', params.colorCoefs(2));
        set(slider_blue, 'Value', params.colorCoefs(3));    
        set(slider_threshold, 'Value', params.colorThreshold);
        
        threshParams{end + 1} = params;
    end

    function changeColor(~, ~)
        idx = get(color_popup, 'Value');
        
        params = threshParams{idx};
        
        set(slider_red, 'Value', params.colorCoefs(1));
        set(slider_green, 'Value', params.colorCoefs(2));
        set(slider_blue, 'Value', params.colorCoefs(3));    
        set(slider_threshold, 'Value', params.colorThreshold);
        
        updateThreshold();
    end

    function saveColor(~, ~)
        idx = get(color_popup, 'Value');
        
        threshParams{idx}.colorCoefs(1) = slider_red.Value;
        threshParams{idx}.colorCoefs(2) = slider_green.Value;
        threshParams{idx}.colorCoefs(3) = slider_blue.Value;
        threshParams{idx}.colorCoefs(3) = slider_blue.Value;   
        threshParams{idx}.colorThreshold = slider_threshold.Value;
    end

    function applyParams(~, ~)
        uiresume(images_fig);

        close(images_fig);
        close(controls_fig);
    end

    function params=getDefaultColorParams()
        params = struct('colorCoefs', [slider_red.Value slider_green.Value slider_blue.Value], ...
                         'colorThreshold', slider_threshold.Value, ...
                         'colorName', 'default red');
    end
end