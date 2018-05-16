function threshParams=selectThreshold(img)

format compact;
scrsz = get(0,'ScreenSize');
images_fig = figure(1);
set(images_fig,'Name','Original Image', 'Position',[10 scrsz(4)*.05 scrsz(3)*1/3 scrsz(4)*.9]);
set(images_fig,'MenuBar','none');

subplot(2,1,1)
image(img)
axis image

subplot(2,1,2)
image(img)
axis image

controls_fig = figure(2);

set(controls_fig,'Name','Controls', 'Position',[scrsz(3)*0.5 scrsz(4)*.5 200 250]);
set(controls_fig,'MenuBar','none');   %hide menu bars

fsize = get(controls_fig, 'Position');
slider_red = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.8, fsize(3)*0.8 , 25],...
              'value',1, 'min',-1, 'max',1);        
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.8 + 25 50 15],...
                'String','red');
          
slider_green = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.6, fsize(3)*0.8 , 25],...
              'value',-0.5, 'min',-1, 'max',1);       
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.6 + 25 50 15],...
                'String','green');
            
slider_blue = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.4, fsize(3)*0.8 , 25],...
              'value',-0.5, 'min',-1, 'max',1);
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.4 + 25 50 15],...
                'String','blue');
            
slider_threshold = uicontrol('Parent',controls_fig,'Style','slider','Position',[fsize(3)*0.1,fsize(4)*0.2, fsize(3)*0.8 , 25],...
              'value',40, 'min',0, 'max',100);
uicontrol('Parent',controls_fig,'Style','text','Position',[fsize(3)*0.4 fsize(4)*0.2 + 25 50 15],...
                'String','Threshold');
         
          
ok_button = uicontrol('Parent',controls_fig,'Style','pushbutton', 'String','Apply', ...
                        'Position',[fsize(3)*0.1,10, fsize(3)*0.8 ,25]);
          
slider_red.Callback = @updateThreshold;
slider_green.Callback = @updateThreshold;
slider_blue.Callback = @updateThreshold;
slider_threshold.Callback = @updateThreshold;
ok_button.Callback = @applyParams;

updateThreshold();

uiwait(images_fig);
          
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

    function applyParams(~, ~)
        threshParams = struct('colorCoefs', [slider_red.Value slider_green.Value slider_blue.Value], ...
                              'colorThreshold', slider_threshold.Value);

        uiresume(images_fig);

        close(images_fig);
        close(controls_fig);
    end
end