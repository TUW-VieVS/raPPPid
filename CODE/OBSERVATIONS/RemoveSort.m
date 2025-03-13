function Epoch = RemoveSort(settings, Epoch, q)
% This function sorts the observations for the epoch-wise processing.
% Furthermore, satellites from GNSS not-processed are removed.
% 
% INPUT:
%   settings        struct, settings from GUI
%   obs             struct, observations and data from rinex-obs-file
%   Epoch           struct, epoch-specific data for current epoch
%   q               number of current epoch
% OUTPUT:
%   Epoch       struct, updated
%   obs             struct, updated
%
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


%% (1) Sort satellites and obervationss (ascending raPPPid number)
sats = Epoch.sats;
[sats, sat_index] = sort(sats);
Epoch.sats = sats;
Epoch.obs = Epoch.obs(sat_index,:);
Epoch.LLI_bit_rinex = Epoch.LLI_bit_rinex(sat_index,:);
Epoch.ss_digit_rinex = Epoch.ss_digit_rinex(sat_index,:);
Epoch.gps  = Epoch.gps(sat_index);
Epoch.glo  = Epoch.glo(sat_index);
Epoch.gal  = Epoch.gal(sat_index);
Epoch.bds  = Epoch.bds(sat_index);
Epoch.qzss = Epoch.qzss(sat_index);
Epoch.other_systems = Epoch.other_systems(sat_index);


%% (2) Find satellite systems not used and removed them
is_wrong_system = ...
      ~settings.INPUT.use_GPS  .* Epoch.gps  ...
    | ~settings.INPUT.use_GLO  .* Epoch.glo  ...
    | ~settings.INPUT.use_GAL  .* Epoch.gal  ...
    | ~settings.INPUT.use_BDS  .* Epoch.bds  ...
    | ~settings.INPUT.use_QZSS .* Epoch.qzss ...    
    | Epoch.other_systems;
[Epoch] = remove_sats(Epoch, is_wrong_system);


%% (3) Excluded specific satellites from processing (input in GUI)
% exclude-sats-matrix: col 1 = sat; col 2: GPS=0 / GLO=1 / GAL=2
%                      rows = excluded sats
if ~isempty(intersect(settings.PROC.exclude_sats, Epoch.sats))      % check for agreement
    excluded_sats = settings.PROC.exclude_sats;
    excluded_gps  = (excluded_sats >   0) & (excluded_sats < 100);
    excluded_glo  = (excluded_sats > 100) & (excluded_sats < 200);
    excluded_gal  = (excluded_sats > 200) & (excluded_sats < 300);
    excluded_bds  = (excluded_sats > 300) & (excluded_sats < 400);
    excluded_qzss = (excluded_sats > 400) & (excluded_sats < 500);
    
    if settings.INPUT.use_GPS && any(excluded_gps)      % GPS
        remove_GPS_PRN = excluded_sats(excluded_gps);           % get prns of excluded GPS satellites
        [~,remove_GPS] = ismember(Epoch.sats, remove_GPS_PRN);	% check if prns are observed in current epoch
        remove_GPS(~Epoch.gps) = 0;                          	% that only GPS satellites are removed
        [Epoch] = remove_sats(Epoch, remove_GPS);               % remove data for GPS
    end
    if settings.INPUT.use_GLO && any(excluded_glo)    	% GLONASS, exactly the same as for GPS
        remove_GLO_PRN = excluded_sats(excluded_glo);
        [~,remove_GLO] = ismember(Epoch.sats, remove_GLO_PRN);
        remove_GLO(~Epoch.glo) = 0;
        [Epoch] = remove_sats(Epoch, remove_GLO);
    end
    if settings.INPUT.use_GAL && any(excluded_gal)    	% GALILEO, exactly the same as for GPS
        remove_GAL_PRN = excluded_sats(excluded_gal);
        [~,remove_GAL] = ismember(Epoch.sats, remove_GAL_PRN);
        remove_GAL(~Epoch.gal) = 0;
        [Epoch] = remove_sats(Epoch, remove_GAL);
    end
    if settings.INPUT.use_BDS && any(excluded_bds)    	% BEIDOU, exactly the same as for GPS
        remove_BDS_PRN = excluded_sats(excluded_bds);
        [~,remove_BDS] = ismember(Epoch.sats, remove_BDS_PRN);
        remove_BDS(~Epoch.bds) = 0;
        [Epoch] = remove_sats(Epoch, remove_BDS);
    end
    if settings.INPUT.use_QZSS && any(excluded_qzss)   	% QZSS, exactly the same as for GPS
        remove_QZSS_PRN = excluded_sats(excluded_qzss);
        [~,remove_QZSS] = ismember(Epoch.sats, remove_QZSS_PRN);
        remove_QZSS(~Epoch.qzss) = 0;
        [Epoch] = remove_sats(Epoch, remove_QZSS);
    end    
end


%% (4) Exclude satellites from processing for specific epochs (input in GUI)
if ~isempty(settings.PROC.excl_partly)              % check for input
    from = settings.PROC.excl_partly(:,2);
    to   = settings.PROC.excl_partly(:,3);
    if any((from <= q) & (q <= to))                 % check if any input is valid for current epoch
        prn  = mod(settings.PROC.excl_partly(:,1),100);
        gnss = floor(settings.PROC.excl_partly(:,1)/100);
        % prns of satellites which should be removed for each gnss
        excluded_GPS_PRN  = prn((gnss == 0) & (from <= q) & (q <= to));
        excluded_GLO_PRN  = prn((gnss == 1) & (from <= q) & (q <= to));
        excluded_GAL_PRN  = prn((gnss == 2) & (from <= q) & (q <= to));
        excluded_BDS_PRN  = prn((gnss == 3) & (from <= q) & (q <= to));
        excluded_QZSS_PRN = prn((gnss == 4) & (from <= q) & (q <= to));
        [~,remove_GPS]  = ismember(Epoch.sats.*Epoch.gps,     excluded_GPS_PRN);
        [~,remove_GLO]  = ismember((Epoch.sats-100) .* Epoch.glo,  excluded_GLO_PRN);
        [~,remove_GAL]  = ismember((Epoch.sats-200) .* Epoch.gal,  excluded_GAL_PRN);
        [~,remove_BDS]  = ismember((Epoch.sats-300) .* Epoch.bds,  excluded_BDS_PRN);
        [~,remove_QZSS] = ismember((Epoch.sats-400) .* Epoch.qzss, excluded_QZSS_PRN);
        [Epoch] = remove_sats(Epoch, (remove_GPS|remove_GLO|remove_GAL|remove_BDS|remove_QZSS));
    end
end