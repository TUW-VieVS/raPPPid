function settings = recover_settings(path)
% This AI-generated function rebuilds the variable settings from the data 
% in the text file settings_summary.txt (written by settings2txt.m). 
%
% All fields of getSettingsFromGUI.m are initialized (neutral), so that the 
% recovered struct can be used like the original one. Fields which are not 
% part of settings_summary.txt keep their neutral value. 
%
% INPUT:
%	path            string, path to results folder of processing or
%                   directly to the settings_summary.txt-file
% OUTPUT:
%	settings        struct, contains recovered fields
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% initialize with neutral values (same fields as getSettingsFromGUI)
settings = init_settings();

% open, read and close file
if ~isfile(path);   path = [path '/settings_summary.txt'];   end
fid = fopen(path);
if fid < 0
    return              % file not available, return empty struct
end
TXT = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
TXT = TXT{1};
fclose(fid);
TXT = regexprep(TXT, '[\r\s]+$', '');           % remove trailing whitespace

% frequently used pattern for numbers
NUM = '([-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?|[-+]?Inf|NaN)';

% split settings_summary.txt into its sections
INP                = getSection(TXT, 'Input Data:');
[METH,  head_METH] = getSection(TXT, 'Processing Method:');
ORB                = getSection(TXT, 'Orbit/Clock Data:');
BIA                = getSection(TXT, 'Biases:');
PHA                = getSection(TXT, 'Phase Biases:');
TRO                = getSection(TXT, 'Troposphere:');
ION                = getSection(TXT, 'Ionosphere:');
OTH                = getSection(TXT, 'Other Corrections:');
KIN                = getSection(TXT, 'Kinematic:');
ADJ                = getSection(TXT, 'Adjustment:');
FIX                = getSection(TXT, 'Ambiguity Fixing:');
PRO                = getSection(TXT, 'Processing Options:');
EXP                = getSection(TXT, 'Export options:');
RUN                = getSection(TXT, 'Processing:');
OTH_txt = strjoin(OTH, '\n');       % also as one string, as (due to missing
FIX_txt = strjoin(FIX, '\n');       % line breaks) not every entry is on its own line


%% File - Set input files

settings.INPUT.file_obs = getValue(INP, 'Obs-File:');

% processing in real-time
line = INP(startsWith(INP, 'Real-Time processing from'));
tok = {};
if ~isempty(line)
    tok = regexp(line{1}, 'Real-Time processing from (.*) to (.*)$', 'tokens', 'once');
end
if ~isempty(tok)
    settings.INPUT.bool_realtime = true;
    settings.INPUT.realtime_start_GUI = strtrim(tok{1});
    settings.INPUT.realtime_ende_GUI  = strtrim(tok{2});
end
% kinematic processing
if any(strcmp(INP, 'Kinematic processing'))
    settings.KINE.bool_kinematic = true;
end

% coordinate system of the export
coordsys = getValue(INP, 'Coordinate System:');
if ~isempty(regexp(coordsys, '^(EPSG:?\s*)?\d+$', 'once'))
    settings.EXP.coord_sys = 'EPSG Code:';
    settings.EXP.epsg_code = regexprep(coordsys, '^EPSG:?\s*', '');
else
    settings.EXP.coord_sys = 'no transformation';
end

% processed GNSS and their frequencies
GNSS = {'GPS',  'GLO',       'GAL',     'BDS',    'QZSS'};      % field names
NAME = {'GPS',  'GLONASS',   'Galileo', 'BeiDou', 'QZSS'};      % names in "Selected ... Signals"
PROC_NAME = {'GPS', 'GLONASS', 'Galileo', 'BeiDou', 'QZSS'};    % names in processing options
freq_found = false(1, numel(GNSS));
for i = 1:numel(GNSS)
    [sig, head] = getSection(TXT, ['Selected ' NAME{i} ' Signals:']);
    if isempty(head) && i == 2      % older versions of settings2txt.m
        [sig, head] = getSection(TXT, 'Selected GLONASS Signals:');
    end
    if ~isempty(head)              % GNSS was processed
        settings.INPUT.(['use_' GNSS{i}]) = true;
        freq = parseList(getValue(sig, 'Frequency:'));
        if numel(freq) == 3
            settings.INPUT.([lower(GNSS{i}) '_freq']) = freq(:);
            freq_found(i) = true;
        end
    end
end
% frequencies (as fallback) and rankings from processing options
for i = 1:numel(GNSS)
    if ~settings.INPUT.(['use_' GNSS{i}]);   continue;   end
    fld = lower(GNSS{i});
    freq = parseList(getValue(PRO, [PROC_NAME{i} '-Frequencies:']));
    if numel(freq) == 3 && ~freq_found(i)
        settings.INPUT.([fld '_freq']) = freq(:);
    end
    settings.INPUT.([fld '_ranking']) = getValue(PRO, [PROC_NAME{i} '-Ranking:']);
end
% settings2txt.m labels the ranking of QZSS as BeiDou, it follows the one of BDS
if settings.INPUT.use_QZSS && isempty(settings.INPUT.qzss_ranking)
    rank_lines = getValues(PRO, 'BeiDou-Ranking:');
    if settings.INPUT.use_BDS && numel(rank_lines) >= 2
        settings.INPUT.qzss_ranking = rank_lines{2};
    elseif ~settings.INPUT.use_BDS && ~isempty(rank_lines)
        settings.INPUT.qzss_ranking = rank_lines{1};
    end
end
% indices of the selected frequencies
[~, settings.INPUT.gps_freq_idx]  = ismember(settings.INPUT.gps_freq,  DEF.freq_GPS_names);
[~, settings.INPUT.glo_freq_idx]  = ismember(settings.INPUT.glo_freq,  DEF.freq_GLO_names);
[~, settings.INPUT.gal_freq_idx]  = ismember(settings.INPUT.gal_freq,  DEF.freq_GAL_names);
[~, settings.INPUT.bds_freq_idx]  = ismember(settings.INPUT.bds_freq,  DEF.freq_BDS_names);
[~, settings.INPUT.qzss_freq_idx] = ismember(settings.INPUT.qzss_freq, DEF.freq_QZSS_names);

% type of processing (single file or batch)
type = getValue(RUN, 'Type:');
if contains(type, 'Batch')
    settings.INPUT.bool_batch  = true;
    settings.INPUT.bool_parfor = contains(type, 'parfor');
end

% raPPPid version
idx = find(startsWith(RUN, 'raPPPid '), 1);
if ~isempty(idx)
    settings.version = strtrim(RUN{idx}(9:end));
end


%% Models - Orbit/Clock Data

% precise products or broadcast products + correction stream
idx_prec = find(strcmp(ORB, 'Precise products:'), 1);
if ~isempty(idx_prec)
    settings.ORBCLK.bool_precise = true;
    settings.ORBCLK.bool_sp3 = 1;
    settings.ORBCLK.bool_clk = 1;
    files = cell(1,3);              % sp3, clk, obx
    for i = 1:3
        if idx_prec + i > numel(ORB);   break;   end
        line = ORB{idx_prec + i};
        if strcmp(line, 'No ORBEX File');   break;   end
        tok = regexp(line, '^([^:]+):\s*(.*)$', 'tokens', 'once');
        if isempty(tok);   break;   end
        settings.ORBCLK.prec_prod = strtrim(tok{1});
        files{i} = strtrim(tok{2});
    end
    settings.ORBCLK.file_sp3 = files{1};
    settings.ORBCLK.file_clk = files{2};
    settings.ORBCLK.file_obx = files{3};
    settings.ORBCLK.bool_obx = ~isempty(files{3});
    if strcmp(settings.ORBCLK.prec_prod, 'manually') && isempty(settings.ORBCLK.file_clk)
        settings.ORBCLK.bool_clk = 0;       % processing only with sp3-file
    end
