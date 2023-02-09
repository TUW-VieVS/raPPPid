function  [input, obs, settings, RINEX] = readAllInputFiles(settings)

% Reads in all input files: o-file, navigation-files, correction-stream to
% broadcast-orbits, precise ephemeris, precise clocks, ionex-file,
% DCB-files, met-file, antex-file
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

bool_print = ~settings.INPUT.bool_parfor;
input = []; Biases = [];



%% Files - Set input files


% Read the header of the observation file
obs = anheader(settings);
glo_channels = settings.INPUT.use_GLO & any(isnan(obs.glo_channel));

% Looking for the observation types and the right column number
obs = find_obs_col(obs, settings);

% Read observation file
[RINEX, obs.epochheader] = readRINEX(settings.INPUT.file_obs, obs.rinex_version);
if settings.PROC.timeFrame(2) == 999999        % processing till end of RINEX file
    settings.PROC.timeFrame(2) = numel(obs.epochheader);   % process all epochs of RINEX file
end

% Start-date in different time-formats
hour = obs.startdate(4) + obs.startdate(5)/60 + obs.startdate(6)/3660;
obs.startdate_jd = cal2jd_GT(obs.startdate(1),obs.startdate(2), obs.startdate(3) + hour/24);
[obs.startGPSWeek, obs.startSow, ~] = jd2gps_GT(obs.startdate_jd);
[obs.doy, ~] = jd2doy_GT(obs.startdate_jd);

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
    [input.ORBCLK.preciseEph_GPS, input.ORBCLK.preciseEph_GLO, input.ORBCLK.preciseEph_GAL, input.ORBCLK.preciseEph_BDS] = ...
        read_precise_eph(path_sp3);
    obs.coordsyst = GetCoordSystemFromSP3(path_sp3);
    if settings.INPUT.use_GPS && isempty(input.ORBCLK.preciseEph_GPS); errordlg('No precise orbits for GPS in sp3-file!', 'Error'); end
    if settings.INPUT.use_GLO && isempty(input.ORBCLK.preciseEph_GLO); errordlg('No precise orbits for Glonass in sp3-file!', 'Error'); end
    if settings.INPUT.use_GAL && isempty(input.ORBCLK.preciseEph_GAL); errordlg('No precise orbits for Galileo in sp3-file!', 'Error'); end
    if settings.INPUT.use_BDS && isempty(input.ORBCLK.preciseEph_BDS); errordlg('No precise orbits for BeiDou in sp3-file!', 'Error'); end
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
        load(clk_file_mat, 'preClk_GPS', 'preClk_GLO', 'preClk_GAL', 'preClk_BDS');
        % produce an error if one variable could not be loaded to start new
        % read-in of the precise clock file
        preClk_GPS; preClk_GLO; preClk_GAL; preClk_BDS;
    catch             	% read in original file and save as .mat-file
        [preClk_GPS, preClk_GLO, preClk_GAL, preClk_BDS] = read_precise_clocks(clk_file);
        % save as .mat-file for next processing (faster loading)
        save(clk_file_mat, 'preClk_GPS', 'preClk_GLO', 'preClk_GAL', 'preClk_BDS')
        delete(clk_file);               % delete clk file to save disk space
    end
    input.ORBCLK.preciseClk_GPS = preClk_GPS;
    input.ORBCLK.preciseClk_GLO = preClk_GLO;
    input.ORBCLK.preciseClk_GAL = preClk_GAL;
    input.ORBCLK.preciseClk_BDS = preClk_BDS;
elseif settings.ORBCLK.bool_sp3         % no precise clock file but a precise orbit (sp3 file)   
    % save the clock information from sp3 as it would be from precise clock file
    input = preciseOrbit2Clock(input, settings);
    settings.ORBCLK.bool_clk = 1;       % overwrite setting for precise clock
