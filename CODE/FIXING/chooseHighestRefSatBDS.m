function Epoch = chooseHighestRefSatBDS(Epoch, elev_bds, cutoff, settings)
% Function to find or change reference satellite for BeiDou.
% INPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   elev_bds  	vector, elevation of possible BeiDou ref sats with +/- sign for rising/setting
%   cutoff      boolean vector, true if satellite is not used 
%   settings    struct, processing settings from GUI
% OUTPUT:
%   Epoch       struct, updated with reference satellite and index
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if settings.INPUT.use_BDS
    bds_prns = Epoch.sats(Epoch.bds);
    
    % no possible reference satellites
    if isempty(bds_prns) || all(isnan(elev_bds)) || all(cutoff(Epoch.bds))
        Epoch = resetRefSatBDS(Epoch);
        return
    end
    
    if settings.AMBFIX.bool_AMBFIX          % check if integer ambiguity fixing is enabled
        % prefere satellites which have WL or NL fixed
        WL_fix = ~isnan(Epoch.WL_12(bds_prns));
        NL_fix = ~isnan(Epoch.NL_12(bds_prns));
        elev_bds(WL_fix) = abs(elev_bds(WL_fix)) + 90;
        elev_bds(NL_fix) = abs(elev_bds(NL_fix)) + 90;
        if strcmp(settings.IONO.model, '2-Frequency-IF-LCs') && settings.INPUT.proc_freqs == 2  % PPPAR and 2xIF is processed
            % prefere satellites which have WL or NL fixed
            EW_fix = ~isnan(Epoch.WL_23(bds_prns));
            EN_fix = ~isnan(Epoch.NL_23(bds_prns));
            elev_bds(EW_fix) = abs(elev_bds(EW_fix)) + 90;
            elev_bds(EN_fix) = abs(elev_bds(EN_fix)) + 90;
        end
        % downweight satellites which are not fixable
        unfixable = ~Epoch.fixable(Epoch.bds);
        elev_bds(unfixable) = elev_bds(unfixable) - 90;
    end
    
    % find reference satellite
    if max(elev_bds) > 0            % at least one BeiDou satellite is ascending, take highest ascending satellite
        Epoch.refSatBDS = bds_prns(elev_bds == max(elev_bds));
    else                            % all satellites are setting, take highest descending satellite
        Epoch.refSatBDS = bds_prns(elev_bds == min(elev_bds));
    end
    % Epoch.refSatBDS_idx is handled in change2refSat.m
    
end

