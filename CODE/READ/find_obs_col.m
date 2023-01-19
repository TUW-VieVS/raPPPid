function obs = find_obs_col(obs, settings)
% Find columns of all observation types in the observation matrix. 
% If an observation type exists more than once the columns are ranked based 
% on the observation ranking (best/lowest ranking first) in case of RINEX 3
% For RINEX 2 the C1 observation is taken if there is no P1 observation and
% C2 if there is no P2
%
% INPUT:
%   obs........struct observations
%   settings...struct, settings for processing from GUI
% OUTPUT:
%   obs........struct observations, updated with column-numbers
% 
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparation
bool_print = ~settings.INPUT.bool_parfor;
% GPS
obs.GPS.C1 = [];   obs.GPS.C2 = [];   obs.GPS.C3 = [];
obs.GPS.L1 = [];   obs.GPS.L2 = [];   obs.GPS.L3 = [];
obs.GPS.S1 = [];   obs.GPS.S2 = [];   obs.GPS.S3 = [];
obs.GPS.D1 = [];   obs.GPS.D2 = [];   obs.GPS.D3 = [];
% GLO
obs.GLO.C1 = [];   obs.GLO.C2 = [];   obs.GLO.C3 = [];
obs.GLO.L1 = [];   obs.GLO.L2 = [];   obs.GLO.L3 = [];
obs.GLO.S1 = [];   obs.GLO.S2 = [];   obs.GLO.S3 = [];
obs.GLO.D1 = [];   obs.GLO.D2 = [];   obs.GLO.D3 = [];
% GAL
obs.GAL.C1 = [];   obs.GAL.C2 = [];   obs.GAL.C3 = [];
obs.GAL.L1 = [];   obs.GAL.L2 = [];   obs.GAL.L3 = [];
obs.GAL.S1 = [];   obs.GAL.S2 = [];   obs.GAL.S3 = [];
obs.GAL.D1 = [];   obs.GAL.D2 = [];   obs.GAL.D3 = [];
% BDS
obs.BDS.C1 = [];   obs.BDS.C2 = [];   obs.BDS.C3 = [];
obs.BDS.L1 = [];   obs.BDS.L2 = [];   obs.BDS.L3 = [];
obs.BDS.S1 = [];   obs.BDS.S2 = [];   obs.BDS.S3 = [];
obs.BDS.D1 = [];   obs.BDS.D2 = [];   obs.BDS.D3 = [];

% create variable which contains the 2-digit observation type which should be
% used. Necessary mainly for rinex 2 observation data, for rinex 3
% observation data this step is already done when converting the rinex 3
% (3-digit) observation type to the rinex 2 (2-digit) observation type
LL = {'L1'; 'L2'; 'L3'};
CC = {'C1'; 'C2'; 'C3'};
SS = {'S1'; 'S2'; 'S3'};
DD = {'D1'; 'D2'; 'D3'};
if obs.rinex_version == 2
    f_1 = settings.INPUT.gps_freq{1}(2);
    f_2 = settings.INPUT.gps_freq{2}(2);
    LL = {['L' f_1]; ['L' f_2]; ''};
    CC = {['C' f_1]; ['C' f_2]; ''};
    SS = {['S' f_1]; ['S' f_2]; ''};
    DD = {['D' f_1]; ['D' f_2]; ''};
    % P-Code is prefered angainst C-Code
    P2_idx = contains(CC, 'C2');
    P1_idx = contains(CC, 'C1');
    if any(P2_idx) && contains(obs.types_gps, 'P2')     % P2 is taken instead of C2
        CC(P2_idx) = {'P2'};
    end
    if any(P1_idx) && contains(obs.types_gps, 'P1')     % P1 is taken instead of C1
        CC(P1_idx) = {'P1'};
    end
end


