% readNexfin :  Reads nexfin-data, cuts out segment from marker-to-marker
%
% SYNTAX
% >> [signals] = readNexfin;
% >> [signals] = readNexfin(part);
% >> [signals] = readNexfin(part,filename);
%
% INPUTS
% - part :    'all'  -> Entire file is read
%             'part' -> Script will ask for marker numbers
%                       segment in between will be returned
% - filename : Enter filename if you want to skip 'explorer window'
%
% OUTPUT
% - signals :  Struct that contains all signals
%              signals.tECG  : time vector ECG-signal
%              signals.tBP   : time vector BP-signal
%              signals.ECG   : ECG-signal
%              signals.BP    : BP-signal

function [signals] = readNexfin(partstr,filename)

if nargin < 2;
    [f,d]     = uigetfile('*040.csv');
    f         = [d,f];
else
    [d,f,ext] = fileparts(filename);
    
    if isempty(d)
        error('Please give full path and filename!'); 
    end
    f         = [d,f,ext];
end

[mts,mns] = xlsread(f);
mts  = mts/1e6;
if size(mns,1) > 1
    for i = 2:size(mns,1);
        mns{i,1} = i-1;
    end
else
    for i = 2:(size(mts,1)+1);
        mns{i,1} = i-1;
        mns{i,2} = ['m',num2str(i-1)]; 
    end
end

if strcmp(partstr,'part')
    disp(' ')
    disp(mns)
    disp(' ')
    s = str2num(input('Give one start and one end-number (corr. markers) : ','s')); %#ok
    disp(' ')
else
    s = 0;    
end

f_BP  = 200;   dt_BP  = 1/f_BP;
f_ECG = 1000;  dt_ECG = 1/f_ECG;

noECG = dir([f(1:end-8),'_013.bin']);
if size(noECG,1) ~= 0
ECG  = fopen([f(1:end-8),'_013.bin']);
ECG  = fread(ECG,inf,'int16');
tECG = dt_ECG : dt_ECG : size(ECG,1)*dt_ECG;
end

BP   = fopen([f(1:end-8),'_103.bin']);
BP   = fread(BP,inf,'int16');
BP   = BP*0.25;
tBP  = dt_BP : dt_BP : size(BP,1)*dt_BP;

if s(1) ~= 0
    marker1 = mts(s(1));
    marker2 = mts(s(2));
else
    if strcmp(partstr,'part');
        partstr = 'all';
    end
end

if strcmp(partstr,'part');
    if size(noECG,1) ~= 0
        signals.tECG  = tECG((marker1/dt_ECG):(marker2/dt_ECG));
        signals.ECG   = ECG ((marker1/dt_ECG):(marker2/dt_ECG));
    end
    signals.tBP   = tBP ((marker1/dt_BP) :(marker2/dt_BP));
    signals.BP    = BP  ((marker1/dt_BP) :(marker2/dt_BP));
elseif strcmp(partstr,'all');
    if size(noECG,1) ~= 0
        signals.tECG  = tECG;
        signals.ECG   = ECG;
    end
    signals.tBP   = tBP;
    signals.BP    = BP;
end