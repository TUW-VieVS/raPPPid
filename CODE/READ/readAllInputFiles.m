function  [input, obs, settings, OBSDATA] = readAllInputFiles(settings)

% Reads in all input files in an internal raPPPid format: observations, 
% navigation file, precise satellite orbits, precise clocks, IONEX,
% DCB-files, SINEX Bias, met-file, antex-file, ...
% 
% INPUT:
%   settings    struct, processing settings from the GUI
% OUTPUT:
%	input       struct, contains most input data
%   obs         struct, contains observation-specific data
%   settings    struct, updated with some new fields
%   OBSDATA     cell, contains data of the observation file (e.g., RINEX)
% 
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

bool_print = ~settings.INPUT.bool_parfor;
input = []; Biases = []; 



%% Files - Set input files

% Analyze header of observation file
settings.INPUT.rawDataAndroid = false;
obs = anheader(settings);       % read the header of RINEX observation file
if isempty(obs)
    % no RINEX file -> analyze the Android raw sensor data file
    obs = analyzeAndroidRawData(settings.INPUT.file_obs, settings);
    settings.INPUT.rawDataAndroid = true;
end


% Look for the observation types and the corresponding column number
% (create obs.use_column)
obs = find_obs_col(obs, settings);
% save and print information to obs and command window
obs = SavePrintObsType(obs, settings);

% Read-in RINEX observation file in the case of postprocessing
if ~settings.INPUT.bool_realtime
    if ~settings.INPUT.rawDataAndroid
        % RINEX file
        [OBSDATA, obs.newdataepoch] = readRINEX(settings.INPUT.file_obs, obs.rinex_version);
        if settings.PROC.timeFrame(2) == 999999        % processing till end of observation file
            settings.PROC.timeFrame(2) = numel(obs.newdataepoch);       % determine number of epochs contained in observation file
        end
    else
        % raw sensor data from Android (e.g., smartphone)
        [OBSDATA, obs.newdataepoch] = readAndroidRawSensorData(settings.INPUT.file_obs, obs.vars_raw);
        if settings.PROC.timeFrame(2) == 999999        % processing till end of observation file
            settings.PROC.timeFrame(2) = numel(obs.newdataepoch) - 1; 	% number of all epochs
        end
    end

else
    OBSDATA = {}; obs.newdataepoch = [];
end

% Start-date in different time-formats
hour = obs.startdate(4) + obs.startdate(5)/60 + obs.startdate(6)/3660;
obs.startdate_jd = cal2jd_GT(obs.startdate(1),obs.startdate(2), obs.startdate(3) + hour/24);
[obs.startGPSWeek, obs.startSow, ~] = jd2gps_GT(obs.startdate_jd);
[obs.doy, ~] = jd2doy_GT(obs.startdate_jd);
% print startdate of observation file
if bool_print
    fprintf('\nObservation start:\n')
    t = datetime(obs.startdate(1), obs.startdate(2), obs.startdate(3), ...
        obs.startdate(4), obs.startdate(5), obs.startdate(6), 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    fprintf('  %s | %d/%d | %d/%03d\n\n', t, obs.startGPSWeek, floor(obs.startSow/86400), obs.startdate(1), floor(obs.doy))
end

% check if GLONASS channels could be detected (e.g., RINEX header)
glo_channels = settings.INPUT.use_GLO & any(isnan(obs.glo_channel));

% automatic download of the files which are needed for processing and some
% changes (filepaths and booleans) in the struct settings for the futher processing
settings = downloadInputFiles(settings, obs.startdate, glo_channels);



%% Models - Orbit/clock data

% -) Precise Products

