function forward_body = estimateForwardBodyVector(acc_raw, prev_forward_body)
% Estimates the forward body-frame unit vector using PCA on raw IMU 
% accelerations. Works for any phone orientation (flat, portrait, diagonal).
% 
% Deng, Z.-A., Wang, G., Hu, Y., & Cui, Y. (2016). Carrying Position 
% Independent User Heading Estimation for Indoor Pedestrian Navigation with 
% Smartphones. Sensors, 16(5), 677. https://doi.org/10.3390/s16050677
% 
% Wang, B., Liu, X., Yu, B., Jia, R., & Gan, X. (2018). Pedestrian Dead 
% Reckoning Based on Motion Mode Recognition Using a Smartphone. Sensors, 
% 18(6), 1811. https://doi.org/10.3390/s18061811
% 
% Groves, P. D. (2008). Principles of GNSS, inertial, and multisensor 
% integrated navigation systems. Artech House
%
% INPUT:
%   acc_raw           [N×3] raw accelerometer samples (body frame)
%   prev_forward_body [3×1] forward vector from previous epoch
%
% OUTPUT:
%   forward_body     [3×1] unit vector in body frame, walking direction
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

acc_mean = mean(acc_raw, 1)'; 
g_norm   = norm(acc_mean);

if g_norm < 1.0
    forward_body = prev_forward_body;
    if isempty(forward_body)
        forward_body = [0; 1; 0];  % default flat phone 
    end
    return
end

g_hat = acc_mean / g_norm; 
proj = acc_raw * g_hat; 
acc_lin = acc_raw - proj * g_hat'; % gravity-removed

% Gravity removal is more robust for arbitrary orientations
acc_centered = acc_lin - mean(acc_lin, 1); 

if size(acc_centered, 1) < 3
    forward_body = [0; 1; 0];
    return
end

[~, ~, V] = svd(acc_centered, 'econ');
forward_body_candidate = V(:, 1); 
forward_body = forward_body_candidate / norm(forward_body_candidate);

end