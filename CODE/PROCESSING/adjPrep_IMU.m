function [Adjust, imu_available, S_fn] = adjPrep_IMU(Adjust, Epoch)
% This function performs the IMU first-time initialization (attitude and
% bias) and the IMU mechanization (strap-down integration of the raw IMU
% samples) used to predict the filter state. It is called from adjPrep_ZD
% and adjPrep_iono during the prediction step of the parameter estimation.
%
% INPUT:
%   Adjust          struct, all adjustment relevant data
%   Epoch           struct, epoch-specific data for current epoch
% OUTPUT:
%   Adjust          updated (quaternion, biases, IMU position/velocity, ...)
%   imu_available   boolean, true if IMU mechanization was performed
%   S_fn            skew-symmetric matrix of last specific force (for the
%                   Transition matrix coupling), zeros(3) if not available
% 
%Revision:
%   ...
%
% Created by Hoor Bano
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


imu_available = false;
S_fn = zeros(3);

%% ----- IMU first-time initialization -----
% Runs once when float solution exists and real IMU data first arrives.
imu_data_ok = isfield(Epoch, 'IMU')         && isfield(Epoch.IMU, 'acc_raw') && ...
              ~isempty(Epoch.IMU.acc_raw)   && size(Epoch.IMU.acc_raw,1) >= 5 && ...
              isfield(Epoch.IMU, 'gyr_raw') && ~isempty(Epoch.IMU.gyr_raw);
imu_static = (isfield(Epoch,'motionState') && Epoch.motionState == 0) || ...
             (isfield(Epoch,'ZUPT_prob') && Epoch.ZUPT_prob > Const.IMU_ZUPT_THRESH_STATIC);

if ~Adjust.quat_initialized && imu_data_ok && imu_static
    g_n      = [0; 0; -Const.g0];
    acc_mean = mean(Epoch.IMU.acc_raw, 1)';

    ax = acc_mean(1);  ay = acc_mean(2);  az = acc_mean(3);
    roll_init  = atan2(ay, az);
    pitch_init = atan2(-ax, sqrt(ay^2 + az^2));

    % ---- Yaw Initialization: Android yaw only when body +Y is horizontal enough
    g_b   = acc_mean / norm(acc_mean);
    betaY = asind(abs(g_b(2))); % tilt of body +Y from horizontal

    yaw_init = 0;
    if isfield(Epoch.IMU,'OrientationDeg') && ~isempty(Epoch.IMU.OrientationDeg)
        % yaw_android_1 = mean(Epoch.IMU.OrientationDeg(:,1));  % CW from magnetic North
        yaw_android = rad2deg(angle(mean(exp(1i*deg2rad(Epoch.IMU.OrientationDeg(:,1))))));
        yaw_init = -deg2rad(wrapTo180(yaw_android));
    end

    cp = cos(pitch_init);  sp = sin(pitch_init);
    cr = cos(roll_init);   sr = sin(roll_init);

    % Tilt-only attitude
    Cbn_level = [cp,  sp*sr,  sp*cr;
                 0,   cr,    -sr;
                -sp,  cp*sr,  cp*cr];

    % Heading about nav Up
    Rz_nav = [cos(yaw_init), -sin(yaw_init), 0;
              sin(yaw_init),  cos(yaw_init), 0;
              0,              0,             1];

    Cbn_init = Rz_nav * Cbn_level;		% body-to-navigation rotation matrix

    Adjust.quat = rotm2quat(Cbn_init)'; % q_nb

    b_residual = acc_mean + Cbn_init' * g_n;
    Adjust.bias_acc = b_residual;

    fprintf('[IMU INIT] roll=%.1f  pitch=%.1f  yaw=%.1f deg  betaY=%.1f\n', ...
            rad2deg(roll_init), rad2deg(pitch_init), rad2deg(yaw_init), betaY)

    Adjust.param(24:26) = 0;
    Adjust.param(27:29) = b_residual;
    Adjust.param(30:32) = 0;

    Adjust.param_sigma(24:26, 24:26) = eye(3) * Const.IMU_INIT_VAR_ATT;
    Adjust.param_sigma(27:29, 27:29) = eye(3) * Const.IMU_INIT_VAR_BIAS_MECH;
    Adjust.param_sigma(30:32, 30:32) = eye(3) * Const.IMU_INIT_VAR_GYRO;

    Adjust.vel_imu      = zeros(3,1);
    Adjust.pos_imu      = zeros(3,1);
    Adjust.pos_imu_step = zeros(3,1);
    Adjust.quat_initialized = true;
end


