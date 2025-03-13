function [stec] = corr2brdc_stec(corr_vtec, az, elev, pos_geo, Ttr)
% Calculates the ionospheric correction from spherical harmonics 
% coefficients, provided by a correction stream.
% 
% Zhixi Nie et al.; Quality assessment of CNES real-time ionospheric
% products; GPS Solutions (2019) 23:11; 
% https://doi.org/10.1007/s10291-018-0802-2;
% 
% INPUT:
%   corr_vtec   struct, containing data from correction stream
%   az          azimut [°]
%   elev        elevation [°]
%   pos_geo     struct, ph = latitude [rad], la = longitude [rad], h = height [m]
%   t           GPS time of computation epoch [sod]
% OUTPUT:
%   stec        Slant Total Electron Content [TECU]
% 
% Revision:
%	2025/02/06, MFWG: improving code, changing input variables
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
lat_rx = pos_geo.lat;    	% latitude/phi of receiver [rad] 
lon_rx = pos_geo.lon;     	% longitude/lambda of receiver [rad]
H_rx   = pos_geo.h/1000;   	% height of receiver [km]

H_I = corr_vtec.height/1000;% height of ionospheric layer [km]
R_e = Const.RE / 1000;      % radius of earth [km]

elev = elev/180*pi;         % convert elevation into [rad]
az = az/180*pi;             % convert azimuth into [rad]

% find nearest VTEC data in correction stream
% ||| interpolate 
dt = Ttr - corr_vtec.t;     % time difference [sow]
dt(dt<0) = [];              % ignore future data to maintain real-time conditions

idx = find(dt == min(dt));  	% index of nearest VTEC data
C_nm = corr_vtec.Cnm(:,:,idx);	% cosine coefficients [TECU]
S_nm = corr_vtec.Snm(:,:,idx); 	% sine coefficients [TECU] 


%% calculate ionospheric pierce point 
% according to IGS State Space Representation (SSR) Format version 1.00

% compute geocentric latitude of receiver
lat_rx_ = atan( (1-Const.WGS84_E_SQUARE) * tan(lat_rx) );   

% calculate spherical earth central angle between user location and the
% projection of the IPP to the earth surface
psi_IPP = pi/2 - elev - asin( (R_e+H_rx)/(R_e+H_I) * cos(elev) );              % (4)

% calculate latitude of Ionospheric Pierce Point (IPP)
lat_IPP = asin( sin(lat_rx_)*cos(psi_IPP) + cos(lat_rx_)*sin(psi_IPP)*cos(az) );    % (3)

% calculate longitude of IPP
cond_1 = lat_rx_ >= 0 &&  tan(psi_IPP)*cos(az) > tan(pi/2-lat_rx_);
cond_2 = lat_rx_ <  0 && -tan(psi_IPP)*cos(az) > tan(pi/2+lat_rx_);
if cond_1 || cond_2
    lon_IPP = lon_rx + pi - asin( (sin(psi_IPP)*sin(az)) / cos(lat_IPP) );     % (5)
else
    lon_IPP = lon_rx      + asin( (sin(psi_IPP)*sin(az)) / cos(lat_IPP) );     % (6)
end


%% calculate mean sun-fixed and phase shifted longitude of the IPP
t = mod(Ttr,86400);     % [sod]
lon_S = mod(lon_IPP + (t-50400)*pi/43200, 2*pi);       % (2)


%% calculate VTEC with spherical harmonics with (1)
[N,M] = size(C_nm);         % degree N and order M
mmm = zeros(N,M) + 0:M - 1;
cosine = C_nm .* cos(mmm.*lon_S);
sine   = S_nm .* sin(mmm.*lon_S);
P_nm = legendre_Pnm(N, M, lat_IPP);
vtec = sum(sum( (cosine+sine).*P_nm )); 	% calculate complete sum


%% check VTEC and calculate STEC 
if vtec < 0;     vtec = 0;     end

% formula according to IGS SSR format
stec = vtec / (sin(elev + psi_IPP));      % (12)
