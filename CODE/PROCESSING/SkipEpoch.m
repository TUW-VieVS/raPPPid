function [Epoch, storeData, Adjust] = SkipEpoch(Epoch, storeData, Adjust, settings, reason, restart)
% This function skips one epoch of the processing if, for example, less 
% than four satellites are visible or the RINEX epoch header states that 
% this specific epoch is invalid.
%
% INPUT:
%	Epoch           struct, epoch-specific data
%   storeData       struct, contains saved data of processing
%   Adjust          struct, adjustment specific-variables
%   settings        struct, processing settings from GUI
%   reason          string, stating the reason of skipping this epoch
%   restart         boolean, restart solution when skipping or not
% OUTPUT:
%	Epoch           updated
%   storeData       updated
%   Adjust          updated
%
% Revision:
%   2025/05/07, MFG: skip with or without reset
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% print information to command window
if ~settings.INPUT.bool_parfor; fprintf(reason); end

% save time of current epoch
storeData.gpstime(Epoch.q,1) = Epoch.gps_time;
% save time after last reset of current epoch
storeData.dt_last_reset(Epoch.q) = Epoch.gps_time - Adjust.reset_time;

% keep data of last epoch
Epoch = Epoch.old;   

if restart
    % restart float and fixed solution
    Adjust.float = false;
    Adjust.fixed = false;
    if ~Adjust.float
        % reset reference satellites and all fixed ambiguities
        Epoch = resetRefSat(Epoch, '');
    end
end