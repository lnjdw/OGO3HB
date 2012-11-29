function [Volume] = fitVolume(volumeList,timeList,lengthList)
order = 6;
parameter = polyfit(timeList,volumeList,order);
x = 1:lengthList;
y = 0;
i = 0;
while i <= order
    y = y + parameter(order-i+1)*x.^i;
    i = i+1;
end
plot(x,y,timeList,volumeList);
Volume = y(x);
end

