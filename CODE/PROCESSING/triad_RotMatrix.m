function Adjust = triad_RotMatrix(Adjust, Epoch, vel_enu, R_triad)
% Estimates the body-to-navigation attitude with the TRIAD algorithm from
% two vector observations (gravity/down and horizontal travel direction)
% and applies the resulting attitude correction as a sequential EKF
% (error-state) update to the quaternion carried in Adjust.quat.
%
% INPUT:
%   Adjust      adjustment/filter relevant variables [struct]
%   Epoch       epoch-specific data [struct]
%   vel_enu     receiver velocity in the local ENU navigation frame [m/s], [3x1]
%   R_triad     measurement noise covariance matrix of the TRIAD attitude
%               update [3x3]
% OUTPUT:
%   Adjust      updated with the TRIAD attitude correction (.quat, .param,
%               .param_sigma, .z_triad) [struct]
%
% Created by Hoor Bano
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

acc_epoch = mean(Epoch.IMU.acc_raw, 1)';
n_states = numel(Adjust.param);

if norm(acc_epoch) < 8.0 || norm(acc_epoch) > 11.0
    % accelerometer magnitude too far from 1g (e.g. strong dynamics) ->
    % gravity is not a reliable "down" reference this epoch, skip update
else
    r1_body = -acc_epoch / norm(acc_epoch);    % unit down in body frame
    r1_nav  = [0; 0; -1];                      % unit down in ENU nav frame

    % Horizontal walking velocity in nav frame
    vel_horiz = [vel_enu(1); vel_enu(2); 0];
    if norm(vel_horiz) > 0.3   % need sufficient horizontal speed for a reliable heading reference
        r2_nav = vel_horiz / norm(vel_horiz);

        % current attitude estimate (body -> nav) used to project the
        % nav-frame heading reference into the body frame
        C_bn_curr = quat2rotm(quatconj(Adjust.quat'));
        r2_body_raw = C_bn_curr' * r2_nav;

        % Remove gravity component (project to body horizontal plane)
        up_body = -r1_body;
        r2_body_raw = r2_body_raw - dot(r2_body_raw, up_body) * up_body;

        if norm(r2_body_raw) > 0.1   % skip if second vector nearly parallel to gravity (degenerate)
            r2_body = r2_body_raw / norm(r2_body_raw);
% r2_body = [0; 0; 1];
            % Building TRIAD orthonormal bases
            t1_n     = r1_nav;
            cross_n  = cross(r1_nav, r2_nav);
            if norm(cross_n) > 0.1   % skip if r1_nav and r2_nav are (nearly) parallel
                t2_n = cross_n / norm(cross_n);
                t3_n = cross(t1_n, t2_n);

                % Body frame triad
                t1_b    = r1_body;
                cross_b = cross(r1_body, r2_body);
                if norm(cross_b) > 0.1   % skip if r1_body and r2_body are (nearly) parallel
                    t2_b = cross_b / norm(cross_b);
                    t3_b = cross(t1_b, t2_b);

                    % TRIAD attitude solution: rotation mapping the body
                    % triad onto the nav triad
                    M_nav  = [t1_n, t2_n, t3_n];
                    M_body = [t1_b, t2_b, t3_b];
                    C_bn_triad = M_nav * M_body';

                    % Ensuring orthonormality (SVD correction), det = +1
                    % enforces a proper rotation (no reflection)
                    [U, ~, V] = svd(C_bn_triad);
                    C_bn_triad = U * diag([1,1,det(U*V')]) * V';

                    % Attitude error between TRIAD solution and current
                    % estimate, converted from the skew-symmetric part of
                    % the relative rotation to a small-angle rotation vector
                    dC   = C_bn_triad * C_bn_curr';
                    dphi = [dC(3,2) - dC(2,3); dC(1,3) - dC(3,1); dC(2,1) - dC(1,2)] / 2;
                    Adjust.z_triad = dphi;

                    % design matrix selecting the 3 attitude error states
                    H_triad = zeros(3, n_states);
                    H_triad(1,24) = 1;
                    H_triad(2,25) = 1;
                    H_triad(3,26) = 1;

                    [Adjust.param, Adjust.param_sigma] = ekfUpdate(Adjust.param, Adjust.param_sigma, ...
                                                                   H_triad, R_triad, dphi);

                    % Apply attitude correction to quaternion and reset
                    % the attitude error states (error-state EKF reset)
                    phi     = Adjust.param(24:26);
                    ang_phi = norm(phi);
                    if ang_phi > 1e-10
                        n_phi   = phi / ang_phi;
                        dq_corr = [cos(ang_phi/2); ...
                                  -n_phi(1)*sin(ang_phi/2); ...
                                  -n_phi(2)*sin(ang_phi/2); ...
                                  -n_phi(3)*sin(ang_phi/2)];
                        Adjust.quat = quatMultiply(dq_corr, Adjust.quat);
                        Adjust.quat = Adjust.quat / norm(Adjust.quat);
                        Adjust.param(24:26) = 0;
                    end

                end % cross_b check
            end % cross_n check
        end % r2_body norm check
    end % vel_horiz norm check
end % acc_epoch check

end


function [param_new, sigma_new] = ekfUpdate(param, sigma, H, R, z)
% Sequential (Joseph-form) EKF measurement update.
%
% INPUT:
%   param       current state vector [n x 1]
%   sigma       current state covariance matrix [n x n]
%   H           design/observation matrix [m x n]
%   R           measurement noise covariance matrix [m x m]
%   z           measurement innovation [m x 1]
% OUTPUT:
%   param_new   updated state vector [n x 1]
%   sigma_new   updated state covariance matrix (Joseph form, guaranteed
%               symmetric) [n x n]

S         = H * sigma * H' + R;
K         = sigma * H' / S;
param_new = param + K * z;
I_KH      = eye(size(sigma)) - K * H;
sigma_new = I_KH * sigma * I_KH' + K * R * K';
sigma_new = (sigma_new + sigma_new') / 2;
end