%% Find column of observation in observation matrix
% FOR GPS
obs.gps_col.L1 = find_obs_type(LL{1}, obs.types_gps, obs.ranking_gps);
obs.gps_col.L2 = find_obs_type(LL{2}, obs.types_gps, obs.ranking_gps);
obs.gps_col.L3 = find_obs_type(LL{3}, obs.types_gps, obs.ranking_gps);
obs.gps_col.C1 = find_obs_type(CC{1}, obs.types_gps, obs.ranking_gps);
obs.gps_col.C2 = find_obs_type(CC{2}, obs.types_gps, obs.ranking_gps);
obs.gps_col.C3 = find_obs_type(CC{3}, obs.types_gps, obs.ranking_gps);
obs.gps_col.S1 = find_obs_type(SS{1}, obs.types_gps, obs.ranking_gps);
obs.gps_col.S2 = find_obs_type(SS{2}, obs.types_gps, obs.ranking_gps);
obs.gps_col.S3 = find_obs_type(SS{3}, obs.types_gps, obs.ranking_gps);
obs.gps_col.D1 = find_obs_type(DD{1}, obs.types_gps, obs.ranking_gps);
obs.gps_col.D2 = find_obs_type(DD{2}, obs.types_gps, obs.ranking_gps);
obs.gps_col.D3 = find_obs_type(DD{3}, obs.types_gps, obs.ranking_gps);

% FOR GLONASS
obs.glo_col.L1 = find_obs_type(LL{1}, obs.types_glo, obs.ranking_glo);
obs.glo_col.L2 = find_obs_type(LL{2}, obs.types_glo, obs.ranking_glo);
obs.glo_col.L3 = find_obs_type(LL{3}, obs.types_glo, obs.ranking_glo);
obs.glo_col.C1 = find_obs_type(CC{1}, obs.types_glo, obs.ranking_glo);
obs.glo_col.C2 = find_obs_type(CC{2}, obs.types_glo, obs.ranking_glo);
obs.glo_col.C3 = find_obs_type(CC{3}, obs.types_glo, obs.ranking_glo);
obs.glo_col.S1 = find_obs_type(SS{1}, obs.types_glo, obs.ranking_glo);
obs.glo_col.S2 = find_obs_type(SS{2}, obs.types_glo, obs.ranking_glo);
obs.glo_col.S3 = find_obs_type(SS{3}, obs.types_glo, obs.ranking_glo);
obs.glo_col.D1 = find_obs_type(DD{1}, obs.types_glo, obs.ranking_glo);
obs.glo_col.D2 = find_obs_type(DD{2}, obs.types_glo, obs.ranking_glo);
obs.glo_col.D3 = find_obs_type(DD{3}, obs.types_glo, obs.ranking_glo);

% FOR GALILEO
obs.gal_col.L1 = find_obs_type(LL{1}, obs.types_gal, obs.ranking_gal);
obs.gal_col.L2 = find_obs_type(LL{2}, obs.types_gal, obs.ranking_gal);
obs.gal_col.L3 = find_obs_type(LL{3}, obs.types_gal, obs.ranking_gal);
obs.gal_col.C1 = find_obs_type(CC{1}, obs.types_gal, obs.ranking_gal);
obs.gal_col.C2 = find_obs_type(CC{2}, obs.types_gal, obs.ranking_gal);
obs.gal_col.C3 = find_obs_type(CC{3}, obs.types_gal, obs.ranking_gal);
obs.gal_col.S1 = find_obs_type(SS{1}, obs.types_gal, obs.ranking_gal);
obs.gal_col.S2 = find_obs_type(SS{2}, obs.types_gal, obs.ranking_gal);
obs.gal_col.S3 = find_obs_type(SS{3}, obs.types_gal, obs.ranking_gal);
obs.gal_col.D1 = find_obs_type(DD{1}, obs.types_gal, obs.ranking_gal);
obs.gal_col.D2 = find_obs_type(DD{2}, obs.types_gal, obs.ranking_gal);
obs.gal_col.D3 = find_obs_type(DD{3}, obs.types_gal, obs.ranking_gal);

