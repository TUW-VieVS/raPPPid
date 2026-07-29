function [X_rot, V_rot] = correctEarthRotation(tau, X, V)
% This function corrects the satellite position and velocity for the Earth
% rotation during the signal's travel time.
%
% INPUT:
%   tau     travel time of GNSS signal, corrected for receiver clock error
%   X       3x1, satellite position in ECEF
%   V       3x1, satellite velocities in ECEF
% OUTPUT:
%   X_rot   3x1, corrected satellite position in ECEF
%   V_rot   3x1, corrected satellite velocities in ECEF
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

% calculate angle of rotation, how much Earth has rotated during travel time
omegatau = Const.WE * tau;      % [rad]

% build rotation matrix (around z-axis)
R3 = [  cos(omegatau) sin(omegatau)     0;
       -sin(omegatau) cos(omegatau)     0;
        0             0                 1];

% correct satellite position and velocits
X_rot = R3*X;
V_rot = R3*V;