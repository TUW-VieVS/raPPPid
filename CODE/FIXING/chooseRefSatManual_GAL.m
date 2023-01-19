function Epoch = chooseRefSatManual_GAL(Epoch, settings, cutoff, elev)
% This function chooses the reference satellite manually by the list which
% was entered into the GUI. If no satellite of the list is observed the
% reference satellite is chosen depending on the "Highest Satellite"
% criterion
%
% INPUT:
%   Epoch       struct, containing epoch-specific data
%   settings        struct, processing settings from GUI
%   cutoff          boolean vector, satellite under cutoff-angle?
%   elev            vector, elevation [°] of epoch-satellites
% OUTPUT:
%   Epoch       struct, updated with choosen reference satellite(s)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

cutoff_prns = Epoch.sats(any(cutoff));

if settings.INPUT.use_GAL
    GAL_list = settings.AMBFIX.refSatGAL;
    % check if satellites from manual reference satellite list are under
    % cutoff and exclude if they are
    remove = false(1, numel(GAL_list));
    for i = 1:numel(GAL_list)
        remove(i) = ismember(GAL_list(i), cutoff_prns);
    end
    GAL_list(remove) = [];
    if Epoch.refSatGAL == 0
        % no reference satellite yet
        idx_list = find(ismember(GAL_list, Epoch.sats), 1, 'first');
        if any(idx_list)
            Epoch.refSatGAL = GAL_list(idx_list);
            Epoch.WL_12(Epoch.refSatGAL) = 0;
			Epoch.NL_12(Epoch.refSatGAL) = 0;
            Epoch.WL_23(Epoch.refSatGAL) = 0;
			Epoch.NL_23(Epoch.refSatGAL) = 0;
            fprintf('\tGalileo Reference Satellite set by hand: %03d                 \n', Epoch.refSatGAL);
        else        % no manual reference satellite observed
            fprintf('\tNo Galileo manual reference satellite is observed!                 \n');
            Epoch = chooseHighestRefSatGAL(Epoch, elev(Epoch.gal), Epoch.exclude, settings);
        end
        
    elseif ~ismember(Epoch.refSatGAL, Epoch.sats)
        % manual reference satellite is not observed anymore
        idx_list = find(ismember(GAL_list, Epoch.sats), 1, 'first');
        if any(idx_list)
            Epoch.refSatGAL = GAL_list(idx_list);
            fprintf('\tChange of manual Reference Satellite Galileo to %03d                           \n', Epoch.refSatGAL);
            % Recalculate ambiguities
            Epoch.WL_12(201:299) = Epoch.WL_12(201:299) - Epoch.WL_12(Epoch.refSatGAL);
            Epoch.NL_12(201:299) = Epoch.NL_12(201:299) - Epoch.NL_12(Epoch.refSatGAL);
			Epoch.WL_23(201:299) = Epoch.WL_23(201:299) - Epoch.WL_23(Epoch.refSatGAL);
			Epoch.NL_23(201:299) = Epoch.NL_23(201:299) - Epoch.NL_23(Epoch.refSatGAL);
        else        % no manual reference satellite observed
            fprintf('\tNo Galileo manual reference satellite is observed!                 \n');
            Epoch = chooseHighestRefSatGAL(Epoch, elev(Epoch.gal),Epoch.exclude, settings);
        end
    end
end
Epoch.refSatGAL_idx = find(Epoch.sats == Epoch.refSatGAL);


end