% Read precise ephemerides file
if settings.ORBCLK.bool_sp3
    path_sp3 = settings.ORBCLK.file_sp3;
    if contains(path_sp3, '$')
        [fname, fpath] = ConvertStringDate(path_sp3, obs.startdate(1:3));
        path_sp3 = ['../DATA/ORBIT' fpath fname];
    end
    [sp3_GPS, sp3_GLO, sp3_GAL, sp3_BDS, sp3_QZSS] = read_precise_eph(path_sp3);
    input.ORBCLK.preciseEph_GPS = sp3_GPS;
    input.ORBCLK.preciseEph_GLO = sp3_GLO;
    input.ORBCLK.preciseEph_GAL = sp3_GAL;
    input.ORBCLK.preciseEph_BDS = sp3_BDS;
    input.ORBCLK.preciseEph_QZSS = sp3_QZSS;
    obs.coordsyst = GetCoordSystemFromSP3(path_sp3);
    if settings.INPUT.use_GPS && isempty(input.ORBCLK.preciseEph_GPS); errordlg('No precise orbits for GPS in sp3-file!', 'Error'); end
    if settings.INPUT.use_GLO && isempty(input.ORBCLK.preciseEph_GLO); errordlg('No precise orbits for Glonass in sp3-file!', 'Error'); end
    if settings.INPUT.use_GAL && isempty(input.ORBCLK.preciseEph_GAL); errordlg('No precise orbits for Galileo in sp3-file!', 'Error'); end
    if settings.INPUT.use_BDS && isempty(input.ORBCLK.preciseEph_BDS); errordlg('No precise orbits for BeiDou in sp3-file!', 'Error'); end
    if settings.INPUT.use_QZSS&& isempty(input.ORBCLK.preciseEph_QZSS);errordlg('No precise orbits for QZSS in sp3-file!', 'Error'); end
end

% Read precise clock file
if settings.ORBCLK.bool_clk
    clk_file = settings.ORBCLK.file_clk;
    % check for auto-detection
    if contains(clk_file, '$')
        [fname, fpath] = ConvertStringDate(clk_file, obs.startdate(1:3));
        clk_file = ['../DATA/CLOCK' fpath fname];
    end
    if strcmp(clk_file(end-3:end), '.mat'); clk_file_mat = clk_file;
    else;                                   clk_file_mat = [clk_file, '.mat'];    end
    try                 % load .mat-file, if available
        load(clk_file_mat, 'preClk_GPS', 'preClk_GLO', 'preClk_GAL', 'preClk_BDS', 'preClk_QZSS');
        % produce an error if one variable could not be loaded to start new
        % read-in of the precise clock file
        preClk_GPS; preClk_GLO; preClk_GAL; preClk_BDS; 
        if settings.INPUT.use_QZSS; preClk_QZSS; end
    catch             	% read in original file and save as .mat-file
        if ~isfile(clk_file)
            delete(clk_file_mat);
            errordlg('No clock file: Please restart processing!', 'Error');
        end
        [preClk_GPS, preClk_GLO, preClk_GAL, preClk_BDS, preClk_QZSS] = read_precise_clocks(clk_file);
        % save as .mat-file for next processing (faster loading)
        save(clk_file_mat, 'preClk_GPS', 'preClk_GLO', 'preClk_GAL', 'preClk_BDS', 'preClk_QZSS')
        delete(clk_file);               % delete clk file to save disk space
    end
    input.ORBCLK.preciseClk_GPS = preClk_GPS;
    input.ORBCLK.preciseClk_GLO = preClk_GLO;
    input.ORBCLK.preciseClk_GAL = preClk_GAL;
    input.ORBCLK.preciseClk_BDS = preClk_BDS;
    if settings.INPUT.use_QZSS; input.ORBCLK.preciseClk_QZSS = preClk_QZSS; end
elseif settings.ORBCLK.bool_sp3         % no precise clock file but a precise orbit (sp3 file)   
    % save the clock information from sp3 as it would be from precise clock file
    input = preciseOrbit2Clock(input, settings);
    settings.ORBCLK.bool_clk = 1;       % overwrite setting for precise clock
end
% if CNES and integer recovery clock: exclude unfixed satellites
if settings.AMBFIX.bool_AMBFIX && strcmp(settings.ORBCLK.prec_prod, 'CNES') && strcmp(settings.BIASES.phase, 'off')
    settings = excludeUnfixedSats(obs, settings);
end

% Read ERP file
if settings.OTHER.polar_tides && ~isempty(settings.ORBCLK.file_erp)
    input.ORBCLK.ERP = read_erp(settings.ORBCLK.file_erp);
end

