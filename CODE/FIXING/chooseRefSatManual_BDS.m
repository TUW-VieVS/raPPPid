function Epoch = chooseRefSatManual_BDS(Epoch, settings, cutoff, elev)
% This function chooses the reference satellite manually by the list which
% was entered into the GUI. If no satellite of the list is observed the
% reference satellite is chosen depending on the "Highest Satellite"
% criterion
%
% INPUT:
%   Epoch       struct, containing epoch-specific data
%   settings   	struct, processing settings from GUI
%   cutoff     	boolean vector, satellite under cutoff-angle?
%   elev       	vector, elevation [°] of epoch-satellites
% OUTPUT:
%   Epoch       struct, updated with choosen reference satellite(s)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

cutoff_prns = Epoch.sats(any(cutoff));

if settings.INPUT.use_BDS
    BDS_list = settings.AMBFIX.refSatBDS;
    % check if satellites from manual reference satellite list are under
    % cutoff and exclude if they are
    remove = false(1, numel(BDS_list));
    for i = 1:numel(BDS_list)
        remove(i) = ismember(BDS_list(i), cutoff_prns);
    end
    BDS_list(remove) = [];
    if Epoch.refSatBDS == 0
        % no reference satellite yet
        idx_list = find(ismember(BDS_list, Epoch.sats), 1, 'first');
        if any(idx_list)
            Epoch.refSatBDS = BDS_list(idx_list);
            Epoch.WL_12(Epoch.refSatBDS) = 0;
			Epoch.NL_12(Epoch.refSatBDS) = 0;
            Epoch.WL_23(Epoch.refSatBDS) = 0;
			Epoch.NL_23(Epoch.refSatBDS) = 0;
            fprintf('\tBeiDou Reference Satellite set by hand: %03d                 \n', Epoch.refSatBDS);
        else        % no manual reference satellite observed
            fprintf('\tNo BeiDou manual reference satellite is observed!                 \n');
            Epoch = chooseHighestRefSatBDS(Epoch, elev(Epoch.bds), Epoch.exclude, settings);
        end
        
    elseif ~ismember(Epoch.refSatBDS, Epoch.sats)
        % manual reference satellite is not observed anymore
        idx_list = find(ismember(BDS_list, Epoch.sats), 1, 'first');
        if any(idx_list)
            Epoch.refSatBDS = BDS_list(idx_list);
            fprintf('\tChange of manual Reference Satellite BeiDou to %03d                           \n', Epoch.refSatBDS);
            % Recalculate ambiguities
            Epoch.WL_12(301:399) = Epoch.WL_12(301:399) - Epoch.WL_12(Epoch.refSatBDS);
            Epoch.NL_12(301:399) = Epoch.NL_12(301:399) - Epoch.NL_12(Epoch.refSatBDS);
			Epoch.WL_23(301:399) = Epoch.WL_23(301:399) - Epoch.WL_23(Epoch.refSatBDS);
			Epoch.NL_23(301:399) = Epoch.NL_23(301:399) - Epoch.NL_23(Epoch.refSatBDS);
        else        % no manual reference satellite observed
            fprintf('\tNo BeiDou manual reference satellite is observed!                 \n');
            Epoch = chooseHighestRefSatBDS(Epoch, elev(Epoch.bds),Epoch.exclude, settings);
        end
    end
end
Epoch.refSatBDS_idx = find(Epoch.sats == Epoch.refSatBDS);


