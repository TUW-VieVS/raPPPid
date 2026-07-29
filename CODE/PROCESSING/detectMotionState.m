function [motionState, ZUPT_prob] = detectMotionState(Epoch)
% Classifies the motion state for the current epoch using raw IMU data
% stored in Epoch.IMU. This function uses statistical thresholds and 
% Gaussian-based scoring to distinguish between three motion states: 
% Static, Quasi-Static, and Walking. These are stored into the variable 
% motionState:
%   0 = static
%   1 = quasi-static
%   2 = walking
%
% INPUT:
%   Epoch       struct, must contain Epoch.IMU.acc_raw [m/s^2] and
%                   Epoch.IMU.gyr_raw [rad/s]
%               (N×3 matrices at 100Hz, bias already subtracted)
%
% OUTPUT:
%   motionState     scalar integer, motion class for this epoch [0, 1, or 2]
%   ZUPT_prob       scalar [0-1], probability of being stationary
%
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% define some constants
tol_acc = 0.3;              % [m/s^2], tolerance for gravity magnitude deviation
tol_ang = 10/180*pi;        % [°] to [rad], tolerance for angular velocity 
thresh_acc = 0.1;           % [m/s^2], maximum stdev for acceleration on any axis
thresh_ang = 0.01;          % [rad], maximum stdev for angular velocity on any axis
thresh_linear_acc = 0.25;   % [m/s^2], threshold for linear acceleration


% set defaults assuming most active state
motionState = 2;   % walking
ZUPT_prob   = 0;

% check if the required IMU fields exist
if ~isfield(Epoch, 'IMU') || ...
   ~isfield(Epoch.IMU, 'acc_raw') || isempty(Epoch.IMU.acc_raw) || ...
   ~isfield(Epoch.IMU, 'gyr_raw') || isempty(Epoch.IMU.gyr_raw)
    return
end

% get variables
acc  = Epoch.IMU.acc_raw;   % [N×3] m/s^2
gyro = Epoch.IMU.gyr_raw;   % [N×3] rad/s

% calculate the magnitude of the vectors for every sample
acc_mag  = vecnorm(acc,  2, 2);
gyro_mag = vecnorm(gyro, 2, 2); 



%% ZUPT probability 
% score for acceleration: how close is the magnitude to standard gravity?
s_acc  = exp(-(abs(acc_mag - Const.g0) / tol_acc).^2);
% score for gyroscope: how close is the angular velocity to 0 rad/s?
s_gyro = exp(-(gyro_mag / tol_ang).^2);

% final probability is the mean of the minimum score of both sensors across the epoch
ZUPT_prob = mean(min(s_acc, s_gyro));   % epoch mean



%% Static detection
% static detection relies on the standard deviation (noise floor).
std_acc  = std(acc,  0, 1);   % [1×3], std acceleration per axis
std_gyro = std(gyro, 0, 1);   % [1×3], std gyroscope per axis

% check with thresholds if static
isTrueStatic = all(std_acc  < thresh_acc) && all(std_gyro < thresh_ang);  



%% Quasi-static detection
% for example: tilt

% calculate mean gravity direction and its norm
g_hat  = mean(acc, 1);                       
g_norm = norm(g_hat);

isQuasiStatic = false;
if g_norm > 1e-3
    % normalize to create a unit gravity vector
    g_hat  = g_hat / g_norm;            
    % removing gravity component to isolate linear motion
    a_lin  = acc - (acc * g_hat') .* g_hat;  
    % check if mean magnitude of the remaining linear acceleration is below threshold
    isQuasiStatic = mean(vecnorm(a_lin, 2, 2)) < thresh_linear_acc;
end



%% final classification, priority: static > quasi-Static > walking
if isTrueStatic
    motionState = 0;    % static
elseif isQuasiStatic
    motionState = 1;    % quasi-static
else
    motionState = 2;   % walking
end
