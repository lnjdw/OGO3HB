function CreatePVLoop(vdata)
%CREATEPVLOOP Summary of this function goes here
%   Detailed explanation goes here
global debug;
debug = true;

[tp p] = BloodPressure.ImportPressure();
tp = tp(41:231);
p = p(41:231);
tp = tp-min(tp);

figure(3);
slider = uicontrol('Style', 'slider',...
        'Min',-0.2,'Max',0.2,'Value',0,...
        'Units', 'pixels', 'Position', [0 0 200 20],...
        'Callback', @RefreshPlot);
    
    function RefreshPlot(~,~)
        ndata = vdata+get(slider, 'Value');
        
        [tv v] = BloodPressure.EstimateVolume(ndata,tp);

        figure(3);
        plot(v,p);
    end

RefreshPlot();
debug = false;

end