else
    settings.ORBCLK.bool_precise = false;
    settings.ORBCLK.bool_brdc = 1;
    % multi-GNSS navigation file
    [val, found] = getValue(ORB, 'Multi-GNSS Navigation file:');
    if found
        settings.ORBCLK.bool_nav_multi = true;
        tok = regexp(val, '^([^:]+):\s*(.*)$', 'tokens', 'once');
        if ~isempty(tok)
            settings.ORBCLK.multi_nav = strtrim(tok{1});
            settings.ORBCLK.file_nav_multi = strtrim(tok{2});
        end
    end
    % navigation files for each GNSS
    if any(startsWith(ORB, 'GPS Navigation file:')) || any(startsWith(ORB, 'GLONASS Navigation file:'))
        settings.ORBCLK.bool_nav_single = true;
        settings.ORBCLK.file_nav_GPS = getValue(ORB, 'GPS Navigation file:');
        settings.ORBCLK.file_nav_GLO = getValue(ORB, 'GLONASS Navigation file:');
        settings.ORBCLK.file_nav_GAL = getValue(ORB, 'Galileo Navigation file:');
        settings.ORBCLK.file_nav_BDS = getValue(ORB, 'BeiDou Navigation file:');
    end
    % correction stream
    if any(startsWith(ORB, 'Correction stream file:'))
        val = getValue(ORB, 'Correction stream file:');
        tok = regexp(val, '^([^:]+):\s*(.*)$', 'tokens', 'once');
        if ~isempty(tok)
            settings.ORBCLK.CorrectionStream = strtrim(tok{1});
            settings.ORBCLK.file_corr2brdc   = strtrim(tok{2});
        end
        ref = getValue(ORB, 'Correction stream reference point:');
        settings.ORBCLK.CorrectionStream_APC = strcmp(ref, 'APC');
        settings.ORBCLK.CorrectionStream_COM = strcmp(ref, 'COM');
        age = parseNumbers(regexprep(getValue(ORB, 'Corrections age limit [s]:'), '\(.*\)', ''));
        if numel(age) == 3;   settings.ORBCLK.CorrectionStream_age = age;   end
        if strcmp(settings.ORBCLK.CorrectionStream, 'manually')
            settings.ORBCLK.corr2brdc_clk = 1;
            settings.ORBCLK.corr2brdc_orb = 1;
        end
    else
        settings.ORBCLK.CorrectionStream = 'off';
    end
end


%% Models - Biases

% code biases: the first line describes the chosen model
if ~isempty(BIA)
    line = BIA{1};
    if startsWith(line, 'CODE DCBs (')
        settings.BIASES.code = line;
        settings.BIASES.code_file = {getValue(BIA, 'P1P2:'); getValue(BIA, 'P1C1:')};
    elseif startsWith(line, 'manually, Sinex-Bias-File:')
        settings.BIASES.code = 'manually';
        settings.BIASES.code_manually_Sinex_bool = 1;
        settings.BIASES.code_file = strtrim(line(numel('manually, Sinex-Bias-File:')+1:end));
    elseif strcmp(line, 'CODE DCBs manually')
        settings.BIASES.code = 'manually';
        settings.BIASES.code_manually_DCBs_bool = 1;
        settings.BIASES.code_file = {getValue(BIA, 'P1P2:'); getValue(BIA, 'P1C1:'); getValue(BIA, 'P2C2:')};
    elseif startsWith(line, 'Code biases from correction stream')
        settings.BIASES.code = 'Correction Stream';
    elseif strcmp(line, 'no')
        settings.BIASES.code = 'off';
    elseif startsWith(line, 'Broadcasted Time Group Delay')
        settings.BIASES.code = 'Broadcasted TGD';
    else
        tok = regexp(line, '^([^:]+):\s*(.*)$', 'tokens', 'once');
        if ~isempty(tok)
            settings.BIASES.code = strtrim(tok{1});
            settings.BIASES.code_file = strtrim(tok{2});
        end
    end
end
settings.BIASES.code_corr2brdc_bool = strcmp(settings.BIASES.code, 'Correction Stream');
% receiver biases
if any(strcmp(BIA, 'Receiver Bias Estimation is enabled'))
    settings.BIASES.estimate_rec_dcbs = true;
end

% phase biases
settings.BIASES.phase = 'off';
if ~isempty(PHA)
    line = PHA{1};
    if startsWith(line, 'TUW-WL-File:')
        settings.BIASES.phase = 'TUW (not implemented)';
        settings.BIASES.phase_file = {getValue(PHA, 'TUW-WL-File:'); getValue(PHA, 'TUW-NL-File:')};
    elseif startsWith(line, 'Phase biases from correction stream')
        settings.BIASES.phase = 'Correction Stream';
    elseif strcmp(line, 'no')
        settings.BIASES.phase = 'off';
    elseif contains(line, '(not implemented)') && ~contains(line, ':')
        settings.BIASES.phase = line;
    else
        tok = regexp(line, '^([^:]+):\s*(.*)$', 'tokens', 'once');
        if ~isempty(tok)
            settings.BIASES.phase = strtrim(tok{1});
            settings.BIASES.phase_file = strtrim(tok{2});
        end
    end
end
settings.BIASES.phase_corr2brdc_bool = strcmp(settings.BIASES.phase, 'Correction Stream');


%% Models - Troposphere

[settings.TROPO.zhd, vmf1] = parseTropo(getValue(TRO, 'zhd:'));
[settings.TROPO.zwd, vmf2] = parseTropo(getValue(TRO, 'zwd:'));
[settings.TROPO.mfh, vmf3] = parseTropo(getValue(TRO, 'mfh:'));
[settings.TROPO.mfw, vmf4] = parseTropo(getValue(TRO, 'mfw:'));
[settings.TROPO.Gh,  vmf5] = parseTropo(getValue(TRO, 'Gn_h & Ge_h:'));
[settings.TROPO.Gw,  vmf6] = parseTropo(getValue(TRO, 'Gn_w & Ge_w:'));
vmf = {vmf1, vmf2, vmf3, vmf4, vmf5, vmf6};         % VMF version (operational, forecast)
vmf(cellfun('isempty', vmf)) = [];
if ~isempty(vmf);   settings.TROPO.vmf_version = vmf{1};   end
% tropo file
val = getValue(TRO, 'manually:');
if any(startsWith(TRO, 'manually:'))
    settings.TROPO.tropo_file = 'manually';
    settings.TROPO.tropo_filepath = val;
end
% meteorological data
settings.TROPO.p = firstNumber(getValue(TRO, 'p:'), NaN);
settings.TROPO.q = firstNumber(getValue(TRO, 'q:'), NaN);
settings.TROPO.T = firstNumber(getValue(TRO, 'T:'), NaN);
% estimate ZWD?
line = TRO(startsWith(TRO, 'ZWD is'));
if ~isempty(line)
    line = line{1};
    if contains(line, 'is not estimated')
        settings.TROPO.estimate_ZWD = false;
    else
        settings.TROPO.estimate_ZWD = true;
        if contains(line, 'from minute')
            settings.TROPO.est_ZWD_from = firstNumber(line(strfind(line, 'from minute')+11:end), 0);
        else
            settings.TROPO.est_ZWD_from = 0;
        end
    end
