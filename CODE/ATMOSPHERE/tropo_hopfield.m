function [std, mfw, ztd] = tropo_hopfield(time, el, met, est_ZWD)
% Implementation of Hopfield troposphere model with values for
% temperature, pressure and humidity from GUI or *.met file
% check [01]: p130ff
%
% INPUT: 
% 	time        in sec of week
%	el          elevation [rad]
%	met         pressure [mbar]
%               temperature [°C]
%               relative humidity [%]
% 	est_ZWD     boolean, true if Zenith Wet Delay gets estimated
% OUTPUT:
% 	std         slant total delay [m]
%	mfw         wet mapping function
% 	ztd         zenith total delay
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if numel(met) == 3      % values from GUI
    T = met(1,1);       % temperature [°C]
    p = met(2,1);       % pressure of air [mbar]
    rh = met(3,1);      % relative humidity [%]
    e = calc_partial_pressure_water_vapor(T, rh);	% partial pressure of water vapor [hPa]
else    
    interval_met = met.time_sow(2) - met.time_sow(1);  	% get time index
    time_index = floor(mod(time,86400)/interval_met) + 1;  
    if time_index >= length(met.temp)-1
        time_index = length(met.temp)-1;
    end
    dt = mod(mod(time,86400),interval_met)/interval_met;
    % get temperatur
    T = met.temp(time_index)     + (met.temp(time_index+1)-met.temp(time_index))*dt;
    % get pressure of air [mbar]
    p = met.press(time_index)    + (met.press(time_index+1)-met.press(time_index))*dt;
    % get relative humidity
    rh = met.rel_hum(time_index) + (met.rel_hum(time_index+1)-met.rel_hum(time_index))*dt;
    % calculation of partial pressure of water vapor
    e = calc_partial_pressure_water_vapor(T, rh);
end

T = T + 273.16;     % convert temperature from [°C] in [°K]

% calculate hydrostatic and wet zenith delay 
zhd = 10^(-6)* 77.64/5 * p/T * (40136 + 148.72*(T-273.16));
zwd = 0; 
if ~est_ZWD         % ZWD is not estimated
    zwd = 10^(-6)/5 * (-12.96*T + 3.718*10^5) * e/T^2 * 11000;
end

% calculate mapping functions (Elevation in degrees)
el = el*180/pi;
mfh = 1 / sin(sqrt(el^2+6.25)*pi/180);      % mapping function dry trop
mfw = 1 / sin(sqrt(el^2+2.25)*pi/180);      % mapping function wet trop

ztd = zhd + zwd;            % Zenith Total Delay [m]
std = zhd*mfh + zwd*mfw;      % Slant delay [m]





