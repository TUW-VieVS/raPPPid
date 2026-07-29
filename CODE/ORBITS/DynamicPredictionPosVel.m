function [param_pred, Transition] = DynamicPredictionPosVel(...
    param, Epoch, obs, settings, Transition, bool_float)
% This function performs a dynamic prediction and propagate the position 
% and velocity state using orbital motion dynamics and numerical 
% integration.
% 
% INPUT:
%   param           current parameter vector
%   Epoch           struct, data of current epoch
%   obs             struct, observation-specific data
%   settings        struct, processing settings from GUI
%   Transition      Transition matrix
%   bool_float      boolean, true if valid float solution
% OUTPUT:
%	param_pred      1x6, dynamic prediction of position and velocity
%   Transition      Transition matrix, updated
%
% Revision:
%   ...
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************



% check if filter runs currently forwards or backwards
bool_bwd = strcmp(settings.ADJ.filter.direction, 'Backwards') || ...
    (strcmp(settings.ADJ.filter.direction, 'Bwd-Fwd') && ~Epoch.bool_2nd) ||...
    (strcmp(settings.ADJ.filter.direction, 'Fwd-Bwd') &&  Epoch.bool_2nd);

% build vector for numerical integration
dt = Epoch.gps_time - Epoch.old.gps_time;
vec = Epoch.old.gps_time : dt : Epoch.gps_time;

% fallback (e.g., first epoch)
if isempty(Epoch.old.gps_time)
    dt = obs.interval;              % use observation interval instead of time difference to last epoch           
    if bool_bwd; dt = -dt; end      % negative dt for backwards
    vec = Epoch.gps_time-dt : dt : Epoch.gps_time;
end

% Compute accelerations from different physical effects
F_rad_grav = transition_radius(param, Epoch, obs, settings.KINE.satellite);     % gravity acceleration [m/s²]
[F_rad_drag, F_vel_drag] = transition_drag(param, settings.KINE.satellite);     % drag acceleration/velocity

% Earth rotation matrices
Omega_mat = [0,         -Const.WE,	0;
            Const.WE,   0,          0;
            0,          0,          0];
CoriolisMat = -2 * Omega_mat;

% Centrifugal acceleration
CentrifugalMat =    [Const.WE^2,    0,              0;
                    0,              Const.WE^2,     0;
                    0,              0,              0];

F_combined_rad = F_rad_grav + F_rad_drag + CentrifugalMat;  % total radial acceleration
F_combined_vel = F_vel_drag + CoriolisMat;                  % velocity-dependent acceleration

% state transition matrix
F_matrix = [zeros(3) eye(3); F_combined_rad F_combined_vel];

% discrete-time approximation F ≈ I + A * dt (valid for small dt)
Transition(1:6,1:6) = eye(6) + F_matrix*dt;

opts = odeset('RelTol', 1e-9, 'AbsTol', 1e-9);

% numerical integration of full orbital dynamics
[~, state_vec] = ode45(@(t, X) rhs_orbital_motion(t, X, settings.KINE.satellite, ...
    Epoch, obs, [0;0;0], vec(1), bool_float), vec, param(1:6), opts);
param_pred(1:6) = state_vec(end, 1:6)';