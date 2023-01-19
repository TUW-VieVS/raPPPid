function Epoch = handleRefSats(Epoch, model, settings, HMW_12, HMW_23, HMW_13)
% This function handles the reference satellite for one processing epoch in
% If no reference satellite is chosen yet a reference satellite depending
% on the choice in the GUI is choosen. Otherwise the current reference
% satellite is checked and if necessary a change or reset of the reference
% satellite performed.
% For: GPS and Galileo
%
% INPUT:
%   Epoch       struct, epoch-specific data
%   model     	struct, modelled values of observations
%   settings  	struct, processing settings from GUI
%	HMW_12,...  Hatch-Melbourne-Wübbena LC observables
% OUTPUT:
%   Epoch       struct, updated with reference satellite and index
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% prepare
elev = model.el;                  	% elevation of satellites of this epoch
elev(Epoch.cs_found) = NaN;         % exclude satellites with cycle slip
elev(elev == 0) = NaN;              % exclude satellites without elevation (e.g. satellite has no precise orbit or clock)
refSatGPS_old = Epoch.refSatGPS;    % GPS reference satellite from last epoch
refSatGAL_old = Epoch.refSatGAL;    % Galileo reference satellite from last epoch
refSatBDS_old = Epoch.refSatBDS;    % BeiDou reference satellite from last epoch

% index/geometry could have changed
Epoch.refSatGPS_idx = find(Epoch.sats == Epoch.refSatGPS);
Epoch.refSatGAL_idx = find(Epoch.sats == Epoch.refSatGAL);
Epoch.refSatBDS_idx = find(Epoch.sats == Epoch.refSatBDS);

% check reference satellites (existing and still valid)
[new_GPS, new_GAL, new_BDS, change_GPS, change_GAL, change_BDS] = ...
    checkRefSat(Epoch, settings, Epoch.exclude, elev);


%% GPS
if new_GPS || change_GPS
    % a new GPS reference satellite has to be found
    switch settings.AMBFIX.refSatChoice
        case 'Highest satellite'
            elev_gps = elev(Epoch.gps);
            Epoch = chooseHighestRefSatGPS(Epoch, elev_gps, Epoch.exclude, settings);
        case 'manual choice (list):'
            Epoch = chooseRefSatManual_GPS(Epoch, settings, Epoch.exclude, model.el);
    end
    
end


%% Galileo
if new_GAL || change_GAL
    % a new Galileo reference satellite has to be found
    switch settings.AMBFIX.refSatChoice
        case 'Highest satellite'
            elev_gal = elev(Epoch.gal);
            Epoch = chooseHighestRefSatGAL(Epoch, elev_gal, Epoch.exclude, settings);
        case 'manual choice (list):'
            Epoch = chooseRefSatManual_GAL(Epoch, settings, Epoch.exclude, model.el);
    end
end


%% BeiDou
if new_BDS || change_BDS
    % a new BeiDou reference satellite has to be found
    switch settings.AMBFIX.refSatChoice
        case 'Highest satellite'
            elev_bds = elev(Epoch.bds);
            Epoch = chooseHighestRefSatBDS(Epoch, elev_bds, Epoch.exclude, settings);            
        case 'manual choice (list):'
            Epoch = chooseRefSatManual_BDS(Epoch, settings, Epoch.exclude, model.el);
    end
end


%% change
if new_GPS || change_GPS || new_GAL || change_GAL || new_BDS || change_BDS
    Epoch = change2refSat(Epoch, new_GPS, new_GAL, new_BDS, ...
        change_GPS, change_GAL, change_BDS, ...
        refSatGPS_old, refSatGAL_old, refSatBDS_old, ...
        settings.INPUT.use_GPS, settings.INPUT.use_GAL, settings.INPUT.use_BDS, ...
        ~settings.INPUT.bool_parfor);
end