% Read ORBEX file
if settings.ORBCLK.bool_obx && ~isempty(settings.ORBCLK.file_obx)
    path_obx = settings.ORBCLK.file_obx;
    if contains(path_obx, '$')
        [fname, fpath] = ConvertStringDate(path_obx, obs.startdate(1:3));
        path_obx = ['../DATA/ORBIT' fpath fname];
    end
    % read & save ORBEX file or load *.mat
    if ~exist([path_obx '.mat'], 'file')
        OBX = read_orbex(path_obx);
        save([path_obx '.mat'], 'OBX');     % save as .mat-file for next processing (faster loading)
    else
        load([path_obx '.mat'], 'OBX');     % load .mat-file
    end
    input.ORBCLK.OBX = OBX;
end


% -) Broadcast products + correction stream

% Read RINEX navigation ephemerides files and convert to internal Matlab format
bool_nav_iono = strcmp(settings.IONO.source, 'Klobuchar model') || ...
    strcmp(settings.IONO.source, 'NeQuick model') || ...
    strcmp(settings.IONO.source, 'NTCM-G');
if (settings.ORBCLK.bool_brdc || glo_channels || bool_nav_iono) && ~settings.INPUT.bool_realtime
    [input] = read_brdc(settings, input, obs.leap_sec, glo_channels);
    if settings.INPUT.use_GLO
        % find out channels of Glonass satellites and save them in input.glo_channel
        obs.glo_channel = NaN(99,1);
        for i = 1:DEF.SATS_GLO        % loop over Glonass satellites
            channel_sat = input.ORBCLK.Eph_GLO(15,input.ORBCLK.Eph_GLO(1,:)==i);    % channels of ephemeris of current satellite
            if ~isempty(channel_sat)
                obs.glo_channel(i,1) = channel_sat(1);    % save channel of 1st ephemeris data
            end
        end
    end
end


% Read recorded correction-stream to broadcast ephemeris:
% load the from the last time saved .mat-file or read in from file directly.
% GPS and Galileo corrections are read even if their processing is not activated.
input.ORBCLK.corr2brdc_GPS = []; input.ORBCLK.corr2brdc_GLO = [];
input.ORBCLK.corr2brdc_GAL = []; input.ORBCLK.corr2brdc_BDS = [];
input.ORBCLK.corr2brdc_vtec = [];
if strcmp(settings.ORBCLK.CorrectionStream, 'manually') && settings.ORBCLK.bool_brdc && ~settings.INPUT.bool_realtime
    corr2brdc_path = settings.ORBCLK.file_corr2brdc;
    if contains(corr2brdc_path, '$')
        [fname, fpath] = ConvertStringDate(corr2brdc_path, obs.startdate(1:3));
        corr2brdc_path = ['../DATA/STREAM' fpath fname];
    end
    corr2brdc_mat  = corr2brdc_path;
    if ~contains(corr2brdc_mat, '.mat')   % make sure, "filename" denotes the .mat version
        corr2brdc_mat = [corr2brdc_mat, '.mat'];
    end
    if exist(corr2brdc_mat,'file') && ~settings.INPUT.bool_realtime      % load .mat-file, if available
        load(corr2brdc_mat, 'corr2brdc_GPS', 'corr2brdc_GLO', 'corr2brdc_GAL', 'corr2brdc_BDS', 'corr2brdc_vtec');	% load .mat-file
    else                                                    % no .mat-file so read-in correction-stream
        if bool_print; fprintf('Reading corrections to broadcast ephemerides (this may take up to several minutes)\n'); end
        % open and read file file
        fid = fopen(corr2brdc_path);
        lines = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
        lines = lines{1};
        fclose(fid);
        [corr2brdc_GPS, corr2brdc_GLO, corr2brdc_GAL, corr2brdc_BDS, ...
            corr2brdc_vtec] = read_corr2brdc_stream(lines);
        save(corr2brdc_mat, 'corr2brdc_GPS', 'corr2brdc_GLO', 'corr2brdc_GAL', 'corr2brdc_BDS', 'corr2brdc_vtec')   % save as .mat-file for next processing (faster loading)
        %         delete(erase(filename,'.mat'));   % delete the original file (only wastes disk space)
    end
    input.ORBCLK.corr2brdc_vtec = corr2brdc_vtec;
    % save only corrections from used GNSS in input:
    if settings.INPUT.use_GPS;   input.ORBCLK.corr2brdc_GPS  = corr2brdc_GPS;    end
    if settings.INPUT.use_GLO;   input.ORBCLK.corr2brdc_GLO  = corr2brdc_GLO;    end
    if settings.INPUT.use_GAL;   input.ORBCLK.corr2brdc_GAL  = corr2brdc_GAL;    end
    if settings.INPUT.use_BDS;   input.ORBCLK.corr2brdc_BDS  = corr2brdc_BDS;    end
