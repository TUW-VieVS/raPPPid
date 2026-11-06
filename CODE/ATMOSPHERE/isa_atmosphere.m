function [P_H, e_hPa, T_H] = isa_atmosphere(H)
% This functions computes standard atmospheric conditions up to 20,000 m.
% According to https://www.atmospheris.org/iso-2533
% 
% INPUT:
%   H       Geometric / Orthometric altitude [meters]
% OUTPUT:
%   P_H     Total Atmospheric Pressure [hPa]
%   e_hPa   Water Vapor Pressure [hPa] (Modeled decay; 0 in pure ISA)
%   T_H     Absolute Temperature [Kelvin]
%
% Revision:
%   ...
% 
% Created by Paul Dohnal
% 
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% Constants
gn   = 9.80665;     % Acceleration of gravity [m/s^2]
R    = 287.05287;   % Gas constant for dry air [J/(kg*K)]

% Sea level reference conditions (ISA)
Tb   = 288.15;      % [K]
Pb   = 1013.25;     % [hPa]
beta   = -0.0065;     % Lapse rate in Troposphere [K/m]

% Water vapor model reference
e0   = 11.6;        % Mean surface water vapor pressure [hPa]
He   = 2000;        % Scale height for water vapor decay [m]

% Layer 0: Troposphere (0 to 11,000 m)
if H <= 11000
    T_H   = Tb + beta * H;
    P_H = Pb * (T_H / Tb)^(-gn / (beta * R));

    % Layer 1: Tropopause / Lower Stratosphere (11,000 m to 20,000 m)
elseif H <= 20000
    H11   = 11000;
    T11   = Tb + beta * H11; % 216.65 K
    P11   = Pb * (T11 / Tb)^(-gn / (beta * R)); % ~226.32 hPa

    T_H   = T11;
    P_H = P11 * exp(-gn * (H - H11) / (R * T11));
else
    error('Altitude exceeds 20,000 m limit for this basic ISA layer model.');
end

% Water vapor pressure model (NOT ISA)
% Note: Set e0 = 0 if strict dry ISA definition is required.
e_hPa = e0 * exp(-H / He); 
end