end
% if CNES and integer recovery clock: exclude unfixed satellites
if settings.AMBFIX.bool_AMBFIX && strcmp(settings.ORBCLK.prec_prod, 'CNES') && strcmp(settings.BIASES.phase, 'off')
    settings = excludeUnfixedSats(obs, settings);
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
if settings.ORBCLK.bool_brdc || glo_channels
    [input] = read_brdc(settings, input, obs.leap_sec, glo_channels);
    if settings.INPUT.use_GLO
        % find out channels of Glonass satellites and save them in input.glo_channel
        obs.glo_channel = NaN(99,1);
        for i = 1:DEF.SATS_GLO        % loop over Glonass satellites
            channel_sat = input.Eph_GLO(15,input.Eph_GLO(1,:)==i);    % channels of ephemeris of current satellite
            if ~isempty(channel_sat)
                obs.glo_channel(i,1) = channel_sat(1);    % save channel of 1st ephemeris data
            end
        end
    end
end


% Read correction-stream to broadcast ephemeris:
% load the from the last time saved .mat-file or read in from file directly.
% GPS and Galileo corrections are read even if their processing is not activated.
if strcmp(settings.ORBCLK.CorrectionStream, 'manually') && settings.ORBCLK.bool_brdc
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
        if bool_print; fprintf('Reading corrections to broadcast ephemerides...\n'); end
        [corr2brdc_GPS, corr2brdc_GLO, corr2brdc_GAL, corr2brdc_BDS, corr2brdc_vtec] = readCorr2Brdc(corr2brdc_path, settings.ORBCLK.corr2brdc_clk, settings.ORBCLK.corr2brdc_orb, settings.BIASES.code_corr2brdc_bool);
        save(corr2brdc_mat, 'corr2brdc_GPS', 'corr2brdc_GLO', 'corr2brdc_GAL', 'corr2brdc_BDS', 'corr2brdc_vtec')   % save as .mat-file for next processing (faster loading)
        %         delete(erase(filename,'.mat'));   % delete the original file (only wastes disk space)
    end
    input.ORBCLK.corr2brdc_vtec = corr2brdc_vtec;
    % save only corrections from used GNSS in input:
    if settings.INPUT.use_GPS;   input.ORBCLK.corr2brdc_GPS  = corr2brdc_GPS;    end
    if settings.INPUT.use_GLO;   input.ORBCLK.corr2brdc_GLO  = corr2brdc_GLO;    end
    if settings.INPUT.use_GAL;   input.ORBCLK.corr2brdc_GAL  = corr2brdc_GAL;    end
    if settings.INPUT.use_BDS;   input.ORBCLK.corr2brdc_BDS  = corr2brdc_BDS;    end
    % manipulate variables
    input = changeVariables_Corr2Brdc(settings, input);
end
if strcmp(settings.ORBCLK.CorrectionStream, 'manually') && contains(settings.ORBCLK.file_corr2brdc, 'CLK22') && ~strcmp(obs.GPS.L1, 'L1W') && strcmp(obs.GPS.L1, 'L2W') && settings.AMBFIX.bool_AMBFIX
    errordlg('No phase biases: CLK22-Stream contains phase biases for L1W and L2W only!', 'Error');
end


% Assign code and phase biases from recorded correction-stream to observation types
if strcmp(settings.ORBCLK.CorrectionStream, 'manually')   &&   (settings.BIASES.code_corr2brdc_bool || settings.BIASES.phase_corr2brdc_bool)
    if obs.rinex_version >= 3       % 3-digit-obs-types from Rinex 3 onwards
        [obs] = assign_corr2brdc_biases(obs, input, settings);
    else                            % Rinex 2 observation file (2-digit-obs-types)
        [obs] = assign_corr2brdc_biases_rinex2(obs, input);
    end
end



%% Models - Troposphere