end
if strcmp(settings.ORBCLK.CorrectionStream, 'manually') && contains(settings.ORBCLK.file_corr2brdc, 'CLK22') && ~strcmp(obs.GPS.L1, 'L1W') && strcmp(obs.GPS.L1, 'L2W') && settings.AMBFIX.bool_AMBFIX
    errordlg('No phase biases: CLK22-Stream contains phase biases for L1W and L2W only!', 'Error');
end


% Assign code and phase biases from recorded correction-stream to observation types
if strcmp(settings.ORBCLK.CorrectionStream, 'manually') && ~settings.INPUT.bool_realtime && ...
        (settings.BIASES.code_corr2brdc_bool || settings.BIASES.phase_corr2brdc_bool)
    if obs.rinex_version >= 3 || obs.rinex_version == 0  	% 3-digit-obs-types from Rinex 3 onwards
        [obs] = assign_corr2brdc_biases(obs, input, settings);
    else                            % Rinex 2 observation file (2-digit-obs-types)
        [obs] = assign_corr2brdc_biases_rinex2(obs, input);
    end
end



%% Models - Troposphere

% check if mapping functions are needed
bool_mfh = ~strcmpi(settings.TROPO.zhd,'no');
bool_mfw = ~strcmpi(settings.TROPO.zwd,'no');

% get and read the V3GR files (VMF3 or GRAD)
if strcmpi(settings.TROPO.zhd,'VMF3') || strcmpi(settings.TROPO.zwd,'VMF3') || ...
        (bool_mfh && strcmpi(settings.TROPO.mfh,'VMF3') ) || (bool_mfw && strcmpi(settings.TROPO.mfw,'VMF3')) || ...
        strcmpi(settings.TROPO.Gh,'GRAD') || strcmpi(settings.TROPO.Gw,'GRAD')
    input = get_V3GR(obs, input, settings);
end


% get and read the files for VMF1
if strcmpi(settings.TROPO.zhd,'VMF1') || strcmpi(settings.TROPO.zwd,'VMF1') || ...
        (bool_mfh && strcmpi(settings.TROPO.mfh,'VMF1')) || (bool_mfw && strcmpi(settings.TROPO.mfw,'VMF1'))
    input = get_VMF1(obs, input, settings);
end


% read trop-files from IGS, if specified
if strcmpi(settings.TROPO.zhd,'Tropo file') || strcmpi(settings.TROPO.zwd,'Tropo file')
    switch settings.TROPO.tropo_file
        case 'manually'
            tropo_file = settings.TROPO.tropo_filepath;
            if contains(settings.TROPO.tropo_filepath, '$')
                [file_tropo, fpath_tropo] = ConvertStringDate(settings.TROPO.tropo_filepath, obs.startdate(1:3));
                tropo_file = ['../DATA/TROPO/' fpath_tropo file_tropo];
            end
            input.TROPO.tropoFile.data = readTropoFile(tropo_file, obs.stationname);
            
        case 'IGS troposphere product'
            % download tropofile
            [tropofile, success] = DownloadTropoFile(obs.station_long, obs.startdate(1), jd2doy_GT(obs.startdate_jd));
            if success
                input.TROPO.tropoFile.data = readTropoFile(tropofile, obs.station_long);
            else
                errordlg('IGS Tropo file not found, GPT3 used instead!', 'ERROR')
                fprintf('%s%s%s\n' , 'Tropo file ',  file_tropoFile, ' not found => GPT3 used instead');
                settings.TROPO.zhd = 'p (GPT3) + Saastamoinen';
                settings.TROPO.zwd = 'e (GPT3) + Askne';
            end
        otherwise
            errordlg('Error in getTropoFile.m', 'ERROR');
    end
end


