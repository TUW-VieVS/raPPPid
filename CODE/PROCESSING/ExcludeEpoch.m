function [settings, Epoch, Adjust, storeData] = ...
    ExcludeEpoch(settings, Epoch, Adjust, storeData, bool_print)
% Function to jump over epochs excluded in the GUI
%
% INPUT:
%   settings        struct, processing settings (from GUI)
%   Epoch           struct, epoch-specific variables
%   Adjust          struct, variables relevant for parameter estimation
%   storeData       struct, struct, stores data of whole processing
%   bool_print      boolean, true to print to command window
% OUTPUT:
%   settings        struct, processing settings (from GUI)
%   Epoch           struct, epoch-specific variables
%   Adjust          struct, variables relevant for parameter estimation
%   storeData       struct, struct, stores data of whole processing
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


q = Epoch.q;

storeData.gpstime(Epoch.q,1) = Epoch.gps_time;                  % save time of current epoch
storeData.dt_last_reset(q) = Epoch.gps_time-Adjust.reset_time;  % save time after last reset of current epoch

Epoch = Epoch.old;
Epoch.code  = [];
Epoch.phase = [];
Epoch.doppler = [];

if bool_print
    fprintf('... excluded (%s)          \n', Epoch.rinex_header);
end

% check for reset
if any(q == settings.PROC.excl_epochs_reset)    
    if bool_print
        fprintf('\n\nEpoch %d: RESET of solution            \n', q)
    end
    
    % reset float solution (other parameters are handled in adjustmentPreparation)
    Adjust.float = false;
    Adjust.float_reset_epochs = [Adjust.float_reset_epochs, q];     % save float reset
    Adjust.reset_time = Epoch.gps_time;
    
    % reset fixed solution
    if settings.AMBFIX.bool_AMBFIX
        Adjust.fixed = false;
        Adjust.fixed_reset_epochs = [Adjust.fixed_reset_epochs, q];     % save fixed reset
        Epoch.WL_23(:) = NaN;       % reset EW, WL and NL ambiguities
        Epoch.WL_12(:) = NaN;
        Epoch.WL_13(:) = NaN;
        Epoch.NL_12(:) = NaN;       % reset ambiguities of NLs
        Epoch.NL_23(:) = NaN;
		% reset reference satellites
        Epoch.refSatGPS = 0; Epoch.refSatGLO = 0; Epoch.refSatGAL = 0; Epoch.refSatBDS = 0; Epoch.refSatQZS = 0;
        Epoch.refSatGPS_idx = []; Epoch.refSatGLO_idx = []; Epoch.refSatGAL_idx = []; Epoch.refSatBDS_idx = []; Epoch.refSatQZS_idx = [];
        % reset Hatch-Melbourne-Wübbena LCs (ATTENTION: values of MW are overwritten!)
        Adjust.HMW_12(1:q,:) = 0; 
        Adjust.HMW_23(1:q,:) = 0; 
        Adjust.HMW_13(1:q,:) = 0;
        % create new entry in time to first fix
        storeData.ttff(end+1) = NaN;
    end
end