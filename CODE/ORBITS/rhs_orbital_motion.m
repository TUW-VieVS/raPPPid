function rhs_pos_vel = rhs_orbital_motion(t, X, sat,  Epoch, obs, dist_a)
% This function integrates over time to calculate the satellite position
% and velocity for the next epoch
% 
% INPUT:
%   X        	satellite position and velocity, [m] and [m/s]
%   Epoch       struct, contains epoch-specific data
%   obs         struct, contains observation-specific data
%   dist_a      some uncertainty acceleration  [m/s^2]
% OUTPUT:
%	rhs_pos_vel satellite position and velocity for next epoch, [m] and [m/s]
%
% Revision:
%   ...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

r = X(1:3);
v = X(4:6);


%% J2 Perturbation Acceleration 

aJ2 = J2_acceleration(r, Const.J2, Const.GM, Const.RE_equ);

%% Atmospheric Drag

altitude = norm(r) - Const.RE_equ; 
rhoAtmo = getAtmosphericDensity(altitude);
Ballistic = sat.mass / (sat.drag * sat.area);
v_rel = v - cross([0;0;Const.WE], r);
dragA = -0.5 * rhoAtmo * (1/Ballistic) * norm(v_rel) * v_rel;

%% Third Body Accelerations

h = mod(Epoch.gps_time, 86400)/3600;
rMoon2Sat = r - moonPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
rMoon2Earth = -moonPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
rSun2Sat = r - 1e3*sunPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
rSun2Earth = -1e3*sunPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);

aMoon = -Const.Moon_muM*((rMoon2Sat / norm(rMoon2Sat)^3) -  (rMoon2Earth / norm(rMoon2Earth)^3));
aSun  = -Const.Sun_muS*((rSun2Sat / norm(rSun2Sat)^3) -  (rSun2Earth / norm(rSun2Earth)^3));

%% Solar Radiation Pressure
R = rSun2Sat;
d = norm(R);
alpha = (Const.P_srp * sat.solar * sat.area) / sat.mass;
a_srp = -alpha * (Const.AU/d)^2 * (R/d);

%% Disturbance torque

Dist = dist_a;

%% Fictitious forces in ECEF (rotating frame)

omega_vec = [0; 0; Const.WE];
Coriolis   = -2 * cross(omega_vec, v);
Centrifugal= -cross(omega_vec, cross(omega_vec, r));

%% Right-hand side equations

d_r = v;

d_v = ((-Const.GM / norm(r)^3) * r) + aJ2 + aSun + aMoon + Dist + dragA + a_srp + Centrifugal + Coriolis;

rhs_pos_vel = [d_r; d_v];

end
