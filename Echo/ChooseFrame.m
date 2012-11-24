function [rightFrame1 rightFrame2] = ChooseFrame(echo1, echo2)
%MEASURESEGMENT Display a GUI to let the user draw the ventricle contours.

%% echo
% Read the image file
tic;
movie1 = mmreader(echo1);
m1 = read(movie1);
toc

tic;
movie2= mmreader(echo2);
m2 = read(movie2);
toc

    function imageSlider(~, ~)
        fn = round(get(gui_imageslider,'Value'));
        if get(gui_offsetslider, 'Value')>(movie2.NumberOfFrames-fn-1)
            set(gui_offsetslider, 'Value', movie2.NumberOfFrames-fn-1);
        end
        if get(gui_offsetslider, 'Value')<(-fn+1)
            set(gui_offsetslider, 'Value', -fn+1);
        end
        set(gui_offsetslider, 'Max', movie2.NumberOfFrames-fn-1);
        set(gui_offsetslider, 'Min', -fn+1);
        os = round(get(gui_offsetslider,'Value'));
        rightFrame1 = m1(:,:,:,fn);
        rightFrame2 = m2(:,:,:,fn+os);
        subplot(1,2,1); imshow(rightFrame1, 'Border', 'tight');
        subplot(1,2,2); imshow(rightFrame2, 'Border', 'tight');
        set(gui_framenr, 'String', sprintf('Video 1: Frame %d   Video 2: Frame %d   (Offset: %d)', fn, fn+os, os));
    end


% Create the main window for the gui
gui_main = figure('Toolbar','none',...
          'Menubar', 'none',...
          'Name','PickAFrame',...
          'NumberTitle','off',...
          'IntegerHandle','off');
      
    function figResize(~,~)
        fpos = get(gui_main,'Position');
        %set(gui_panel, 'Position', [30 155 fpos(3)-30 fpos(4)-155]);
        set(gui_infovid1, 'Position', [(6*fpos(3)/20)-100 fpos(4)-30 200 30]);
        set(gui_infovid2, 'Position', [(15*fpos(3)/20)-100 fpos(4)-30 200 30]);
        set(gui_offsetslider, 'Position', [fpos(3)-300 0 200 28]);
        set(gui_offsetlabel, 'Position', [fpos(3)-400 0 100 28]);
        set(gui_imageslider, 'Position', [0 0 fpos(3)-400 28]);
        set(gui_continuebutton, 'Position', [fpos(3)-100 0 100 28]);
    end

% Add the scroll panel.
%gui_panel = imscrollpanel(gui_main, gui_image);

% Position the scroll panel to accommodate the other tools.
%set(gui_panel,'Units','pixels','Position',[30 155 fpos(3)-30 fpos(4)-155]);

%% Controls

gui_infovid1 = uicontrol(gui_main,...
    'Style', 'text', 'String', 'Long Axis View',...
    'Units', 'pixels', 'Position', [200 0 200 30],...
    'FontSize', 14, 'FontWeight', 'bold');

gui_infovid2 = uicontrol(gui_main,...
    'Style', 'text', 'String', 'Short Axis View',...
    'Units', 'pixels', 'Position', [200 0 200 30],...
    'FontSize', 14, 'FontWeight', 'bold');

gui_continuebutton = uicontrol(gui_main,...
    'Style', 'pushbutton', 'String', 'Continue',...
    'Units', 'pixels', 'Position', [0 800 100 28],...
    'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0 0 .4], 'ForegroundColor', 'w',...
    'Callback', @continueFunction);

% Create image slider
gui_imageslider = uicontrol(gui_main,...
    'Style', 'slider',...
    'Min', 1, 'Max', movie1.NumberOfFrames, 'SliderStep', [1/(movie1.NumberOfFrames-1) 1/(movie1.NumberOfFrames-1)], 'Value', 1,...
    'Units', 'pixels', 'Position', [0 0 870 28],...
    'BackgroundColor', [.1 .1 .1],...
    'Callback', @imageSlider...
    );

gui_offsetlabel = uicontrol(gui_main,...
    'Style', 'text', 'String', 'Offset: ',...
    'FontSize', 12,...
    'Units', 'pixels', 'Position', [0 0 870 28]);

gui_offsetslider = uicontrol(gui_main,...
    'Style', 'slider',...
    'Min', 0, 'Max', movie2.NumberOfFrames, 'SliderStep', [1/(movie2.NumberOfFrames-1) 1/(movie2.NumberOfFrames-1)], 'Value', 0,...
    'Units', 'pixels', 'Position', [0 0 870 28],...
    'BackgroundColor', [.1 0 0],...
    'Callback', @imageSlider...
    );

gui_framenr = uicontrol(gui_main,...
    'Style', 'text',...
    'String', 'Frame 0',...
    'Units', 'pixels', 'Position', [0 28 280 18],...
    'BackgroundColor', [.6 .6 .6]...
    );

    function continueFunction(~,~)
        close(gui_main);
    end

set(gui_main, 'ResizeFcn', @figResize);
imageSlider(0,0);

waitfor(gui_main);
end    
    