% FOR BEIDOU
obs.bds_col.L1 = find_obs_type(LL{1}, obs.types_bds, obs.ranking_bds);
obs.bds_col.L2 = find_obs_type(LL{2}, obs.types_bds, obs.ranking_bds);
obs.bds_col.L3 = find_obs_type(LL{3}, obs.types_bds, obs.ranking_bds);
obs.bds_col.C1 = find_obs_type(CC{1}, obs.types_bds, obs.ranking_bds);
obs.bds_col.C2 = find_obs_type(CC{2}, obs.types_bds, obs.ranking_bds);
obs.bds_col.C3 = find_obs_type(CC{3}, obs.types_bds, obs.ranking_bds);
obs.bds_col.S1 = find_obs_type(SS{1}, obs.types_bds, obs.ranking_bds);
obs.bds_col.S2 = find_obs_type(SS{2}, obs.types_bds, obs.ranking_bds);
obs.bds_col.S3 = find_obs_type(SS{3}, obs.types_bds, obs.ranking_bds);
obs.bds_col.D1 = find_obs_type(DD{1}, obs.types_bds, obs.ranking_bds);
obs.bds_col.D2 = find_obs_type(DD{2}, obs.types_bds, obs.ranking_bds);
obs.bds_col.D3 = find_obs_type(DD{3}, obs.types_bds, obs.ranking_bds);



%% Create obs.use_column
% Cell-Array indicating which columns are ranked best for each GNSS and 
% observation type. 
% 1st row GPS, 2nd GLO, 3rd GAL, 4rd BDS
% columns:  1 | 2| 3| 4| 5| 6| 7| 8| 9|10|11|12
%           L1|L2|L3|C1|C2|C3|S1|S2|S3|D1|D2|D3
obs.use_column = [...
    save_best_columns(obs.gps_col, settings.INPUT.gps_freq ); ...
    save_best_columns(obs.glo_col, settings.INPUT.glo_freq); ...
    save_best_columns(obs.gal_col, settings.INPUT.gal_freq )
    save_best_columns(obs.bds_col, settings.INPUT.bds_freq )];



%% save observation type and print it to command window
if bool_print; fprintf('\nProcessed Frequencies and Signals:      \n'); end

% --- GPS ---
if settings.INPUT.use_GPS          
    if ~strcmpi(settings.INPUT.gps_freq(1),'OFF')
        idx_L = obs.use_column{1, 1};
        idx_C = obs.use_column{1, 4};
        idx_S = obs.use_column{1, 7};
        idx_D = obs.use_column{1,10};
        if obs.rinex_version >= 3
            obs.GPS.L1 = obs.types_gps_3(3*idx_L-2:3*idx_L);
            obs.GPS.C1 = obs.types_gps_3(3*idx_C-2:3*idx_C);
            obs.GPS.S1 = obs.types_gps_3(3*idx_S-2:3*idx_S);
            obs.GPS.D1 = obs.types_gps_3(3*idx_D-2:3*idx_D);
        elseif obs.rinex_version == 2       % rinex 2 observation file
            obs.GPS.L1 = obs.types_gps(2*idx_L-1:2*idx_L);
            obs.GPS.C1 = obs.types_gps(2*idx_C-1:2*idx_C);
            obs.GPS.S1 = obs.types_gps(2*idx_S-1:2*idx_S);
            obs.GPS.D1 = obs.types_gps(2*idx_D-1:2*idx_D);
        end
        if bool_print; fprintf('  GPS 1: %s, %s, %s, %s\n', obs.GPS.C1, obs.GPS.L1, obs.GPS.S1, obs.GPS.D1); end
    end
    if ~strcmpi(settings.INPUT.gps_freq(2),'OFF')
        idx_L = obs.use_column{1, 2};
        idx_C = obs.use_column{1, 5};
        idx_S = obs.use_column{1, 8};
        idx_D = obs.use_column{1,11};
        if obs.rinex_version >= 3
            obs.GPS.L2 = obs.types_gps_3(3*idx_L-2:3*idx_L);
            obs.GPS.C2 = obs.types_gps_3(3*idx_C-2:3*idx_C);
            obs.GPS.S2 = obs.types_gps_3(3*idx_S-2:3*idx_S);
            obs.GPS.D2 = obs.types_gps_3(3*idx_D-2:3*idx_D);
        elseif obs.rinex_version == 2   % rinex 2 observation file
            obs.GPS.L2 = obs.types_gps(2*idx_L-1:2*idx_L);
            obs.GPS.C2 = obs.types_gps(2*idx_C-1:2*idx_C);
            obs.GPS.S2 = obs.types_gps(2*idx_S-1:2*idx_S); 
            obs.GPS.D2 = obs.types_gps(2*idx_D-1:2*idx_D); 
        end
        if bool_print; fprintf('  GPS 2: %s, %s, %s, %s\n', obs.GPS.C2, obs.GPS.L2, obs.GPS.S2, obs.GPS.D2); end
    end
    if ~strcmpi(settings.INPUT.gps_freq(3),'OFF')
        idx_L = obs.use_column{1, 3};
        idx_C = obs.use_column{1, 6};
        idx_S = obs.use_column{1, 9};
        idx_D = obs.use_column{1,12};
        if obs.rinex_version >= 3  
            % observation type exists only from rinex 3 onwards
            obs.GPS.L3 = obs.types_gps_3(3*idx_L-2:3*idx_L);
            obs.GPS.C3 = obs.types_gps_3(3*idx_C-2:3*idx_C);
            obs.GPS.S3 = obs.types_gps_3(3*idx_S-2:3*idx_S);
            obs.GPS.D3 = obs.types_gps_3(3*idx_D-2:3*idx_D);
        end
        if bool_print; fprintf('  GPS 3: %s, %s, %s, %s\n', obs.GPS.C3, obs.GPS.L3, obs.GPS.S3, obs.GPS.D3); end
    end
