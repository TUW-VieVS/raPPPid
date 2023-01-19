function vtec = iono_gims(Lat_IPP, Lon_IPP, Ttr, ionex_data, method)
% Interpolates VTEC from (global) ionosphere map (IONEX-format). The IONEX
% maps are give in UTC time but interpolation is based on gps-time (the
% leap seconds are not considered).
% 
% INPUT:
%   Lat_IPP         latitude of ionospheric pierce point [°]
%   Lon_IPP         longitude of ionospheric pierce point [°]
%   Ttr             signal transmission time [sow]
%   ionex_data      Data from ionex-File [struct]
%   method          type of interpolation (GUI)
% OUTPUT:
%   vtec            interpolated Total Vertical Electron Content
%  
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Map interpolation, functions for interpolation are below
switch method
    case 'Consecutive Rotated Maps'
        vtec = method_interp_consec_maps(Ttr, Lat_IPP, Lon_IPP, ionex_data);
    case 'Nearest Map'
        vtec = method_nearest_map(Ttr, Lat_IPP, Lon_IPP, ionex_data);
    case 'Consecutive Maps'
        vtec = method_consec_maps(Ttr, Lat_IPP, Lon_IPP, ionex_data);
    case 'Nearest Rotated Map'
        vtec = method_nearest_rot_map(Ttr, Lat_IPP, Lon_IPP, ionex_data);
end

% Frequency
% use only single frequencies e.g. GPS L1 or L2 since the linear
% combinations of these will not work!!!
vtec = vtec*10^ionex_data.exponent;

end             % end of iono_gims



%% Interpolation-Methods
% check this out 'IONEX: The IONosphere Map EXchange Format - Version 1.1'
% http://ftp.unibe.ch/aiub/ionex/draft/ionex11.pdf

% used if method == 1: nearest map
function vtec = method_nearest_map(Ttr, Lat_IPP, Lon_IPP, ionex)
% Select time index, conversion from sow to the interval of GIM
time_index = round((Ttr-ionex.start_sow)/ ionex.interval)+1; % + 1 wegen Verspeicherung

% Find Indices for the IPP in the TEC-Map and Bivariate Interpolation
gim = ionex.map(:,:,time_index);
vtec = calcTEC(ionex.lat, ionex.lon, Lat_IPP, Lon_IPP,gim);
end


% used if method == 2: consecutive maps
function vtec = method_consec_maps(Ttr, Lat_IPP, Lon_IPP, ionex)
% Select time index, conversion from sow to index of the GIM depending on the interval of the Iono-Data
time_index(1) = round((Ttr-ionex.start_sow)/ ionex.interval)+1; % + 1 wegen Verspeicherung
T0 = ionex.start_sow + (time_index(1)-1)*ionex.interval;
if (Ttr - T0 > 0)       % Ttr soll zwischen T0 und T1 liegen: T0-Ttr-T1
    time_index(2) = time_index(1) + 1;
else
    time_index(2) = time_index(1);
    time_index(1) = time_index(1) - 1;
    T0 = ionex.start_sow + (time_index(1)-1)*ionex.interval;
end
T1 = ionex.start_sow + (time_index(2)-1)*ionex.interval;
% time_index(1) belongs to T0, time_index(2) to T1


% Find Indices for the IPP in the TEC-Map and Bivariate Interpolation
gim_0 = ionex.map(:,:,time_index(1));
vtec0 = calcTEC(ionex.lat, ionex.lon, Lat_IPP, Lon_IPP, gim_0);
gim_1 = ionex.map(:,:,time_index(2));
vtec1 = calcTEC(ionex.lat, ionex.lon, Lat_IPP, Lon_IPP, gim_1);

% Time interpolation
fac0 = (T1 - Ttr)/ionex.interval;
fac1 = (Ttr - T0)/ionex.interval;
vtec = vtec0*fac0 + vtec1*fac1;
end


% used if method == 3: nearest rotated map, something is not working
function vtec = method_nearest_rot_map(Ttr, Lat_IPP, Lon_IPP, ionex)
% Select time index, conversion from sow to the interval of the TEC-Map
time_index = round((Ttr-ionex.start_sow)/ ionex.interval) + 1; % +1 wegen Verspeicherung

