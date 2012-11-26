function plv = varelast(Emax,Epas,V0,Vlv,tact,tcycle,t)

% determine time relative to start activation

ts = t-floor(t/tcycle)*tcycle;

act = 0;
if ts<tact
    act=(sin(pi*ts/tact))^2;
end

plv = (Epas + act*(Emax-Epas))*(Vlv-V0);

end
