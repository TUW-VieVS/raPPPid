function [lat_IPP, lon_IPP] = calculate_IPP(lat_rx, lon_rx, az, el, H)
% This function calculates the geographic latitude and longitude of the
% ionospheric Pierce Point (IPP).
% The point of interest for which a TEC value has to be estimated is not 
% the location of the receiver but the location of the IPP. 
% 
% Reference:
% European GNSS (Galileo) Open Service - NTCM G Ionospheric Model Description, 
% Issue 1.0, European Commission (EC)
% Equations 24-26
% 
% INPUT:
%   lat_rx      latitude of the receiver [rad]
%   lon_rx      longitude of the receiver [rad]
%   el          elevation of the satellite[rad]
%   az          azimuth to the satellite [rad]
%   H           height of ionospheric shell (e.g., 450e3) [m]
% OUTPUT:
%   lat_IPP     latitude of the ionospheric Pierce Point [rad]
%	lon_IPP     longitude of the ionospheric Pierce Point [rad]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

% calculate Earth's central angle between the user position and the Earth
% projection of the ionospheric pierce point [rad] (eq. 24)
psi_IPP = pi/2 - el - asin( Const.RE/(Const.RE + H) * cos(el));

% calculate latitude of the ionospheric pierce point [rad] (eq. 25)
lat_IPP = asin(sin(lat_rx)*cos(psi_IPP) + cos(lat_rx)*sin(psi_IPP)*cos(az)); 

% calculate longitude of ionospheric pierce point [rad] (eq. 26) 
lon_IPP = lon_rx + asin(sin(psi_IPP)*sin(az)/cos(lat_IPP));