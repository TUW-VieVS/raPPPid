function [X, V] = SatPos_brdc_GLO(Ttr, prn, Eph)
% Calculates the satellite position for a Glonass satellite from the 
% broadcast navigation message.
% 
% GLONASS ICD 2008: 
% A.3.1.2.Simplify of algorithm for re-calculation of ephemeris to current time 
% 
% INPUT:
%   Ttr     time of signal emission in GPS time [sow]
%   prn     satellite number
%   Eph     struct, Glonass broadcast ephemeris which were read in
% OUTPUT:
%   X   	satellite position in PZ90, [m]
%   V   	satellite velocity in PZ90, [m]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


w = Const.PZ90_WE;      % Earth´s rotation rate, [rad/s]

% For details on variable Eph check read_brdc.m and subfunctions
Eph_prn = Eph(1,:);                 % prns of navigation data
bool_prn = (Eph_prn == (prn-100));  % columns of current prn
% get variables
x 	= Eph(5,bool_prn);  	% PZ90, [km]
y   = Eph(6,bool_prn);
z   = Eph(7,bool_prn);
v_x = Eph(8,bool_prn);   	% PZ90, [km/s]
v_y = Eph(9,bool_prn);
v_z = Eph(10,bool_prn);
a_x = Eph(11,bool_prn);  	% PZ90, [km/s^2]
a_y = Eph(12,bool_prn);
a_z = Eph(13,bool_prn);
toe = Eph(18,bool_prn);   	% epoch of ephemerides, GPS time [sow]

% somehow this works without transforming the coordinates to intertial
% reference frame???
% theta_G0 = 0; 	% [rad]
% theta_Ge = theta_G0 + w*(toe - 10800);	% [rad]
% % transform position and velocity from ECEF Greenwich coordinate system 
% % PZ-90 to absolute (intertial) coordinate system
% % position
% X = x .* cos(theta_Ge) - y .* sin(theta_Ge);
% Y = x .* sin(theta_Ge) + y .* cos(theta_Ge);
% Z = z;
% % velocity
% V_x = v_x .* cos(theta_Ge) - v_y .* sin(theta_Ge) - w * Y;
% V_y = v_x .* sin(theta_Ge) + v_y .* cos(theta_Ge) + w * X;
% V_z = v_z;
% % acceleration
% A_x = a_x .* cos(theta_Ge) - a_y .* sin(theta_Ge);
% A_y = a_x .* sin(theta_Ge) + a_y .* cos(theta_Ge);
% A_z = a_z;
% % put together
% pos = [ X ;  Y ;  Z ]';
% vel = [V_x; V_y; V_z]';
% acc = [A_x; A_y; A_z]';

% put together
pos = [ x ;  y ;  z ]';
vel = [v_x; v_y; v_z]';
acc = [a_x; a_y; a_z]';

% Runge Kutta 4 orbit integration
[X, V] = rungeKutta4(toe', pos*1000, vel*1000, acc*1000, Ttr);

