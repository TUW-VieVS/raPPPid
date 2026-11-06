function iono_est = GetIonoMatrix(storeData, satellites)
% Extracts the estimated ionospheric delay of all satellites and epochs
% from the full parameter vectors.
%
% INPUT:
%   storeData       struct, data from processing
%   satellites      struct, satellite-specific data
% OUTPUT:
%   iono_est        matrix, epochs x satellites, estimated ionospheric delay [m]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


n_eps = numel(storeData.param_full);    % number of epochs
iono_est = zeros(n_eps, DEF.SATS);      % initialize

% loop over epochs to extract the estimated ionospheric delay
for q = 1:n_eps
    param = storeData.param_full{q};    % full parameter vector of current epoch
    sats = satellites.sats{q};          % satellites of current epoch
    n = numel(sats);                    % number of satellites in current epoch
    
    % handle epochs without valid solution
    if isempty(param) || n == 0;     continue;     end

    % get ionospheric delay estimation of current epoch
    iono_est(q, sats) = param(end-n+1:end);
end