end


%% Models - Ionosphere

settings.IONO.model = getValue(ION, 'Model:');
settings.IONO.source = getValue(ION, 'Ionosphere source:');
idx = find(startsWith(ION, 'Ionosphere source:'), 1);
if ~isempty(idx) && strcmp(settings.IONO.source, 'IONEX File') && idx < numel(ION)
    line = ION{idx+1};      % source of IONEX file
    tok = regexp(line, '^([^:]+:)\s*(.*)$', 'tokens', 'once');
    if ~isempty(tok)
        settings.IONO.model_ionex = tok{1};
        if strcmp(tok{1}, 'Source:')        % 'Source: <origin>, <file>'
            k = strfind(tok{2}, ', ');
            if ~isempty(k)
                settings.IONO.file_source = strtrim(tok{2}(1:k(1)-1));
                settings.IONO.file_ionex  = strtrim(tok{2}(k(1)+2:end));
            else
                settings.IONO.file_source = strtrim(tok{2});
            end
        else
            settings.IONO.file_ionex = strtrim(tok{2});
        end
    end
    settings.IONO.type_ionex = getValue(ION, 'IONEX product type:');
    settings.IONO.interpol   = getValue(ION, 'TEC-Interpolation:');
    % visibility of the IONEX panel in the GUI
    settings.IONO.model_ionex_vis = matlab.lang.OnOffSwitchState.on;
    settings.IONO.interpol_vis = matlab.lang.OnOffSwitchState.on;
    settings.IONO.interpol_text_vis = matlab.lang.OnOffSwitchState.on;
end
if strcmp(settings.IONO.model_ionex, 'Auto-Detection:')
    settings.IONO.folder_auto = 1;
    settings.IONO.folder_manual = 0;
end


%% Models - Other corrections

% ANTEX file
if any(startsWith(OTH, 'Manual Antex file:'))
    settings.OTHER.antex = 'Manual choice:';
    settings.OTHER.file_antex = getValue(OTH, 'Manual Antex file:');
elseif any(startsWith(OTH, 'igsXX_wwww.atx autodetection:'))
    settings.OTHER.antex = 'igsXX_wwww.atx autodetection';
    settings.OTHER.file_antex = getValue(OTH, 'igsXX_wwww.atx autodetection:');
elseif any(startsWith(OTH, 'Download current igsXX.atx:'))
    settings.OTHER.antex = 'Download current igsXX.atx';
    settings.OTHER.file_antex = getValue(OTH, 'Download current igsXX.atx:');
elseif any(startsWith(OTH, 'Antex file:'))      % older settings_summary.txt
    settings.OTHER.antex = 'igsXX_wwww.atx autodetection';    % (most common option)
    settings.OTHER.file_antex = getValue(OTH, 'Antex file:');
end
settings.OTHER.antex_rec_manual = any(startsWith(OTH, 'Own corrections from MyAntex.atx'));

% activated corrections
settings.OTHER.bool_rec_arp     = hasBullet(OTH, 'Antenna Reference Point');
settings.OTHER.bool_rec_pco     = hasBullet(OTH, 'Receiver Phase Center Offset');
settings.OTHER.bool_rec_pcv     = hasBullet(OTH, 'Receiver Phase Center Variations');
settings.OTHER.bool_sat_pco     = hasBullet(OTH, 'Satellite Phase Center Offset');
settings.OTHER.bool_sat_pcv     = hasBullet(OTH, 'Satellite Phase Center Variations');
settings.OTHER.bool_wind_up     = hasBullet(OTH, 'Phase Wind-Up Correction');
settings.OTHER.bool_eclipse     = hasBullet(OTH, 'Eclipse condition is on');
settings.OTHER.shapiro          = hasBullet(OTH, 'Shapiro Effect Correction');
settings.OTHER.bool_GDV         = hasBullet(OTH, 'Group Delay Variation Correction');
settings.OTHER.bool_solid_tides = hasBullet(OTH, 'Solid Tides Correction');
settings.OTHER.ocean_loading    = hasBullet(OTH, 'Ocean Loading');
settings.OTHER.polar_tides      = hasBullet(OTH, 'Polar Tides');

% cycle-slip detection (regexp on whole text, line breaks are unreliable)
tok = regexp(OTH_txt, ['L1-C1: threshold = ' NUM ' \[m\], window-size = ' NUM], 'tokens', 'once');
if ~isempty(tok)
    settings.OTHER.CS.l1c1 = true;
    settings.OTHER.CS.l1c1_threshold = str2double(tok{1});
    settings.OTHER.CS.l1c1_window    = str2double(tok{2});
end
tok = regexp(OTH_txt, ['dL1-dL2: threshold = ' NUM], 'tokens', 'once');
if ~isempty(tok)
    settings.OTHER.CS.DF = true;
    settings.OTHER.CS.DF_threshold = str2double(tok{1});
end
tok = regexp(OTH_txt, ['Doppler-Shift: threshold = ' NUM], 'tokens', 'once');
if ~isempty(tok)
    settings.OTHER.CS.Doppler = true;
    settings.OTHER.CS.D_threshold = str2double(tok{1});
end
tok = regexp(OTH_txt, ['Time difference: threshold = ' NUM ' \[m\], degree = ' NUM], 'tokens', 'once');
if ~isempty(tok)
    settings.OTHER.CS.TimeDifference = true;
    settings.OTHER.CS.TD_threshold = str2double(tok{1});
    settings.OTHER.CS.TD_degree    = str2double(tok{2});
end
tok = regexp(OTH_txt, ['HMW LC: threshold = ' NUM ' \[cy\], factor = ' NUM], 'tokens', 'once');
if ~isempty(tok)
    settings.OTHER.CS.HMW = true;
    settings.OTHER.CS.HMW_threshold = str2double(tok{1});
    settings.OTHER.CS.HMW_factor    = str2double(tok{2});
end
settings.PROC.LLI = contains(OTH_txt, 'LLI from RINEX is used');

% multipath detection
tok = regexp(OTH_txt, ['Code time-difference: threshold = ' NUM ' \[m\], degree = ' NUM ', cooldown = ' NUM], 'tokens', 'once');
if ~isempty(tok)
    settings.OTHER.mp_detection = true;
    settings.OTHER.mp_thresh   = str2double(tok{1});
    settings.OTHER.mp_degree   = str2double(tok{2});
    settings.OTHER.mp_cooldown = str2double(tok{3});
end
tok = regexp(OTH_txt, ['Code range rate with Doppler: threshold = ' NUM], 'tokens', 'once');
if ~isempty(tok)
    settings.OTHER.mp_doppler = true;
    settings.OTHER.mp_doppler_thresh = str2double(tok{1});
end


%% Model - Kinematic

if any(startsWith(KIN, 'IMU data is used:'))
    settings.KINE.bool_IMU = true;
    settings.KINE.file_IMU = getValue(KIN, 'IMU data is used:');
end
if any(startsWith(KIN, 'Lever arm'))
    settings.KINE.bool_offset = true;
    lever = parseNumbers(getValue(KIN, 'Lever arm (reference point -> antenna) [m]:'));
    if numel(lever) == 3;   settings.KINE.leverarm = lever(:);   end
