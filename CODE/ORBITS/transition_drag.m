function [F_rad_drag, F_vel_drag] = transition_drag(param, sat)
% This function calculates the partial derivatives of the drag acceleration 
% components with respect to the radius and veloctiy of the satellite for 
% the Transition Matrix.
% 
% 
% INPUT:
%   param           satellite position and velocity, [m] and [m/s]
%   sat             struct, contains satellite parameter (e.g., mass)
% OUTPUT:
%	F_rad_drag      drag acceleration components for the radius
%   F_vel_drag      drag acceleration components for the velocity
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
H0_height = 7000;

altitude = r - Const.RE_equ; 
rhoAtmo = getAtmosphericDensity(altitude);
Ballistic = sat.mass / (sat.drag * sat.area);    % Satellite ballistic Coefficent 

v_rel = param(4:6) - cross([0;0;Const.WE], param(1:3));     % Calculating the relative velocity of the satellite 
K = -0.5*(1/Ballistic);

% Differentiating density wrt sat radius 
rho_dx = (-x*rhoAtmo) / (H0_height*r);
rho_dy = (-y*rhoAtmo) / (H0_height*r);
rho_dz = (-z*rhoAtmo) / (H0_height*r);

% Differentiating norm of velocity wrt sat radius 
norm_v_dx = (-v_rel(2)*Const.WE) / norm(v_rel);
norm_v_dy = ( v_rel(1)*Const.WE) / norm(v_rel);

v_dx = [0; -Const.WE; 0];
v_dy = [Const.WE; 0; 0];

% Calculating the partial derivatives of three dimensions of the drag 
% component wrt to the satellite radius
F_rad_drag_x = K*((rho_dx*norm(v_rel)*v_rel) + (rhoAtmo*(norm_v_dx*v_rel + norm(v_rel)*v_dx)));
F_rad_drag_y = K*((rho_dy*norm(v_rel)*v_rel) + (rhoAtmo*(norm_v_dy*v_rel + norm(v_rel)*v_dy)));
F_rad_drag_z = K*(rho_dz*norm(v_rel)*v_rel);

F_rad_drag = [F_rad_drag_x'; F_rad_drag_y'; F_rad_drag_z'];

% Calculating the partial derivatives of drag component wrt to the satellite velocity
F_vel_drag = K*rhoAtmo*(eye(3)*norm(v_rel) + ((v_rel*v_rel')/norm(v_rel)));