% Rotation by t-Ti around z-axis
Ttr = mod(Ttr,86400);                   % Ttr now in seconds of day
T =  mod(ionex.start_sow + (time_index - 1)*ionex.interval, 86400); % also in seconds of day
% T can be before or after Ttr
Lon_IPP = Lon_IPP + 360*(Ttr - T)/86400;

% Find Indices for the IPP in the TEC-Map and Bivariate Interpolation
gim = ionex.map(:,:,time_index);
vtec = calcTEC(ionex.lat, ionex.lon, Lat_IPP, Lon_IPP, gim);
end


% used if method == 4: interpolation between consecutive rotated maps
function tec_value = method_interp_consec_maps(Ttr, Lat_IPP, Lon_IPP, ionex)
if Ttr <= ionex.start_sow 
    % transmission time is before 1st epoch of IONEX file (this can happen
    % e.g. at the beginning of the day), set Ttr to the time of the 1st
    % ionex map
%    fprintf('Transmission time %02.0f [sow] set to time of 1st IONEX map.         \n', Ttr);
    Ttr = ionex.start_sow;    
elseif Ttr > ionex.end_sow
    % transmission time is after last epoch of IONEX file (this can happen
    % e.g. at the end of the day), set Ttr to the time of the last ionex map
    Ttr = ionex.end_sow;    
end
% Select time index, conversion from sow to the intervall of the GIM
time_index(1) = round((Ttr-ionex.start_sow)/ ionex.interval)+1; % +1 wegen Verspeicherung
T0 = ionex.start_sow + (time_index(1)-1)*ionex.interval;
if Ttr - T0 > 0             % Ttr soll zwischen T0 und T1 liegen
    time_index(2) = time_index(1) + 1;
elseif Ttr == T0             
    time_index(2) = time_index(1);
else
    time_index(2) = time_index(1);
    time_index(1) = time_index(1) - 1;
    T0 = ionex.start_sow + (time_index(1)-1)*ionex.interval;
end

T1 = ionex.start_sow + (time_index(2)-1)*ionex.interval;
% Ttr soll zwischen T0 und T1 liegen: T0-Ttr-T1

% Rotation by t-Ti around z-axis
% T0 = mod(T0, 86400);    % [sod]
% T1 = mod(T1, 86400);    % [sod]
% Ttr = mod(Ttr, 86400);  % [sod]
Lon_IPP_0 = Lon_IPP + 360*(Ttr - T0)/86400;
Lon_IPP_1 = Lon_IPP + 360*(Ttr - T1)/86400;
% 15°/h, Latitude does not change by rotating around z-axis

% Find Indices for the IPP in the TEC-Map und Bivariate Interpolation
gim_0 = ionex.map(:,:,time_index(1));
vtec_0 = calcTEC(ionex.lat, ionex.lon, Lat_IPP, Lon_IPP_0, gim_0);
gim_1 = ionex.map(:,:,time_index(2));
vtec_1 = calcTEC(ionex.lat, ionex.lon, Lat_IPP, Lon_IPP_1, gim_1);

% Time interpolation
fac0 = (T1 - Ttr)/ionex.interval;
fac1 = (Ttr - T0)/ionex.interval;

tec_value = fac0*vtec_0 + fac1*vtec_1;  
end


%% Function for determine Indices and TEC 
% Indices of the IPP in the GIM-Matrix and calculating TEC-value with Bivariate Interpolation

function tec = calcTEC(ionex_lat, ionex_lon, Lat_IPP, Lon_IPP, gim)
 

% Initialization
lon_ind = NaN;
lat_ind = NaN;

% if IPP is outside of GIM raster take value on the edge of the GIM
if (Lat_IPP >= ionex_lat(1))
    Lat_IPP = ionex_lat(1);
    lat_ind = 1;
end
if (Lat_IPP <= ionex_lat(2))
    Lat_IPP = ionex_lat(2);
    lat_ind = size(gim,1);
end
if (Lon_IPP <= ionex_lon(1))
    Lon_IPP = ionex_lon(1);
    lon_ind = 1;
