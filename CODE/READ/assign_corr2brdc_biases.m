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
% Revision:
%   2026/07/21, MFWG: merge corr2brdc bias time-vectors into one common
%   2026/07/24, MFWG: adding QZSS
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| assumes that the stream contains GPS corrections


% initialize used phase and code bias correction type (3-digit) for each GNSS
obs.used_biases_GPS = cell(3,2);
obs.used_biases_GLO = cell(3,2);
obs.used_biases_GAL = cell(3,2);
obs.used_biases_BDS = cell(3,2);
obs.used_biases_QZSS = cell(3,2);

% prepare variables
gps_cols = 1:DEF.SATS_GPS;
glo_cols = 100 + (1:DEF.SATS_GLO);
gal_cols = 200 + (1:DEF.SATS_GAL);
bds_cols = 300 + (1:DEF.SATS_BDS);
qzss_cols = 400 + (1:DEF.SATS_QZSS);



%% --- CODE BIASES ---
% merge the code-bias time-vectors of all used GNSS into one common,
% sorted time-vector (the systems' CODE_BIAS messages are not
% necessarily sent at the same epochs)
t_code_all = [];
if settings.INPUT.use_GPS; t_code_all = [t_code_all; input.ORBCLK.corr2brdc_GPS.t_code(:)]; end
if settings.INPUT.use_GLO; t_code_all = [t_code_all; input.ORBCLK.corr2brdc_GLO.t_code(:)]; end
if settings.INPUT.use_GAL; t_code_all = [t_code_all; input.ORBCLK.corr2brdc_GAL.t_code(:)]; end
if settings.INPUT.use_BDS; t_code_all = [t_code_all; input.ORBCLK.corr2brdc_BDS.t_code(:)]; end
if settings.INPUT.use_QZSS; t_code_all = [t_code_all; input.ORBCLK.corr2brdc_QZSS.t_code(:)]; end
obs.C_corr_time = unique(t_code_all);

