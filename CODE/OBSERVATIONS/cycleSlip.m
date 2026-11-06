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
%   Epoch       update of .cs_found, .usePhase and added some Cycle-Slip calculations
%  
% Revision:
%   2023/06/11, MFWG: adding QZSS
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

if contains(settings.PROC.method, 'Phase')  % except code only solution
    
    % --- single-frequency cycle-slip detection 
    if settings.OTHER.CS.l1c1
        Epoch = cycleSlip_CLdiff(settings, Epoch, use_column);
    end   
    
    
    % --- dL_i-dL_j cycle-slip detection is enabled 
    if settings.OTHER.CS.DF && abs((Epoch.q - Epoch.old.q)) == 1 && ~isempty(Epoch.old.sats)
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
    
    % --- cycle-slip detection based on averaged HMW LC
    if settings.OTHER.CS.HMW
        Epoch = cycleSlip_HMW(settings, Epoch, use_column);
    end

    % --- check if Loss of Lock Indicator is set in RINEX observation file
    if settings.PROC.LLI && ~settings.INPUT.rawDataAndroid
        Epoch = cycleSlip_LLI(Epoch, use_column, settings);
    end

    % phase observations with detected cycle slips are not used
    Epoch.usePhase = Epoch.usePhase & ~Epoch.cs_found;


    if strcmp(settings.IONO.model, 'Estimate, decoupled clock')
        % ||| check if useful for other PPP models
        % only use observations of satellites with all expected
        % observations because DCM is sensitive to missing observations
        n = settings.INPUT.n_gnss_freqs;
        if n(1) == 3;   n(1) = 2;   end     % do not check GPS L5
        bool_all = check_all_obs(Epoch, n, settings.INPUT.use_GPS, settings.INPUT.use_GLO, settings.INPUT.use_GAL, settings.INPUT.use_BDS, settings.INPUT.use_QZSS);
        Epoch.useCode(~bool_all) = false;
    end
    
    if strcmp(settings.IONO.model, 'Estimate, decoupled clock')
        % DCM is sensitive if (single) phase observations are missing ->
        % exclude satellite completely (although a cycle slip might have
        % been detected on a single frequency only)
        Epoch.usePhase(~all(Epoch.usePhase,2), :) = false;
        Epoch.useCode = Epoch.useCode & Epoch.usePhase;
    end


    % save detected cycle slips in Epoch.sat_status
    Epoch.sat_status(~Epoch.usePhase) = 3;
end