% read the GPT3 grid 
if strcmpi(settings.TROPO.zhd,'p (GPT3) + Saastamoinen') || strcmpi(settings.TROPO.zwd,'e (GPT3) + Askne') || strcmpi(settings.TROPO.zwd,'e (in situ) + Askne') || ...
        (bool_mfh && strcmpi(settings.TROPO.mfh,'GPT3')) || (bool_mfw && strcmpi(settings.TROPO.mfw,'GPT3')) || ...
        strcmpi(settings.TROPO.zhd,'Tropo file') || strcmpi(settings.TROPO.Gh,'GPT3') || strcmpi(settings.TROPO.Gw,'GPT3')
    load('gpt3_5.mat', 'gpt3_5');               % file located in \CODE\ATMOSPHERE
    input.TROPO.GPT3.cell_grid = gpt3_5;        % avoids gpt3_5_fast_readGrid.m
    % input.TROPO.GPT3.cell_grid = gpt3_5_fast_readGrid;
end




%% Models - Ionosphere

if strcmpi(settings.IONO.model,'Estimate with ... as constraint')   ||   strcmpi(settings.IONO.model,'Correct with ...')
    path_ionex = settings.IONO.file_ionex;
    % check for auto-detection
    if strcmpi(settings.IONO.model_ionex, 'Auto-Detection:')
        % create file-path with auto-detection
        [ionex_filename, fpath_ionex] = ConvertStringDate(settings.IONO.autodetection, obs.startdate(1:3));
        if settings.IONO.folder_manual
            path_ionex = [settings.IONO.folder, '/' ,ionex_filename];
        else        % automatic folder from raPPPid folder structur
            path_ionex = ['../DATA/IONO', fpath_ionex, ionex_filename];
        end
        if ~isfile(path_ionex)
            errordlg('Check Auto-Detection of IONEX-File!', 'No File found');
        end
    end    
    switch settings.IONO.source
        case 'IONEX File'               % Ionex-File
            input.IONO.ionex = read_ionex_TUW(path_ionex);
        case 'CODE Spherical Harmonics' % CODE ion file
            input.IONO.ion = read_ion(settings.IONO.file_ion);
        case 'TOBS File'                % TOBS file (ATom software)
            input.IONO.TOBS_STEC = read_TOBS('..\DATA\IONO\MyTobsFile.TOBS', obs.leap_sec, obs.stationname, obs.startdate_jd);            
    end
    settings.IONO.file_ionex = path_ionex;
end

% Check if coefficients from broadcast navigation message are needed for
% ionospheric correction (e.g. Klobuchar, NeQuick)
bool_nav_klo = strcmpi(settings.IONO.source,'Klobuchar model') && (~isfield(input, 'IONO') || ~isfield(input.IONO, 'klob_coeff') || isempty(input.IONO.klob_coeff));
bool_nav_neq = strcmpi(settings.IONO.source,'NeQuick model')   && (~isfield(input, 'IONO') || ~isfield(input.IONO, 'nequ_coeff') || isempty(input.IONO.nequ_coeff));

% if Klobuchar is activated check if coefficients are read in
if bool_nav_klo || bool_nav_neq
    [input.IONO.klob_coeff, input.IONO.nequ_coeff] = read_nav_iono(settings.ORBCLK.file_nav_multi);
end


%% Models - Biases

% ----- Code -----
% -) read SINEX-Bias-File when
%   - CAS or DLR Multi-GNSS DCBs for code biases
%   - CODE OSB File
%   - manually selected SINEX-Bias-File for code biases
%   - CNES Archive for code and phase biases
bool_sinex = any(strcmp(settings.BIASES.code, ...
    {'CAS Multi-GNSS DCBs','CAS Multi-GNSS OSBs','DLR Multi-GNSS DCBs','CODE OSBs','CNES OSBs','CODE MGEX','WUM MGEX','CNES MGEX','GFZ MGEX','HUST MGEX','CNES postprocessed'}));