if settings.BIASES.code_corr2brdc_bool && ~isempty(obs.C_corr_time)

    % initialize
    rows = length(obs.C_corr_time);
    obs.C1_corr = zeros(rows,410); obs.C2_corr = zeros(rows,410); obs.C3_corr = zeros(rows,410);

    % -- GPS --
    if settings.INPUT.use_GPS && ~isempty(input.ORBCLK.corr2brdc_GPS.cbias)
        t_gps = input.ORBCLK.corr2brdc_GPS.t_code;
        code_gps = fieldnames(input.ORBCLK.corr2brdc_GPS.cbias);             % fieldnames of GPS code bias corrections
        if isfield(obs.GPS, 'C1') && ~isempty(obs.GPS.C1)
            [bias_use, obs.used_biases_GPS{1,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GPS.cbias, zeros(length(t_gps),DEF.SATS_GPS), code_gps, obs.GPS.C1, 'GPS C1');
            obs.C1_corr(:,gps_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_gps, bias_use);
        end
        if isfield(obs.GPS, 'C2') && ~isempty(obs.GPS.C2)
            [bias_use, obs.used_biases_GPS{2,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GPS.cbias, zeros(length(t_gps),DEF.SATS_GPS), code_gps, obs.GPS.C2, 'GPS C2');
            obs.C2_corr(:,gps_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_gps, bias_use);
        end
        if isfield(obs.GPS, 'C3') && ~isempty(obs.GPS.C3)
            [bias_use, obs.used_biases_GPS{3,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GPS.cbias, zeros(length(t_gps),DEF.SATS_GPS), code_gps, obs.GPS.C3, 'GPS C3');
            obs.C3_corr(:,gps_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_gps, bias_use);
        end
    end

    % -- GLONASS --
    if settings.INPUT.use_GLO && ~isempty(input.ORBCLK.corr2brdc_GLO.cbias)
        t_glo = input.ORBCLK.corr2brdc_GLO.t_code;
        code_glo = fieldnames(input.ORBCLK.corr2brdc_GLO.cbias);             % fieldnames of GLONASS code bias corrections
        if isfield(obs.GLO, 'C1') && ~isempty(obs.GLO.C1)
            [bias_use, obs.used_biases_GLO{1,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GLO.cbias, zeros(length(t_glo),DEF.SATS_GLO), code_glo, obs.GLO.C1, 'Glonass C1');
            obs.C1_corr(:,glo_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_glo, bias_use);
        end
        if isfield(obs.GLO, 'C2') && ~isempty(obs.GLO.C2)
            [bias_use, obs.used_biases_GLO{2,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GLO.cbias, zeros(length(t_glo),DEF.SATS_GLO), code_glo, obs.GLO.C2, 'Glonass C2');
            obs.C2_corr(:,glo_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_glo, bias_use);
        end
        if isfield(obs.GLO, 'C3') && ~isempty(obs.GLO.C3)
            [bias_use, obs.used_biases_GLO{3,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GLO.cbias, zeros(length(t_glo),DEF.SATS_GLO), code_glo, obs.GLO.C3, 'Glonass C3');
            obs.C3_corr(:,glo_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_glo, bias_use);
        end
    end

    % -- Galileo --
    if settings.INPUT.use_GAL && ~isempty(input.ORBCLK.corr2brdc_GAL.cbias)
        t_gal = input.ORBCLK.corr2brdc_GAL.t_code;
        code_gal = fieldnames(input.ORBCLK.corr2brdc_GAL.cbias);             % fieldnames of Galileo code bias corrections
        if isfield(obs.GAL, 'C1') && ~isempty(obs.GAL.C1)
            [bias_use, obs.used_biases_GAL{1,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GAL.cbias, zeros(length(t_gal),DEF.SATS_GAL), code_gal, obs.GAL.C1, 'Galileo C1');
            obs.C1_corr(:,gal_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_gal, bias_use);
        end
        if isfield(obs.GAL, 'C2') && ~isempty(obs.GAL.C2)
            [bias_use, obs.used_biases_GAL{2,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GAL.cbias, zeros(length(t_gal),DEF.SATS_GAL), code_gal, obs.GAL.C2, 'Galileo C2');
            obs.C2_corr(:,gal_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_gal, bias_use);
        end
        if isfield(obs.GAL, 'C3') && ~isempty(obs.GAL.C3)
            [bias_use, obs.used_biases_GAL{3,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GAL.cbias, zeros(length(t_gal),DEF.SATS_GAL), code_gal, obs.GAL.C3, 'Galileo C3');
            obs.C3_corr(:,gal_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_gal, bias_use);
        end
    end

    % -- BeiDou --
    if settings.INPUT.use_BDS && ~isempty(input.ORBCLK.corr2brdc_BDS.cbias)
        t_bds = input.ORBCLK.corr2brdc_BDS.t_code;
        code_bds = fieldnames(input.ORBCLK.corr2brdc_BDS.cbias);             % fieldnames of BeiDou code bias corrections
        if isfield(obs.BDS, 'C1') && ~isempty(obs.BDS.C1)
            [bias_use, obs.used_biases_BDS{1,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_BDS.cbias, zeros(length(t_bds),DEF.SATS_BDS), code_bds, obs.BDS.C1, 'BeiDou C1');
            obs.C1_corr(:,bds_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_bds, bias_use);
        end
        if isfield(obs.BDS, 'C2') && ~isempty(obs.BDS.C2)
            [bias_use, obs.used_biases_BDS{2,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_BDS.cbias, zeros(length(t_bds),DEF.SATS_BDS), code_bds, obs.BDS.C2, 'BeiDou C2');
            obs.C2_corr(:,bds_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_bds, bias_use);
        end
        if isfield(obs.BDS, 'C3') && ~isempty(obs.BDS.C3)
            [bias_use, obs.used_biases_BDS{3,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_BDS.cbias, zeros(length(t_bds),DEF.SATS_BDS), code_bds, obs.BDS.C3, 'BeiDou C3');
            obs.C3_corr(:,bds_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_bds, bias_use);
        end
    end

    % -- QZSS --
    if settings.INPUT.use_QZSS && ~isempty(input.ORBCLK.corr2brdc_QZSS.cbias)
        t_qzss = input.ORBCLK.corr2brdc_QZSS.t_code;
        code_qzss = fieldnames(input.ORBCLK.corr2brdc_QZSS.cbias);       % fieldnames of QZSS code bias corrections
        if isfield(obs.QZSS, 'C1') && ~isempty(obs.QZSS.C1)
            [bias_use, obs.used_biases_QZSS{1,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_QZSS.cbias, zeros(length(t_qzss),DEF.SATS_QZSS), code_qzss, obs.QZSS.C1, 'QZSS C1');
            obs.C1_corr(:,qzss_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_qzss, bias_use);
        end
        if isfield(obs.QZSS, 'C2') && ~isempty(obs.QZSS.C2)
            [bias_use, obs.used_biases_QZSS{2,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_QZSS.cbias, zeros(length(t_qzss),DEF.SATS_QZSS), code_qzss, obs.QZSS.C2, 'QZSS C2');
            obs.C2_corr(:,qzss_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_qzss, bias_use);
        end
        if isfield(obs.QZSS, 'C3') && ~isempty(obs.QZSS.C3)
            [bias_use, obs.used_biases_QZSS{3,2}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_QZSS.cbias, zeros(length(t_qzss),DEF.SATS_QZSS), code_qzss, obs.QZSS.C3, 'QZSS C3');
            obs.C3_corr(:,qzss_cols) = scatter_corr2brdc_bias(obs.C_corr_time, t_qzss, bias_use);
        end
    end
end


%% --- PHASE BIASES ---
% merge the phase-bias time-vectors of all used GNSS into one common sorted time-vector
t_phase_all = [];
if settings.INPUT.use_GPS; t_phase_all = [t_phase_all; input.ORBCLK.corr2brdc_GPS.t_phase(:)]; end
if settings.INPUT.use_GAL; t_phase_all = [t_phase_all; input.ORBCLK.corr2brdc_GAL.t_phase(:)]; end
if settings.INPUT.use_BDS; t_phase_all = [t_phase_all; input.ORBCLK.corr2brdc_BDS.t_phase(:)]; end
if settings.INPUT.use_QZSS; t_phase_all = [t_phase_all; input.ORBCLK.corr2brdc_QZSS.t_phase(:)]; end
obs.L_corr_time = unique(t_phase_all);

if settings.BIASES.phase_corr2brdc_bool && ~isempty(obs.L_corr_time)

    rows = length(obs.L_corr_time);
    obs.L1_corr = zeros(rows,410); obs.L2_corr = zeros(rows,410); obs.L3_corr = zeros(rows,410);

    % -- GPS --
    if settings.INPUT.use_GPS && ~isempty(input.ORBCLK.corr2brdc_GPS.pbias)
        t_gps = input.ORBCLK.corr2brdc_GPS.t_phase;
        gps_phase = fieldnames(input.ORBCLK.corr2brdc_GPS.pbias);         % fieldnames of GPS phase biases
        if isfield(obs.GPS, 'L1') && ~isempty(obs.GPS.L1)
            [bias_use, obs.used_biases_GPS{1,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GPS.pbias, zeros(length(t_gps),DEF.SATS_GPS), gps_phase, obs.GPS.L1, 'GPS L1');
            obs.L1_corr(:,gps_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_gps, bias_use);
        end
        if isfield(obs.GPS, 'L2') && ~isempty(obs.GPS.L2)
            [bias_use, obs.used_biases_GPS{2,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GPS.pbias, zeros(length(t_gps),DEF.SATS_GPS), gps_phase, obs.GPS.L2, 'GPS L2');
            obs.L2_corr(:,gps_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_gps, bias_use);
        end
        if isfield(obs.GPS, 'L3') && ~isempty(obs.GPS.L3)
            [bias_use, obs.used_biases_GPS{3,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GPS.pbias, zeros(length(t_gps),DEF.SATS_GPS), gps_phase, obs.GPS.L3, 'GPS L3');
            obs.L3_corr(:,gps_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_gps, bias_use);
        end
    end

    % -- GLONASS --
    % ||| no phase biases existing

    % -- Galileo --
    if settings.INPUT.use_GAL && ~isempty(input.ORBCLK.corr2brdc_GAL.pbias)
        t_gal = input.ORBCLK.corr2brdc_GAL.t_phase;
        gal_phase = fieldnames(input.ORBCLK.corr2brdc_GAL.pbias);         % fieldnames of Galileo phase biases
        if isfield(obs.GAL, 'L1') && ~isempty(obs.GAL.L1)
            [bias_use, obs.used_biases_GAL{1,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GAL.pbias, zeros(length(t_gal),DEF.SATS_GAL), gal_phase, obs.GAL.L1, 'Galileo L1');
            obs.L1_corr(:,gal_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_gal, bias_use);
        end
        if isfield(obs.GAL, 'L2') && ~isempty(obs.GAL.L2)
            [bias_use, obs.used_biases_GAL{2,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GAL.pbias, zeros(length(t_gal),DEF.SATS_GAL), gal_phase, obs.GAL.L2, 'Galileo L2');
            obs.L2_corr(:,gal_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_gal, bias_use);
        end
        if isfield(obs.GAL, 'L3') && ~isempty(obs.GAL.L3)
            [bias_use, obs.used_biases_GAL{3,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_GAL.pbias, zeros(length(t_gal),DEF.SATS_GAL), gal_phase, obs.GAL.L3, 'Galileo L3');
            obs.L3_corr(:,gal_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_gal, bias_use);
        end
    end

    % -- BeiDou --
    if settings.INPUT.use_BDS && ~isempty(input.ORBCLK.corr2brdc_BDS.pbias)
        t_bds = input.ORBCLK.corr2brdc_BDS.t_phase;
        bds_phase = fieldnames(input.ORBCLK.corr2brdc_BDS.pbias);         % fieldnames of BeiDou phase biases
        if isfield(obs.BDS, 'L1') && ~isempty(obs.BDS.L1)
            [bias_use, obs.used_biases_BDS{1,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_BDS.pbias, zeros(length(t_bds),DEF.SATS_BDS), bds_phase, obs.BDS.L1, 'BeiDou L1');
            obs.L1_corr(:,bds_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_bds, bias_use);
        end
        if isfield(obs.BDS, 'L2') && ~isempty(obs.BDS.L2)
            [bias_use, obs.used_biases_BDS{2,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_BDS.pbias, zeros(length(t_bds),DEF.SATS_BDS), bds_phase, obs.BDS.L2, 'BeiDou L2');
            obs.L2_corr(:,bds_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_bds, bias_use);
        end
        if isfield(obs.BDS, 'L3') && ~isempty(obs.BDS.L3)
            [bias_use, obs.used_biases_BDS{3,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_BDS.pbias, zeros(length(t_bds),DEF.SATS_BDS), bds_phase, obs.BDS.L3, 'BeiDou L3');
            obs.L3_corr(:,bds_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_bds, bias_use);
        end
    end

    % -- QZSS --
    if settings.INPUT.use_QZSS && ~isempty(input.ORBCLK.corr2brdc_QZSS.pbias)
        t_qzss = input.ORBCLK.corr2brdc_QZSS.t_phase;
        qzss_phase = fieldnames(input.ORBCLK.corr2brdc_QZSS.pbias);     % fieldnames of QZSS phase biases
        if isfield(obs.QZSS, 'L1') && ~isempty(obs.QZSS.L1)
            [bias_use, obs.used_biases_QZSS{1,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_QZSS.pbias, zeros(length(t_qzss),DEF.SATS_QZSS), qzss_phase, obs.QZSS.L1, 'QZSS L1');
            obs.L1_corr(:,qzss_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_qzss, bias_use);
        end
        if isfield(obs.QZSS, 'L2') && ~isempty(obs.QZSS.L2)
            [bias_use, obs.used_biases_QZSS{2,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_QZSS.pbias, zeros(length(t_qzss),DEF.SATS_QZSS), qzss_phase, obs.QZSS.L2, 'QZSS L2');
            obs.L2_corr(:,qzss_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_qzss, bias_use);
        end
        if isfield(obs.QZSS, 'L3') && ~isempty(obs.QZSS.L3)
            [bias_use, obs.used_biases_QZSS{3,1}] = find_corr2brdc_bias(...
                input.ORBCLK.corr2brdc_QZSS.pbias, zeros(length(t_qzss),DEF.SATS_QZSS), qzss_phase, obs.QZSS.L3, 'QZSS L3');
            obs.L3_corr(:,qzss_cols) = scatter_corr2brdc_bias(obs.L_corr_time, t_qzss, bias_use);
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
    field = all_biases(idx_field);              % get field name
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



function biases_merged = scatter_corr2brdc_bias(t_all, t_gnss, biases_native)
% Places code/phase biases values (indexed by a GNSS-specific time-vector 
% (t_gnss) into a matrix indexed by the common, merged time-vector t_all. 
% This is necessary because the SSR stream might send code or phase biases
% at different points in time. Rows of t_all for which this GNSS has no 
% message stay all-zero and are skipped by apply_corr2brdc_biases.m
% INPUT:
%   t_all           vector, merged (for all GNSS) correction time-vector [sow]
%   t_gnss          vector, time-vector of the current GNSS [sow]
%   biases_native   matrix, biases indexed by t_gnss
% OUTPUT:
%   biases_merged   matrix, bias values indexed by t_all
% *************************************************************************

% initialize
biases_merged = zeros(length(t_all), size(biases_native,2));

% check if any biases for this GNSS
if isempty(t_gnss)
    return
end

% map each the timestamps of the current GNSS onto the rows of the merged timestamps
[found, loc] = ismember(t_gnss, t_all);
biases_merged(loc(found), :) = biases_native(found, :);
