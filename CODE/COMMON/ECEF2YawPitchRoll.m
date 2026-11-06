function [yaw, pitch, roll] = ECEF2YawPitchRoll(R, lat, lon, flu)
% This function recovers yaw, pitch and roll from a rotation matrix that
% rotates from the body frame to the ECEF frame. It is the inverse of
% YawPitchRoll2ECEF: yaw, pitch and roll are returned in the conventional
% (NED) sense, regardless of the body-axis labeling.
%
% The body frame is selected with the boolean flu:
%   flu = true  (default): FLU (Forward-Left-Up)
%   flu = false          : NED (North-East-Down)
% The FLU body axes relate to the NED body axes as:
% Forward = North, Left = -East, Up = -Down.
%
% INPUT:
%   R       3x3, rotation matrix (body -> ECEF), e.g. model.R2ECEF
%   lat     [rad], receiver geodetic latitude
%   lon     [rad], receiver geodetic longitude
%   flu     [bool], optional, true = FLU, false = NED
% OUTPUT:
%   yaw     [degree], rotation around the vertical axis
%   pitch   [degree], rotation around the transverse axis
%   roll    [degree], rotation around the longitudinal axis
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

% default to FLU body frame
if nargin < 4 || isempty(flu)
    flu = true;
end

% undo the FLU relabeling -> body expressed with NED axes
% (diag([1,-1,-1]) is its own inverse)
if flu
    R = R * diag([1, -1, -1]);
end

% build rotation from NED to ECEF using latitude and longitude
slat = sin(lat);
clat = cos(lat);
slon = sin(lon);
clon = cos(lon);
% rotation from NED to ECEF
Ren = [ -slat*clon, -slon, -clat*clon;
        -slat*slon,  clon, -clat*slon;
        clat,          0,     -slat ];

% undo NED -> ECEF rotation (Ren is orthonormal -> inverse = transpose)
% Rnb = Rz(yaw) * Ry(pitch) * Rx(roll)
Rnb = Ren.' * R;

% extract ZYX (yaw-pitch-roll) Euler angles [rad]
yaw   = atan2(  Rnb(2,1), Rnb(1,1) );
pitch = atan2( -Rnb(3,1), hypot(Rnb(3,2), Rnb(3,3)) );
roll  = atan2(  Rnb(3,2), Rnb(3,3) );

% convert yaw/pitch/roll from radians to degrees
yaw   = yaw   / pi * 180;
pitch = pitch / pi * 180;
roll  = roll  / pi * 180;
