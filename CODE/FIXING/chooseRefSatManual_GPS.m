function Epoch = chooseRefSatManual_GPS(Epoch, settings, cutoff, elev)
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


cutoff_prns = Epoch.sats(any(cutoff,2));

if settings.INPUT.use_GPS
    GPS_list = settings.AMBFIX.refSatGPS;
    % check if satellites from manual reference satellite list are under
    % cutoff and exclude if they are
    remove = false(1, numel(GPS_list));
    for i = 1:numel(GPS_list)
        remove(i) = ismember(GPS_list(i), cutoff_prns);
    end
    GPS_list(remove) = [];
    if Epoch.refSatGPS == 0  
        % no reference satellite yet
        idx_list = find(ismember(GPS_list, Epoch.sats), 1, 'first');
        if any(idx_list)
            Epoch.refSatGPS = GPS_list(idx_list);
            Epoch.NL_12(Epoch.refSatGPS) = 0;
            Epoch.WL_12(Epoch.refSatGPS) = 0;
            Epoch.WL_23(Epoch.refSatGPS) = 0;
			Epoch.NL_23(Epoch.refSatGPS) = 0;
            fprintf('\tGPS Reference Satellite set by hand: %03d                 \n', Epoch.refSatGPS);
        else        % no manual reference satellite observed
            fprintf('\tNo GPS manual reference satellite is observed!                 \n');
            Epoch = chooseHighestRefSatGPS(Epoch, elev(Epoch.gps), Epoch.exclude, settings);
        end

    elseif ~ismember(Epoch.refSatGPS, Epoch.sats)
        % manual reference satellite is not observed anymore
        idx_list = find(ismember(GPS_list, Epoch.sats), 1, 'first');
        if any(idx_list)
            Epoch.refSatGPS = GPS_list(idx_list);
            fprintf('\tChange of manual Reference Satellite GPS to %03d                           \n', Epoch.refSatGPS);
            % Recalculate ambiguities
            Epoch.WL_12(1:99) = Epoch.WL_12(1:99) - Epoch.WL_12(Epoch.refSatGPS);
            Epoch.NL_12(1:99) = Epoch.NL_12(1:99) - Epoch.NL_12(Epoch.refSatGPS);
			Epoch.WL_23(1:99) = Epoch.WL_23(1:99) - Epoch.WL_23(Epoch.refSatGPS);
			Epoch.NL_23(1:99) = Epoch.NL_23(1:99) - Epoch.NL_23(Epoch.refSatGPS);
        else        % no manual reference satellite observed
            fprintf('\tNo GPS manual reference satellite is observed!                 \n');
            Epoch = chooseHighestRefSatGPS(Epoch, elev(Epoch.gps), Epoch.exclude, settings);
        end
    end
end
Epoch.refSatGPS_idx = find(Epoch.sats == Epoch.refSatGPS);

end