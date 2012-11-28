function [x y] = ImportPressure()
%PLOTPRESSURE Summary of this function goes here
%   Detailed explanation goes here
global debug;

res = Nexfin.readNexfin('part','+Nexfin\Data\\REC-205_040.csv');

if debug
    figure(1);
    plot(res.tBP(41:231), res.BP(41:231));
end

x = res.tBP;
y = res.BP;

end