end
if (Lon_IPP >= ionex_lon(2))
    Lon_IPP = ionex_lon(2);
    lon_ind = size(gim,2);
end

% Calculate Indizes if not already done
% Longitude
if ionex_lon(1) > Lon_IPP && isnan(lon_ind)
    lon_ind = floor(   (Lon_IPP - ionex_lon(1))/ionex_lon(3)) + 1;
elseif isnan(lon_ind)
    lon_ind = floor(abs(Lon_IPP - ionex_lon(1))/ionex_lon(3)) + 1;
end
% Latitude
if ionex_lat(1) > Lat_IPP && isnan(lat_ind)
    lat_ind = ceil(   (Lat_IPP - ionex_lat(1))/ionex_lat(3)) + 1;
elseif isnan(lat_ind)
    lat_ind = ceil(abs(Lat_IPP - ionex_lat(1))/ionex_lat(3)) + 1;
end

% Calculate Latitude&Longitude of the lower-left raster-point with indices
lats = ionex_lat(1) : ionex_lat(3) : ionex_lat(2);
lat_rasterpoint = lats(lat_ind);
longs = ionex_lon(1) : ionex_lon(3) : ionex_lon(2);
lon_rasterpoint = longs(lon_ind);

% Get the 4 TEC-Values to interpolate
if (lat_ind == 1) || (lon_ind == size(gim,2))   % IPP is on the edge of GIM
    if (lat_ind == 1 && lon_ind == size(gim,2)) % Lat-Index too small and Long-Index too big
        tecs(2,1) = gim(lat_ind, lon_ind);          % lower-left-point
        tecs(1,1) = gim(lat_ind, lon_ind);          % upper-left-point
        tecs(2,2) = gim(lat_ind, lon_ind);          % lower-right-point
        tecs(1,2) = gim(lat_ind, lon_ind);          % upper-right-point
    elseif lat_ind == 1                         % only Latitude-Index too small
        tecs(2,1) = gim(lat_ind,   lon_ind);        % lower-left-point
        tecs(1,1) = gim(lat_ind,   lon_ind);      	% upper-left-point
        tecs(2,2) = gim(lat_ind, lon_ind+1);       	% lower-right-point
        tecs(1,2) = gim(lat_ind, lon_ind+1);        % upper-right-point
    elseif lon_ind == size(gim,2)               % only Longitude-Index too big 
        tecs(2,1) = gim(lat_ind,   lon_ind);        % lower-left-point
        tecs(1,1) = gim(lat_ind-1, lon_ind);        % upper-left-point
        tecs(2,2) = gim(lat_ind,   lon_ind);        % lower-right-point
        tecs(1,2) = gim(lat_ind-1, lon_ind);        % upper-right-point
    end
else                                            % IPP lies inside of the GIM
    tecs(2,1) = gim(lat_ind,     lon_ind);          % lower-left-point
    tecs(1,1) = gim(lat_ind-1,   lon_ind);          % upper-left-point
    tecs(2,2) = gim(lat_ind,   lon_ind+1);          % lower-right-point
    tecs(1,2) = gim(lat_ind-1, lon_ind+1);          % upper-right-point
end
% tecs = [ E_0,1    E_1,1   = [ upper-left     upper-right   = [ (1,1)  (1,2)
%          E_0,0    E_1,0 ]     lower-left     lower-right ]     (2,1)  (2,2) ]


% --- Bivariate Interpolation ---
% Check out: https://files.igs.org/pub/data/format/ionex1.pdf
q = (Lat_IPP - lat_rasterpoint)/abs(ionex_lat(3));    % weight for latitude
p = (Lon_IPP - lon_rasterpoint)/abs(ionex_lon(3));    % longitude
tec  = (1-p)*(1-q)*tecs(2,1) + p*(1-q)*tecs(2,2) + q*(1-p)*tecs(1,1) + p*q*tecs(1,2);
%tec = (1-p)*(1-q)*E_0,0     + p*(1-q)*E_1,0     + q*(1-p)*E_0,1     + p*q*E_1,1;
% [0.1 TECU]

end