function [Epoch] = cycleSlip(Epoch, settings, use_column)
% Performs cycle-slip detection. It is possible to insert artificial cycle
% slip into the observations by uncommenting and editing the function 
% cycleSlip_artificial.m (in PPP_main.m)
%
% INPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   settings	struct, settings from GUI
%   use_column	cell, used columns of observation matrix for all GNSS and observation types
% OUTPUT:
%   Epoch       update of .cs_found and added some Cycle-Slip calculations
%  
% Revision:
%   2023/06/11, MFWG: adding QZSS
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

if contains(settings.PROC.method, 'Phase')  % except code only solution
    
    
    % --- ||| check cs detection based on HMW LC
    % https://link.springer.com/article/10.1007/s11018-019-01639-5?shared-article-renderer
    
    % --- single-frequency cycle-slip detection 
    if settings.OTHER.CS.l1c1
        Epoch = cycleSlip_CLdiff(settings, Epoch, use_column);
    end   
    
    
    % --- dL_i-dL_j cycle-slip detection is enabled 
    if settings.OTHER.CS.DF && (Epoch.q - Epoch.old.q) == 1 && ~isempty(Epoch.old.sats)
        Epoch = cycleSlip_dL(settings, Epoch, use_column);  
    end    
    
   
    % --- cycle-slip detection based on Doppler-Shift
    if settings.OTHER.CS.Doppler && ~isempty(Epoch.old.usable) && Epoch.old.usable == 1
        Epoch = cycleSlip_Doppler(Epoch, use_column, settings);
    end
    
    
    % --- cycle-slip detection based on time-difference of phase observations
    if settings.OTHER.CS.TimeDifference
        Epoch = cycleSlip_TimeDiff(Epoch, use_column, settings);
    end    
    
    
    % --- check if Loss of Lock Indicator is set in RINEX observation file
    if settings.PROC.LLI
        Epoch = cycleSlip_LLI(Epoch, use_column, settings);
    end
   
    if strcmp(settings.IONO.model, 'Estimate, decoupled clock')
        % DCM is sensitive if single phase observations are missing ->
        % exclude all phase observations (although cycle slip might have
        % been detected only on a single frequency)
        Epoch.cs_found(any(Epoch.cs_found,2), :) = 1;
    end

    % save detected cycle slips in Epoch.sat_status
    Epoch.sat_status(Epoch.cs_found) = 3;
end