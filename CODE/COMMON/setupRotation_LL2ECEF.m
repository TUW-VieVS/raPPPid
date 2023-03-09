function  R = setupRotation_LL2ECEF(phi,lam)
% Rotation matrix from Local Level (NEU) to ECEF Frame  - 
% Local Level origin in point with phi and lam
% can be interpreted as the axes of the Local Level Frame expressed in the
% ECEF frame
% 
% INPUT:
%   phi         latitude [rad]
%   lam         longitude [rad]
% OUTPUT:
%	R           3x3, rotation matrix from Local Level to ECEF frame
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% North
R(1,1) = -sin(phi)*cos(lam);
R(2,1) = -sin(phi)*sin(lam);
R(3,1) =  cos(phi);

% East
R(1,2) = -sin(lam);
R(2,2) =  cos(lam);
R(3,2) =  0;

% Up (Left-handed)
R(1,3) =  cos(phi)*cos(lam);
R(2,3) =  cos(phi)*sin(lam);
R(3,3) =  sin(phi);
