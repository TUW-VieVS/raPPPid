function [dZHD, dZWD] = tropo_height_correction(pos_WGS84, H0, atm)
% This function calculates the height correction for kinematic processing
% with the VMF3. Used variables:
% H  ... current height [m]
% H0 ... reference height [m]
% e0 ... water vapor pressure [hPa]
% p0 ... total pressure [hPa]
% T0 ... temperature [K]
% lat ... latitude of receiver
% 
% check also:
% Multi-technique comparison of troposphere zenith delays and gradients during CONT08
% Teke et.al. 2011
% 
% INPUT:
%   pos_WGS84       struct, current receiver position (lat, lon, height)
%   H0              height for which the VMF coefficients were interpolated
%   atm             (1x3) Atmospheric data with p0, e0, T0
% OUTPUT:
%	dZHD, dZWD      corrections for ZHD and ZWD due to the change of height
%
% Revision:
%   ...
%
% Created by Paul Dohnal
% 
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

% get receiver height and latitude
H = pos_WGS84.h;
lat = pos_WGS84.lat;

% extract atmospheric values (calculated once when calling the V3GR)
p0 = atm(1);
e0 = atm(2);
T0 = atm(3);

gamma = 0.0065;     % average temperature lapse rate [K/m]
RL = 287.058;       % specific gas constant [m^2/(s^2*K)]

% (1) Pressure at height H
p = p0.*(1 - (gamma.*(H-H0) ./ T0)).^(Const.g0 ./ (gamma .* RL));

% (2) Correction to ZHD
dZHD = (0.0022768 .* (p - p0)) ./ (1 - 0.00266 .* cos(2.*lat) - 0.28e-6.*H0);

% (3) Correction to ZWD
dZWD = (-2.789.*e0./T0.^2) .* ((5383./T0)-0.7803) .* gamma .* (H-H0);

