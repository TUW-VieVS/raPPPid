function Epoch = chooseHighestRefSatGAL(Epoch, elev_gal, cutoff, settings)
% Function to find or change reference satellite for Galileo.
% INPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   elev_gal  	vector, elevation of possible gps ref sats with +/- sign for rising/setting
%   cutoff      boolean vector, true if satellite is not used 
%   settings    struct, processing settings from GUI
% OUTPUT:
%   Epoch       struct, updated with reference satellite and index
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if settings.INPUT.use_GAL
    gal_prns = Epoch.sats(Epoch.gal);
    
    % no possible reference satellites
    if isempty(gal_prns) || all(isnan(elev_gal)) || all(cutoff(Epoch.gal))
        Epoch = resetRefSat(Epoch, 'GAL');
        return
    end
    
    if settings.AMBFIX.bool_AMBFIX          % check if integer ambiguity fixing is enabled
        % prefere satellites which have WL or NL fixed
        WL_fix = ~isnan(Epoch.WL_12(gal_prns));
        NL_fix = ~isnan(Epoch.NL_12(gal_prns));
        elev_gal(WL_fix) = abs(elev_gal(WL_fix)) + 90;
        elev_gal(NL_fix) = abs(elev_gal(NL_fix)) + 90;
        if strcmp(settings.IONO.model, '2-Frequency-IF-LCs') && settings.INPUT.proc_freqs == 2  % PPPAR and 2xIF is processed
            % prefere satellites which have WL or NL fixed
            EW_fix = ~isnan(Epoch.WL_23(gal_prns));
            EN_fix = ~isnan(Epoch.NL_23(gal_prns));
            elev_gal(EW_fix) = abs(elev_gal(EW_fix)) + 90;
            elev_gal(EN_fix) = abs(elev_gal(EN_fix)) + 90;
        end
        % downweight satellites which are not fixable
        unfixable = ~Epoch.fixable(Epoch.gal);
        elev_gal(unfixable) = elev_gal(unfixable) - 90;
    end
    
    % the elevation of satellites with cycle-slip is set to NaN
    elev_gal(Epoch.cs_found(Epoch.gal)) = NaN;
    
    
    % find reference satellite
    if max(elev_gal) > 0   	% at least one Galileo satellite is ascending, take highest ascending satellite
        refSat = gal_prns(elev_gal == max(elev_gal));
        Epoch.refSatGAL = refSat(1);    % to be on the safe side
    else                    % all satellites are setting, take highest descending satellite
        refSat = gal_prns(elev_gal == min(elev_gal));
        Epoch.refSatGAL = refSat(1);
    end
    % Epoch.refSatGAL_idx is handled in change2refSat_IF/_DCM
    
end

