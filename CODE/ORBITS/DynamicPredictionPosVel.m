function [param_pred, Transition] = DynamicPredictionPosVel(param, ...
    Epoch, obs, settings, Transition, last_reset)
% blablabla
%
% INPUT:
%   param           current parameter vector
%   Epoch           struct, data of current epoch
%   obs             struct, observation-specific data
%   settings        struct, processing settings from GUI
%   Transition      Transition matrix
%   last_reset      
% OUTPUT:
%	param_pred      1x6, dynamic prediction of position and velocity
%   Transition      Transition matrix, updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************



% ||| check and comment
F_rad_grav = transition_radius(param, Epoch, obs, settings.ADJ.satellite);
[F_rad_drag, F_vel_drag] = transition_drag(param, settings.ADJ.satellite);

Omega_mat = [0,         -Const.WE,	0;
            Const.WE,   0,          0;
            0,          0,          0];

CoriolisMat = -2 * Omega_mat;

% CentrifugalMat = Omega_mat * Omega_mat;
CentrifugalMat =    [Const.WE^2,    0,              0;
                    0,              Const.WE^2,    0;
                    0,              0,              -Const.WE^2];

F_combined_rad = F_rad_grav + F_rad_drag + CentrifugalMat;
F_combined_vel = F_vel_drag + CoriolisMat;

F_matrix = [zeros(3) eye(3); F_combined_rad F_combined_vel];

Transition(1:6,1:6) = eye(6) + F_matrix*obs.interval;

opts = odeset('RelTol', 1e-9, 'AbsTol', 1e-9);

% create time vector        ||| check this
time_total = Epoch.gps_time - last_reset;
dt = obs.interval;
if Epoch.q > 1
    dt = Epoch.gps_time - Epoch.old.gps_time;       % time since last epoch
end
vec = time_total : dt : time_total+dt;


[~, state_vec] = ode45(@(t, X) rhs_orbital_motion(t, X, settings.ADJ.satellite,  Epoch, obs, [0;0;0]), ...
    vec, param(1:6), opts);
param_pred(1:6) = state_vec(end, 1:6)';