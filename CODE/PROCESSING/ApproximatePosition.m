function xyz = ApproximatePosition(Epoch, input, obs, settings)
% This function calculates an approximate position with a simple code-only 
% solution. The accuracy of this approximate position should be sufficient 
% for PPP filtering. Some parameters and error sources are ignored.
% 
% INPUT:
%   Epoch           struct, epoch-specific data
%   input           struct, input data for processing
%   settings        struct, settings for processing from GUI
% OUTPUT:
%   xyz             approximate position in cartesian coordinates
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


n_freq = settings.INPUT.proc_freqs; 	% number of processed frequencies
n_sats = numel(Epoch.sats);            	% number of satellites
param = zeros(11,1);     % build parameter-vector: 3 position, 3 velocity, and 5 time offsets for each GNSS
 
% Start iteration
for iteration = 1:10
    % model the observations to each satellite
    [model, Epoch] = modelApproximately(settings, input, Epoch, param, obs, iteration);
    useCode = Epoch.useCode(:);
    model_code = model.rho...            	% theoretical distance
        - Const.C * model.dT_sat_rel ...  	% satellite clock
        + param(7)*Epoch.gps + param(8)*Epoch.glo ....  % receiver clock error (GPS + GLO)
        + param(9)*Epoch.gal + param(10)*Epoch.bds ...  % receiver clock error (GAL + BDS)
        + param(11)*Epoch.qzss ....                     % receiver clock error (QZSS)
        + model.trop + model.iono...        % atmosphere
        - model.dX_PCO_rec_corr...          % Phase Center Offset Receiver
        - model.dX_ARP_ECEF_corr...         % Antenna Reference Point Receiver
        + model.dX_PCO_sat_corr;            % Phase Center Offset Satellite

    % observed minus computed
    omc = (Epoch.code(:) - model_code(:)) .* useCode;
    
    % Preparing the build of the Design-Matrix
    sat_pos_x = repmat(model.Rot_X(1,:)', 1, n_freq);  	% satellite ECEF position x
    sat_pos_y = repmat(model.Rot_X(2,:)', 1, n_freq);  	% satellite ECEF position y
    sat_pos_z = repmat(model.Rot_X(3,:)', 1, n_freq);  	% satellite ECEF position z
    % Partial derivatives
    dR_dx       = -( sat_pos_x(:)-param(1) ) ./  model.rho(:) .* useCode;
    dR_dy       = -( sat_pos_y(:)-param(2) ) ./  model.rho(:) .* useCode;
    dR_dz       = -( sat_pos_z(:)-param(3) ) ./  model.rho(:) .* useCode;
    dR_dvx      = repmat(zeros(n_sats,1), n_freq, 1).* useCode;
    dR_dvy      = repmat(zeros(n_sats,1), n_freq, 1).* useCode;
    dR_dvz      = repmat(zeros(n_sats,1), n_freq, 1).* useCode;    
    dR_dt_GPS   = repmat(1*Epoch.gps,  n_freq, 1) .* useCode;
    dR_dt_GLO   = repmat(1*Epoch.glo,  n_freq, 1) .* useCode;
    dR_dt_GAL   = repmat(1*Epoch.gal,  n_freq, 1) .* useCode;
    dR_dt_BDS   = repmat(1*Epoch.bds,  n_freq, 1) .* useCode;
    dR_dt_QZSS  = repmat(1*Epoch.qzss, n_freq, 1) .* useCode;
    % Build Design-Matrix
    A = [dR_dx, dR_dy, dR_dz, dR_dvx, dR_dvy, dR_dvz, dR_dt_GPS, dR_dt_GLO, dR_dt_GAL, dR_dt_BDS, dR_dt_QZSS];
    
    % Build Weight-Matrix
    P_diag = createWeights(Epoch, model, settings);




    P_diag = P_diag(:,1:n_freq);      % e.g., IF LC processed
    P = diag(P_diag(:));
    
    % Standard LSQ Adjustment
    dx = adjustment(A, P, omc, 5);
    
    % add changes in estimated parameters
    param = param + dx.x;

    % Stop iterations in case of coordinate convergence on dm-level
    if norm(dx.x(1:3)) < 1e-1
        break;
    end
    
end

% only the approximate position is returned
xyz = param(1:3);


