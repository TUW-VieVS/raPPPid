function [N, N_var] = GetAmbiguityMatrix(storeData, all_sats, proc_frqs, j)
% Extracts the float ambiguities of the j-th frequency and their variances
% from the full parameter vectors and covariance matrices of all epochs.
%
% INPUT:
%   storeData       struct, data from processing
%   all_sats        cell, sats{q} contains the satellites of epoch q
%   proc_frqs       number of processed frequencies
%   j               frequency to extract (1, 2 or 3)
% OUTPUT:
%   N               matrix, epochs x 410, float ambiguities [m]
%   N_var           matrix, epochs x 410, variances of float ambiguities
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


NO_PARAM = storeData.NO_PARAM;          % number of fixed parameters    
n_eps = numel(storeData.param_full);    % number of epochs

% initialize
N     = zeros(n_eps, DEF.SATS);
N_var = zeros(n_eps, DEF.SATS);

% loop over epochs to extract the estimated ionospheric delay
for q = 1:n_eps
    param = storeData.param_full{q};    % parameter vector of current epoch
    sats = all_sats{q};                 % satellites of current epoch
    n = numel(sats);                    % number of satellites in current epoch

    % handle epochs without valid solution
    if isempty(param) || n == 0;     continue;     end

    % get float ambiguities of current epoch
    [N_q, idx_N] = GetAmbiguitiesFromParam(param, NO_PARAM, n, proc_frqs);

    % extract and reshape float ambiguities according to the number of sats 
    % and frequencies
    N_q = reshape(N_q, n, proc_frqs);
    N(q, sats) = N_q(:, j);
    
    % extract and reshape the variances of the float ambiguities
    if ~isempty(storeData.param_sigma{q})
        var_q = reshape(diag(storeData.param_sigma{q}(idx_N, idx_N)), n, proc_frqs);
        N_var(q, sats) = var_q(:, j);
    end
end
