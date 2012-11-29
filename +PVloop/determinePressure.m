  function [Pressure] = determinePressure(Nexfin,loopNumber)

%% Parameters
marginMinimum = 25;
marginLoop = 100;
marginGradient = 10;
displacement = 50;
steepnessStart = 13;
steepnessStop = 9;
raiseBase = 0;
raiseTop = 0;
raiseAll = 10;
widthFactor = 1.1;
gradientLeft = 2;
gradientRight = 2;

% the first loop might be kinda weird because it might start in the middle
% of a cycle, to prevent this use a loop number higher than 1 or just use an
% empty string ('').
if isempty(loopNumber)
    loopNumber = 2;
end

%% Open the correct file,
% either enter a viable file location e.g.
% 'D:\Documents\MATLAB\\REC-205_040.csv',
% or an empty string (''). This will let you search for an appropriate file.
if isempty(Nexfin) ~= 1
    signals = readNexfin('part',Nexfin);
else signals = readNexfin('part');
end
segment = signals.BP;

%% Searching for minimums
i = 1 + marginMinimum;
j = 1;
minimums = zeros(round(length(segment)/50));
while i <= (length(segment)-marginMinimum)
    totalscore = 0;
    while j <= marginMinimum
        currentValue = segment(i);
        if segment(i-j) > currentValue
            totalscore = totalscore+1;
        end
        if segment(i+j) > currentValue
            totalscore = totalscore+1;
        end
        j = j+1;
    end
    if totalscore > marginMinimum*1.8
        minimums(i) = i;
    end
    j = 1;
    i = i+1;
end
minimums = minimums(minimums~=0);

%% Searching for starts/ends of loops
splitValues = zeros(length(minimums));
i = 1;
while i <= length(minimums)-1;
    if isempty(splitValues) == 1 && minimums(i) + marginLoop < max(minimums)
        splitValues = minimums(i); 
    end
    if isempty(splitValues) ~= 1 && minimums(i) - marginLoop > max(splitValues(:))
        splitValues(i) = minimums(i);
    end
	i = i+1;
end
splitValues = splitValues(splitValues~=0);

%% Convert arterial pressure to ventricular pressure
% Checking if the loop actually exists
if loopNumber < length(splitValues)
    fragment = segment(splitValues(loopNumber)-displacement:splitValues(loopNumber+1)-displacement);
else display('There are not enough loops to reach the number you entered.')
end

%% Looking for the highest en lowest gradient
i = 1 + marginGradient;
lowestGradient = [1000 0];
highestGradient = [-1000 0];
while i <= length(fragment)-marginGradient
    gradient = (fragment(i+marginGradient) - fragment(i))/marginGradient;
    if gradient < lowestGradient(1)
        lowestGradient = [gradient i];
    end
    if gradient > highestGradient(1)
        highestGradient = [gradient i + marginGradient];
    end
    i = i+1;
end

%% Starting the graph from scratch, just using the top of the highest peak
segment = fragment + raiseTop;
i = 1;

widthChange= round((widthFactor-1)*highestGradient(2));
highestGradient(2) = highestGradient(2) - widthChange;
lowestGradient(2) = lowestGradient(2) + widthChange;

while i <= highestGradient(2)
    segment(i) = raiseBase;
    i = i+1;
end
i = lowestGradient(2);
while i <= length(segment)
    segment(i) = raiseBase;
    i = i+1;
end

%% Constructing the base of the peak
steepnessCompensationLeft = (1-steepnessStart/20)*steepnessStart*sqrt((lowestGradient(1).^2 + highestGradient(1).^2));

stepsLeft = floor((fragment(highestGradient(2))-raiseBase)./(steepnessCompensationLeft./2)*gradientLeft);
i = highestGradient(2)-stepsLeft+1;
while i <= highestGradient(2)
    segment(i) = segment(i-1) + (fragment(highestGradient(2))-raiseBase)/stepsLeft + steepnessStart*((-(stepsLeft+1)./2)+(i-(highestGradient(2)-stepsLeft+1)))./(stepsLeft+1);
    i = i+1;
end
steepnessCompensationRight = (1-steepnessStop/20)*steepnessStop*sqrt((lowestGradient(1).^2 + highestGradient(1).^2));

stepsRight = floor((fragment(lowestGradient(2))-raiseBase)./(steepnessCompensationRight./2)*gradientRight);
i = lowestGradient(2)+stepsRight-1;
while i >= lowestGradient(2)
    segment(i) = segment(i+1) + (fragment(lowestGradient(2))-raiseBase)/stepsRight + steepnessStop*((-(stepsRight+1)./2)+((lowestGradient(2)+stepsRight-1)-i))./(stepsRight+1);
    i = i-1;
end

%% Smoothing of the corners up top
i = highestGradient(2);
while i <= highestGradient(2) + 4
    segment(i) = segment(i)*((95+(i-highestGradient(2)))./100);
    i = i+1;
end
i = lowestGradient(2);
while i >= lowestGradient(2) - 4
    segment(i) = segment(i)*((95-(i-lowestGradient(2)))./100);
    i = i-1;
end    

%% Moving the graph to the start of the plot and move it up or down
segment = segment + raiseAll;
segmentBefore = segment;
firstPart = segment((highestGradient(2)-stepsLeft):(length(segment)));
secondPart = segment(1:(highestGradient(2)-stepsLeft-1));
i = 1;
while i <= length(segment)
    if i <= length(segment) - (highestGradient(2)-stepsLeft-1)
        segment(i) = firstPart(i);
    end
    if i > length(segment) - (highestGradient(2)-stepsLeft-1) && i <= (length(segment))
        segment(i) = secondPart(i-(length(segment) - (highestGradient(2)-stepsLeft-1)));    
    end
    i = i+1;
end

%{%
% Remove the second % if you are going to use it for another program,
% it will stop the graph from showing up
plot(1:length(segment),segment,1:length(segment),fragment,1:length(segment),segmentBefore);
legend('ventrical pressure','arterial pressure')
title('pressures in different locations')
%}

%% returning the pressure
Pressure = segment;
end

