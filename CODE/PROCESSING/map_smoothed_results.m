function storeData = map_smoothed_results(storeData, NO_PARAM)
% This functions maps the results of the RTS smoother into the struct
% storeData (e.g., for plotting).
%
% INPUT:
%   storeData       struct, collected results of the processing
%   NO_PARAM        number of estimated parameters
% OUTPUT:
%	storeData       updated
%
% Revision:
%   ...
%
% Created by Paul Dohnal
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


n_epochs = length(storeData.x_smooth);      % number of epochs

% Backup original forward filter solution before overwriting
if isfield(storeData, 'param') && ~isfield(storeData, 'param_fwd')
    storeData.param_fwd = storeData.param;
end

% initialize smoothed variables with the forward solution, epochs without
% smoothed solution keep the forward values
storeData.param_smooth     = storeData.param;
storeData.pos_sigma_smooth = NaN(size(storeData.param,1), 3);

% loop over epochs to save variables
for q = 1:n_epochs
    if ~isempty(storeData.x_smooth{q}) && length(storeData.x_smooth{q}) >= NO_PARAM
        storeData.param_smooth(q, 1:NO_PARAM) = storeData.x_smooth{q}(1:NO_PARAM)';

        P_diag = diag(storeData.P_smooth{q});
        storeData.pos_sigma_smooth(q, 1:3) = sqrt(P_diag(1:3))';
        
        % full parameter vector and covariance matrix
        storeData.param_full{q}  = storeData.x_smooth{q};
        storeData.param_sigma{q} = storeData.P_smooth{q};
    end
end

% Overwrite standard plot arrays (param_full and param_sigma are updated above)
storeData.param = storeData.param_smooth;

% remove intermediate variables of the smoother (already saved in param_full and param_sigma)
storeData = rmfield(storeData, {'x_smooth', 'P_smooth'});

