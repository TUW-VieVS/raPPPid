function [obs] = SavePrintObsType(obs, settings)
% This function saves the observation type into, for example, obs.GPS.L1 or
% obs.BDS.C2 and prints the processed observations to the command window.
%
% INPUT:
%   obs         struct, observations specific information
%   settings    struct, processing settings from GUI
% OUTPUT:
%	obs         struct, updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

bool_print = ~settings.INPUT.bool_parfor;
if bool_print; fprintf('\nSelected Frequencies and Signals:      \n'); end

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

% --- GPS ---
if settings.INPUT.use_GPS
    if ~strcmpi(settings.INPUT.gps_freq(1),'OFF')
        idx_L = obs.use_column{1, 1};
        idx_C = obs.use_column{1, 4};
        idx_S = obs.use_column{1, 7};
        idx_D = obs.use_column{1,10};
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
        if obs.rinex_version >= 3 || obs.rinex_version == 0
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
% Note (according to RINEX 4 specifications): When reading a RINEX file, 
% both 1I/Q/X and 2I/Q/X observation codes  should be accepted and treated 
% the same as 2I/Q/X in the current RINEX standard. 
if settings.INPUT.use_BDS
    if ~strcmpi(settings.INPUT.bds_freq(1),'OFF')
        idx_L = obs.use_column{4, 1};
        idx_C = obs.use_column{4, 4};
        idx_S = obs.use_column{4, 7};
        idx_D = obs.use_column{4,10};
        if obs.rinex_version >= 3 || obs.rinex_version == 0
            % observation type exists only from rinex 3 onwards
            obs.BDS.L1 = BDS_2_to_1(obs.types_bds_3(3*idx_L-2:3*idx_L));
            obs.BDS.C1 = BDS_2_to_1(obs.types_bds_3(3*idx_C-2:3*idx_C));
            obs.BDS.S1 = BDS_2_to_1(obs.types_bds_3(3*idx_S-2:3*idx_S));
            obs.BDS.D1 = BDS_2_to_1(obs.types_bds_3(3*idx_D-2:3*idx_D));
        end
        if bool_print; fprintf('  BDS 1: %s, %s, %s, %s\n', obs.BDS.C1, obs.BDS.L1, obs.BDS.S1, obs.BDS.D1); end
    end
    if ~strcmpi(settings.INPUT.bds_freq(2),'OFF')
        idx_L = obs.use_column{4, 2};
        idx_C = obs.use_column{4, 5};
        idx_S = obs.use_column{4, 8};
        idx_D = obs.use_column{4,11};
        if obs.rinex_version >= 3 || obs.rinex_version == 0
            % observation type exists only from rinex 3 onwards
            obs.BDS.L2 = BDS_2_to_1(obs.types_bds_3(3*idx_L-2:3*idx_L));
            obs.BDS.C2 = BDS_2_to_1(obs.types_bds_3(3*idx_C-2:3*idx_C));
            obs.BDS.S2 = BDS_2_to_1(obs.types_bds_3(3*idx_S-2:3*idx_S));
            obs.BDS.D2 = BDS_2_to_1(obs.types_bds_3(3*idx_D-2:3*idx_D));
        end
        if bool_print; fprintf('  BDS 2: %s, %s, %s, %s\n', obs.BDS.C2, obs.BDS.L2, obs.BDS.S2, obs.BDS.D2); end
    end
    if ~strcmpi(settings.INPUT.bds_freq(3),'OFF')
        idx_L = obs.use_column{4, 3};
        idx_C = obs.use_column{4, 6};
        idx_S = obs.use_column{4, 9};
        idx_D = obs.use_column{4, 12};
        if obs.rinex_version >= 3 || obs.rinex_version == 0
            % observation type exists only from rinex 3 onwards
            obs.BDS.L3 = BDS_2_to_1(obs.types_bds_3(3*idx_L-2:3*idx_L));
            obs.BDS.C3 = BDS_2_to_1(obs.types_bds_3(3*idx_C-2:3*idx_C));
            obs.BDS.S3 = BDS_2_to_1(obs.types_bds_3(3*idx_S-2:3*idx_S));
            obs.BDS.D3 = BDS_2_to_1(obs.types_bds_3(3*idx_D-2:3*idx_D));
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



function obstype_3 = BDS_2_to_1(obstype_3)
% convert BeiDou 1I/Q/X to 2I/Q/X observation codes (RINEX specification)
if ~isempty(obstype_3) && obstype_3(2) == '1' && ...
        (obstype_3(3) == 'I' || obstype_3(3) == 'Q' || obstype_3(3) == 'X') 
    obstype_3(2) = '2';
end



