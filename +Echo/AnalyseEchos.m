function [I dd time1 time2] = AnalyseEchos(filenameLongAxis, filenameShortAxis, loadOldType1, loadOldType2)
%ANALYSEECHOS Calculate the volume of the left ventricle using echo images
%   [I dd] = AnalyseEchos(filenameLongAxis, filenameShortAxis, loadOld)
%   calculates the volume of the left ventricle using a echo image of the 
%   long axis (filenameLongAxis) and a image of the short axis of the
%   heart. loadOld is optional, when set true the function uses the data
%   stored in 'echodata.mat'. By default the value is false and the GUI is 
%   used to obtain new data.
%   The function returns the volume of the left ventricle (I) in mL. dd is
%   the difference in width of the chambre between both images (in cm).
%   Furthermore the function displays a 3D model of the ventricle.

%% Handle default arguments
if nargin < 4, loadOldType2 = false; end
if nargin < 3, loadOldType1 = false; end
if nargin < 1
    [tempf tempp] = uigetfile('*.avi', 'Select long axis video...');
    filenameLongAxis = fullfile(tempp,tempf);
end
if nargin < 2
    [tempf tempp] = uigetfile('*.avi', 'Select long axis video...');
    filenameShortAxis = fullfile(tempp,tempf);
end
[frame1 frame2 time1 time2] = Echo.ChooseFrame(filenameLongAxis, filenameShortAxis);

%% Load old data or launch GUI to create new data
if ~loadOldType1
    [data_refpix1 data_refcm1 data_shape1 data_coeff data_intersect data_imagetype] = Echo.MeasureSegment({frame1, frame2},1);
    f1 = data_refcm1/data_refpix1;
    save('echodatatype1.mat', 'f1', 'data_shape1', 'data_coeff', 'data_intersect', 'data_imagetype');
else
    f1=[];data_shape1=[];data_coeff=[];data_intersect=[];data_imagetype=[];
    load('echodatatype1.mat');
end
if ~loadOldType2
    [data_refpix2 data_refcm2 data_shape2] = Echo.MeasureSegment({frame1, frame2},2);
    f2 = data_refcm2/data_refpix2;
    save('echodatatype2.mat', 'f2', 'data_shape2');
else
    f2=[];data_shape2=[];
    load('echodatatype2.mat');
end

% Determine the size of the freehand drawing data
sz = size(data_shape1);

%% Short Axis Data
% Calculate short axis ellipse ratio
ellipse_size = f2.*[data_shape2(3) data_shape2(4)];
if data_imagetype == 2
    % PSL view instead of AP4, so the width and height should have been
    % interchanged.
    ellipse_size = [ellipse_size(2) ellipse_size(1)];
end
ellipse_ratio = ellipse_size(1)/ellipse_size(2);

%% Long Axis Data
% Create the axis function of the freehand drawing
a1 = data_coeff(1);
b1 = data_coeff(2);
y1 = @(x)(a1*x+b1);

% Calculate the coefficients of the perpendicular function
a2 = -1/a1;
b2 = data_intersect(1,2)-a2*data_intersect(1,1);

% Calculate the distance covered by the lines y=a1*x+b1 and y=a2*x+b2 when
% x increases with 1.
dddx1 = sqrt(a1^2+1);
dddx2 = sqrt(a2^2+1);

%% Ventricle Diameter
% Start at the long axis of the free hand drawing and calculate the
% distance to the edge of the ventricle
    function [d d1 d2] = getDiameter(x,y)
        % Look to the left
        i = 1;
        while x-i > 0
            if data_shape1(min(sz(1),max(1,round(-a2*i+y))), round(x-i)) == 0
                break;
            end
            i = i+1;
        end
        i = i-1;
        d1 = f1*i*dddx2; %sqrt((f1*-a2*i)^2+(f1*i)^2);

        % Look to the right
        j = 1;
        while x+j < sz(2)
            if data_shape1(min(sz(1),max(1,round(a2*j+y))), round(x+j)) == 0
                break;
            end
            j = j+1;
        end
        j = j-1;
        d2 = f1*j*dddx2; %sqrt((f1*a2*j)^2+(f1*j)^2);
        
        % Calculate the total diameter
        d = d1+d2;
    end

%% Calculate Ventricle Diameters
% Walk down the center axis of the free hand drawing
xdata = [];
ydata = [];
k = 0;
while k < sz(2)
    kx = k;
    ky = y1(kx);
    [kdata(1) kdata(2) kdata(3)] = getDiameter(kx,ky);
    if kdata(1) > 0
        xdata = [xdata; kx*dddx1];%sqrt(kx^2+(a1*kx)^2)];
        ydata = [ydata; kdata(1)];
    end
    k = k+1;
end

% Close the ventricle at both sides
xdata = [min(xdata)-dddx1;xdata;max(xdata)+dddx1]+dddx1;
xdata = f2.*(xdata-min(xdata));
ydata = [0;ydata;0];

%% 3D Model
% Create a mesh of the ventricle
[X Y] = meshgrid(xdata', -10:.01:10);
Z = [];
area = [];
for i=1:length(xdata)
    if data_imagetype == 1
        newz = (ydata(i)/2).*ellipse_ratio.*real(sqrt(1-((-10:.01:10)./(ydata(i)/2)).^2));
        Y(:,i) = max(min(Y(:,i), (ydata(i)/2)), -(ydata(i)/2)); % Cut off x-y plane outside the ventricle
    else
        newz = (ydata(i)/2).*real(sqrt(1-((-10:.01:10)./((ydata(i)/2).*ellipse_ratio)).^2));
        Y(:,i) = max(min(Y(:,i), ellipse_ratio*(ydata(i)/2)), -ellipse_ratio*(ydata(i)/2)); % Cut off x-y plane outside the ventricle
    end
    Z = [Z; newz];
    % Calculate the area of one slice
    area = [area; pi*ellipse_ratio*(ydata(i)/2)^2];
end

gui_main = figure('Toolbar', 'figure',...
          'Menubar','none',...
          'Name','Model of the left ventricle',...
          'NumberTitle','off',...
          'IntegerHandle','off');
surf(X,Y,Z','FaceColor','interp',...
 'EdgeColor','none',...
 'FaceLighting','phong');
camlight left;
colormap([1 0 0]);
hold on;
surf(X,Y,-1.*Z','FaceColor','interp',...
 'EdgeColor','none',...
 'FaceLighting','phong');
title('3D Model of the Left Ventricle');
xlabel('x (cm)');
ylabel('y (cm)');
zlabel('z (cm)');
axis equal

%% Volume
% Add all slices together to calculate the volume
I = sum(f1.*area); % cm^3 == ml
%text(1, -5, 4, sprintf('Volume = %4.3f mL', I), 'BackgroundColor', [.8 .8 .8]);
uicontrol('Style', 'text', 'String', sprintf('Volume = %4.3f mL', I),...
    'Units', 'pixels', 'Position', [0 0 150 20]);

%% Accuracy Check
diam1 = ellipse_size(2);
diam2 = getDiameter((b2-b1)/(a1-a2), y1((b2-b1)/(a1-a2)));
dd = abs(diam1-diam2);
uicontrol('Style', 'text', 'String', sprintf('Diameter 1: %2.2f cm; Diameter 2: %2.2f cm; Difference: %1.3f cm', diam1, diam2, dd),...
    'Units', 'pixels', 'Position', [150 0 400 20]);
hold off;
end

