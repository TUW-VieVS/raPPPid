function param_var = GetParamVarFromSigma(param_sigma, NO_PARAM)
% Reconstruct the variances of the estimated parameters from the 
% corresponding (co)variance matrix. Only the variances of the leading
% NO_PARAM parameters are extracted. 
%
% INPUT:
%   param_sigma     cell (nEpochs x 1), (co)variance matrix for each epoch
%   NO_PARAM        number of estimated parameters
% OUTPUT:
%   param_var       [nEpochs x NO_PARAM], variance of the estimated parameters
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

if isempty(param_sigma)
    param_var = [];
    return
end

n = numel(param_sigma);             % number of epochs
param_var = zeros(n, NO_PARAM);     % initialize

for i = 1:n         % loop over all epochs
    Q = param_sigma{i};             % get covariance matrix of current epoch
    if isempty(Q); continue; end
    k = min(NO_PARAM, size(Q,1));
    param_var(i,1:k) = diag(Q(1:k,1:k))';   % extract variances
end
