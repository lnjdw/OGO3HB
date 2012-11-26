% zero-element windkessel model
%
clear
close all
%
%                   qmv   plv   qav
%                   -->    |    -->
%  pven -- Rven --- MV ----+--- AV --- Rart -- part
%                          |               
%                    E(t) ===              
%                          |               
%                          0               
%
% >>> parameters

% ventricle: plv = (Epas + act*(Emax-Epas))(Vlv-V0)

V0      = 0;		% [ml]  - intercept volume
Epas    = 0.006;    % [kPa/ml] - passive elastance 
Emax    = 0.3;      % [kPa/ml] - maximum elastance  
tact    = 500;      % [ms]  - duration activation
tcycle  = 1000;     % [ms]  - duration cycle

% valves

Rart    = 5;     	% [kPa.ms/ml] - outflow resistance
Rven    = 1;        % [kPa.ms/ml] - inflow resistance

% >>> loading and time steps

% pressures

ppre    = 1;        % [kPa] - constant preload
pafter  = 15;       % [kPa] - constant afterload

% discretisation

dt      = 2.;		 % [ms] - time step
ncycle  = 4;         % [-] - number of cycles
ninc    = ncycle*tcycle/dt;   % [-] - number of increments

% >>> initialisation

% increment 1 : initialisation

j        = 1;		% [-]   - increment counter
t(j)     = 0;		% [ms]  - increment time 
%
Vlv(j)   = ppre/Epas;
plv(j)   = Model.varelast(Emax,Epas,V0,Vlv(j),tact,tcycle,t(j)); 
%
pven(j)   = ppre;	% [kPa] - constant left atrial pressure
part(j)   = pafter;	% [kPa] - constant arterial pressure
%
qav(j)    = 0;      % [ml/ms] - aortic flow
qmv(j)    = 0;      % [ml/ms] - mitral flow

% >>> loop over increments

while(j<=ninc)
%
j       = j+1;
t(j)    = t(j-1)+dt;

dVlvdt  = qmv(j-1)-qav(j-1);

Vlv(j)  = Vlv(j-1)+dVlvdt*dt;

plv(j)  = Model.varelast(Emax,Epas,V0,Vlv(j),tact,tcycle,t(j));
part(j) = pafter;
pven(j) = ppre;

qav(j)  = max(0,(plv(j)-part(j))/Rart);    
qmv(j)  = max(0,(pven(j)-plv(j))/Rven);     

end

% >>> postprocessing

subplot(2,2,1)
hold on
plot(t,plv,t,part,t,pven,'linewidth',2)
xlabel('time [ms]','FontSize',16);
ylabel('pressure [kPa]','FontSize',16);

subplot(2,2,2)
hold on
plot(t,qav,t,qmv,'linewidth',2)
xlabel('time [ms]','FontSize',16);
ylabel('flow [ml/ms]','FontSize',16);

subplot(2,2,3)
hold on
plot(t,Vlv,'linewidth',2)
xlabel('time [ms]','FontSize',16);
ylabel('volume [ml]','FontSize',16);

subplot(2,2,4)
hold on
plot(Vlv,plv,'linewidth',2)
xlabel('volume [ml]','FontSize',16);
ylabel('pressure [kPa]','FontSize',16);

% >>>  end

