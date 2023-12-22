function [settings, Epoch, Adjust, storeData, HMW_12, HMW_23, HMW_13] = ...
    ExcludeEpoch(settings, Epoch, Adjust, storeData, HMW_12, HMW_23, HMW_13, bool_print)
% Function to jump over epochs excluded in the GUI
%
% INPUT:
%   ...
% OUTPUT:
%	...
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
        Epoch.NL_12(:) = NaN;
        Epoch.NL_23(:) = NaN;
        Epoch.refSatGPS = 0;            % reset reference satellites GPS and Galileo
        Epoch.refSatGPS_idx = [];
        Epoch.refSatGAL = 0;
        Epoch.refSatGAL_idx = [];
        Epoch.refSatBDS = 0;
        Epoch.refSatBDS_idx = [];
        % restart fixing in [GUI-definded] epochs
        settings.AMBFIX.start_fixing(end+1, :) = ...    % -1 as we are already in epoch where reset is happening
            [q+settings.AMBFIX.start_WL-1, q+settings.AMBFIX.start_NL-1];
        % reset Hatch-Melboure-Wübbena LCs (ATTENTION: values of MW are overwritten!)
        HMW_12(1:q,:) = 0; HMW_23(1:q,:) = 0; HMW_13(1:q,:) = 0;
        % create new entry in time to first fix
        storeData.ttff(end+1) = NaN;
    end
end