bool_manually_sinex = strcmp(settings.BIASES.code, 'manually') && settings.BIASES.code_manually_Sinex_bool;
bool_CNES_archive_biases = strcmp(settings.ORBCLK.CorrectionStream, 'CNES Archive') && (settings.BIASES.code_corr2brdc_bool || settings.BIASES.phase_corr2brdc_bool);
settings.AMBFIX.APC_MODEL = false;
if bool_sinex || bool_manually_sinex || bool_CNES_archive_biases
    if bool_sinex || bool_manually_sinex
        path_sinex = settings.BIASES.code_file;
    elseif bool_CNES_archive_biases
        path_sinex = settings.BIASES.code_file;     % or settings.BIASES.phase_file
    end
    % check for auto-detection Sinex-BIAS-File
    if contains(path_sinex, '$')
        [fname, fpath] = ConvertStringDate(path_sinex, obs.startdate(1:3));
        path_sinex = ['../DATA/BIASES' fpath fname];
    end
    % create path to potential *.mat-file (already read-in)
    if ~strcmp(path_sinex(end-3:end), '.mat'); sinex_file = [path_sinex, '.mat'];
    else; sinex_file = path_sinex; end
    % check if Sinex BIAS file was already read-in and saved as *.mat
    if exist(sinex_file, 'file')
        load(sinex_file, 'Biases');      % already read in, load .mat-file
    else            % mainly for huge CNES-whole-day-files
        if bool_print; fprintf('Reading and converting SINEX Bias file (this can take up to several minutes)...\n'); end
        Biases = read_SinexBias(Biases, path_sinex, obs.glo_channel);
        save(sinex_file, 'Biases')            % save as .mat-file for next processing (faster loading)
        if strcmp(settings.BIASES.code, 'CNES postprocessed') || ...
                (strcmp(settings.ORBCLK.CorrectionStream, 'CNES Archive') && (settings.BIASES.code_corr2brdc_bool || settings.BIASES.phase_corr2brdc_bool))
            delete(erase(sinex_file,'.mat'));     % delete the huge original file (only wastes disk space)
        end
    end
    input = save_SinexBias(input, Biases);
    % find correct biases depending processed observation type
    [obs] = assign_sinex_biases(obs, input.BIASES.sinex, settings);
    % check if APC model is applied for WL fixing
    if ~isempty(Biases.Header.APC_MODEL) || strcmp(Biases.Header.SAT_ANT_PCC_APPLIED, 'YES')
        settings.AMBFIX.APC_MODEL = true;
    end
end

% -) CODE DCBs: directly selected or manually
if strcmp(settings.BIASES.code, 'CODE DCBs (P1P2, P1C1, P2C2)') || ( strcmp(settings.BIASES.code, 'manually') && settings.BIASES.code_manually_DCBs_bool )
    path_dcb = settings.BIASES.code_file;
    % check for auto-detection DCB-Files
    if contains(path_dcb{1}, '$')
        [fname, fpath] = ConvertStringDate(path_dcb{1}, obs.startdate(1:3));
        path_dcb{1} = ['../DATA/BIASES' fpath(1:6) fname];
    end
    if contains(path_dcb{2}, '$')
        [fname, fpath] = ConvertStringDate(path_dcb{2}, obs.startdate(1:3));
        path_dcb{2} = ['../DATA/BIASES' fpath(1:6) fname];
    end
    if contains(path_dcb{3}, '$')
        [fname, fpath] = ConvertStringDate(path_dcb{3}, obs.startdate(1:3));
        path_dcb{3} = ['../DATA/BIASES' fpath(1:6) fname];
    end
    % read DCBs from file
    [input.BIASES.dcb_P1P2, input.BIASES.dcb_P1P2_GLO] = ...     % read P1P2-DCB values from .dcb-file
        read_dcb(path_dcb{1}, settings.INPUT.use_GPS, settings.INPUT.use_GLO);
    [input.BIASES.dcb_P1C1, input.BIASES.dcb_P1C1_GLO] = ...     % read P1C1-DCB values from .dcb-file
        read_dcb(path_dcb{2}, settings.INPUT.use_GPS, settings.INPUT.use_GLO);
    [input.BIASES.dcb_P2C2, input.BIASES.dcb_P2C2_GLO] = ...     % read P2C2-DCB values from .dcb-file
        read_dcb(path_dcb{3}, settings.INPUT.use_GPS, settings.INPUT.use_GLO);
end

% -) check if receiver code biases are needed and get them
if settings.INPUT.proc_freqs > 1 && ~settings.BIASES.estimate_rec_dcbs
    [obs] = get_rec_biases(settings, input, obs);
end



