function Adjust = applyIMUCorrections(Adjust, Epoch, settings)
% Applies IMU-derived virtual measurements and yaw corrections as
% sequential EKF updates after the main GNSS Kalman filter update.
%
% INPUT:
%   Adjust      struct, adjustment data after main KF update
%   Epoch       struct, epoch-specific data including Epoch.IMU
%   settings    struct, processing settings
% OUTPUT:
%   Adjust      updated with virtual measurement corrections
%
% Revision:
%   ...
%
% Created by Hoor Bano
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


if ~isfield(Epoch, 'IMU') || ~isfield(Adjust, 'quat_initialized') || ~Adjust.quat_initialized
    return
end
n_states = numel(Adjust.param);

isStatic  = Epoch.motionState == 0 || Epoch.ZUPT_prob > Const.IMU_ZUPT_THRESH_STATIC;
isQuasi   = Epoch.motionState == 1 && Epoch.ZUPT_prob > Const.IMU_ZUPT_THRESH_QUASI && ~isStatic;
isWalking = ~isStatic && ~isQuasi;

R_zupt = Const.IMU_SIGMA_ZUPT_VEL^2;                % ZUPT velocity noise
R_zaru_mat = eye(3) * Const.IMU_SIGMA_ZARU_GYRO^2;
R_nhc = Const.IMU_SIGMA_NHC_VEL^2;                  % NHC lateral velocity noise
R_yaw_doppler = Const.IMU_SIGMA_YAW_DOPPLER^2;      % yaw noise from Doppler


%% Common geometry
pos_ecef = Adjust.param(1:3);
[lat0, lon0, ~] = ecef2geodetic(wgs84Ellipsoid, pos_ecef(1), pos_ecef(2), pos_ecef(3));

R_ecef2enu = [-sind(lon0),            cosd(lon0),            0; ...
              -sind(lat0)*cosd(lon0), -sind(lat0)*sind(lon0), cosd(lat0); ...
               cosd(lat0)*cosd(lon0),  cosd(lat0)*sind(lon0), sind(lat0)];
R_enu2ecef = R_ecef2enu';

vel_ecef = Adjust.param(4:6);
vel_enu  = R_ecef2enu * vel_ecef;
speed_2d = norm(vel_enu(1:2));

gnss_bearing_valid = speed_2d > Const.IMU_NHC_MIN_SPEED;

if gnss_bearing_valid
    gnss_bearing = atan2(vel_enu(2), vel_enu(1));  % CCW from East
end


%% ZUPT: velocity = 0 when static
if isStatic
    H_zupt = zeros(3, n_states);
    H_zupt(1,4) = 1; H_zupt(2,5) = 1; H_zupt(3,6) = 1;

    % measurement matrix (selects velocity states)
    z_zupt = -vel_ecef;
    R_zupt_mat = diag([R_zupt R_zupt R_zupt]);

    [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_zupt, R_zupt_mat, z_zupt);
end


%% ZARU: when static, measured gyro = gyro bias
if isStatic && isfield(Epoch.IMU,'gyr_raw') && ~isempty(Epoch.IMU.gyr_raw)
    gyr_meas = mean(Epoch.IMU.gyr_raw, 1)'; 
    gyr_std  = std(Epoch.IMU.gyr_raw, 0, 1)';
    if norm(gyr_meas) < Const.IMU_ZARU_GATE_MEAN && max(gyr_std) < Const.IMU_ZARU_GATE_STD
        H_zaru = zeros(3, n_states);
        H_zaru(1,30) = 1; H_zaru(2,31) = 1; H_zaru(3,32) = 1;
        z_zaru = gyr_meas - Adjust.param(30:32);   
        [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_zaru, R_zaru_mat, z_zaru);
    end
end


%% NHC: zero lateral velocity along the horizontal direction perpendicular
if isWalking && gnss_bearing_valid
    % lateral horizontal unit vector (rotate forward +90 deg about Up):
    lat_enu = [-sin(gnss_bearing); cos(gnss_bearing); 0];

    % express lateral direction in ECEF (velocity states are ECEF)
    lat_ecef = R_enu2ecef * lat_enu;
    z_nhc = -(lat_ecef' * vel_ecef);

    H_nhc = zeros(1, n_states);
    H_nhc(1, 4:6) = lat_ecef';

    [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_nhc, R_nhc, z_nhc);
end


%% Doppler yaw another way
% if ~isfield(Adjust,'walk_count'),     Adjust.walk_count = 0;     end
% if ~isfield(Adjust,'yaw_gnss_accum'), Adjust.yaw_gnss_accum = 0; end
% 
% if isWalking && gnss_bearing_valid && speed_2d > 0.8
%     yaw_now = atan2(2*(Adjust.quat(1)*Adjust.quat(4)+Adjust.quat(2)*Adjust.quat(3)), ...
%                     1-2*(Adjust.quat(3)^2+Adjust.quat(4)^2));
%     d = wrapToPi(gnss_bearing - yaw_now);
%     Adjust.yaw_gnss_accum = Adjust.yaw_gnss_accum + d;
%     Adjust.walk_count     = Adjust.walk_count + 1;
% 
%     if Adjust.walk_count >= 50
%         mean_offset = Adjust.yaw_gnss_accum / Adjust.walk_count;
%         z_yaw = mean_offset;
%         H_yaw = zeros(1,n_states); H_yaw(1,26) = 1;
%         [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, ...
%                                                         H_yaw, deg2rad(15)^2, z_yaw);
%         dpsi = Adjust.param(26);
%         if abs(dpsi) > 1e-10
%             dq = [cos(dpsi/2);0;0;sin(dpsi/2)];
%             Adjust.quat = quatMultiply(Adjust.quat, dq);
%             Adjust.quat = Adjust.quat/norm(Adjust.quat);
%             Adjust.param(26) = 0;
%         end
%         Adjust.walk_count     = 0;
%         Adjust.yaw_gnss_accum = 0;
%     end
% end


%% Doppler yaw (comparing gnss bearing against forward_body heading)
% if isWalking && gnss_bearing_valid && isfield(Adjust, 'quat')
%     C_bn        = quat2rotm(quatconj(Adjust.quat'));
%     forward_enu = C_bn * forward_body;
%     Adjust.yaw_forward = atan2(forward_enu(2), forward_enu(1));  % CCW from East
% 
%     z_yaw = wrapToPi(gnss_bearing - Adjust.yaw_forward);
%     Adjust.z_yaw = z_yaw;
%     Adjust.gnss_bearing = gnss_bearing;
%     H_yaw = zeros(1, n_states);
%     H_yaw(1, 26) = 1;
%     [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_yaw, R_yaw_doppler, z_yaw);
% 
%     delta_psi = Adjust.param(26);
%     if abs(delta_psi) > 1e-10
%         dq = [cos(delta_psi/2); 0; 0; sin(delta_psi/2)];
%         Adjust.quat = quatMultiply(Adjust.quat, dq); % Sola 2017, Eqn. 198
%         Adjust.quat = Adjust.quat / norm(Adjust.quat);
%         Adjust.param(26) = 0;
%     end
% end

Adjust.bias_acc = Adjust.param(27:29);
Adjust.param(24:26) = 0;

end




function [param_new, sigma_new] = ekfUpdate(param, sigma, H, R, z)
    S         = H * sigma * H' + R;
    K         = sigma * H' / S;
    param_new = param + K * z;
    I_KH      = eye(size(sigma)) - K * H;
    sigma_new = I_KH * sigma * I_KH' + K * R * K';
    sigma_new = (sigma_new + sigma_new') / 2;
end
