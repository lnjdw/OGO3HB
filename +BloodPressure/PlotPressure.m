function PlotPressure()
%PLOTPRESSURE Summary of this function goes here
%   Detailed explanation goes here

res = Nexfin.readNexfin('part','+Nexfin\Data\\REC-205_040.csv');

figure;
plot(res.tBP(41:231), res.BP(41:231));

end

