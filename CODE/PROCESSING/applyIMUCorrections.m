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
%
% Created by Hoor Bano
% 
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


if ~isfield(Epoch, 'IMU') || ~isfield(Adjust, 'quat_initialized') || ~Adjust.quat_initialized
    return
end

n_states = numel(Adjust.param);

isStatic  = Epoch.motionState == 0 || Epoch.ZUPT_prob > 0.95;
isQuasi   = Epoch.motionState == 1 && Epoch.ZUPT_prob > 0.2 && ~isStatic;
isWalking = ~isStatic && ~isQuasi;

R_zupt = 0.05^2;                % ZUPT velocity noise
R_nhc = 0.09;                   % NHC lateral velocity noise 
R_zaru = deg2rad(0.5)^2;        % ZARU attitude rate noise 
R_yaw_doppler = deg2rad(10)^2;  % yaw noise from Doppler
R_yaw_mag = deg2rad(40)^2;      % yaw noise from magnetometer 
R_rp = deg2rad(20)^2; 
R_triad = diag([deg2rad(5)^2, deg2rad(5)^2, deg2rad(10)^2]);
mag_field_nominal = 48e-6;
mag_field_tol     = 20e-6;

% % forward body axis
% if isfield(Adjust, 'forward_body')
%     forward_body = Adjust.forward_body;
% else
    forward_body = [0; 0; 1]; % Flat phone in hand
% end

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

gnss_bearing_valid = speed_2d > 0.7;

if gnss_bearing_valid
    gnss_bearing = atan2(vel_enu(2), vel_enu(1));  % CCW from East
end

%% ZUPT: velocity = 0 when static
% if isStatic
%     H_zupt = zeros(3, n_states);
%     H_zupt(1,4) = 1; H_zupt(2,5) = 1; H_zupt(3,6) = 1;
% 
%     % measurement matrix (selects velocity states)
%     z_zupt = -vel_ecef;
%     R_zupt_mat = diag([R_zupt R_zupt R_zupt]);
% 
%     [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_zupt, R_zupt_mat, z_zupt);
% end

%% ZARU: attitude error drift = 0 when static
% if isStatic
%     imu_idx_att = 24:26;
%     att_err = Adjust.param(imu_idx_att);
% 
%     H_zaru = zeros(3, n_states);
%     H_zaru(1,24) = 1;  H_zaru(2,25) = 1;  H_zaru(3,26) = 1;
% 
%     % measurement matrix (selects attitude error states)
%     z_zaru = -att_err;
% 
%     R_zaru_mat = diag([R_zaru, R_zaru, R_zaru]);
%     [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_zaru, R_zaru_mat, z_zaru);
% end