end

% --- GLONASS ---
if settings.INPUT.use_GLO       
    if ~strcmpi(settings.INPUT.glo_freq(1),'OFF')
        idx_L = obs.use_column{2, 1};
        idx_C = obs.use_column{2, 4};
        idx_S = obs.use_column{2, 7};
        idx_D = obs.use_column{2,10};
        if obs.rinex_version >= 3
            % observation type exists only from rinex 3 onwards
            obs.GLO.L1 = obs.types_glo_3(3*idx_L-2:3*idx_L);
            obs.GLO.C1 = obs.types_glo_3(3*idx_C-2:3*idx_C);
            obs.GLO.S1 = obs.types_glo_3(3*idx_S-2:3*idx_S);
            obs.GLO.D1 = obs.types_glo_3(3*idx_D-2:3*idx_D);
        elseif obs.rinex_version == 2   % rinex 2 observation file
            obs.GLO.L1 = obs.types_glo(2*idx_L-1:2*idx_L);
            obs.GLO.C1 = obs.types_glo(2*idx_C-1:2*idx_C);
            obs.GLO.S1 = obs.types_glo(2*idx_S-1:2*idx_S);
            obs.GLO.D1 = obs.types_glo(2*idx_D-1:2*idx_D);
        end
        if bool_print; fprintf('  GLO 1: %s, %s, %s, %s\n', obs.GLO.C1, obs.GLO.L1, obs.GLO.S1, obs.GLO.D1); end
    end
    if ~strcmpi(settings.INPUT.glo_freq(2),'OFF')
        idx_L = obs.use_column{2, 2};
        idx_C = obs.use_column{2, 5};
        idx_S = obs.use_column{2, 8};
        idx_D = obs.use_column{2,11};
        if obs.rinex_version >= 3
            % observation type exists only from rinex 3 onwards
            obs.GLO.L2 = obs.types_glo_3(3*idx_L-2:3*idx_L);
            obs.GLO.C2 = obs.types_glo_3(3*idx_C-2:3*idx_C);
            obs.GLO.S2 = obs.types_glo_3(3*idx_S-2:3*idx_S);
            obs.GLO.D2 = obs.types_glo_3(3*idx_D-2:3*idx_D);
        elseif obs.rinex_version == 2   % rinex 2 observation file
            obs.GLO.L2 = obs.types_glo(2*idx_L-1:2*idx_L);
            obs.GLO.C2 = obs.types_glo(2*idx_C-1:2*idx_C);
            obs.GLO.S2 = obs.types_glo(2*idx_S-1:2*idx_S); 
            obs.GLO.D2 = obs.types_glo(2*idx_D-1:2*idx_D); 
        end
        if bool_print; fprintf('  GLO 2: %s, %s, %s, %s\n', obs.GLO.C2, obs.GLO.L2, obs.GLO.S2, obs.GLO.D2); end
    end
    if ~strcmpi(settings.INPUT.glo_freq(3),'OFF')
        idx_L = obs.use_column{2, 3};
        idx_C = obs.use_column{2, 6};
        idx_S = obs.use_column{2, 9};
        idx_D = obs.use_column{2,12};
        if obs.rinex_version >= 3   
            % observation type exists only from rinex 3 onwards
            obs.GLO.L3 = obs.types_glo_3(3*idx_L-2:3*idx_L);
            obs.GLO.C3 = obs.types_glo_3(3*idx_C-2:3*idx_C);
            obs.GLO.S3 = obs.types_glo_3(3*idx_S-2:3*idx_S);
            obs.GLO.D3 = obs.types_glo_3(3*idx_D-2:3*idx_D);
        end
        if bool_print; fprintf('  GLO 3: %s, %s, %s, %s\n', obs.GLO.C3, obs.GLO.L3, obs.GLO.S3, obs.GLO.D3); end
    end
