function [] = PVLoops(volumeList,timeList,Nexfin,loopNumber)
% Line of testcode: 'PVLoops([70 75 80 85 90 95 100 105 110 115 120 115 110 105 100
% 95 90 85 80 75 70],[0 .05 .1 .15 .2 .25 .3 .35 .4 .45 .5 .55 .6 .65 .7
% .75 .8 .85 .9 .95 1],'D:\Documents\MATLAB\\REC-205_040.csv',38)'
pressure = determinePressure(Nexfin,loopNumber);
volume = fitVolume(volumeList,timeList*length(pressure),length(pressure));
figure;
plot(pressure)
figure;
plot(volume)
figure;
plot(volume,pressure);
end