end
settings.KINE.orient_mode = getValue(KIN, 'Orientation mode:');
settings.KINE.ant_orient  = getValue(KIN, 'Antenna orientation:');
% satellite PPP
if any(startsWith(KIN, 'Satellite, dynamic model is applied'))
    settings.KINE.satellite.bool  = true;
    settings.KINE.satellite.ID    = getValue(KIN, 'Identifier:');
    settings.KINE.satellite.mass  = firstNumber(getValue(KIN, 'Mass [kg]:'), NaN);
    settings.KINE.satellite.area  = firstNumber(getValue(KIN, 'Area [m^2]:'), NaN);
    settings.KINE.satellite.drag  = firstNumber(getValue(KIN, 'Drag coefficient []:'), NaN);
    settings.KINE.satellite.solar = firstNumber(getValue(KIN, 'Solar coefficient []:'), NaN);
end


%% Estimation - Ambiguity fixing

settings.AMBFIX.bool_AMBFIX = ~isempty(FIX) && ~strcmp(FIX{1}, 'Off');
if settings.AMBFIX.bool_AMBFIX
    tok = regexp(FIX_txt, ['Fixing-Start \[s\]: WL = ' NUM ', NL = ' NUM], 'tokens', 'once');
    if ~isempty(tok)
        settings.AMBFIX.start_WL_sec = str2double(tok{1});
        settings.AMBFIX.start_NL_sec = str2double(tok{2});
    else
        tok = regexp(FIX_txt, ['Fixing-Start \[s\] = ' NUM], 'tokens', 'once');    % decoupled clock model
        if ~isempty(tok);   settings.AMBFIX.start_WL_sec = str2double(tok{1});   end
    end
    tok = regexp(FIX_txt, ['HMW fixing: threshold = ' NUM ' \[cy\], releasing threshold = ' NUM ' \[cy\], window = ' NUM], 'tokens', 'once');
    if ~isempty(tok)
        settings.AMBFIX.HMW_thresh  = str2double(tok{1});
        settings.AMBFIX.HMW_release = str2double(tok{2});
        settings.AMBFIX.HMW_window  = str2double(tok{3});
    end
    tok = regexp(FIX_txt, ['Fixing cutoff[^:\n]*:\s*' NUM], 'tokens', 'once');
    if ~isempty(tok);   settings.AMBFIX.cutoff = str2double(tok{1});   end
    settings.AMBFIX.refSatChoice = getValue(FIX, 'Choice of Reference Satellite:');
    if strcmp(settings.AMBFIX.refSatChoice, 'manual choice (list):')
        refSat = {'GPS', 'GLONASS', 'Galileo', 'BeiDou', 'QZSS'};
        refFld = {'refSatGPS', 'refSatGLO', 'refSatGAL', 'refSatBDS', 'refSatQZS'};
        for i = 1:5
            tok = regexp(FIX_txt, [refSat{i} ':[ \t]*([^\n]*)'], 'tokens', 'once');
            if ~isempty(tok) && ~isempty(parseNumbers(tok{1}))
                settings.AMBFIX.(refFld{i}) = parseNumbers(tok{1});
            end
        end
    end
    if any(startsWith(FIX, 'Excluded satellites from fixing:'))
        settings.AMBFIX.exclude_sats_fixing = parseNumbers(getValue(FIX, 'Excluded satellites from fixing:'));
    end
    settings.AMBFIX.wrongFixes = getValue(FIX, 'Detection of Wrong Fixes:');
end


%% Estimation - Adjustment and weighting

% observation weighting scheme
scheme = getValue(ADJ, 'Weighting Scheme for Observations:');
if strcmp(scheme, 'Multipath-LC')
    settings.ADJ.weight_mplc = true;
elseif startsWith(scheme, 'Elevation')
    settings.ADJ.weight_elev = true;
    settings.ADJ.elev_weight_fun = parseWeightFun(scheme, 'Elevation', @ElevationWeightingFunction);
elseif startsWith(scheme, 'C/N0')
    settings.ADJ.weight_sign_str = true;
    settings.ADJ.snr_weight_fun = parseWeightFun(scheme, 'C/N0', @SNRWeightingFunction);
elseif strcmp(scheme, 'Boresight angle')
    settings.ADJ.weight_bore = true;
elseif strcmp(scheme, 'None')
    settings.ADJ.weight_none = true;
end
% GNSS weights (GRECJ)
fac = regexp(getValue(ADJ, 'GNSS weights (GRECJ):'), NUM, 'tokens');
if numel(fac) == 5
    fac = cellfun(@(c) str2double(c{1}), fac);
    settings.ADJ.fac_GPS = fac(1);   settings.ADJ.fac_GLO = fac(2);
    settings.ADJ.fac_GAL = fac(3);   settings.ADJ.fac_BDS = fac(4);
    settings.ADJ.fac_QZSS = fac(5);
end
% standard deviations of observations (stored as variance)
settings.ADJ.var_code    = firstNumber(getValue(ADJ, 'code  [m]', '='), NaN)^2;
settings.ADJ.var_phase   = firstNumber(getValue(ADJ, 'phase [m]', '='), NaN)^2;
settings.ADJ.var_doppler = firstNumber(getValue(ADJ, 'Doppler [Hz]', '='), NaN)^2;
% frequency-specific standard-deviations
idx_code  = find(startsWith(ADJ, 'Code, additional frequency-specific'), 1);
idx_phase = find(startsWith(ADJ, 'Phase, additional frequency-specific'), 1);
settings.ADJ.bool_std_frqs = ~isempty(idx_code) || ~isempty(idx_phase);
if settings.ADJ.bool_std_frqs
    if ~isempty(idx_code)
        last = numel(ADJ);
        if ~isempty(idx_phase) && idx_phase > idx_code;   last = idx_phase - 1;   end
        settings.ADJ.var_code_frq_GUI = parseFrqStd(ADJ(idx_code+1:last));
    end
    if ~isempty(idx_phase)
        settings.ADJ.var_phase_frq_GUI = parseFrqStd(ADJ(idx_phase+1:end));
    end
end
% table used during processing (empty entries are replaced by the general std)
T = settings.ADJ.var_code_frq_GUI;
T(cellfun('isempty', T)) = {sqrt(settings.ADJ.var_code)};
settings.ADJ.var_code_frq = cell2mat(T).^2;
T = settings.ADJ.var_phase_frq_GUI;
T(cellfun('isempty', T)) = {sqrt(settings.ADJ.var_phase)};
settings.ADJ.var_phase_frq = cell2mat(T).^2;
% ionospheric pseudo-observations
tok = regexp(ADJ, ['^ionosphere\s*=\s*' NUM], 'tokens', 'once');
tok = tok(~cellfun('isempty', tok));
if ~isempty(tok);   settings.ADJ.var_iono = str2double(tok{1}{1})^2;   end
settings.IONO.constraint_until = firstNumber(getValue(ADJ, 'Constraint until minute:'), NaN);
settings.IONO.var_iono_decr = firstNumber(getValue(ADJ, 'Decrease stdev [m] to:'), NaN)^2;