end

% --- GALILEO ---
if settings.INPUT.use_GAL       
    if ~strcmpi(settings.INPUT.gal_freq(1),'OFF')
        idx_L = obs.use_column{3, 1};
        idx_C = obs.use_column{3, 4};
        idx_S = obs.use_column{3, 7};
        idx_D = obs.use_column{3,10};
        if obs.rinex_version >= 3
            % observation type exists only from rinex 3 onwards
            obs.GAL.L1 = obs.types_gal_3(3*idx_L-2:3*idx_L);
            obs.GAL.C1 = obs.types_gal_3(3*idx_C-2:3*idx_C);
            obs.GAL.S1 = obs.types_gal_3(3*idx_S-2:3*idx_S);
            obs.GAL.D1 = obs.types_gal_3(3*idx_D-2:3*idx_D);
        end
        if bool_print; fprintf('  GAL 1: %s, %s, %s, %s\n', obs.GAL.C1, obs.GAL.L1, obs.GAL.S1, obs.GAL.D1); end
    end
    if ~strcmpi(settings.INPUT.gal_freq(2),'OFF')
        idx_L = obs.use_column{3, 2};
        idx_C = obs.use_column{3, 5};
        idx_S = obs.use_column{3, 8};
        idx_D = obs.use_column{3,11};
        if obs.rinex_version >= 3
            % observation type exists only from rinex 3 onwards
            obs.GAL.L2 = obs.types_gal_3(3*idx_L-2:3*idx_L);
            obs.GAL.C2 = obs.types_gal_3(3*idx_C-2:3*idx_C);
            obs.GAL.S2 = obs.types_gal_3(3*idx_S-2:3*idx_S);
            obs.GAL.D2 = obs.types_gal_3(3*idx_D-2:3*idx_D);
        end
        if bool_print; fprintf('  GAL 2: %s, %s, %s, %s\n', obs.GAL.C2, obs.GAL.L2, obs.GAL.S2, obs.GAL.D2); end
    end
    if ~strcmpi(settings.INPUT.gal_freq(3),'OFF')
        idx_L = obs.use_column{3, 3};
        idx_C = obs.use_column{3, 6}; 
        idx_S = obs.use_column{3, 9};
        idx_D = obs.use_column{3, 12};
        if obs.rinex_version >= 3
            % observation type exists only from rinex 3 onwards
            obs.GAL.L3 = obs.types_gal_3(3*idx_L-2:3*idx_L);
            obs.GAL.C3 = obs.types_gal_3(3*idx_C-2:3*idx_C);
            obs.GAL.S3 = obs.types_gal_3(3*idx_S-2:3*idx_S);
            obs.GAL.D3 = obs.types_gal_3(3*idx_D-2:3*idx_D);
        end
        if bool_print; fprintf('  GAL 3: %s, %s, %s, %s\n', obs.GAL.C3, obs.GAL.L3, obs.GAL.S3, obs.GAL.D3); end
    end
end

