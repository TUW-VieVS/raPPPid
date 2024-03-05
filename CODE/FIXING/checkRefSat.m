function [newRefSat, changeRefSat] = checkRefSat(Epoch, settings, elev)
% This functions checks if any reference satellites have to be changed. 
% 
% INPUT:
%   Epoch               struct, epoch-specific data for current epoch
%   settings            struct, processing settings from GUI
%   elev                elevation of all satellites [°]
% OUTPUT:
%   newRefSat           1x5, boolean, true if a new reference satellite 
%                           has to be chosen (GPS, GLO, GAL, BDS, QZSS)
%   changeRefSat        1x5, boolean, true if a reference satellite should
%                           be changed (GPS, GLO, GAL, BDS, QZSS)
% 
% Revision:
%   2024/02/05, MFWG: improve code, extend to all GNSS
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% initialize variables
newRefSat    = false(1,5);     % GPS, GLO, GAL, BDS, QZSS
changeRefSat = false(1,5);     % GPS, GLO, GAL, BDS, QZSS

kill = any(Epoch.exclude | Epoch.cs_found | ~Epoch.fixable, 2);
kill_GLO = any(Epoch.exclude | Epoch.cs_found, 2);      % GLONASS satellites are usually not fixable

HighestSat = strcmp(settings.AMBFIX.refSatChoice, 'Highest satellite');


%% check reference satellites

% GPS
if settings.INPUT.use_GPS
    [newRefSat, changeRefSat] = checkRefSat_GNSS(newRefSat, changeRefSat, ...
        HighestSat, Epoch.refSatGPS, Epoch.refSatGPS_idx, elev, Epoch.gps, Epoch.sats, kill, 1);
end

% GLONASS
if settings.INPUT.use_GLO
    [newRefSat, changeRefSat] = checkRefSat_GNSS(newRefSat, changeRefSat, HighestSat, ...
        Epoch.refSatGLO, Epoch.refSatGLO_idx, elev, Epoch.glo, Epoch.sats, kill_GLO, 2);
end

% Galileo
if settings.INPUT.use_GAL
    [newRefSat, changeRefSat] = checkRefSat_GNSS(newRefSat, changeRefSat, HighestSat, ...
        Epoch.refSatGAL, Epoch.refSatGAL_idx, elev, Epoch.gal, Epoch.sats, kill, 3);
end

% BeiDou
if settings.INPUT.use_BDS
    [newRefSat, changeRefSat] = checkRefSat_GNSS(newRefSat, changeRefSat, HighestSat, ...
        Epoch.refSatBDS, Epoch.refSatBDS_idx, elev, Epoch.bds, Epoch.sats, kill, 4);
end

% QZSS
if settings.INPUT.use_QZSS
    [newRefSat, changeRefSat] = checkRefSat_GNSS(newRefSat, changeRefSat, ...
    HighestSat, Epoch.refSatQZS, Epoch.refSatQZS_idx, elev, Epoch.qzss, Epoch.sats, kill, 5);
end





function [newRefSat, changeRefSat] = checkRefSat_GNSS(newRefSat, changeRefSat, ...
    HighestSat, refSat, refSat_idx, elev, gnss, sats, kill, i)
% check reference satellite of current GNSS
% HighestSat ... boolean, true if highest satellites are chosen as ref sats
% refSat ... satellite number of reference satellite
% refSat_idx ... index of reference satellite in Epoch.sats
% elev ... elevation of all satellites [°]
% gnss ... boolean vector for current GNSS
% kill ... boolean, cycle slip or other bad event
% i ... index of GNSS (e.g., 1 for GPS)

elev_gnss = elev(gnss);     % [°], elevation of satellites from current GNSS
elev_refSat = elev(refSat_idx);    % [°], elevation of reference satellite

if refSat ~= 0 && any(gnss)
    if ~ismember(refSat, sats) || kill(refSat_idx)
        % reference satellite got lost
        changeRefSat(i) = true;
    elseif HighestSat
        % check for a better (=higher) reference satellite
        if elev_refSat <= DEF.CUTOFF_REF_SAT && max(elev_gnss) > elev_refSat
            changeRefSat(i) = true;
        end
    end
else
    % currently no reference satellite for this GNSS
    newRefSat(i) = true;
end