% filter type and direction
line = ADJ(contains(ADJ, 'Filter') & ~contains(ADJ, ':'));
if ~isempty(line);   settings.ADJ.filter.type = line{1};   end
settings.ADJ.filter.direction = getValue(ADJ, 'Filter direction:');
% filter settings: initial std | system noise std | dynamic model
param = {'Coordinates', 'coord'; 'Velocity', 'velocity'; 'Zenith Wet Delay', 'zwd'; ...
    'Receiver Clock GPS', 'rclk_gps'; 'Receiver Clock GLO', 'rclk_glo'; ...
    'Receiver Clock GAL', 'rclk_gal'; 'Receiver Clock BDS', 'rclk_bds'; ...
    'Receiver Clock QZSS', 'rclk_qzss'; 'Receiver DCBs', 'DCB'; ...
    'Receiver Biases', 'DCB'; 'Rec Clock Drift', 'rclk_drift'; ...
    'Float Ambiguities', 'amb'; 'Ionospheric Delay', 'iono'};
for i = 1:size(param, 1)
    tok = regexp(ADJ, ['^' param{i,1} ':\s*' NUM '\s*\|\s*' NUM '\s*\|\s*' NUM '\s*$'], 'tokens', 'once');
    tok = tok(~cellfun('isempty', tok));
    if isempty(tok);   continue;   end
    tok = tok{1};
    p = param{i,2};
    settings.ADJ.filter.(['var_' p])      = str2double(tok{1})^2;
    settings.ADJ.filter.(['Q_' p])        = str2double(tok{2})^2;
    settings.ADJ.filter.(['dynmodel_' p]) = str2double(tok{3});
    if strcmp(p, 'DCB')
        settings.BIASES.estimate_rec_dcbs = true;
    end
end


%% Run - Processing options

% processing name
name = getValue(PRO, 'Processing name:');
if isempty(name)        % fallback: search in the whole file
    name = getValue(strtrim(TXT), 'Processing name:');
end
settings.PROC.name = name;
settings.PROC.name_GUI = name;
settings.PROC.output_dir = getValue(PRO, 'Output:');

% processing method
if ~isempty(head_METH)
    settings.PROC.method = strtrim(head_METH(numel('Processing Method:')+1:end));
    if strcmp(settings.PROC.method, 'Phase + Code')
        settings.PROC.method = 'Code + Phase';      % is written like this by settings2txt
    elseif strcmp(settings.PROC.method, 'Error')
        settings.PROC.method = '';
    end
end
settings.PROC.smooth_fac = firstNumber(getValue(METH, 'Smoothing factor:'), NaN);
settings.PROC.AdjustPhase2Code = any(strcmp(PRO, 'Adjust phase to code is ON'));

% time span
idx = find(startsWith(PRO, {'Epochs:', 'Time:', 'Seconds of Day', 'Hours of Day'}), 1);
if ~isempty(idx)
    line = PRO{idx};
    tok = regexp(line, '^(Epochs|Time|Seconds of Day|Hours of Day):?\s*(.*?)\s+-\s+(.*)$', 'tokens', 'once');
    if ~isempty(tok)
        settings.PROC.timeSpan_format_epochs = strcmp(tok{1}, 'Epochs');
        settings.PROC.timeSpan_format_time   = strcmp(tok{1}, 'Time');
        settings.PROC.timeSpan_format_SOD    = strcmp(tok{1}, 'Seconds of Day');
        settings.PROC.timeSpan_format_HOD    = strcmp(tok{1}, 'Hours of Day');
        settings.PROC.timeFrameFrom = strtrim(tok{2});
        settings.PROC.timeFrameTo   = strtrim(tok{3});
        settings.PROC.timeFrame(1) = str2double(settings.PROC.timeFrameFrom);
        if str2double(settings.PROC.timeFrameTo) == 999999      % processing till end of RINEX file
            settings.PROC.timeFrameTo = 'end';
        end
        if strcmp(settings.PROC.timeFrameTo, 'end')
            settings.PROC.timeFrame(2) = 999999;
        else
            settings.PROC.timeFrame(2) = str2double(settings.PROC.timeFrameTo);
        end
    end
end

% reset of solution
tok = regexp(strjoin(PRO, '\n'), ['Reset solution after ' NUM ' (minutes|epochs)'], 'tokens', 'once');
if ~isempty(tok)
    settings.PROC.reset_float = true;
    settings.PROC.reset_after = str2double(tok{1});
    settings.PROC.reset_bool_min   = strcmp(tok{2}, 'minutes');
    settings.PROC.reset_bool_epoch = strcmp(tok{2}, 'epochs');
end

% excluded satellites
idx_sats  = find(strcmp(PRO, 'Excluded Satellites:'), 1);
idx_eps   = find(strcmp(PRO, 'Excluded Epochs:'), 1);
idx_crit  = find(strcmp(PRO, 'Satellite Exclusion Criteria:'), 1);
if isempty(idx_crit);   idx_crit = numel(PRO) + 1;   end
if ~isempty(idx_sats)
    if isempty(idx_eps);   idx_end = idx_crit;   else;   idx_end = idx_eps;   end
    settings.PROC.exclude = parseExcludedSats(PRO(idx_sats+1:idx_end-1));
end
settings = deriveExcludedSats(settings);
% excluded epochs
if ~isempty(idx_eps)
    settings.PROC.exclude_epochs = parseExcludedEpochs(PRO(idx_eps+1:idx_crit-1));
end
settings = deriveExcludedEpochs(settings);

% satellite exclusion criteria
settings.PROC.elev_mask = firstNumber(getValue(PRO, 'Elevation Cutoff:'), NaN);
tok = regexp(getValue(PRO, 'C/N0 Cutoff:'), '^(.*?)\s*\[', 'tokens', 'once');
if ~isempty(tok)
    settings.PROC.SNR_mask = parseNumbers(tok{1});
else
    settings.PROC.SNR_mask = parseNumbers(getValue(PRO, 'C/N0 Cutoff:'));
end
settings.PROC.ss_thresh = firstNumber(getValue(PRO, 'Signal Strength Threshold:'), NaN);

% check observed minus computed
PRO_txt = strjoin(PRO, '\n');
settings.PROC.check_omc = contains(PRO_txt, 'Check of observed minus (omc) computed is ON');
tok = regexp(PRO_txt, ['Threshold Code\s+\[m\]:\s*' NUM], 'tokens', 'once');
if ~isempty(tok);   settings.PROC.omc_code_thresh = str2double(tok{1});   end
tok = regexp(PRO_txt, ['Threshold Phase\s+\[m\]:\s*' NUM], 'tokens', 'once');
if ~isempty(tok);   settings.PROC.omc_phase_thresh = str2double(tok{1});   end
tok = regexp(PRO_txt, ['Threshold Doppler\s+\[m/s\]:\s*' NUM], 'tokens', 'once');
if ~isempty(tok);   settings.PROC.omc_doppler_thresh = str2double(tok{1});   end

% post-fit residual check
tok = regexp(PRO_txt, ['Post-fit residual check is ON, factor\s*' NUM], 'tokens', 'once');
settings.PROC.check_postfit = ~isempty(tok);
if ~isempty(tok);   settings.PROC.postfit_factor = str2double(tok{1});   end

% receiver clock jumps
settings.PROC.bool_rec_clk_jump = contains(PRO_txt, 'Receiver clock jumps are detected');


%% Run - Export options