% --- BEIDOU ----
if settings.INPUT.use_BDS           
    if ~strcmpi(settings.INPUT.bds_freq(1),'OFF')
        idx_L = obs.use_column{4, 1};
        idx_C = obs.use_column{4, 4};
        idx_S = obs.use_column{4, 7};
        idx_D = obs.use_column{4,10};
        if obs.rinex_version >= 3
            % observation type exists only from rinex 3 onwards
            obs.BDS.L1 = obs.types_bds_3(3*idx_L-2:3*idx_L);
            obs.BDS.C1 = obs.types_bds_3(3*idx_C-2:3*idx_C);
            obs.BDS.S1 = obs.types_bds_3(3*idx_S-2:3*idx_S);
            obs.BDS.D1 = obs.types_bds_3(3*idx_D-2:3*idx_D);
        end
        if bool_print; fprintf('  BDS 1: %s, %s, %s, %s\n', obs.BDS.C1, obs.BDS.L1, obs.BDS.S1, obs.BDS.D1); end
    end
    if ~strcmpi(settings.INPUT.bds_freq(2),'OFF')
        idx_L = obs.use_column{4, 2};
        idx_C = obs.use_column{4, 5};
        idx_S = obs.use_column{4, 8};
        idx_D = obs.use_column{4,11};
        if obs.rinex_version >= 3
            % observation type exists only from rinex 3 onwards
            obs.BDS.L2 = obs.types_bds_3(3*idx_L-2:3*idx_L);
            obs.BDS.C2 = obs.types_bds_3(3*idx_C-2:3*idx_C);
            obs.BDS.S2 = obs.types_bds_3(3*idx_S-2:3*idx_S);
            obs.BDS.D2 = obs.types_bds_3(3*idx_D-2:3*idx_D);
        end
        if bool_print; fprintf('  BDS 2: %s, %s, %s, %s\n', obs.BDS.C2, obs.BDS.L2, obs.BDS.S2, obs.BDS.D2); end
    end
    if ~strcmpi(settings.INPUT.bds_freq(3),'OFF')
        idx_L = obs.use_column{4, 3};
        idx_C = obs.use_column{4, 6}; 
        idx_S = obs.use_column{4, 9};
        idx_D = obs.use_column{4, 12};
        if obs.rinex_version >= 3
            % observation type exists only from rinex 3 onwards
            obs.BDS.L3 = obs.types_bds_3(3*idx_L-2:3*idx_L);
            obs.BDS.C3 = obs.types_bds_3(3*idx_C-2:3*idx_C);
            obs.BDS.S3 = obs.types_bds_3(3*idx_S-2:3*idx_S);
            obs.BDS.D3 = obs.types_bds_3(3*idx_D-2:3*idx_D);
        end
        if bool_print; fprintf('  BDS 3: %s, %s, %s, %s\n', obs.BDS.C3, obs.BDS.L3, obs.BDS.S3, obs.BDS.D3); end
    end
end



%% Change 2-digit observation codes
if obs.rinex_version >= 3
    if settings.INPUT.use_GPS
        % Change C1 to P1 for GPS C1W
        obs.types_gps = change2digitObsType(obs.GPS.C1, 'C1W', 'P1', obs.use_column{1, 4}, obs.types_gps);
        obs.types_gps = change2digitObsType(obs.GPS.C2, 'C1W', 'P1', obs.use_column{1, 5}, obs.types_gps);
        obs.types_gps = change2digitObsType(obs.GPS.C3, 'C1W', 'P1', obs.use_column{1, 6}, obs.types_gps);
        % Change C2 to P2 for GPS C2W
        obs.types_gps = change2digitObsType(obs.GPS.C1, 'C2W', 'P2', obs.use_column{1, 4}, obs.types_gps);
        obs.types_gps = change2digitObsType(obs.GPS.C2, 'C2W', 'P2', obs.use_column{1, 5}, obs.types_gps);
        obs.types_gps = change2digitObsType(obs.GPS.C3, 'C2W', 'P2', obs.use_column{1, 6}, obs.types_gps);
    end
    if settings.INPUT.use_GLO
        % Change C1 to P1 for Glonass C1P
        obs.types_glo = change2digitObsType(obs.GLO.C1, 'C1P', 'P1', obs.use_column{2, 4}, obs.types_glo);
        obs.types_glo = change2digitObsType(obs.GLO.C2, 'C1P', 'P1', obs.use_column{2, 5}, obs.types_glo);
        obs.types_glo = change2digitObsType(obs.GLO.C3, 'C1P', 'P1', obs.use_column{2, 6}, obs.types_glo);
        % Change C2 to P2 for GPS C2P
        obs.types_glo = change2digitObsType(obs.GLO.C1, 'C2P', 'P2', obs.use_column{2, 4}, obs.types_glo);
        obs.types_glo = change2digitObsType(obs.GLO.C2, 'C2P', 'P2', obs.use_column{2, 5}, obs.types_glo);
        obs.types_glo = change2digitObsType(obs.GLO.C3, 'C2P', 'P2', obs.use_column{2, 6}, obs.types_glo);
    end
