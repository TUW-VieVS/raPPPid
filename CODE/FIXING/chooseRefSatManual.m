function refSat = chooseRefSatManual(refSatList, Epoch, gnss, elev_gnss, settings, bool_fixable)
% This function chooses the reference satellite manually by the list which
% was entered into the GUI. If no satellite of the list is observed the
% reference satellite is chosen depending on the "Highest Satellite"
% criterion
%
% INPUT:
%   refSatList      manually defined reference satellites from GUI for this GNSS
%   Epoch           struct, containing epoch-specific data
%   gnss            boolean, for current GNSS
%   elev            [°], elevation of satellites from this GNSS
%   settings        struct, processing settings from GUI
%   bool_fixable    boolean, consider fixability of satellites
% OUTPUT:
%   refSat       	number of selected reference satellite
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% preparations
exclude = any(Epoch.exclude(gnss, :), 2);   % to check which satellites are healthy
sats_gnss = Epoch.sats(gnss);       % satellite numbers of current GNSS

% find manually defined reference satellites which are observed and healthy
idx = ismember(refSatList, sats_gnss(~exclude));
refSat = refSatList(idx);

if ~isempty(refSat)
    % take first visible and healthy satellite from reference satellite list as the new refSat
    refSat = refSat(1);
else
    % no satellite from reference satellite list is possible 
    % -> choose highest satellite
    refSat = chooseHighestRefSat(Epoch, sats_gnss, elev_gnss, gnss, settings, bool_fixable);
end



% Epoch.refSatGPS/GLO/GAL/BDS/QZS_idx is handled in change2refSat_IF/_DCM.m