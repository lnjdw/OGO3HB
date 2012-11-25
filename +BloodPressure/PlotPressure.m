function PlotPressure()
%PLOTPRESSURE Summary of this function goes here
%   Detailed explanation goes here

res = Nexfin.readNexfin('part','+Nexfin\Data\\REC-205_040.csv');

figure;
plot(res.tBP, res.BP);

end