%% Roll/Pitch correction from gravity
% if isQuasi && isfield(Epoch.IMU, 'acc_raw') && ~isempty(Epoch.IMU.acc_raw)
%     acc_mean_rp = mean(Epoch.IMU.acc_raw, 1);
%     ax = acc_mean_rp(1); ay = acc_mean_rp(2); az = acc_mean_rp(3);
%     acc_mag_now = norm([ax, ay, az]);
% 
%     if abs(acc_mag_now - 9.81) < 0.5
%         roll_acc  = atan2(ay, az);
%         pitch_acc = atan2(-ax, sqrt(ay^2 + az^2));
% 
%         % Extract current roll/pitch from quaternion
%         C_bn_rp = quat2rotm(quatconj(Adjust.quat'));
%         pitch_now = atan2(-C_bn_rp(3,1), sqrt(C_bn_rp(3,2)^2 + C_bn_rp(3,3)^2));
%         roll_now  = atan2(C_bn_rp(3,2), C_bn_rp(3,3));
% 
%         z_pitch = wrapToPi(pitch_acc - pitch_now);
%         z_roll  = wrapToPi(roll_acc  - roll_now);
% 
%         if abs(z_pitch) < deg2rad(10) && abs(z_roll) < deg2rad(10)
% 
%             % (Groves 2013, Ch.14; Farrell 2008, Ch.11)
%             H_pitch = zeros(1, n_states);
%             H_pitch(1, 24:26) = C_bn_rp(:,2)';   % body Y axis in nav = pitch axis
% 
%             H_roll = zeros(1, n_states);
%             H_roll(1, 24:26) = C_bn_rp(:,1)';    % body X axis in nav = roll axis
% 
%             [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_pitch, R_rp, z_pitch);
%             [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_roll, R_rp, z_roll);
% 
%             phi     = Adjust.param(24:26);
%             ang_phi = norm(phi);
%             if ang_phi > 1e-10
%                 n_phi = phi / ang_phi;
%                 % dq = quatconj of rotation by ang_phi around n_phi in nav frame
%                 dq_rp = [cos(ang_phi/2);          -n_phi(1)*sin(ang_phi/2); ...
%                         -n_phi(2)*sin(ang_phi/2); -n_phi(3)*sin(ang_phi/2)];
%                 Adjust.quat = quatMultiply(dq_rp, Adjust.quat);
%                 Adjust.quat = Adjust.quat / norm(Adjust.quat);
%                 Adjust.param(24:26) = 0;
%             end
%         end
%     end
% end

%% NHC: lateral velocity from forward_body = 0 when walking
% Projecting ECEF velocity onto lateral body axis (perpendicular to heading)
% if isWalking && isfield(Adjust, 'quat')
%     C_bn         = quat2rotm(quatconj(Adjust.quat'));
%     forward_enu  = C_bn * forward_body;
%     lateral_enu_raw  = [-forward_enu(2); forward_enu(1); 0];  % perpendicular to forward in horizontal plane
%     lateral_enu = lateral_enu_raw / norm(lateral_enu_raw);
%     lat_ecef     = R_enu2ecef * lateral_enu;
%     lat_vel      = lat_ecef' * vel_ecef;
% 
%     H_nhc = zeros(1, n_states);
%     H_nhc(1, 4:6) = lat_ecef';
% 
%     z_nhc = -lat_vel;
%     [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_nhc, R_nhc, z_nhc);
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
%         dq = [cos(delta_psi/2); 0; 0; -sin(delta_psi/2)];
%         Adjust.quat = quatMultiply(dq, Adjust.quat); % Sola 2017, Eqn. 198
%         Adjust.quat = Adjust.quat / norm(Adjust.quat);
%         Adjust.param(26) = 0;
%     end
% end

%% Yaw Correction from magnetometer (static state)
% Adjust.mag_strength = norm(Epoch.IMU.mag) * 1e-6;
% if isStatic && isfield(Epoch.IMU, 'mag') && ~isnan(Epoch.IMU.mag(1))
%     eul_mag  = quat2eul(quatconj(Adjust.quat'), 'ZYX');
%     roll_m = eul_mag(3); pitch_m = eul_mag(2); yaw_now_m = eul_mag(1);
% 
%     cr = cos(roll_m);  sr = sin(roll_m);
%     cp = cos(pitch_m); sp = sin(pitch_m);
% 
%     % Tilt compensation: project mag onto horizontal plane
%     R_tilt = [cp, sp*sr, sp*cr; 0, cr, -sr; -sp, cp*sr, cp*cr];
%     mag_level = R_tilt * Epoch.IMU.mag(:);
%     mag_yaw = atan2(mag_level(2), mag_level(1));
%     z_mag   = wrapToPi(mag_yaw - yaw_now_m);
% 
%     H_mag = zeros(1, n_states);
%     H_mag(1, 26) = 1;
%     [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, H_mag, R_yaw_mag, z_mag);
% 
%     delta_psi_mag = Adjust.param(26);
%     if abs(delta_psi_mag) > 1e-10
%         dq_mag = [cos(delta_psi_mag/2); 0; 0; -sin(delta_psi_mag/2)];
%         Adjust.quat = quatMultiply(dq_mag, Adjust.quat);
%         Adjust.quat = Adjust.quat / norm(Adjust.quat);
%         Adjust.param(26) = 0;
%     end
% end

%% TRIAD Method
% Two vector pairs in nav and body frame for direct C_bn estimate

% if isWalking && speed_2d > 0.7 && isfield(Epoch.IMU, 'acc_raw') && ~isempty(Epoch.IMU.acc_raw)
%     Adjust = triad_RotMatrix(Adjust, Epoch, vel_enu, R_triad);
% end

Adjust.bias_acc = Adjust.param(27:29);

end

function [param_new, sigma_new] = ekfUpdate(param, sigma, H, R, z)
    S         = H * sigma * H' + R;
    K         = sigma * H' / S;
    param_new = param + K * z;
    I_KH      = eye(size(sigma)) - K * H;
    sigma_new = I_KH * sigma * I_KH' + K * R * K';
    sigma_new = (sigma_new + sigma_new') / 2;
end