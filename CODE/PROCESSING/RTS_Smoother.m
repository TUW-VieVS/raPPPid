function storeData = RTS_Smoother(storeData, NO_PARAM, active_sats, bool_print)
% This functions uses a Rauch-Tung-Striebel-Smoother to perform a second
% run over the data. Only for post-processing.
% 
% INPUT:
%   storeData       struct, collected results of the processing
%   NO_PARAM        number of estimated parameters
% 	active_sats 	cell, observed satellites for each epoch
%   bool_print      boolean, true to print progress to the command window
% OUTPUT:
%	storeData       updated
%
% Revision:
%   2026/10/23, MFWG: exclude reset/re-initialized parameters from smoothing
%
% Created by Paul Dohnal
% 
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% 1. Find last valid epoch
valid_mask = cellfun(@(x) ~isempty(x) && length(x) >= NO_PARAM, storeData.param_full);
last_valid_idx = find(valid_mask, 1, 'last');

if isempty(last_valid_idx) || last_valid_idx < 2
    warning('RTS Smoother: Insufficient valid epochs.');
    return;
end

n_epochs = last_valid_idx;

% Preallocate smoothed cells
storeData.x_smooth = cell(n_epochs, 1);
storeData.P_smooth = cell(n_epochs, 1);

% Initialize last epoch (Smoothed = Filtered)
storeData.x_smooth{n_epochs} = storeData.param_full{n_epochs};
storeData.P_smooth{n_epochs} = storeData.param_sigma{n_epochs};

% 2. Backward Pass
q_update = 17;      % [epochs], update rate of printed progress
l_estr = 0;         % length of last printed progress
for q = (n_epochs - 1) : -1 : 1
    % print progress
    if bool_print && (mod(q,q_update) == 0 || q == 1)
        progress = (n_epochs - q) / (n_epochs - 1) * 100;
        % keep short: backspaces must stay within the padding of other messages
        estr = sprintf('\nEpoch %d %.0f%%\n', q, progress);
        fprintf('%s%s', repmat(char(8), 1, l_estr), estr);
        l_estr = length(estr);
        drawnow;
    end

    x_upd_k = storeData.param_full{q};
    P_upd_k = storeData.param_sigma{q};

    % Check current epoch validity
    if isempty(x_upd_k) || length(x_upd_k) < NO_PARAM
        storeData.x_smooth{q} = [];
        storeData.P_smooth{q} = [];
        continue;
    end

    % Check target epoch k+1 validity
    if isempty(storeData.x_smooth{q+1}) || isempty(storeData.param_pred_full{q+1}) || ...
            length(storeData.param_pred_full{q+1}) < NO_PARAM
        storeData.x_smooth{q} = x_upd_k;
        storeData.P_smooth{q} = P_upd_k;
        continue;
    end

    % Satellite alignment across epochs
    sats_k      = active_sats{q};
    x_pred_kp1  = storeData.param_pred_full{q+1};
    P_pred_kp1  = storeData.param_sigma_pred{q+1};
    Phi_kp1     = storeData.Transition{q+1};
    sats_kp1    = active_sats{q+1};
    x_smth_kp1  = storeData.x_smooth{q+1};
    P_smth_kp1  = storeData.P_smooth{q+1};

    % Match satellites between epoch k and k+1
    [common_sats, idx_in_k, idx_in_kp1] = intersect(sats_k, sats_kp1);

    n_sats_k   = length(sats_k);
    n_sats_kp1 = length(sats_kp1);

    % The state vector holds [NO_PARAM | block_1 | block_2 | ...] where 
    % the block holds the frequency-wise ambiguities and then the estimated
    % ionospheric delays
    n_blocks   = (length(x_upd_k) - NO_PARAM) / n_sats_k;

    % indices of the satellite-wise parameters of the common satellites 
    % (block-wise order, same as in the state vector)
    off = 0:n_blocks-1;                                   % [1 x blocks]
    map_k   = [1:NO_PARAM, NO_PARAM + reshape(idx_in_k(:)   + off*n_sats_k,   1, [])];
    map_kp1 = [1:NO_PARAM, NO_PARAM + reshape(idx_in_kp1(:) + off*n_sats_kp1, 1, [])];

    % Slice sub-matrices of epoch k+1
    x_pred_sub     = x_pred_kp1(map_kp1);
    P_pred_sub     = P_pred_kp1(map_kp1, map_kp1);
    x_smth_sub_kp1 = x_smth_kp1(map_kp1);
    P_smth_sub_kp1 = P_smth_kp1(map_kp1, map_kp1);

    Phi_sub = eye(length(map_k));           % same size for both epochs
    if ~isempty(Phi_kp1)
        Phi_sub = Phi_kp1(map_kp1, map_kp1);   % square, in satellite order of epoch k+1 (already aligned with k)
    end

    % Identify satellite-wise parameters which are not connected by the
    % transition from epoch k to k+1 in two steps:
    % 1) reset after the update of epoch k+1 because code or phase was 
    % excluded on any frequency -> the smoothed state of epoch k+1 contains 
    % already the new parameter
    bool_reset = full(storeData.exclude(q+1, common_sats) | storeData.excludePhase(q+1, common_sats));
    reset_mask = [false(1, NO_PARAM), repmat(bool_reset(:)', 1, n_blocks)]';
    % 2) re-initialized in the prediction of epoch k+1 -> predicted value 
    % is not the propagated one
    x_prop_sub = Phi_sub * x_upd_k(map_k);
    reinit_mask = abs(x_pred_sub - x_prop_sub) > 1e-3;
    reinit_mask(1:NO_PARAM) = false;
    % parameters of epoch k+1 used for smoothing
    keep = ~reset_mask & ~reinit_mask;

    % Calculate Smoother Gain for all parameters of epoch k, using only the
    % connected parameters of epoch k+1
    C_k = (P_upd_k(:, map_k) * Phi_sub(keep, :)') / P_pred_sub(keep, keep);
    C_k(isnan(C_k) | isinf(C_k)) = 0;

    % Smoothed state and covariance updates
    dx = x_smth_sub_kp1(keep) - x_pred_sub(keep);
    dP = P_smth_sub_kp1(keep, keep) - P_pred_sub(keep, keep);
    x_smooth_k = x_upd_k + C_k * dx;
    P_smooth_k = P_upd_k + C_k * dP * C_k';

    storeData.x_smooth{q} = x_smooth_k;
    storeData.P_smooth{q} = P_smooth_k;
end
