function [F_rad_grav] = transition_radius(param, Epoch, obs, sat)
% This function calculates the partial derivatives of the acceleration 
% components with respect to the radius of the satellite for the Transition 
% Matrix. The drag component is calculated in transition_drag.m
% Reference: Space Flight Dynamics (Chapter 5) by Craig A. Kluever
% 
% 
% INPUT:
%   param           satellite position and velocity, [m] and [m/s]
%   Epoch           struct, contains epoch-specific data
%   obs             struct, contains observation-specific data
%   sat             struct, contains satellite parameter (e.g., mass)
% OUTPUT:
%	F_rad_grav      acceleration components for the Transition Matrix
%
% Revision:
%   ...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


r = norm(param(1:3));
x = param(1); y = param(2); z = param(3);

%% Two Body Gravity
dx_two_body = (-Const.GM/r^3)*eye(3) + (3*Const.GM/r^5)*param(1:3)*param(1:3)'; % Component of two body gravity term wrt satellite radius

%% Third Body Perturbations
h = mod(Epoch.gps_time, 86400) / 3600; % Current time of day in decimal hours 
rMoon2Sat = r - moonPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h); % Radius from Moon to the Satellite
rSun2Sat = r - 1e3*sunPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h); % Radius from Sun to the Satellite

dA_Moon = -Const.Moon_muM * (eye(3)/norm(rMoon2Sat)^3 - 3*(rMoon2Sat*rMoon2Sat')/norm(rMoon2Sat)^5); % Third Body Acceleration wrt satellite radius Term due to Moon
dA_Sun = -Const.Sun_muS * (eye(3)/norm(rSun2Sat)^3 - 3*(rSun2Sat*rSun2Sat')/norm(rSun2Sat)^5); % Third Body Acceleration Term wrt satellite radius due to Sun

%% Solar Radiation Pressure
R = rSun2Sat;
d = norm(R);
alpha_srp = (Const.P_srp * sat.solar * sat.area) / sat.mass; % Scalar acceleration magnitude for the SRP

I = eye(3); % Identity Matrix
A_srp = -alpha_srp * Const.AU^2 * (I/d^3 - 3*(R*R')/d^5); % Component of SRP acceleration term wrt satellite radius

%% J2 Perturbation  

% Computing the overall J2 perturbation amplitude scalar 
alpha = 1.5*Const.J2*Const.GM*Const.RE_equ^2/r^5;

% Computing partial derivatives of alpha wrt satellite radius
alpha_dx = -7.5*Const.J2*Const.GM*Const.RE_equ^2*x/r^7;
alpha_dy = -7.5*Const.J2*Const.GM*Const.RE_equ^2*y/r^7;
alpha_dz = -7.5*Const.J2*Const.GM*Const.RE_equ^2*z/r^7;

% Defining the shape factors (fx, fy, fz for J2)
fx = x*((5*z^2/r^2) - 1);
fy = y*((5*z^2/r^2) - 1);
fz = z*((5*z^2/r^2) - 3);

% Computing the partial derivatives of fx wrt satellite radius
dfx_dx = ((5*z^2/r^2) - 1) - (10*x^2*z^2/r^4);
dfx_dy = -10*x*y*z^2/r^4;
dfx_dz = 10*x*z*(x^2+y^2)/r^4;

% Computing the partial derivatives of fy wrt satellite radius
dfy_dx = -10*x*y*z^2/r^4;
dfy_dy = ((5*z^2/r^2) - 1) - (10*y^2*z^2/r^4);
dfy_dz = 10*y*z*(x^2+y^2)/r^4;

% Computing the partial derivatives of fz wrt satellite radius
dfz_dx = -10*x*z^3/r^4;
dfz_dy = -10*y*z^3/r^4;
dfz_dz = (5*z^2/r^2) + (10*z^2*(x^2+y^2)/r^4);

dA_dJ2 = zeros(3,3);

% Assembling the components 
dA_dJ2(1,1) = alpha_dx*fx + alpha*dfx_dx;
dA_dJ2(1,2) = alpha_dy*fx + alpha*dfx_dy;
dA_dJ2(1,3) = alpha_dz*fx + alpha*dfx_dz;

dA_dJ2(2,1) = alpha_dx*fy + alpha*dfy_dx;
dA_dJ2(2,2) = alpha_dy*fy + alpha*dfy_dy;
dA_dJ2(2,3) = alpha_dz*fy + alpha*dfy_dz;

dA_dJ2(3,1) = alpha_dx*fz + alpha*dfz_dx;
dA_dJ2(3,2) = alpha_dy*fz + alpha*dfz_dy;
dA_dJ2(3,3) = alpha_dz*fz + alpha*dfz_dz;

%% Sum 
F_rad_grav = dx_two_body + dA_dJ2 + dA_Sun + dA_Moon + A_srp;



