function [velo, rec_clk_drift] = ApproximateVelocity(Epoch, input, obs, settings, xyz)
% This function calculates an approximate velocity with a simple Doppler
% solution and LSQ adjustment. The accuracy of this approximate velocity
% should be sufficient for PPP filtering. Furthermore, an approximation for
% the receiver clock drift is calculated after the calculating the
% approximate velocity, because velocity and receiver clock drift are
% strongly correlated.
%
% INPUT:
%   Epoch           struct, epoch-specific data
%   settings        struct, settings for processing from GUI
%   xyz             3x1, (approximate) receiver position in ECEF
% OUTPUT:
%   velocity        3x1, approximate velocity in ECEF
%   rec_clk_drift   approximate receiver clock drift
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


n_proc = settings.INPUT.proc_freqs; 	% number of processed frequencies
n_sats = numel(Epoch.sats);            	% number of satellites
s_f = n_proc * n_sats;

% build parameter-vector analog to ApproximatePosition: 
% 3 position, 3 velocity, 5 time offsets, rec clk drift
param = zeros(11,1);     
param(1:3) = xyz;

% get wavelengths for estimation of receiver clock error
wavelengths = Epoch.l1;
if n_proc == 1 && strcmp(settings.IONO.model, '2-Frequency-IF-LCs')
    wavelengths = (Epoch.f1.^2.*Epoch.l1-Epoch.f2.^2.*Epoch.l2) ./ (Epoch.f1.^2-Epoch.f2.^2);
elseif n_proc == 2
    wavelengths = [Epoch.l1; Epoch.l2];
elseif n_proc == 3
    wavelengths = [Epoch.l1; Epoch.l2; Epoch.l3];
end

% Start iteration
for iteration = 1:30

    % model the observations to each satellite
    [model, Epoch] = modelApproximately(settings, input, Epoch, param, obs, 0);

    % get satellite positions
    sat_pos_x = repmat(model.Rot_X(1,:)', n_proc, 1);  	% satellite ECEF position x
    sat_pos_y = repmat(model.Rot_X(2,:)', n_proc, 1);  	% satellite ECEF position y
    sat_pos_z = repmat(model.Rot_X(3,:)', n_proc, 1);  	% satellite ECEF position z

    % build Design Matrix
    A_Doppler = zeros(numel(Epoch.doppler), 4);
    % Partial derivations: velocity
    rho = model.rho(:);
    A_Doppler(:,4) = (param(1) - sat_pos_x) ./ rho;   % x velocity
    A_Doppler(:,5) = (param(2) - sat_pos_y) ./ rho;   % y velocity
    A_Doppler(:,6) = (param(3) - sat_pos_z) ./ rho;   % z velocity
    % Partial derivations: receiver clock drift
    A_Doppler(:,11) = ones(size(wavelengths));  % receiver clock drift

    % weight matrix
    P_Doppler = eye(s_f);       % ignore weighting here -> eye

    % get receiver and satellite positions and velocities
    pos_r = xyz;                % receiver position  [m]
    vel_r = param(4:6);         % receiver velocity  [m/s]
    pos_s = model.Rot_X;        % satellite position [m]
    vel_s = model.Rot_V;        % satellite velocity [m/s]

    % get receiver clock drift
    rec_clk_drift = param(11);

    % calculate velocity and position part for observation equation, check
    % Diss. Glaner p.13
    v =  - vel_s + vel_r;
    r = (- pos_s + pos_r) ./ vecnorm(- pos_s + pos_r);

    % model doppler observation [m/s]
    dot_r_v = repmat(dot(r,v), 1, n_proc)';
    model_doppler = dot_r_v  + rec_clk_drift;

    % calculate observed minus computed of Doppler shift and exclude observations
    omc_doppler = (model_doppler(:) + Epoch.doppler(:)) .* ~Epoch.exclude(:);
    omc_doppler = -(omc_doppler);

    % standard LSQ Adjustment
    dx = adjustment(A_Doppler, P_Doppler, omc_doppler, 5);

    % add changes in estimated parameters
    param = param + dx.x;

    % Stop iterations in case of convergence on dm-level
    if norm(dx.x(4:6)) < 1e-1
        break;
    end

end



% calculate receiver clock drift after velocity estimation
rec_clk_drift_ = -Epoch.doppler(:) - dot_r_v;
rec_clk_drift_ = rec_clk_drift_(~isnan(rec_clk_drift_));    % remove NaNs
rec_clk_drift = median(rec_clk_drift_);

% return the approximate velocity
velo = param(4:6);




