function obs = assign_corr2brdc_biases(obs, input, settings)
% Finds the correct code and/or phase biases from CNES stream and assigns
% it to obs.L1/L2/L3/C1/C2/C3_corr
%
% INPUT:
%   obs         struct, observable specific data
%   input       struct, data which was read in
%   settings    struct, processing settings from GUI
% OUTPUT:
%   obs         struct, updated with obs.C1/C2/C3_corr and obs.L1/L2/L3_corr
%               and C_/L_corr_time and used_biases
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| assumes that the biases of all GNSS have the same time-stamp
% ||| assumes that the stream contains GPS corrections


% initialize used phase and code bias correction type (3-digit) for each GNSS
obs.used_biases_GPS = cell(3,2);
obs.used_biases_GLO = cell(3,2);
obs.used_biases_GAL = cell(3,2);
obs.used_biases_BDS = cell(3,2);

% prepare variables
gps_cols = 1:DEF.SATS_GPS;
glo_cols = 100 + (1:DEF.SATS_GLO);
gal_cols = 200 + (1:DEF.SATS_GAL);
bds_cols = 300 + (1:DEF.SATS_BDS);

% needed for initializing and checking for new data
if settings.INPUT.use_GPS
    corr2brdc = input.ORBCLK.corr2brdc_GPS;
elseif settings.INPUT.use_GLO
    corr2brdc = input.ORBCLK.corr2brdc_GLO;
elseif settings.INPUT.use_GAL
    corr2brdc = input.ORBCLK.corr2brdc_GAL;
else
    corr2brdc = input.ORBCLK.corr2brdc_BDS;
end



