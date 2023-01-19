function xyz = ApproximatePosition(Epoch, input, obs, settings)
% This function calculates an approximate position with a rather simple 
% code only solution. The accuracy of this approximate position should be 
% at least some meters and therefore definitely enough for the PPP filtering.
% If no IF-LC is processed receiver DCBs are not considered in the 
% Design-Matrix as nevertheless m-level accuracy should be reached.
% Alternatively only C1 observation could be used.
% 
% INPUT:
%   Epoch       struct, epoch-specific data
%   input           struct, input data for processing
%   settings        struct, settings for processing from GUI
% OUTPUT:
%   xyz             approximate position in cartesian coordinates
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


num_freq = settings.INPUT.proc_freqs;
param = zeros(7,1);     % build parameter-vector: 3 coordinates and 4 time offsets for each GNSS
 
% Start iteration
for iteration = 1:10
    % model the observations to each satellite
    [model, Epoch] = modelApproximately(settings, input, Epoch, param, obs, iteration);
    cutoff = Epoch.exclude(:);
    model_code = model.rho...            	% theoretical distance
        - Const.C * model.dT_sat_rel ...  	% satellite clock
        + param(4)*Epoch.gps + param(5)*Epoch.glo ....  % receiver clock
        + param(6)*Epoch.gal + param(7)*Epoch.bds ....  % receiver clock
        + model.trop + model.iono...            	% atmosphere
        - model.dX_PCO_rec_corr...             		% Phase Center Offset Receiver
        - model.dX_ARP_ECEF_corr...                 % Antenna Reference Point Receiver
        + model.dX_PCO_sat_corr;               		% Phase Center Offset Satellite

    % observed minus computed
    omc = (Epoch.code(:) - model_code(:)) .* ~cutoff;
    
    % Preparing the build of the Design-Matrix
    sat_pos_x = repmat(model.Rot_X(1,:)', 1, num_freq);  	% satellite ECEF position x
    sat_pos_y = repmat(model.Rot_X(2,:)', 1, num_freq);  	% satellite ECEF position y
    sat_pos_z = repmat(model.Rot_X(3,:)', 1, num_freq);  	% satellite ECEF position z
    % Partial derivatives
    dR_dx       = -( sat_pos_x(:)-param(1) ) ./  model.rho(:) .* ~cutoff;
    dR_dy       = -( sat_pos_y(:)-param(2) ) ./  model.rho(:) .* ~cutoff;
    dR_dz       = -( sat_pos_z(:)-param(3) ) ./  model.rho(:) .* ~cutoff;
    dR_dt_GPS   = repmat(1*Epoch.gps, num_freq, 1) .* ~cutoff;
    dR_dt_GLO   = repmat(1*Epoch.glo, num_freq, 1) .* ~cutoff;
    dR_dt_GAL   = repmat(1*Epoch.gal, num_freq, 1) .* ~cutoff;
    dR_dt_BDS   = repmat(1*Epoch.bds, num_freq, 1) .* ~cutoff;
    
    % Build Design-Matrix
    A = [dR_dx, dR_dy, dR_dz, dR_dt_GPS, dR_dt_GLO, dR_dt_GAL, dR_dt_BDS];
    
    % Build Weight-Matrix
    P_diag = createWeights(Epoch, model.el, settings);
    P_diag = P_diag(:,1:num_freq);      % e.g., IF LC processed
    P = diag(P_diag(:));
    
    % Standard LSQ Adjustment
    dx = adjustment(A, P, omc, 5);
    
    % add changes in estimated parameters
    param = param + dx.x;

    % Stop iterations in case of coordinate convergence on mm-level
    if norm(dx.x(1:3)) < 1e-4
        xyz = param(1:3);
        return;
    end
    
end

% only the approximate position is returned
xyz = param(1:3);


