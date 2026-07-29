function [az, el] = Rot2AzimuthElevation(R, los0, ant_orientation)
% This function calculates the azimuth and elevation to a specific GNSS
% satellite in the coordinate frame of a moving vehicle (e.g., drone).
% ATTENTION: uses NED (North-East-DOWN)
% 
% INPUT:
%   R           3x3, rotation matrix from body to ECEF
%   los0        3x1, unit line of sight vector (receiver to satellite)
% OUTPUT:
%	az          azimuth from north positive clockwise [°]
%	el          elevation angle [°]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

% transform line of sight vector into the body frame
los0_BF = R' * los0;

% components in body frame
x = los0_BF(1);     % points forwards
y = los0_BF(2);     % to the right
z = los0_BF(3);     % points downwards

% calculate azimuth and elevation in [°]
az = atan2(y, x) * 180 / pi;
el = atan2(-z, sqrt(x^2 + y^2)) * 180 / pi;

% consider mounting of antenna and adjust azimuth
if strcmp(ant_orientation, 'backwards')
    % the north direction of the GNSS antenna points in backwards directions 
    % of movement (or backwards relative to the body forward direction).
    az = az - 180;      % rotate azimuth by 180°
end

% make sure that azimuth is positive and in [0, 360)
if az < 0                   
    az = az + 360;
end