EXP_txt = strjoin(EXP, '\n');
settings.EXP.settings         = contains(EXP_txt, 'settings.mat is exported');
settings.EXP.data4plot        = contains(EXP_txt, 'data4plot.mat is exported');
settings.EXP.model_save       = contains(EXP_txt, 'model_save is saved to data4plot.mat');
settings.EXP.settings_summary = contains(EXP_txt, 'settings_summary.txt is written');
settings.EXP.results_txt      = contains(EXP_txt, 'results_float.txt is written');
settings.EXP.results_csv      = contains(EXP_txt, 'results_float.csv is written');
settings.EXP.bool_csv_utc     = contains(EXP_txt, 'UTC timestamps are included in CSV');
settings.EXP.tropo_est        = contains(EXP_txt, 'TRO is exported');
settings.EXP.nmea             = contains(EXP_txt, 'NMEA file is exported');
settings.EXP.kml              = contains(EXP_txt, 'KML file is exported');
settings.EXP.sp3              = contains(EXP_txt, 'sp3 file is exported');
settings.EXP.obs_bias         = contains(EXP_txt, 'L3_bias is saved to obs');
settings.EXP.obs_epochheader  = contains(EXP_txt, 'epochheader is saved to obs');
settings.EXP.storeData_iono_mf    = contains(EXP_txt, 'iono_mf is saved to storeData');
settings.EXP.storeData_vtec       = contains(EXP_txt, 'vtec is saved to storeData');
settings.EXP.storeData_mp_1_2     = contains(EXP_txt, 'mp1, mp2 is saved to storeData');
settings.EXP.storeData_sat_status = contains(EXP_txt, 'sat_status is saved to storeData');
settings.EXP.storeData = settings.EXP.storeData_iono_mf || settings.EXP.storeData_vtec || ...
    settings.EXP.storeData_mp_1_2 || settings.EXP.storeData_sat_status;
settings.EXP.satellites_D = contains(EXP_txt, 'is saved to satellites');
if settings.EXP.satellites_D;   settings.EXP.satellites = true;   end


%% Fields which are added to settings during processing

settings.INPUT.use_GNSS = settings.INPUT.use_GPS + settings.INPUT.use_GLO + settings.INPUT.use_GAL + ...
    settings.INPUT.use_BDS + settings.INPUT.use_QZSS;
[settings.INPUT.num_freqs, settings.INPUT.proc_freqs, settings.INPUT.n_gnss_freqs] = CountProcessedFrequencies(settings);
% observation file is not a RINEX file but a raw Android GNSS logger file
settings.INPUT.rawDataAndroid = endsWith(lower(settings.INPUT.file_obs), {'.txt', '.csv'});
settings.AMBFIX.APC_MODEL = false;
% epochs (only possible for time span in epochs), the indices q_range are
% created like in PPP_main.m
if settings.PROC.timeSpan_format_epochs
    settings.PROC.epochs = [floor(settings.PROC.timeFrame(1)), ceil(settings.PROC.timeFrame(2))];
    q_range = 1:settings.PROC.epochs(2)-settings.PROC.epochs(1)+1;
    switch settings.ADJ.filter.direction
        case 'Fwd-Bwd';     q_range = [q_range(1:end-1) fliplr(q_range)];
        case 'Bwd-Fwd';     q_range = [fliplr(q_range) q_range(2:end)];
        case 'Backwards';   q_range = fliplr(q_range);
    end
    settings.PROC.q_range = q_range;
end

end



%% Auxiliary functions

function settings = init_settings()
% initialize the struct settings with the fields of getSettingsFromGUI.m
% and neutral values (false, empty, NaN)
settings.version = '';

% input
settings.INPUT.file_obs = '';
settings.INPUT.bool_batch = false;
settings.INPUT.bool_parfor = false;
settings.INPUT.bool_realtime = false;
settings.INPUT.realtime_start_GUI = '';
settings.INPUT.realtime_ende_GUI = '';
gnss = {'gps', 'glo', 'gal', 'bds', 'qzss'};
for i = 1:numel(gnss)
    settings.INPUT.(['able_' upper(gnss{i})]) = 'on';
    settings.INPUT.(['use_' upper(gnss{i})]) = false;
    settings.INPUT.([gnss{i} '_freq']) = {'OFF'; 'OFF'; 'OFF'};
    settings.INPUT.([gnss{i} '_freq_idx']) = zeros(3,1);
    settings.INPUT.([gnss{i} '_ranking']) = '';
end
settings.INPUT.glo_freq = {'G1'; 'OFF'; 'OFF'};         % GUI default of GLONASS
settings.INPUT.rawDataAndroid = false;
settings.INPUT.subfolder = '';

% orbits and clocks
settings.ORBCLK.bool_sp3 = 0;
settings.ORBCLK.bool_clk = 0;
settings.ORBCLK.bool_brdc = 0;
settings.ORBCLK.corr2brdc_clk = 0;
settings.ORBCLK.corr2brdc_orb = 0;
settings.ORBCLK.prec_prod = '';
settings.ORBCLK.MGEX = 0;
settings.ORBCLK.prec_prod_type = 'Final';
settings.ORBCLK.multi_nav = '';
settings.ORBCLK.CorrectionStream = 'off';
settings.ORBCLK.CorrectionStream_age = [];
settings.ORBCLK.CorrectionStream_APC = 0;
settings.ORBCLK.CorrectionStream_COM = 0;
settings.ORBCLK.file_sp3 = '';
settings.ORBCLK.file_clk = '';
settings.ORBCLK.file_obx = '';
settings.ORBCLK.file_nav_GPS = '';
settings.ORBCLK.file_nav_GLO = '';
settings.ORBCLK.file_nav_GAL = '';
settings.ORBCLK.file_nav_BDS = '';
settings.ORBCLK.file_nav_multi = '';
settings.ORBCLK.bool_nav_multi = false;
settings.ORBCLK.bool_nav_single = false;
settings.ORBCLK.bool_precise = false;
settings.ORBCLK.file_corr2brdc = '';
settings.ORBCLK.bool_obx = false;

% troposphere
settings.TROPO.zhd = '';
settings.TROPO.zwd = '';
settings.TROPO.mfh = '';
settings.TROPO.mfw = '';
settings.TROPO.Gh = '';
settings.TROPO.Gw = '';
settings.TROPO.vmf_version = '';
settings.TROPO.tropo_file = '';
settings.TROPO.tropo_filepath = '';
settings.TROPO.p = NaN;
settings.TROPO.T = NaN;
settings.TROPO.q = NaN;
settings.TROPO.estimate_ZWD = false;
settings.TROPO.est_ZWD_from = 0;

% ionosphere
settings.IONO.model = '';
settings.IONO.source = '';
settings.IONO.model_ionex = '';
settings.IONO.model_ionex_vis = matlab.lang.OnOffSwitchState.off;
settings.IONO.file_ionex = '';
settings.IONO.type_ionex = '';
settings.IONO.file_source = '';
settings.IONO.interpol = '';
settings.IONO.interpol_vis = matlab.lang.OnOffSwitchState.off;
settings.IONO.interpol_text_vis = matlab.lang.OnOffSwitchState.off;
settings.IONO.ionex_autodetect = '';
settings.IONO.ionex_autodetect_vis = matlab.lang.OnOffSwitchState.off;
settings.IONO.constraint_until = NaN;
settings.IONO.var_iono_decr = NaN;

% biases
settings.BIASES.code = '';
settings.BIASES.code_corr2brdc_bool = false;
settings.BIASES.code_manually_DCBs_bool = 0;
settings.BIASES.code_manually_Sinex_bool = 0;
settings.BIASES.phase = 'off';
settings.BIASES.phase_corr2brdc_bool = false;
settings.BIASES.estimate_rec_dcbs = false;

