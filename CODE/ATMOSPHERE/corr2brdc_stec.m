function [stec] = corr2brdc_stec(C_nm, S_nm, H_I, az, elev, lat_rx, lon_rx, H_rx, Ttr)
% Calculates the ionospheric correction from spherical harmonics 
% coefficients, provided by a correction stream.
% 
% Zhixi Nie et al.; Quality assessment of CNES real-time ionospheric
% products; GPS Solutions (2019) 23:11; 
% https://doi.org/10.1007/s10291-018-0802-2;
% 
% INPUT:
%   C_nm        cosine coefficients [TECU]
%   S_nm        sine coefficients [TECU] 
%   H_I         height of ionospheric layer [m]
%   az          azimuth [°]
%   elev        elevation [°]
%   lat_rx      latitude of receiver [rad]
%   lon_rx      longitude of receiver [rad]
%   H_rx        height of receiver [m]
%   Ttr         GPS time of computation epoch [sod]
% OUTPUT:
%   stec        Slant Total Electron Content [TECU]
% 
% Revision:
%	2025/02/06, MFWG: improving code, changing input variables
%   2025/11/10, MFWG: input changed
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
H_rx   = H_rx/1000;   	    % convert to [km]
H_I = H_I/1000;             % convert to [km]
R_e = Const.RE / 1000;      % radius of earth [km]

elev = elev/180*pi;         % convert elevation into [rad]
az = az/180*pi;             % convert azimuth into [rad]


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
t = mod(Ttr, 86400);    % [sod]
lon_S = mod(lon_IPP + (t-50400)*pi/43200, 2*pi);       % (2)


%% calculate VTEC with spherical harmonics with (1)
[N,M] = size(C_nm);         % degree N and order M
mmm = repmat(0:M - 1, N, 1);
cosine = C_nm .* cos(mmm.*lon_S);
sine   = S_nm .* sin(mmm.*lon_S);
P_nm = legendre_Pnm(N, M, lat_IPP);
vtec = sum(sum( (cosine+sine).*P_nm )); 	% calculate complete sum


%% check VTEC and calculate STEC 
if vtec < 0;     vtec = 0;     end

% formula according to IGS SSR format
stec = vtec / (sin(elev + psi_IPP));      % (12)