% IMU Mechanization at full 100Hz using raw samples
if Adjust.quat_initialized && imu_data_ok
    dt_imu  = 1 / Const.IMU_SAMPLE_RATE_HZ; % IMU sample interval [s]
    n_imu   = size(Epoch.IMU.acc_raw, 1);
    g_n     = [0; 0; -Const.g0];                % gravity in nav frame (ENU)

    % getting EKF-estimated acceleration bias for correction
    ekf_bias = Adjust.bias_acc;
    ekf_gyro_bias = Adjust.param(30:32);
    Adjust.pos_imu_step = zeros(3,1);
    f_n_last = g_n;     % initialize for S_fn computation after loop

    for k = 1:n_imu
        % -- Mahony tilt correction --
        a_raw = Epoch.IMU.acc_raw(k,:)';
        an = norm(a_raw);
        e = zeros(3,1);
        if abs(an - Const.g0) < Const.IMU_MAHONY_ACC_GATE
            v_meas = a_raw / an;                                   % measured up in body frame
            C_bn   = quat2rotm(Adjust.quat');
            v_pred = C_bn' * [0;0;1];                              % predicted up in body frame
            e = cross(v_meas, v_pred) * max(0, 1-abs(an-Const.g0)/Const.IMU_MAHONY_TAPER_WIDTH);  % tilt error
        else
            e_bias = 0;
            e = 0;
        end

        ekf_gyro_bias = ekf_gyro_bias - 0 * e * dt_imu;

        % corrected body-frame measurements
        acc_b = Epoch.IMU.acc_raw(k,:)' - ekf_bias;
        gyr_b = Epoch.IMU.gyr_raw(k,:)' - ekf_gyro_bias + Const.IMU_MAHONY_KP*e;

        % propagate quaternion (strapdown, body frame gyro increment)
        omega = norm(gyr_b);
        if omega > 1e-10
            axis  = gyr_b / omega;
            theta = omega * dt_imu;
            dq    = [cos(theta/2); axis * sin(theta/2)];
            Adjust.quat = quatMultiply(Adjust.quat, dq);
            Adjust.quat = Adjust.quat / norm(Adjust.quat);
        end

        % rotate specific force to nav frame and integrate velocity/position
        C_bn = quat2rotm(Adjust.quat');
        f_n  = C_bn * acc_b;
        % q_bn   = quatconj(Adjust.quat');
        % f_n    = quatrotate(q_bn, acc_b')';
        a_n    = f_n + g_n;
        Adjust.vel_imu      = Adjust.vel_imu      + a_n * dt_imu;
        Adjust.pos_imu      = Adjust.pos_imu      + Adjust.vel_imu * dt_imu;
        Adjust.pos_imu_step = Adjust.pos_imu_step + Adjust.vel_imu * dt_imu;
        f_n_last = f_n;
        Adjust.a_n = a_n;
    end
    Adjust.param(30:32) = ekf_gyro_bias;

    %% ---- Forward body vector
    % if ~(isfield(Adjust, 'forward_body_frozen') && Adjust.forward_body_frozen)
    %
    %     pos_ecef_0 = Adjust.param(1:3);
    %     [lat0_f, lon0_f, ~] = ecef2geodetic(wgs84Ellipsoid, ...
    %                             pos_ecef_0(1), pos_ecef_0(2), pos_ecef_0(3));
    %     R_ecef2enu_f = [-sind(lon0_f),               cosd(lon0_f),             0; ...
    %                     -sind(lat0_f)*cosd(lon0_f),  -sind(lat0_f)*sind(lon0_f), cosd(lat0_f); ...
    %                      cosd(lat0_f)*cosd(lon0_f),   cosd(lat0_f)*sind(lon0_f), sind(lat0_f)];
    %
    %     vel_enu_f  = R_ecef2enu_f * Adjust.param(4:6);
    %     speed_2d_f = norm(vel_enu_f(1:2));
    %
    %     if speed_2d_f > 0.5 && size(Epoch.IMU.acc_raw, 1) >= 20
    %
    %         % Running PCA
    %         forward_body_pca = estimateForwardBodyVector(Epoch.IMU.acc_raw);
    %
    %         % Resolving sign using GNSS bearing
    %         gnss_bear_f = atan2(vel_enu_f(2), vel_enu_f(1)); % CCW from East
    %         C_bn_now    = quat2rotm(quatconj(Adjust.quat'));
    %
    %         fwd_enu_plus  = C_bn_now *  forward_body_pca;
    %         fwd_enu_minus = C_bn_now * (-forward_body_pca);
    %
    %         bear_plus  = atan2(fwd_enu_plus(2),  fwd_enu_plus(1));
    %         bear_minus = atan2(fwd_enu_minus(2), fwd_enu_minus(1));
    %
    %         err_plus  = abs(wrapToPi(gnss_bear_f - bear_plus));
    %         err_minus = abs(wrapToPi(gnss_bear_f - bear_minus));
    %
    %         if err_minus < err_plus
    %             forward_body_pca = -forward_body_pca;
    %         end
    %
    %         best_err = min(err_plus, err_minus);
    %         if best_err < deg2rad(45)
    %             Adjust.forward_body        = forward_body_pca;
    %             Adjust.forward_body_frozen = true;
    %         end
    %
    %     end
    % end

    % skew-symmetric matrix of last specific force for F matrix coupling
    S_fn = [0,           -f_n_last(3),  f_n_last(2);
            f_n_last(3),  0,           -f_n_last(1);
           -f_n_last(2),  f_n_last(1),  0];

    Adjust.bias_acc = Adjust.param(27:29);
    imu_available = true;
end
