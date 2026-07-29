function [R] = YawPitchRoll2ECEF(yaw, pitch, roll, lat, lon)
% This function calculates the orientation in ECEF using yaw, pitch, roll
% as an input. Roll, pitch, and yaw are defined here in the conventional
% way. The output is the rotation matrix from the body frame to the ECEF.
% ATTENTION: uses NED (North-East-DOWN)
% 
% INPUT:
%   yaw     [°], yaw rotates around the vertical axis.
%   pitch   [°], pitch rotates around the transverse axis
%   roll    [°], roll rotates around the longitudinal axis 
%   lat     [rad], latitude
%   lon     [rad], longitude
% OUTPUT:
%	R       rotation matrix
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% convert yaw/pitch/roll from degrees to radians
yaw = yaw/180*pi;
pitch = pitch/180*pi;
roll = roll/180*pi;

% compute sines and cosines for the Euler angles
cy = cos(yaw);
sy = sin(yaw);
cp = cos(pitch);
sp = sin(pitch);
cr = cos(roll);
sr = sin(roll);

% rotation about Z (yaw) - body heading relative to NED frame
Rz = [  cy -sy  0;
        sy  cy  0;
        0   0   1 ];
% rotation about Y (pitch) - nose up/down relative to NED
Ry = [  cp   0  sp;
        0    1   0;
       -sp   0  cp ];
% rotation about X (roll) - roll about body longitudinal axis
Rx = [  1   0    0;
        0  cr  -sr;
        0  sr   cr ];
% combined rotation from body frame to NED (North-East-Down) frame
Rnb = Rz * Ry * Rx;

% build rotation from NED to ECEF using latitude and longitude
slat = sin(lat);
clat = cos(lat);
slon = sin(lon);
clon = cos(lon);
% rotation from NED to ECEF
Ren = [ -slat*clon, -slon, -clat*clon;
        -slat*slon,  clon, -clat*slon;
        clat,          0,     -slat ];

% final rotation: body -> ECEF
R = Ren * Rnb;