%% --- CODE BIASES ---
obs.C_corr_time = corr2brdc.t_code;
if settings.BIASES.code_corr2brdc_bool && ~isempty(corr2brdc.cbias)
    
    % initialize
    rows = length(obs.C_corr_time);
    obs.C1_corr = zeros(rows,410); obs.C2_corr = zeros(rows,410); obs.C3_corr = zeros(rows,410);
    
    % -- GPS --
    if settings.INPUT.use_GPS && ~isempty(input.ORBCLK.corr2brdc_GPS.cbias)
        code_gps = fieldnames(input.ORBCLK.corr2brdc_GPS.cbias);             % fieldnames of GPS code bias corrections
        if isfield(obs.GPS, 'C1') && ~isempty(obs.GPS.C1)
            [obs.C1_corr(:,gps_cols), obs.used_biases_GPS{1,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GPS.cbias, obs.C1_corr(:,gps_cols), code_gps, obs.GPS.C1, 'GPS C1');
        end
        if isfield(obs.GPS, 'C2') && ~isempty(obs.GPS.C2)
            [obs.C2_corr(:,gps_cols), obs.used_biases_GPS{2,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GPS.cbias, obs.C2_corr(:,gps_cols), code_gps, obs.GPS.C2, 'GPS C2');
        end
        if isfield(obs.GPS, 'C3') && ~isempty(obs.GPS.C3)
            [obs.C3_corr(:,gps_cols), obs.used_biases_GPS{3,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GPS.cbias, obs.C3_corr(:,gps_cols), code_gps, obs.GPS.C3, 'GPS C3');
        end
    end
    
    % -- Glonass
    if settings.INPUT.use_GLO && ~isempty(input.ORBCLK.corr2brdc_GLO.cbias)
        code_glo = fieldnames(input.ORBCLK.corr2brdc_GLO.cbias);             % fieldnames of Glonass code bias corrections
        if isfield(obs.GLO, 'C1') && ~isempty(obs.GLO.C1)
            [obs.C1_corr(:,glo_cols), obs.used_biases_GLO{1,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GLO.cbias, obs.C1_corr(:,glo_cols), code_glo, obs.GLO.C1, 'Glonass C1');
        end
        if isfield(obs.GLO, 'C2') && ~isempty(obs.GLO.C2)
            [obs.C2_corr(:,glo_cols), obs.used_biases_GLO{2,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GLO.cbias, obs.C2_corr(:,glo_cols), code_glo, obs.GLO.C2, 'Glonass C2');
        end
        if isfield(obs.GLO, 'C3') && ~isempty(obs.GLO.C3)
            [obs.C3_corr(:,glo_cols), obs.used_biases_glo{3,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GLO.cbias, obs.C3_corr(:,glo_cols), code_glo, obs.GLO.C3, 'Glonass C3');
        end
    end
    
    % -- Galileo --
    if settings.INPUT.use_GAL && ~isempty(input.ORBCLK.corr2brdc_GAL.cbias)
        code_gal = fieldnames(input.ORBCLK.corr2brdc_GAL.cbias);             % fieldnames of Galileo code bias corrections
        if isfield(obs.GAL, 'C1') && ~isempty(obs.GAL.C1)
            [obs.C1_corr(:,gal_cols), obs.used_biases_GAL{1,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GAL.cbias, obs.C1_corr(:,gal_cols), code_gal, obs.GAL.C1, 'Galileo C1');
        end
        if isfield(obs.GAL, 'C2') && ~isempty(obs.GAL.C2)
            [obs.C2_corr(:,gal_cols), obs.used_biases_GAL{2,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GAL.cbias, obs.C2_corr(:,gal_cols), code_gal, obs.GAL.C2, 'Galileo C2');
        end
        if isfield(obs.GAL, 'C3') && ~isempty(obs.GAL.C3)
            [obs.C3_corr(:,gal_cols), obs.used_biases_GAL{3,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GAL.cbias, obs.C2_corr(:,gal_cols), code_gal, obs.GAL.C3, 'Galileo C3');
        end
    end
    
    % -- BeiDou --
    if settings.INPUT.use_BDS && ~isempty(input.ORBCLK.corr2brdc_BDS.cbias)
        code_bds = fieldnames(input.ORBCLK.corr2brdc_BDS.cbias);             % fieldnames of BeiDou code bias corrections
        if isfield(obs.BDS, 'C1') && ~isempty(obs.BDS.C1)
            [obs.C1_corr(:,bds_cols), obs.used_biases_BDS{1,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_BDS.cbias, obs.C1_corr(:,bds_cols), code_bds, obs.BDS.C1, 'BeiDou C1');
        end
        if isfield(obs.BDS, 'C2') && ~isempty(obs.BDS.C2)
            [obs.C2_corr(:,bds_cols), obs.used_biases_BDS{2,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_BDS.cbias, obs.C2_corr(:,bds_cols), code_bds, obs.BDS.C2, 'BeiDou C2');
        end
        if isfield(obs.BDS, 'C3') && ~isempty(obs.BDS.C3)
            [obs.C3_corr(:,bds_cols), obs.used_biases_BDS{3,2}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_BDS.cbias, obs.C2_corr(:,bds_cols), code_bds, obs.BDS.C3, 'BeiDou C3');
        end
    end
end


%% --- PHASE BIASES ---
obs.L_corr_time = corr2brdc.t_phase;
if settings.BIASES.phase_corr2brdc_bool && ~isempty(corr2brdc.pbias)
    
    rows = length(obs.L_corr_time);
    obs.L1_corr = zeros(rows,410); obs.L2_corr = zeros(rows,410); obs.L3_corr = zeros(rows,410);
    
    % -- GPS --
    if settings.INPUT.use_GPS && ~isempty(input.ORBCLK.corr2brdc_GPS.pbias)
        gps_phase = fieldnames(input.ORBCLK.corr2brdc_GPS.pbias);         % fieldnames of GPS phase biases
        if isfield(obs.GPS, 'L1') && ~isempty(obs.GPS.L1)
            [obs.L1_corr(:,gps_cols), obs.used_biases_GPS{1,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GPS.pbias, obs.L1_corr(:,gps_cols), gps_phase, obs.GPS.L1, 'GPS L1');
        end
        if isfield(obs.GPS, 'L2') && ~isempty(obs.GPS.L2)
            [obs.L2_corr(:,gps_cols), obs.used_biases_GPS{2,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GPS.pbias, obs.L2_corr(:,gps_cols), gps_phase, obs.GPS.L2, 'GPS L2');
        end
        if isfield(obs.GPS, 'L3') && ~isempty(obs.GPS.L3)
            [obs.L3_corr(:,gps_cols), obs.used_biases_GPS{3,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GPS.pbias, obs.L3_corr(:,gps_cols), gps_phase, obs.GPS.L3, 'GPS L3');
        end
    end
    
    % -- Glonass --
    % ||| no phase biases existing
    
    % -- Galileo --
    if settings.INPUT.use_GAL && ~isempty(input.ORBCLK.corr2brdc_GAL.pbias)
        gal_phase = fieldnames(input.ORBCLK.corr2brdc_GAL.pbias);         % fieldnames of Galileo phase biases
        if isfield(obs.GAL, 'L1') && ~isempty(obs.GAL.L1)
            [obs.L1_corr(:,gal_cols), obs.used_biases_GAL{1,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GAL.pbias, obs.L1_corr(:,gal_cols), gal_phase, obs.GAL.L1, 'Galileo L1');
        end
        if isfield(obs.GAL, 'L2') && ~isempty(obs.GAL.L2)
            [obs.L2_corr(:,gal_cols), obs.used_biases_GAL{2,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GAL.pbias, obs.L2_corr(:,gal_cols), gal_phase, obs.GAL.L2, 'Galileo L2');
        end
        if isfield(obs.GAL, 'L3') && ~isempty(obs.GAL.L3)
            [obs.L3_corr(:,gal_cols), obs.used_biases_GAL{3,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_GAL.pbias, obs.L3_corr(:,gal_cols), gal_phase, obs.GAL.L3, 'Galileo L3');
        end
    end
    
    % -- BeiDou --
    if settings.INPUT.use_BDS && ~isempty(input.ORBCLK.corr2brdc_BDS.pbias)
        bds_phase = fieldnames(input.ORBCLK.corr2brdc_BDS.pbias);         % fieldnames of BeiDou phase biases
        if isfield(obs.BDS, 'L1') && ~isempty(obs.BDS.L1)
            [obs.L1_corr(:,bds_cols), obs.used_biases_BDS{1,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_BDS.pbias, obs.L1_corr(:,bds_cols), bds_phase, obs.BDS.L1, 'BeiDou L1');
        end
        if isfield(obs.BDS, 'L2') && ~isempty(obs.BDS.L2)
            [obs.L2_corr(:,bds_cols), obs.used_biases_BDS{2,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_BDS.pbias, obs.L2_corr(:,bds_cols), bds_phase, obs.BDS.L2, 'BeiDou L2');
        end
        if isfield(obs.BDS, 'L3') && ~isempty(obs.BDS.L3)
            [obs.L3_corr(:,bds_cols), obs.used_biases_BDS{3,1}] = ...
                find_corr2brdc_bias(input.ORBCLK.corr2brdc_BDS.pbias, obs.L3_corr(:,bds_cols), bds_phase, obs.BDS.L3, 'BeiDou L3');
        end
    end
end


function [biases_use, used_bias] = find_corr2brdc_bias(stream_biases, biases_use, all_biases, obs_signal, string)
% Function to find the correct bias correction from correction stream
% biases
% INPUT:
%   stream_biases     struct, all code/phase biases from stream
%   biases_use        matrix, biases which are used at the moment
%   all_biases        cell, all code/phase biases which stream contains
%   obs_signal        3-digit, processed signal
%   string            for output if search fails
% OUTPUT:
%   biases_use        matrix, biases which will be used
%   used_bias         3-digit, bias which will be used
% *************************************************************************

idx_field = contains(all_biases, obs_signal);
if any(idx_field)
    field = all_biases(idx_field);              % get fieldname
    biases_use = stream_biases.(field{1});      % save bias
    used_bias = field{1};
    
else            % no suitable bias correction
    
    if obs_signal(1) == 'L'     % try taking another phase bias on this frequency
        frqs = cellfun( @(a) a(1,2), all_biases);       % get frequency number
        frq_sig = obs_signal(2);
        idx_field = (frqs == frq_sig);
        if any(idx_field)
            field = all_biases(idx_field);              % get fieldname
            biases_use = stream_biases.(field{1});      % save bias
            used_bias = field{1};
%             msgbox([string ' bias: ' char(field) ' instead of ' obs_signal ' used.'], 'Stream Biases', 'help')
            return
        end
    end
    
%     msgbox(['No Bias for ' string ' in correction stream!'], 'Stream Biases', 'help')
    used_bias = [];
end