% ----- Phase ------
switch settings.BIASES.phase
        
    case 'WHU phase/clock biases'
        wuhan_file = [settings.BIASES.phase_file, '.mat'];
        if exist(wuhan_file, 'file')
            load(wuhan_file, 'Biases');      % already read in, load .mat-file
        else
            Biases = read_SinexBias(Biases, settings.BIASES.phase_file, obs.glo_channel);
            save(wuhan_file, 'Biases')            % save as .mat-file for next processing (faster loading)
        end
        input = save_SinexBias(input, Biases);
        % find correct biases depending processed observation type
        [obs] = assign_sinex_biases(obs, input.BIASES.sinex, settings);
        
    case 'SGG FCBs'
        % reset potential other phase biases (e.g. CODE) which were already read-in
        obs.L1_bias.value(:) = 0;
        obs.L2_bias.value(:) = 0;
        obs.L3_bias.value(:) = 0;
        [input.BIASES.WL_UPDs, input.BIASES.NL_UPDs] = readSGGFCBs(settings.BIASES.phase_file);
        
    case 'NRCAN (not implemented)'
        errordlg('Phase bias read-in not implemented.', 'Error');
        % ||| implement at some point
        
    case 'Correction Stream'
        % already happened
        
    case 'manually (not implemented)'
        errordlg('Phase bias read-in not implemented.', 'Error');
        % ||| implement at some point
        
    case 'off'
        % nothing to do here
        
    otherwise
        errordlg('Strange setting for phase biases.', 'Error');
end



%% Models - Other corrections

% Read ANTEX/atx-file (PCOs and PVCs for receiver and satellites)
input = readAntex(input, settings, obs.startdate_jd, obs.antenna_type);
% Check read-in of ANTEX file
input = checkAntex(input, settings, obs.antenna_type);

% Read data ocean loading correction
if settings.OTHER.ocean_loading
    input.OTHER.OcLoad = read_blq('..\DATA\OceanLoading.blq', obs.stationname);
    if isempty(input.OTHER.OcLoad)
        fprintf(2, '\nStation was not found in OceanLoading.blq!\n')
    end
end



