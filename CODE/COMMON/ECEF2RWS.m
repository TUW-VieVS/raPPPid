function Los_SWR = ECEF2RWS(Rot_X, time, param, leapsec)
% This function converts line-of-sight (LOS) vectors from Earth-Centered 
% Earth-Fixed (ECEF) frame into the RSW (Radial–Along-track–Cross-track) 
% coordinate frame of a satellite or spacecraft.
% 
% R (radial): along the satellite’s position vector
% S (along-track): direction of motion in orbit plane
% W (cross-track): normal to the orbital plane of R and S
% 
% INPUT:
%   Rot_X       [m], position of satellites in ECEF
%   time        [datetime], GPS time of current epoch
%   param       [m], predicted position and velocity
%   sats        satellites of current epoch
%   leapsec     [s], number of leap seconds 
% OUTPUT:
%	Los_SWR     [m], LOS vectors in SWR (be aware of the axes order!)
%
% Revision:
%   ...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% Earth rotation vector
OmegaE = [0; 0; Const.WE];     

% ECI to ECEF rotation
R_z = dcm_eci_2_ecef(time - (leapsec/86400));    

% Satellite position and velocity in ECI frame
r_eci = R_z' * param(1:3);
v_eci = R_z' * param(4:6) + cross(OmegaE, r_eci);

% orbital angular momentum vector
n = cross(r_eci,v_eci);

% transform LOS to ECI
Los_eci = R_z' * (Rot_X - param(1:3));
% compute components R, S, W
R = Los_eci'*(r_eci/norm(r_eci));                 % radial
S = Los_eci'*cross(n/norm(n),r_eci/norm(r_eci));  % along-track
W = Los_eci'*(n/norm(n));                         % cross-track
% save
Los_SWR = [S; W; R];
