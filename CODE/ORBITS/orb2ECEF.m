function [drho, drho_dot] = orb2ECEF(x_sat, v_sat, dr, dr_dot)
% Transformation of along-track, across-track and radial component to ECEF
% orb2ECEF from RTCM 3.1 document Amendment 5
% 
% INPUT:
%   x_sat       broadcasted satellite position in ECEF, [m]
%   v_sat       broadcasted velocity in ECEF, [m/s]
%   dr          orbit position correction from corr2brdc-stream
%   dr_dot      orbit velocity correction from corr2brdc-stream
%               components of corrections vectors: radial, along-track, out-of-plane (across)
% OUTPUT:
%   drho        correction for position, ECEF
%   drho_dot    correction for velocity, ECEF
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% axes of orbital system in ECEF
e_along  = v_sat/norm(v_sat);                                   % along-track component
e_across = cross2(x_sat,v_sat) / norm(cross2(x_sat,v_sat));     % out-of-plane component
e_radial = cross2(e_along,e_across);                            % radial component
R = [e_radial, e_along, e_across];             	% build rotation matrix

% conversion of components radial, along-track, across-track/out-of-plane to ECEF
drho      = R * dr;
drho_dot  = R * dr_dot;