%% Write specified models to command window
if bool_print
    % Orbit/Clock
    fprintf('\n\n');
    fprintf('%s\n','Orbit/Clock data:')
    if settings.ORBCLK.bool_precise
        
        fprintf('  %s\n','Precise products:');
        fprintf('    %s%s%s\n',settings.ORBCLK.prec_prod,':   ',settings.ORBCLK.file_sp3);
        fprintf('    %s%s%s\n',settings.ORBCLK.prec_prod,':   ',settings.ORBCLK.file_clk);
        
    else
        
        fprintf('  %s\n','Broadcast products + Correction stream')
        if settings.ORBCLK.bool_nav_multi
            fprintf('    %s%s%s%s\n','Multi-GNSS Navigation file: ',settings.ORBCLK.multi_nav,':   ',settings.ORBCLK.file_nav_multi);
        end
        if settings.ORBCLK.bool_nav_single
            if settings.INPUT.use_GPS
                fprintf('    %s%s\n','GPS Navigation file: ',settings.ORBCLK.file_nav_GPS);
            end
            if settings.INPUT.use_GLO
                fprintf('    %s%s\n','GLONASS Navigation file: ',settings.ORBCLK.file_nav_GLO);
            end
            if settings.INPUT.use_GAL
                fprintf('    %s%s\n','Galileo Navigation file: ',settings.ORBCLK.file_nav_GAL);
            end
            if settings.INPUT.use_BDS
                fprintf('    %s%s\n','BeiDou Navigation file: ',settings.ORBCLK.file_nav_BDS);
            end
        end
        
        if ~strcmpi(settings.ORBCLK.CorrectionStream,'off')
            if strcmpi(settings.ORBCLK.CorrectionStream,'manually')
                fprintf('    %s%s%s%s\n','Correction stream file: ',settings.ORBCLK.CorrectionStream,':   ',settings.ORBCLK.file_corr2brdc);
            else
                fprintf('    %s%s\n','Correction stream file: ',settings.ORBCLK.CorrectionStream);
            end
        else
            fprintf('    %s\n','No correction stream file');
        end
        
    end
    fprintf('\n');
    
    
    % Troposphere
    fprintf('%s\n', 'Troposphere:');
    fprintf('  %s%s %s\n','zhd: ', settings.TROPO.zhd, detectGridSiteWise(settings.TROPO.zhd, input, settings.TROPO.vmf_version));
    if strcmpi(settings.TROPO.zhd, 'p (in situ) + Saastamoinen')
        fprintf('    %s%7.2f%s\n','p: ', settings.TROPO.p,' hPa');
    end
    fprintf('  %s%s %s\n','zwd: ', settings.TROPO.zwd, detectGridSiteWise(settings.TROPO.zwd, input, settings.TROPO.vmf_version));
    if strcmpi(settings.TROPO.zwd,'e (in situ) + Askne')
        fprintf('    %s%5.2f%s\n','q: ', settings.TROPO.q,' %');
        fprintf('    %s%6.2f%s\n','T: ', settings.TROPO.T,' �C')
    end
    if bool_mfh
        fprintf('  %s%s %s\n','mfh: ', settings.TROPO.mfh, detectGridSiteWise(settings.TROPO.mfh, input, settings.TROPO.vmf_version));
    end
    if bool_mfw
        fprintf('  %s%s %s\n','mfw: ', settings.TROPO.mfw, detectGridSiteWise(settings.TROPO.mfw, input, settings.TROPO.vmf_version));
    end
    fprintf('  %s%s %s\n','Gn_h & Ge_h: ', settings.TROPO.Gh, detectGridSiteWise(settings.TROPO.Gh, input, settings.TROPO.vmf_version));
    fprintf('  %s%s %s\n','Gn_w & Ge_w: ', settings.TROPO.Gw, detectGridSiteWise(settings.TROPO.Gw, input, settings.TROPO.vmf_version));
    fprintf('\n');
    
    
    % Ionosphere
    fprintf('%s\n','Ionosphere:');
    fprintf('  %s%s\n','Model: ',settings.IONO.model)
    if strcmpi(settings.IONO.model,'Estimate with ... as constraint')   ||   strcmpi(settings.IONO.model,'Correct with ...')
        fprintf([settings.IONO.model_ionex,' ',settings.IONO.file_ionex]);
        if strcmpi(settings.IONO.model,'Correct with ...')
            fprintf('    %s%s\n','TEC-Interpolation: ',settings.IONO.interpol);
        end
    end
    fprintf('\n');
    
    
    % Biases
    fprintf('%s\n', 'Biases:');
    switch settings.BIASES.code
        case 'off'
            fprintf('    off\n')
        case 'Broadcasted TGD'
            fprintf('    Broadcasted TGD\n')
        case 'manually'
            if settings.BIASES.code_manually_DCBs_bool
                fprintf('%s\n','    DCBs selected manually: ')
                fprintf('%s%s\n','    P1P2: ', settings.BIASES.code_file{1});
                fprintf('%s%s\n','    P1C1: ', settings.BIASES.code_file{2});
                fprintf('%s%s\n','    P2C2: ', settings.BIASES.code_file{3});
            elseif settings.BIASES.code_manually_Sinex_bool
                fprintf('    %s\n','Biases from Sinex Bias File selected manually: ');
                fprintf('    %s\n',settings.BIASES.code_file)
            end
        case 'Correction Stream'
            fprintf('    Correction Stream\n')
            
        otherwise
            if ~contains(settings.BIASES.code, 'CODE DCBs')
                fprintf(['    ' settings.BIASES.code ':   ' settings.BIASES.code_file '\n'])
            else
                fprintf('%s\n','    CODE DCBs (P1P2, P1C1, P2C2):')
                fprintf('%s%s\n','    P1P2: ', settings.BIASES.code_file{1});
                fprintf('%s%s\n','    P1C1: ', settings.BIASES.code_file{2});
                fprintf('%s%s\n','    P2C2: ', settings.BIASES.code_file{3});
            end
    end
    
    % Phase Biases
    if ~strcmp(settings.BIASES.phase, 'off')
        fprintf('%s\n', 'Phase Biases:');
        switch settings.BIASES.phase
            case 'off'
                fprintf('    No phase biases applied\n')
            case 'Correction Stream'
                fprintf('    Correction Stream\n')
            otherwise
                fprintf(['    ' settings.BIASES.phase ':   ' settings.BIASES.phase_file '\n'])
        end
        
    end
    
    fprintf('\n');
    % Other corrections
    fprintf('%s\n','Other corrections:');
    fprintf('  Antex-File: %s\n', settings.OTHER.file_antex);
    if settings.OTHER.antex_rec_manual
        fprintf('  Receiver corrections from myAntex.atx\n');
    end  
    fprintf('\n');
end




