function refSat = chooseHighestRefSat(Epoch, sats_gnss, elev_gnss, gnss, settings, bool_fixable)
% Function to find or change reference satellite for specific GNSS
%
% INPUT:
%   Epoch           struct, epoch-specific data for current epoch
%   sats_gnss       satellite numbers of current GNSS
%   elev_gps        [°], elevation of satellites of current GNSS
%   gnss            boolean vector for current GNSS
%   settings        struct, processing settings from GUI
%   bool_fixable    boolean, consider fixability of satellites
% OUTPUT:
%   refSat          selected reference satellite
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Some conditions for reference satellite

if settings.AMBFIX.bool_AMBFIX          % check if integer ambiguity fixing is enabled
    
    if strcmp(settings.IONO.model, '2-Frequency-IF-LCs')	% PPPAR and IF
        % prefere satellites which have WL or NL fixed
        WL_fix = ~isnan(Epoch.WL_12(sats_gnss));
        NL_fix = ~isnan(Epoch.NL_12(sats_gnss));
        elev_gnss(WL_fix) = elev_gnss(WL_fix) + 90;         % increase their elevation
        elev_gnss(NL_fix) = elev_gnss(NL_fix) + 90;
        
        if settings.INPUT.proc_freqs == 2                   % PPPAR and 2xIF ?
            % prefere satellites which have EW or EN fixed
            EW_fix = ~isnan(Epoch.WL_23(sats_gnss));
            EN_fix = ~isnan(Epoch.NL_23(sats_gnss));
            elev_gnss(EW_fix) = abs(elev_gnss(EW_fix)) + 90;    % increase their elevation
            elev_gnss(EN_fix) = abs(elev_gnss(EN_fix)) + 90;
        end
    end
    
    if bool_fixable
        % reduce elevation of satellites which are not fixable
        unfixable = ~Epoch.fixable(gnss);
        elev_gnss(unfixable) = elev_gnss(unfixable) - 90;
    end
end


if settings.INPUT.num_freqs >= 3
    % preferre three frequency-satellites (e.g., GPS L5) to facilitate fixing
    bool_3fr = gnss & ~isnan(Epoch.C1) & ~isnan(Epoch.C2) & ~isnan(Epoch.C3);
    bool_3fr = bool_3fr(gnss) & (elev_gnss > settings.AMBFIX.cutoff);
    elev_gnss(bool_3fr) = elev_gnss(bool_3fr) + 180;
end



%% Find suitable reference satellite

if max(elev_gnss) > 0            
    % at least one satellite has "positive" elevation, take highest ascending satellite
    refSat = sats_gnss(elev_gnss == max(elev_gnss));
else
    % take "least lowest" satellite
    refSat = sats_gnss(elev_gnss == min(elev_gnss));
end

refSat = refSat(1);     % to be on the safe side


% Epoch.refSatGPS/GLO/GAL/BDS/QZS_idx is handled in change2refSat_IF/_DCM.m


