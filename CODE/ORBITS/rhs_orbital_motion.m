function rhs_pos_vel = rhs_orbital_motion(t, X, sat,  Epoch, obs, dist_a, t0, isfloat)
% This function integrates over time to calculate the satellite position
% and velocity for the next epoch
%
% INPUT:
%   X        	satellite position and velocity in ECEF, [m] and [m/s]
%   Epoch       struct, contains epoch-specific data
%   obs         struct, contains observation-specific data
%   dist_a      some uncertainty acceleration  [m/s^2]
%   t0   
%   isfloat     boolean, true if valid float solution (from Adjust.float)
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

utc_time = Epoch.time - (obs.leap_sec/86400) + ((t - t0)/86400);
Ci2e = dcm_eci_2_ecef(utc_time);
r_eci = Ci2e.' * r;
v_eci = Ci2e.' * v + cross([0;0;Const.WE], r_eci);

%% J2 Perturbation Acceleration

aJ2 = J2_acceleration(r, Const.J2, Const.GM, Const.RE_equ);

%% Atmospheric Drag

altitude = norm(r) - Const.RE_equ;
rhoAtmo = getAtmosphericDensity(altitude);
Ballistic = sat.mass / (sat.drag * sat.area);
% the atmosphere co-rotates with the Earth, therefore v (ECEF) is already
% the air-relative velocity
dragA = -0.5 * rhoAtmo * (1/Ballistic) * norm(v) * v;

%% Third Body Accelerations

h = mod(Epoch.gps_time + (t - t0), 86400)/3600;
moon_ECEF = moonPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
sun_ECEF = 1e3*sunPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);

rMoon2Sat = r - moon_ECEF;
rMoon2Earth = -moon_ECEF;
rSun2Sat = r - sun_ECEF;
rSun2Earth = -sun_ECEF;

aMoon = -Const.Moon_muM*((rMoon2Sat / norm(rMoon2Sat)^3) -  (rMoon2Earth / norm(rMoon2Earth)^3));
aSun = -Const.Sun_muS*((rSun2Sat / norm(rSun2Sat)^3) -  (rSun2Earth / norm(rSun2Earth)^3));


%% Solar Radiation Pressure

sun_ECI = Ci2e.' * sun_ECEF;
los = strcmpi(sight(r_eci/1e3, sun_ECI/1e3, 'e'),'yes');
R = r_eci - sun_ECI;
d = norm(R);
alpha = (Const.P_srp * sat.solar * sat.area) / sat.mass;

a_srp_eci = alpha * (Const.AU/d)^2 * (R/d) * los;
a_srp = Ci2e * a_srp_eci;

%% Disturbance acceleration

% Empirical coefficients
sat.emp.ARc  = 0;
sat.emp.ARs  = 0;
sat.emp.ASc  = 6.4e-8;
sat.emp.ASs  = -2.3e-8;
sat.emp.ASc2 = -1.70e-7;
sat.emp.ASs2 = -1.30e-7;
sat.emp.AWc  = 0;
sat.emp.AWs  = 0;

Dist = dist_a;
if isfloat
    Rhat = r_eci / norm(r_eci);
    h = cross(r_eci, v_eci);
    What = h / norm(h);
    Shat = cross(What, Rhat);
    Shat = Shat / norm(Shat);

    C_rsw2eci = [Rhat, Shat, What];

    % Argument of latitude u 
    khat = [0;0;1];
    hhat = What;

    n = cross(khat, hhat);
    if norm(n) < 1e-12
        % near-equatorial fallback
        ex = [1;0;0];
        exp = ex - dot(ex,hhat)*hhat;
        exhat = exp / norm(exp);
        eyhat = cross(hhat, exhat);
        u = atan2(dot(r_eci, eyhat), dot(r_eci, exhat));
    else
        nhat = n / norm(n);
        u = atan2( dot(r_eci, cross(nhat, hhat)), dot(r_eci, nhat) );
    end

    % Empirical acceleration in RSW
    ARc  = sat.emp.ARc;   ARs  = sat.emp.ARs;
    ASc  = sat.emp.ASc;   ASs  = sat.emp.ASs;
    ASc2 = sat.emp.ASc2;  ASs2 = sat.emp.ASs2;
    AWc  = sat.emp.AWc;   AWs  = sat.emp.AWs;

    a_rsw = [ARc*cos(u) + ARs*sin(u); ...
             ASc*cos(u) + ASs*sin(u) + ASc2*cos(2*u) + ASs2*sin(2*u); ...
             AWc*cos(u) + AWs*sin(u)];

    a_emp_ecef = Ci2e * (C_rsw2eci * a_rsw);
    Dist = dist_a + a_emp_ecef;
end


%% Fictitious forces in ECEF (rotating frame)

omega_vec = [0; 0; Const.WE];
Coriolis   = -2 * cross(omega_vec, v);
Centrifugal= -cross(omega_vec, cross(omega_vec, r));

%% Right-hand side equations

d_r = v;

d_v = ((-Const.GM / norm(r)^3) * r) + aJ2 + aSun + aMoon + Dist + dragA + a_srp + Centrifugal + Coriolis;

rhs_pos_vel = [d_r; d_v];

end