end

end



%% AUXILIARY FUNCTION
function obs_types = change2digitObsType(proc, digit3, digit2, idx, obs_types)
% function to change the 2-digit-observation code for 
% e.g. GPS L1W from C1 to P1
% INPUT:
%   proc            string, processed 3-digit-observation type on current frequency
%   digit3          string, 3-digit observation type for which the 2-digit
%                       observation type should be changed
%   digit2          string, change observation type into this 
%   idx             column of observation type in observation matrix
%   obs_types       string, 2-digit-observation types for current GNSS
% OUTPUT:
%   obs_types       updated or unchanged
% *************************************************************************

if strcmp(proc, digit3)             % check if observation type to change is processed
    vec = (idx*2-1):(idx*2);
    obs_types(vec) = digit2;        % change 2-digit observation code
end
end



function idx = find_obs_type(type, obs_types, ranking)
% Returns columns i of the observation matrix which contain
% observation type "type"
% Argument I/O: 
% 	obs_types	string with all occuring obs_types without blank
% 	type	  	string containing one type of observation
% 	ranking     vector with ranking of the observations of obs_types
% Returns:
%	idx         vector with indices of the observation type in the
%                   observation matrix sorted by their ranking (1st element
%                   belongs to column with highest ranking, ...)
%                  	empty if type does not exist in obs_types
% *************************************************************************

s = strfind(obs_types, type);	% was findstr before
idx = (s+1)/2;
if numel(idx) > 1                   % observation type exists more than once
    ranking = ranking(idx);         % get ranking of these observation types
    [~, order] = sort(ranking);     % sort by ranking
    idx = idx(order);               % sort obs. columns by ranking
end
end



function row = save_best_columns(obs_gnss_col, proc_freq)
% get and save the column of the best observation type (best/lowest
% ranking) depending on the processed frequencies (proc_freq)
row = cell(1,12);
% Phase
if ~isempty(obs_gnss_col.L1)
    row{1,1}  = obs_gnss_col.L1(1);
end
if ~isempty(obs_gnss_col.L2)
    row{1,2}  = obs_gnss_col.L2(1);
end
if ~isempty(obs_gnss_col.L3)
    row{1,3}  = obs_gnss_col.L3(1);
end
% Code
if ~isempty(obs_gnss_col.C1)
    row{1,4}  = obs_gnss_col.C1(1);
end
if ~isempty(obs_gnss_col.C2)
    row{1,5}  = obs_gnss_col.C2(1);
end
if ~isempty(obs_gnss_col.C3)
    row{1,6}  = obs_gnss_col.C3(1);
end
% Signal Strength
if ~isempty(obs_gnss_col.S1)
    row{1,7} = obs_gnss_col.S1(1);
end
if ~isempty(obs_gnss_col.S2)
    row{1,8} = obs_gnss_col.S2(1);
end
if ~isempty(obs_gnss_col.S3)
    row{1,9} = obs_gnss_col.S3(1);
end
% Doppler
if ~isempty(obs_gnss_col.D1)
    row{1,10} = obs_gnss_col.D1(1);
end
if ~isempty(obs_gnss_col.D2)
    row{1,11} = obs_gnss_col.D2(1);
end
if ~isempty(obs_gnss_col.D3)
    row{1,12} = obs_gnss_col.D3(1);
end
end