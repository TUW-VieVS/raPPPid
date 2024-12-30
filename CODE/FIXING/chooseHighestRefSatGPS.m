function Epoch = chooseHighestRefSatGPS(Epoch, elev_gps, cutoff, settings)
% Function to find or change reference satellite for GPS (if necessary)
% INPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   elev_gps  	vector, [°], elevation of gps ref sats with +/- sign for rising/setting
%   cutoff      boolean vector, true if satellite is not used 
%   settings    struct, processing settings from GUI
% OUTPUT:
%   Epoch       struct, updated with reference satellite and index
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if settings.INPUT.use_GPS
    gps_prns = Epoch.sats(Epoch.gps);
    
    % no possible reference satellites
    if isempty(gps_prns) || all(isnan(elev_gps)) || all(cutoff(Epoch.gps))
        Epoch = resetRefSat(Epoch, 'GPS');
        return
    end    
    
    if settings.AMBFIX.bool_AMBFIX          % check if integer ambiguity fixing is enabled
        % prefere satellites which have WL or NL fixed
        WL_fix = ~isnan(Epoch.WL_12(gps_prns));
        NL_fix = ~isnan(Epoch.NL_12(gps_prns));
        elev_gps(WL_fix) = abs(elev_gps(WL_fix)) + 90;      % abs to reset rising/settings condition
        elev_gps(NL_fix) = abs(elev_gps(NL_fix)) + 90;
        if strcmp(settings.IONO.model, '2-Frequency-IF-LCs') && settings.INPUT.proc_freqs == 2  % PPPAR and 2xIF is processed
            % prefere satellites which have EW or EN fixed
            EW_fix = ~isnan(Epoch.WL_23(gps_prns));
            EN_fix = ~isnan(Epoch.NL_23(gps_prns));
            elev_gps(EW_fix) = abs(elev_gps(EW_fix)) + 90;
            elev_gps(EN_fix) = abs(elev_gps(EN_fix)) + 90;
            % preferre GPS L5 satellites to make fixing the 2nd IF-LC easier
            idx_L5 = ~isnan(Epoch.C1) & ~isnan(Epoch.C2) & ~isnan(Epoch.C3);
            idx_L5 = idx_L5(Epoch.gps) & (elev_gps > settings.AMBFIX.cutoff);
            elev_gps(idx_L5) = elev_gps(idx_L5) + 180;
        elseif contains(settings.IONO.model, 'Estimate') && ...     % uncombined model
                settings.INPUT.proc_freqs > 2
            % preferre GPS L5 satellites to simplify the fixing
            idx_L5 = Epoch.gps & ~isnan(Epoch.C1) & ~isnan(Epoch.C2) & ~isnan(Epoch.C3);
            idx_L5 = idx_L5(Epoch.gps) & (elev_gps > settings.AMBFIX.cutoff);
            elev_gps(idx_L5) = elev_gps(idx_L5) + 180;
        end
        % downweight satellites which are not fixable
        unfixable = ~Epoch.fixable(Epoch.gps);
        elev_gps(unfixable) = elev_gps(unfixable) - 90;
    end

    % find reference satellite
    if max(elev_gps) > 0            % at least one gps satellite has "positive" elevation, take highest ascending satellite
        refSat = gps_prns(elev_gps == max(elev_gps));
        Epoch.refSatGPS = refSat(1);
    else                            % take "least lowest" satellite
        refSat = gps_prns(elev_gps == min(elev_gps));
        Epoch.refSatGPS = refSat(1);
    end
    % Epoch.refSatGPS_idx is handled in change2refSat_IF/_DCM
    
end

