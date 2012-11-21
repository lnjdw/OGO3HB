function [data_refpix data_refcm data_shape data_coeff data_intersect data_imagetype] = MeasureSegment(filenames, type)
%MEASURESEGMENT Display a GUI to let the user draw the ventricle contours.

%% Data
data_refpix = 0;
data_refcm = 1;
data_shape = [];
data_coeff = [0 0];
data_intersect = [0 0 0 0];
data_imagetype = 1;

%% Image
% Read the image file
s = imread(filenames{type});

% Create the main window for the gui
gui_main = figure('Toolbar','none',...
          'Menubar', 'none',...
          'Name','Distance Measurement Tool',...
          'NumberTitle','off',...
          'IntegerHandle','off');
% Put the image in the window
gui_image = imshow(s);
gui_mainh = gca;
fpos = get(gui_main,'Position');

    function figResize(~,~)
        fpos = get(gui_main,'Position');
        set(gui_magslider, 'Position', [0 155 30 fpos(4)-155]);
        set(gui_panel, 'Position', [30 155 fpos(3)-30 fpos(4)-155]);
    end


% Add the scroll panel.
gui_panel = imscrollpanel(gui_main, gui_image);
gui_zoomapi = iptgetapi(gui_panel);

% Position the scroll panel to accommodate the other tools.
set(gui_panel,'Units','pixels','Position',[30 155 fpos(3)-30 fpos(4)-155]);

%% Controls
% Create a frame at the bottom of the window
gui_controlframe = uipanel(gui_main,...
    'Units', 'pixels','Position', [0 0 5000 150],...
    'BackgroundColor', [.6 .6 .6], 'ForegroundColor', 'w');

% GUI sizes
gp_width = 130;
gp_padding = 8;
gp_height = 28;
gp_bheight = 36;

%% Magnification
% Add the Magnification box.
gui_magnificationbox = immagbox(gui_main, gui_image);

% Add the Overview tool.
gui_overview = imoverviewpanel(gui_controlframe, gui_image);
set(gui_overview,'Units','pixels', 'Position', [4 4 300 140]);%'Units','Normalized', 'Position',[0 0 .3 .2]);

% Position the Magnification box
pos = get(gui_magnificationbox,'Position');
set(gui_magnificationbox,'Position',[0 0 pos(3) pos(4)]);

    function magnifySlider(hObj, ~)
        gui_zoomapi.setMagnification(get(hObj,'Value'));
    end

% Create the zoom slider
gui_magslider = uicontrol(gui_main,...
    'Style', 'slider',...
    'Min', 0.1, 'Max', 4, 'Value', 1,...
    'Units', 'pixels', 'Position', [0 155 30 fpos(4)-155],... %[.3 0 .7 .03],...
    'BackgroundColor', [.1 .1 .1],...
    'Callback', {@magnifySlider}...
    );

set(gui_main, 'ResizeFcn', @figResize);

%% Reference Distance
% Create a tool to measure the reference distance
gui_refdisttool = imdistline(gui_mainh, [400 400], [100 200]);
gui_refdistapi = iptgetapi(gui_refdisttool);
gui_refdistapi.setPositionConstraintFcn(@straightLineConstraint);
gui_refdistapi.setColor([1 0 0]);
gui_refdistapi.addNewPositionCallback(@setReference);

% Create a function to make the reference line go vertical only
    function cpos = straightLineConstraint(npos)
        cpos = [npos(1,1) npos(1,2); npos(1,1) npos(2,2)];
    end

% Controls
gui_refpanel = uipanel('Parent', gui_controlframe,'Title', 'Reference Measurement', 'Units', 'pixels', 'Position', [310 5 300 140]);

gui_refstring = uicontrol('Parent', gui_refpanel,'Style', 'text', 'String', '0 pixels ≡',...
        'Position', [gp_padding gp_height*3 gp_width gp_height],...
        'FontWeight', 'bold', 'HorizontalAlignment', 'right');
    
gui_factorstring = uicontrol('Parent', gui_refpanel,'Style', 'text', 'String', '0 cm/pixel',...
        'Position', [2*gp_padding+gp_width gp_height*2 gp_width gp_height],...
        'FontWeight', 'bold');

gui_refcm = uicontrol('Parent', gui_refpanel,'Style', 'popup', 'String', '1 cm|2 cm|3 cm|4 cm|5 cm|6 cm|7 cm|8 cm|9 cm|10 cm|11 cm|12 cm|13 cm|14 cm|15 cm|16 cm|17 cm|18 cm|19 cm|20 cm|21 cm|22 cm|23 cm|24 cm|25 cm|26 cm|27 cm|28 cm|29 cm|30 cm',...
        'Value', 10,...
        'Position', [gp_padding*2+gp_width gp_height*3 gp_width gp_height],...
        'Callback', @setReference);

    function setReference(~,~)
        data_refpix = gui_refdistapi.getDistance();
        data_refcm = get(gui_refcm, 'Value');
        set(gui_refstring,'String',sprintf('%3.0f pixels ≡ ',data_refpix));
        set(gui_factorstring,'String',sprintf('%0.4f pixels/cm',(data_refcm/data_refpix)));
    end

%uicontrol('Parent', gui_refpanel,'Style', 'pushbutton', 'String', 'Set Reference',...
%        'Position', [gp_padding gp_padding 2*gp_width+gp_padding gp_bheight],...
%        'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [.2 0 0], 'ForegroundColor', 'w',...
%        'Callback', @setReference); 

