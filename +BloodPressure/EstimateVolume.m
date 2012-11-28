function [xi yi] = EstimateVolume(data, points)
%PLOTVOLUME Summary of this function goes here
%   Detailed explanation goes here
global debug;

xi = points;
yi = interp1(data(:,3),data(:,1),xi,'spline');

if debug
    figure(2);
    plot(data(:,3),data(:,1),'r.',xi,yi,'b-');
end

end