% other corrections
other = {'bool_rec_arp', 'bool_rec_pco', 'bool_sat_pco', 'bool_rec_pcv', 'bool_sat_pcv', ...
    'bool_solid_tides', 'bool_wind_up', 'bool_GDV', 'shapiro', 'ocean_loading', ...
    'polar_tides', 'bool_eclipse', 'antex_rec_manual', 'mp_detection', 'mp_doppler'};
for i = 1:numel(other)
    settings.OTHER.(other{i}) = false;
end
settings.OTHER.antex = '';
settings.OTHER.file_antex = '';
settings.OTHER.CS.l1c1 = false;
settings.OTHER.CS.l1c1_window = NaN;
settings.OTHER.CS.l1c1_threshold = NaN;
settings.OTHER.CS.DF = false;
settings.OTHER.CS.DF_threshold = NaN;
settings.OTHER.CS.Doppler = false;
settings.OTHER.CS.D_threshold = NaN;
settings.OTHER.CS.TimeDifference = false;
settings.OTHER.CS.TD_threshold = NaN;
settings.OTHER.CS.TD_degree = NaN;
settings.OTHER.CS.HMW = false;
settings.OTHER.CS.HMW_threshold = NaN;
settings.OTHER.CS.HMW_factor = NaN;
settings.OTHER.mp_degree = NaN;
settings.OTHER.mp_thresh = NaN;
settings.OTHER.mp_cooldown = NaN;
settings.OTHER.mp_doppler_thresh = NaN;

% kinematic
settings.KINE.bool_kinematic = false;
settings.KINE.bool_offset = false;
settings.KINE.leverarm = zeros(3,1);
settings.KINE.orient_mode = '';
settings.KINE.ant_orient = '';
settings.KINE.satellite.bool = false;
settings.KINE.satellite.ID = '';
settings.KINE.satellite.mass = NaN;
settings.KINE.satellite.area = NaN;
settings.KINE.satellite.drag = NaN;
settings.KINE.satellite.solar = NaN;
settings.KINE.bool_IMU = false;
settings.KINE.file_IMU = '';

% ambiguity fixing
settings.AMBFIX.bool_AMBFIX = false;
settings.AMBFIX.start_WL_sec = NaN;
settings.AMBFIX.start_NL_sec = NaN;
settings.AMBFIX.cutoff = NaN;
settings.AMBFIX.wrongFixes = '';
settings.AMBFIX.refSatChoice = '';
settings.AMBFIX.refSatGPS = '';
settings.AMBFIX.refSatGLO = '';
settings.AMBFIX.refSatGAL = '';
settings.AMBFIX.refSatBDS = '';
settings.AMBFIX.refSatQZS = '';
settings.AMBFIX.exclude_sats_fixing = [];
settings.AMBFIX.HMW_thresh  = 0.33;     % same defaults as in getSettingsFromGUI
settings.AMBFIX.HMW_release = 0.50;
settings.AMBFIX.HMW_window  = 300;

% adjustment: filter
settings.ADJ.filter.type = '';
settings.ADJ.filter.direction = '';
param = {'coord', 'velocity', 'zwd', 'rclk_gps', 'rclk_glo', 'rclk_gal', 'rclk_bds', ...
    'rclk_qzss', 'DCB', 'rclk_drift', 'amb', 'iono'};
for i = 1:numel(param)
    settings.ADJ.filter.(['var_' param{i}]) = NaN;
    settings.ADJ.filter.(['Q_' param{i}]) = NaN;
    settings.ADJ.filter.(['dynmodel_' param{i}]) = NaN;
end

% adjustment: weighting
settings.ADJ.var_code = NaN;
settings.ADJ.var_phase = NaN;
settings.ADJ.var_iono = NaN;
settings.ADJ.var_doppler = NaN;
settings.ADJ.weight_elev = false;
settings.ADJ.elev_weight_fun = [];
settings.ADJ.weight_mplc = false;
settings.ADJ.weight_sign_str = false;
settings.ADJ.snr_weight_fun = [];
settings.ADJ.weight_bore = false;
settings.ADJ.weight_none = false;
settings.ADJ.fac_GPS = NaN;
settings.ADJ.fac_GLO = NaN;
settings.ADJ.fac_GAL = NaN;
settings.ADJ.fac_BDS = NaN;
settings.ADJ.fac_QZSS = NaN;
settings.ADJ.bool_std_frqs = false;
settings.ADJ.var_code_frq_GUI = cell(5,3);
settings.ADJ.var_phase_frq_GUI = cell(5,3);
settings.ADJ.var_code_frq = NaN(5,3);
settings.ADJ.var_phase_frq = NaN(5,3);

% processing options
settings.PROC.name = '';
settings.PROC.name_GUI = '';
settings.PROC.output_dir = '';
settings.PROC.method = '';
settings.PROC.AdjustPhase2Code = false;
settings.PROC.smooth_fac = NaN;
settings.PROC.timeFrameFrom = '';
settings.PROC.timeFrameTo = '';
settings.PROC.timeFrame = [NaN, NaN];
settings.PROC.timeSpan_format_epochs = false;
settings.PROC.timeSpan_format_time = false;
settings.PROC.timeSpan_format_SOD = false;
settings.PROC.timeSpan_format_HOD = false;
settings.PROC.elev_mask = NaN;
settings.PROC.SNR_mask = NaN;
settings.PROC.ss_thresh = NaN;
settings.PROC.LLI = false;
settings.PROC.check_omc = false;
settings.PROC.omc_code_thresh = NaN;
settings.PROC.omc_phase_thresh = NaN;
settings.PROC.omc_doppler_thresh = NaN;
settings.PROC.check_postfit = false;
settings.PROC.postfit_factor = NaN;
settings.PROC.bool_rec_clk_jump = false;
settings.PROC.reset_float = false;
settings.PROC.reset_fixed = false;
settings.PROC.reset_after = NaN;
settings.PROC.reset_bool_epoch = false;
settings.PROC.reset_bool_min = false;
settings.PROC.exclude_epochs = cell(0,3);
settings.PROC.excl_eps = [];
settings.PROC.excl_epochs_reset = [];
settings.PROC.exclude = cell(0,3);
settings.PROC.excl_partly = [];
settings.PROC.exclude_sats = [];

% export options
exp = {'data4plot', 'results_txt', 'results_csv', 'bool_csv_utc', 'settings', ...
    'settings_summary', 'model_save', 'tropo_est', 'nmea', 'kml', 'sp3', ...
    'obs_bias', 'obs_epochheader', 'storeData', 'storeData_vtec', ...
    'storeData_iono_mf', 'storeData_mp_1_2', 'storeData_sat_status', ...
    'satellites', 'satellites_D'};
for i = 1:numel(exp)
    settings.EXP.(exp{i}) = false;
end
settings.EXP.epoch_decimals = '';
settings.EXP.satellites = true;         % GUI default, only .D is mentioned in settings_summary.txt
settings.EXP.coord_sys = 'no transformation';
settings.EXP.epsg_code = '0';

% plotting (not part of settings_summary.txt)
plt = {'float', 'fixed', 'coordinate', 'map', 'UTM', 'coordxyz', 'XYZ', 'velocity', ...
    'elevation', 'satvisibility', 'amb', 'clock', 'dcb', 'wet_tropo', 'cov_info', ...
    'cov_amb', 'corr', 'skyplot', 'residuals', 'DOP', 'MPLC', 'iono', 'cs', 'mp', ...
    'appl_biases', 'signal_qual', 'res_sats', 'stream_corr', 'attitude'};