uicontrol('Parent', gui_refpanel,'Style', 'text', 'String', 'Factor = ',...
        'Position', [gp_padding gp_height*2 gp_width gp_height],...
        'HorizontalAlignment', 'right');

%% Function Declarations
gui_lvfhtool = [];
gui_valveline = [];
gui_valvelineapi = [];
gui_prev = [];

%% Initiate the freehand drawing tool
    function drawLeftVentricle(~,~)
        if ~isempty(gui_lvfhtool)
            gui_lvfhtool.delete();
        end
        gui_lvfhtool = imfreehand(gui_mainh);
        gui_lvfhtool.setColor([0 1 0]);
        wait(gui_lvfhtool);
        processLV(0);
    end

%% Process freehand drawing
% Determine the long axis of the freehand drawing
    function [bw c] = determineAxis()
        bw = gui_lvfhtool.createMask();
        skel = bwulterode(bw);%bwmorph(bw, 'thin', Inf);
        datap = zeros([sum(sum(skel)) 2]);
        cnt = 1;
        sz = size(skel);
        for iy=1:sz(1)
            for ix=1:sz(2)
                if skel(iy,ix)
                    datap(cnt,1) = ix;
                    datap(cnt,2) = iy;
                    cnt = cnt+1;
                end
            end
        end
        afit = fit(datap(:,1),datap(:,2),'poly1');
        c = coeffvalues(afit);
        %ni = bw.*0.25+skel.*0.25;
        %for ix=1:sz(2)
        %    ni(min(sz(1),max(1,round(c(1).*ix+c(2)))),ix) = 1;
        %end
        %figure(2);
        %imshow(ni);
    end

%% Process Left Ventricle Data
    function processLV(~)
        [data_shape data_coeff] = determineAxis();
        
        if ~isempty(gui_valveline)
            gui_valveline.delete();
        end
        spos = valveConstraint([500 200; 600 300]);
        gui_valveline = imdistline(gui_mainh, [spos(1,1) spos(1,2)], [spos(2,1)-spos(1,1) spos(2,2)-spos(1,2)]);
        gui_valvelineapi = iptgetapi(gui_valveline);
        gui_valvelineapi.setPositionConstraintFcn(@valveConstraint);
        gui_valvelineapi.setColor([0 1 0]);
        
        snext = imread(filenames{2});
        gui_prev = figure('Toolbar','none',...
          'Menubar', 'none',...
          'Name','Short Axis View',...
          'NumberTitle','off',...
          'IntegerHandle','off',...
          'Position', [0 0 300 300]);
        imshow(snext);
        set(gui_continuebutton, 'Enable', 'on');
    end

%% Line perpendicular on long axis
    function cpos = valveConstraint(npos)
        const = npos(1,2)+(1/data_coeff(1))*npos(1,1);
        cpos = [npos(1,1) npos(1,2); npos(2,1) (const-(1/data_coeff(1))*npos(2,1))];
    end
    
%% Create suitable controls
if type == 1
    % Long axis echo
    gui_lvpanel = uipanel('Parent', gui_controlframe, 'Title', 'Analysis', 'Units', 'pixels', 'Position', [620 75 300 69]);
    uicontrol('Parent', gui_lvpanel, 'Style', 'pushbutton', 'String', 'Draw Left Ventricle',...
            'Position', [gp_padding gp_padding 2*gp_width+gp_padding gp_bheight],...
            'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0 .4 0], 'ForegroundColor', 'w',...
            'Callback', @drawLeftVentricle);        
    uicontrol('Parent', gui_refpanel, 'Style', 'text', 'String', 'View: ',...
        'Value', 1, 'HorizontalAlignment', 'right',...
        'Position', [gp_padding gp_padding gp_width gp_height]);
    gui_imtype = uicontrol('Parent', gui_refpanel, 'Style', 'popup', 'String', 'AP4|PSL',...
        'Value', 1,...
        'Position', [gp_padding*2+gp_width gp_padding gp_width gp_height]);
elseif type == 2
    % Short axis echo
    gui_ellipse = imellipse(gui_mainh, [600 200 100 100]);
    gui_ellipseapi = iptgetapi(gui_ellipse);
    gui_ellipseapi.setColor([0 1 0]);
end

%% Continue with next step
    function saveAndContinue(~,~)
        setReference(0, 0);
        if type == 1
            data_intersect = gui_valvelineapi.getPosition();
            data_imagetype = get(gui_imtype, 'Value');
            if ishghandle(gui_prev)
                close(gui_prev);
            end
        elseif type == 2
            data_shape = gui_ellipseapi.getPosition();
        end
        close(gui_main);
    end

%% Continue button
gui_prpanel = uipanel('Parent', gui_controlframe, 'Title', 'Process', 'Units', 'pixels', 'Position', [620 5 300 69]);
gui_continuebutton = uicontrol('Parent', gui_prpanel, 'Style', 'pushbutton', 'String', 'Continue',...
            'Position', [gp_padding gp_padding 2*gp_width+gp_padding gp_bheight],...
            'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0 0 .4], 'ForegroundColor', 'w',...
            'Callback', @saveAndContinue);
if type == 1
    set(gui_continuebutton, 'Enable', 'off');
end

setReference(0,0);
% Wait for the gui to close before returning
waitfor(gui_mainh);

end    
    