% read the V3GR file(s)
if ~(strcmpi(settings.TROPO.zhd,'no')   &&   strcmpi(settings.TROPO.zwd,'no'))
    if strcmpi(settings.TROPO.zhd,'VMF3')   ||   strcmpi(settings.TROPO.zwd,'VMF3')   ||   strcmpi(settings.TROPO.mfh,'VMF3')   ||   strcmpi(settings.TROPO.mfw,'VMF3')   ||   strcmpi(settings.TROPO.Gh,'GRAD')   ||   strcmpi(settings.TROPO.Gw,'GRAD')
        
        % only proceed if the year is >= 1980 and the date is at least 2 days behind the current date, otherwise use GPT3
        current_time = clock;
        current_jd = cal2jd_GT(current_time(1),current_time(2),current_time(3));
        if obs.startdate(1) < 1980   ||   obs.startdate_jd+2 > current_jd
            
            if obs.startdate(1) < 1980
                fprintf('%s%4.0f%s\n' , 'No VMF3 data available for the year ',obs.startdate(1),' => GPT3 used instead!');
            elseif obs.startdate_jd+2 > current_jd
                fprintf('%s\n' , 'VMF3 data is only available with 1 day latency => GPT3 used instead!');
            end
            
            if strcmpi(settings.TROPO.zhd,'VMF3')
                settings.TROPO.zhd = 'p (GPT3) + Saastamoinen';
            end
            if strcmpi(settings.TROPO.zwd,'VMF3')
                settings.TROPO.zwd = 'e (GPT3) + Askne';
            end
            if strcmpi(settings.TROPO.mfh,'VMF3')
                settings.TROPO.mfh = 'GPT3';
            end
            if strcmpi(settings.TROPO.mfw,'VMF3')
                settings.TROPO.mfw = 'GPT3';
            end
            if strcmpi(settings.TROPO.Gh,'GRAD')
                settings.TROPO.Gh = 'GPT3';
            end
            if strcmpi(settings.TROPO.Gw,'GRAD')
                settings.TROPO.Gw = 'GPT3';
            end
            
        else
            
            input = get_V3GR(obs, input, settings);    % call the function which handles VMF3+GRAD
            
        end
        
    end
end


% Check if the in situ meteo values are realistic and give messages, if not
if (settings.TROPO.p<300   ||   settings.TROPO.p>1150)
    answer = questdlg('The inserted in situ pressure is unrealistic. Do you really want to continue?');
    if ~strcmpi(answer,'yes')
        error('The execution was stopped by the user.');
    end
end
if (settings.TROPO.T<-60   ||   settings.TROPO.T>55)
    answer = questdlg('The inserted in situ temperature is unrealistic. Do you really want to continue?');
    if ~strcmpi(answer,'yes')
        error('The execution was stopped by the user.');
    end
end
if (settings.TROPO.q<0   ||   settings.TROPO.q>100)
    answer = questdlg('The inserted in situ relative humidity is unrealistic. Do you really want to continue?');
    if ~strcmpi(answer,'yes')
        error('The execution was stopped by the user.');
    end
end


% read trop-files from IGS, if specified
if strcmpi(settings.TROPO.zhd,'Tropo file')   ||   strcmpi(settings.TROPO.zwd,'Tropo file')
    [settings, input] = getTropoFile (obs, settings, input);
end


% read the GPT3 grid (this is done here in the end of the troposphere section, because perhaps GPT3 was defined as backup in the code above)
if strcmpi(settings.TROPO.zhd,'p (GPT3) + Saastamoinen')   ||   strcmpi(settings.TROPO.zwd,'e (GPT3) + Askne')   ||   strcmpi(settings.TROPO.zwd,'e (in situ) + Askne')   ||   strcmpi(settings.TROPO.mfh,'GPT3')   ||   strcmpi(settings.TROPO.mfw,'GPT3')   ||   strcmpi(settings.TROPO.zhd,'Tropo file')   ||   strcmpi(settings.TROPO.Gh,'GPT3')   ||   strcmpi(settings.TROPO.Gw,'GPT3')
    input.TROPO.GPT3.cell_grid = gpt3_5_fast_readGrid;
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
    if strcmpi(settings.IONO.source,'IONEX File')   % Ionex-File
        input.IONO.ionex = read_ionex_TUW(path_ionex);
    elseif strcmpi(settings.IONO.source,'CODE Spherical Harmonics')   % CODE ion file
        input.IONO.ion = read_ion(settings.IONO.file_ion);
    end
end