for i = 1:numel(plt)
    settings.PLOT.(plt{i}) = false;
end
settings.PLOT.float = true;
settings.PLOT.pos_true = [0; 0; 0];
end


function [lines, head] = getSection(TXT, header)
% Returns the trimmed, non-empty lines of a section of settings_summary.txt
% (without the header line) and the header line itself. A section starts
% with a line without indentation and ends before the next line without
% indentation.
lines = {};   head = '';
idx = find(startsWith(TXT, header), 1);
if isempty(idx);   return;   end
head = TXT{idx};
is_top = cellfun(@(s) ~isempty(s) && ~isspace(s(1)), TXT);
next = find(is_top(idx+1:end), 1);
if isempty(next);   last = numel(TXT);   else;   last = idx + next - 1;   end
lines = strtrim(TXT(idx+1:last));
lines(cellfun('isempty', lines)) = [];
end


function [val, found] = getValue(lines, key, sep)
% Returns the text behind the first line beginning with key. If sep is
% specified, the value starts after the first occurrence of sep in the line.
val = '';   found = false;
idx = find(startsWith(lines, key), 1);
if isempty(idx);   return;   end
line = lines{idx};
if nargin > 2
    k = strfind(line, sep);
    if isempty(k);   return;   end
    val = strtrim(line(k(1)+numel(sep):end));
else
    val = strtrim(line(numel(key)+1:end));
end
found = true;
end


function vals = getValues(lines, key)
% Returns the text behind all lines beginning with key
idx = find(startsWith(lines, key));
vals = cell(1, numel(idx));
for i = 1:numel(idx)
    vals{i} = strtrim(lines{idx(i)}(numel(key)+1:end));
end
end


function bool = hasBullet(lines, txt)
% true if the list of activated corrections contains the entry txt
bool = any(startsWith(lines, ['o ' txt]));
end


function list = parseList(str)
% Splits a comma-separated string into a cell array of trimmed strings
if isempty(str);   list = {};   return;   end
list = strtrim(strsplit(str, ','));
end


function nums = parseNumbers(str)
% Returns all numbers in a string as row vector
nums = sscanf(strrep(str, ',', ' '), '%f')';
if isempty(nums);   nums = [];   end
end


function nr = firstNumber(str, default)
% Returns the first number in a string, otherwise default
nr = default;
tok = regexp(str, '[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?|[-+]?Inf|NaN', 'match', 'once');
if ~isempty(tok);   nr = str2double(tok);   end
end


function [option, version] = parseTropo(str)
% Splits a tropo setting (e.g., 'VMF3 (V3GR, operational)') into the option
% and the VMF version (operational or forecast) which was appended by
% detectGridSiteWise.m
version = '';
pat = '\s*\([^()]*,\s*(operational|forecast)[^()]*\)\s*$';
tok = regexp(str, pat, 'tokens', 'once');
if ~isempty(tok)
    version = tok{1};
    str = regexprep(str, pat, '');
end
option = strtrim(str);
end


function fun = parseWeightFun(scheme, name, converter)
% Converts the weighting function of the observations
% ('name: option_x' or 'name, function: expression') to the same format as
% in getSettingsFromGUI.m
try
    if startsWith(scheme, [name ', function:'])
        str = strtrim(scheme(numel([name ', function:'])+1:end));
    else
        str = strtrim(scheme(numel([name ':'])+1:end));
    end
    fun = converter(str);
catch
    fun = [];
end
end


function T = parseFrqStd(lines)
% Reads the frequency-specific standard-deviations (5x3 cell, rows: GPS,
% GLO, GAL, BDS, QZSS). Not processed GNSS have empty cells.
T = cell(5,3);
key = {'GPS:', 'GLO:', 'GAL:', 'BDS:', 'QZSS:'};
for i = 1:5
    val = getValue(lines, key{i});
    nrs = parseNumbers(val);
    for j = 1:min(3, numel(nrs))
        T{i,j} = nrs(j);
    end
end
end


function excl = parseExcludedSats(lines)
% Reads the excluded satellites, 'PRN 005, from      0 to    Inf'
excl = cell(0,3);
for i = 1:numel(lines)
    tok = regexp(lines{i}, '^PRN\s+(\S+?),\s*from\s+(\S+)\s+to\s+(\S+)$', 'tokens', 'once');
    if isempty(tok);   continue;   end
    prn = str2double(tok{1});
    if isnan(prn);   prn = tok{1};   end
    start = str2double(tok{2});   ende = str2double(tok{3});
    if start == 0 || isnan(start);   start = [];   end         % as empty cell in GUI table
    if isinf(ende) || isnan(ende);   ende = [];    end
    excl(end+1, :) = {prn, start, ende};
end
end


function excl = parseExcludedEpochs(lines)
% Reads the excluded epochs, 'From      1 to    100, no reset'
excl = cell(0,3);
for i = 1:numel(lines)
    tok = regexp(lines{i}, '^From\s+(\S+)\s+to\s+([^,\s]+),\s*(with|no) reset$', 'tokens', 'once');
    if isempty(tok);   continue;   end
    start = str2double(tok{1});   ende = str2double(tok{2});
    if isinf(ende) || isnan(ende);   ende = [];   end
    excl(end+1, :) = {start, ende, strcmp(tok{3}, 'with')};
end
end


function settings = deriveExcludedSats(settings)
% creates settings.PROC.exclude_sats and settings.PROC.excl_partly like
% readExcludeSatellites (in getSettingsFromGUI.m)
excl = settings.PROC.exclude;
M = zeros(0,3);
for i = 1:size(excl,1)
    prn = excl{i,1};
    if ischar(prn)          % e.g., '301:303'
        tok = regexp(prn, '^(\d+):(\d+)$', 'tokens', 'once');
        if isempty(tok);   continue;   end
        prn = str2double(tok{1}):str2double(tok{2});
    end
    start = excl{i,2};   ende = excl{i,3};
    if isempty(start);   start = 0;     end
    if isempty(ende);    ende = Inf;    end
    M = [M; prn(:), repmat([start, ende], numel(prn), 1)];
end
if ~isempty(M)
    bool_excl_partly = (M(:,2) ~= 0) & (M(:,3) ~= 0);
    settings.PROC.excl_partly = M(bool_excl_partly, :);
    settings.PROC.exclude_sats = M(~bool_excl_partly, 1);
else
    settings.PROC.excl_partly = [];
    settings.PROC.exclude_sats = [];
end
end


function settings = deriveExcludedEpochs(settings)
% creates settings.PROC.excl_eps and settings.PROC.excl_epochs_reset like
% in getSettingsFromGUI.m
excl = settings.PROC.exclude_epochs;
settings.PROC.excl_eps = [];
settings.PROC.excl_epochs_reset = [];
for i = 1:size(excl,1)
    start = excl{i,1};   ende = excl{i,2};
    if isempty(ende);   ende = 0;   end
    settings.PROC.excl_eps = [settings.PROC.excl_eps, start:ende];
    if excl{i,3}
        settings.PROC.excl_epochs_reset = [settings.PROC.excl_epochs_reset, start];
    end
end
settings.PROC.excl_eps(settings.PROC.excl_eps == 0) = [];
end