% Check if coefficients from broadcast navigation message are needed for
% ionospheric correction (e.g. Klobuchar, NeQuick)
bool_nav_klo = strcmpi(settings.IONO.source,'Klobuchar model') && (~isfield(input, 'IONO') || ~isfield(input.IONO, 'klob_coeff') || isempty(input.IONO.klob_coeff));
bool_nav_neq = strcmpi(settings.IONO.source,'NeQuick model')   && (~isfield(input, 'IONO') || ~isfield(input.IONO, 'nequ_coeff') || isempty(input.IONO.nequ_coeff));

% if Klobuchar is activated check if coefficients are read in
if bool_nav_klo || bool_nav_neq
    [input.IONO.klob_coeff, input.IONO.nequ_coeff] = read_nav_iono(settings.ORBCLK.file_nav_multi);
end

% if NeQuick model is to be applied, then read and save some of its coefficients already here
if (strcmpi(settings.IONO.model,'Estimate with ... as constraint')   ||   strcmpi(settings.IONO.model,'Correct with ...')) ...
        && strcmpi(settings.IONO.source,'NeQuick model')   &&   bool_nav_neq
    
    % load ccir-File
    month_str = num2str(obs.startdate(2)+10);
    load(['pdF2_',    month_str, '.mat'], 'pdF2_1',    'pdF2_2');
    input.IONO.pdF2_1 = pdF2_1;
    input.IONO.pdF2_2 = pdF2_2;
    load(['pdM3000_', month_str, '.mat'], 'pdM3000_1', 'pdM3000_2');
    input.IONO.pdM3000_1 = pdM3000_1;
    input.IONO.pdM3000_2 = pdM3000_2;
    
    % load modip-file
    input.IONO.modip = load('modip.mat', 'modip');
    input.IONO.modip = input.IONO.modip.modip;
    
end



%% Models - Biases

% ----- Code -----
% -) read SINEX-Bias-File when
%   - CAS or DLR Multi-GNSS DCBs for code biases
%   - CODE OSB File
%   - manually selected SINEX-Bias-File for code biases
%   - CNES Archive for code and phase biases
bool_sinex = any(strcmp(settings.BIASES.code, ...
    {'CAS Multi-GNSS DCBs','CAS Multi-GNSS OSBs','DLR Multi-GNSS DCBs','CODE OSBs','CNES OSBs','CODE MGEX','WUM MGEX','CNES MGEX','GFZ MGEX','CNES postprocessed'}));
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
    [obs] = assign_sinex_biases(obs, input, settings);
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
        [obs] = assign_sinex_biases(obs, input, settings);
        
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
        settings.OTHER.ocean_loading = false; 	% station was not found in OceanLoading.blq
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
    fprintf('  %s%s\n','zhd: ',settings.TROPO.zhd);
    if strcmpi(settings.TROPO.zhd,'p (in situ) + Saastamoinen')
        fprintf('    %s%7.2f%s\n','p: ',settings.TROPO.p,' hPa');
    end
    fprintf('  %s%s\n','zwd: ',settings.TROPO.zwd);
    if strcmpi(settings.TROPO.zwd,'e (in situ) + Askne')
        fprintf('    %s%5.2f%s\n','q: ',settings.TROPO.q,' %');
        fprintf('    %s%6.2f%s\n','T: ',settings.TROPO.T,' °C')
    end
    fprintf('  %s%s\n','mfh: ',settings.TROPO.mfh)
    fprintf('  %s%s\n','mfw: ',settings.TROPO.mfw)
    fprintf('  %s%s\n','Gn_h & Ge_h: ',settings.TROPO.Gh)
    fprintf('  %s%s\n','Gn_w & Ge_w: ',settings.TROPO.Gw)
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
    fprintf('  %s\n','Code:');       % CODE
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
    fprintf('  %s\n', 'Phase:');     % PHASE
    switch settings.BIASES.phase
        case 'off'
            fprintf('    No (additional) phase biases selected\n')
        case 'Correction Stream'
            fprintf('    Correction Stream\n')
        otherwise
            fprintf(['    ' settings.BIASES.phase ':   ' settings.BIASES.phase_file '\n'])
    end
    fprintf('\n');
    
    
    % Other corrections
    fprintf('%s\n','Other corrections:');
    fprintf('  Antex-File: %s\n', settings.OTHER.file_antex);
    fprintf('\n');
end



