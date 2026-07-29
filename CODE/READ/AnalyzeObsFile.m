function [] = AnalyzeObsFile(settings)
% This function performs a raw analysis of a RINEX file or a file 
% containing raw Android sensor data and, thereby, uses many function from 
% raPPPid. 
% 
% INPUT:
%   settings        struct, settings from GUI
% OUTPUT:
%	...
%
% Revision:
%   2025/08/14, MFWG: switch to cal2gpstime
%
% using distinguishable_colors.m (c) 2010-2011, Tim Holy
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


fprintf('\n--------------------------------------------------------\n\n')

% Create waitbar with option to cancel
f = waitbar(0,'Reading header...','Name','Analyzing Observation File', 'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
setappdata(f,'canceling',0);

% read header
[obs] = anheader(settings);     % RINEX file
if isempty(obs)                 % Android raw data
    [obs] = analyzeAndroidRawData(settings.INPUT.file_obs, settings);
end

% read observation file
if obs.rinex_version > 0
    bool_RINEX = true;      % RINEX file
    [OBSDATA, newdataepoch] = readRINEX(settings.INPUT.file_obs, obs.rinex_version);
    n = numel(newdataepoch);
    fprintf('\nRINEX version: %.2f',  obs.rinex_version_full)
else
    bool_RINEX = false;     % raw Android sensor data
    [OBSDATA, newdataepoch, IMUDATA] = readAndroidRawSensorData(settings.INPUT.file_obs, settings.KINE.bool_IMU, obs.vars_raw);
    n = numel(newdataepoch) - 1;
    fprintf('\nRaw Android sensor data')
end
    
% print some information
fprintf('\nStation: %s',  obs.stationname);
fprintf('\nReceiver: %s', obs.receiver_type);
fprintf('\nAntenna: %s',  obs.antenna_type);

% print observation types (e.g., indicated in RINEX header)
fprintf('\n\nObservation types (RINEX notation) according to header\n')
if obs.rinex_version == 3 || obs.rinex_version == 0
    fprintf('GPS: '); print_obs_types(obs.types_gps_3,  3);
    fprintf('GLO: '); print_obs_types(obs.types_glo_3,  3);
    fprintf('GAL: '); print_obs_types(obs.types_gal_3,  3);
    fprintf('BDS: '); print_obs_types(obs.types_bds_3,  3);
    fprintf('QZSS:'); print_obs_types(obs.types_qzss_3, 3);
else
    fprintf('GPS: '); print_obs_types(obs.types_gps,  2);
    fprintf('GLO: '); print_obs_types(obs.types_glo,  2);
    fprintf('GAL: '); print_obs_types(obs.types_gal,  2);
    fprintf('BDS: '); print_obs_types(obs.types_bds,  2);
    fprintf('QZSS:'); print_obs_types(obs.types_qzss, 2);
end

% Start-date in different time-formats
hour = obs.startdate(4) + obs.startdate(5)/60 + obs.startdate(6)/3600;
obs.startdate_jd = cal2jd_GT(obs.startdate(1),obs.startdate(2), obs.startdate(3) + hour/24);
[obs.doy, ~] = jd2doy_GT(obs.startdate_jd);
[obs.startGPSWeek, obs.startSow] = cal2gpstime(obs.startdate);
% print startdate of observation file
fprintf('\nObservation start:\n')
t = datetime(obs.startdate(1), obs.startdate(2), obs.startdate(3), ...
    obs.startdate(4), obs.startdate(5), obs.startdate(6), 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
fprintf('  %s | %d/%d | %d/%03d\n', t, obs.startGPSWeek, floor(obs.startSow/86400), obs.startdate(1), floor(obs.doy))


fprintf('\n%s%.0f', 'Total number of epochs: ', n);                     % number of epochs
fprintf('\n%s%.3f', 'Observation interval [s]: ', obs.interval);      % observation interval
fprintf('\n%s%.2f\n', 'Approximate length [hours]: ', n*obs.interval/3600);    % length of RINEX file in hours

% hardcode some settings
settings.PROC.timeFrame(2) = 1; settings.PROC.timeFrame(2) = n;
settings.PROC.epochs(1) = 1; settings.PROC.epochs(2) = n;
settings.INPUT.num_freqs = max([ ... 
    settings.INPUT.use_GPS *numel(settings.INPUT.gps_freq (~strcmpi(settings.INPUT.gps_freq, 'OFF'))), ...
    settings.INPUT.use_GLO *numel(settings.INPUT.glo_freq (~strcmpi(settings.INPUT.glo_freq, 'OFF'))), ...
    settings.INPUT.use_GAL *numel(settings.INPUT.gal_freq (~strcmpi(settings.INPUT.gal_freq, 'OFF'))), ...
    settings.INPUT.use_BDS *numel(settings.INPUT.bds_freq (~strcmpi(settings.INPUT.bds_freq, 'OFF'))), ...
    settings.INPUT.use_QZSS*numel(settings.INPUT.qzss_freq(~strcmpi(settings.INPUT.qzss_freq,'OFF')))]);
settings.INPUT.proc_freqs = settings.INPUT.num_freqs;
settings.PROC.method = 'Code + Phase + Doppler';
settings.IONO.model = 'off';
settings.EXP.satellites_D = 1;
settings.INPUT.rawDataAndroid = false;
settings.INPUT.bool_realtime = false;
settings.OTHER.mp_doppler = true;

% Prepare variables
[Epoch, satellites, storeData, ~, ~, ~] = initProcessing(settings, obs);

% Looking for the observation types and the right column number (create obs.use_column)
obs = find_obs_col(obs, settings);
% save and print information to obs and command window
obs = SavePrintObsType(obs, settings);
fprintf('\n');

obs_count = zeros(5, max([length(obs.types_gps_3), length(obs.types_glo_3), length(obs.types_gal_3), length(obs.types_bds_3), length(obs.types_qzss_3)])/3);
obs_missing = obs_count; 

%% LOOP OVER OBSERVATION DATA
for q = 1:n
    old_gps_time = Epoch.gps_time;          % save to check for identical observation records
    
    % get observations
    [Epoch] = EpochlyReset_Epoch(Epoch);    
    if bool_RINEX
        [Epoch] = RINEX2Epoch(OBSDATA, newdataepoch, Epoch, q, obs.no_obs_types, obs.rinex_version, settings);
    else
        [Epoch] = RawSensor2Epoch(OBSDATA, IMUDATA, newdataepoch, q, obs.vars_raw, Epoch, settings, obs.use_column, obs.leap_sec);
    end
    
    % check for identical observation data records
    if old_gps_time == Epoch.gps_time
        fprintf(2, ['Duplicate epoch: ' Epoch.rinex_header '\n'])
    end
    % check if epoch data is usable
    if ~Epoch.usable
        storeData.gpstime(q,1) = Epoch.gps_time;
        continue
    end

    obs.glo_channel(isnan(obs.glo_channel)) = 0;
    % -> frequency of GLONASS satellites is not correct but otherwise
    % GLONASS is not analyzed correctly
    Epoch = RemoveSort(settings, Epoch, q);
    [Epoch, obs] = prepareObservations(settings, obs, Epoch);

    % save relevant data
    prns = Epoch.sats;
    % increase epoch counter
    Epoch.tracked(prns) = Epoch.tracked(prns) + 1;
    % save Carrier-to-Noise density
    if ~isempty(Epoch.S1); satellites.SNR_1(q,prns) = Epoch.S1'; end
    if ~isempty(Epoch.S2); satellites.SNR_2(q,prns) = Epoch.S2'; end
    if ~isempty(Epoch.S3); satellites.SNR_3(q,prns) = Epoch.S3'; end
    % save Doppler measurements
    if ~isempty(Epoch.D1)
        Epoch.D1 = Epoch.D1 ./ Epoch.l1;        % convert back to [Hz]
        satellites.D1(q,prns) = Epoch.D1'; 
    end
    if ~isempty(Epoch.D2) 
        Epoch.D2 = Epoch.D2 ./ Epoch.l2;        % convert back to [Hz]
        satellites.D2(q,prns) = Epoch.D2'; 
    end
    if ~isempty(Epoch.D3) 
        Epoch.D3 = Epoch.D3 ./ Epoch.l3;        % convert back to [Hz]
        satellites.D3(q,prns) = Epoch.D3'; 
    end
    % observations
    storeData.C1(q,prns) = Epoch.C1;
    storeData.C1_bias(q,prns) = Epoch.C1_bias;
    if ~isempty(Epoch.C2); storeData.C2(q,prns) = Epoch.C2; end
    if ~isempty(Epoch.C3); storeData.C3(q,prns) = Epoch.C3; end
    if ~isempty(Epoch.L1); storeData.L1(q,prns) = Epoch.L1; end
    if ~isempty(Epoch.L2); storeData.L2(q,prns) = Epoch.L2; end
    if ~isempty(Epoch.L3); storeData.L3(q,prns) = Epoch.L3; end
    satellites.obs(q,prns)  = Epoch.tracked(prns);  	% save number of epochs satellite is tracked
    % time
    storeData.gpstime(q,1) = Epoch.gps_time;
    % tracked satellites
    satellites.obs(q,prns)  = Epoch.tracked(prns);  	% save number of epochs satellite is tracked
    % pseudorange rate check with Doppler
    if ~isempty(Epoch.old.sats)
        [Epoch.mp_DopplerPR, ~] = DopplerCheckPR(Epoch, settings.INPUT.num_freqs, settings.OTHER.mp_doppler_thresh, settings.IONO.model);
        storeData.mp_DopplerPR_1(q,prns) = Epoch.mp_DopplerPR(1,:);
        if settings.INPUT.num_freqs >= 2; storeData.mp_DopplerPR_2(q,prns) = Epoch.mp_DopplerPR(2,:); end
        if settings.INPUT.num_freqs >= 3; storeData.mp_DopplerPR_3(q,prns) = Epoch.mp_DopplerPR(3,:); end
    end

    % count observations for all observation types and each GNSS
    if q == 1 && size(Epoch.obs, 2) > size(obs_count, 2)
        obs_count = zeros(5, size(Epoch.obs, 2)); obs_missing = obs_count;
    end
    [obs_count, obs_missing] = countObservations(obs_count, obs_missing, 1, Epoch.gps, Epoch.obs);
    [obs_count, obs_missing] = countObservations(obs_count, obs_missing, 2, Epoch.glo, Epoch.obs);
    [obs_count, obs_missing] = countObservations(obs_count, obs_missing, 3, Epoch.gal, Epoch.obs);
    [obs_count, obs_missing] = countObservations(obs_count, obs_missing, 4, Epoch.bds, Epoch.obs);
    [obs_count, obs_missing] = countObservations(obs_count, obs_missing, 5, Epoch.qzss,Epoch.obs);
    
    % handle waitbar
    if mod(q,5) == 0
        % Check for clicked Cancel button
        if getappdata(f,'canceling'); delete(f); return; end
        % Update waitbar
        waitbar(q/n,f,sprintf('Progress: %.2f%%',q/n*100))
    end
end

% kill waitbar
delete(f)


%% PERCENTAGE OF OBSERVATIONS
perc = 100 - obs_missing./obs_count * 100;
fprintf('\nPercentage of observations in RINEX file:')
if settings.INPUT.use_GPS
    fprintf('\nGPS:');     printObsPercentage(obs.types_gps_3, perc(1,:));
end
if settings.INPUT.use_GLO
    fprintf('\nGLONASS:'); printObsPercentage(obs.types_glo_3, perc(2,:));
end
if settings.INPUT.use_GAL
    fprintf('\nGalileo:'); printObsPercentage(obs.types_gal_3, perc(3,:));
end
if settings.INPUT.use_BDS
    fprintf('\nBeiDou:');  printObsPercentage(obs.types_bds_3, perc(4,:));
end
if settings.INPUT.use_QZSS
    fprintf('\nQZSS:');    printObsPercentage(obs.types_qzss_3,perc(5,:));
end
fprintf('\n\n')


%% PLOTS
rgb = createDistinguishableColors(40);      % colors for plot, no GNSS has more than 40 satellites
% GNSS to invastigate
isGPS  = settings.INPUT.use_GPS;          
isGLO  = settings.INPUT.use_GLO;
isGAL  = settings.INPUT.use_GAL;
isBDS  = settings.INPUT.use_BDS;
isQZSS = settings.INPUT.use_QZSS;
% create some time variables
epochs = 1:numel(storeData.gpstime);       % vector, 1:#epochs
sow = storeData.gpstime;        % time of epochs in seconds of week
sow = round(10*sow)/10;         % needed if observation in RINEX are not to full second
seconds = sow - sow(1);
hours = seconds / 3600;
[~, hour, min, sec] = sow2dhms(storeData.gpstime(1));
label_x_sec = ['[s], 1st Epoch: ', sprintf('%02d',hour),   'h:',   sprintf('%02d',min),   'm:',   sprintf('%02.0f',sec),   's'];
label_x_h   = ['[h], 1st Epoch: ', sprintf('%02d',hour),   'h:',   sprintf('%02d',min),   'm:',   sprintf('%02.0f',sec),   's'];
label_x_time =  ['Time, 1st Epoch: ', sprintf('%02d',hour),   'h:',   sprintf('%02d',min),   'm:',   sprintf('%02.0f',sec),   's'];
label_x_epc = 'Epochs';
% get stored observations
C1 = storeData.C1; C1(C1==0) = NaN;
C2 = storeData.C2; C2(C2==0) = NaN;
C3 = storeData.C3; C3(C3==0) = NaN;
L1 = storeData.L1; L1(L1==0) = NaN;
L2 = storeData.L2; L2(L2==0) = NaN;
L3 = storeData.L3; L3(L3==0) = NaN;


%     -+-+-+-+- Figures: Signal Quality Plots  -+-+-+-+-
satellites.CL_1 = C1 - L1;
satellites.CL_2 = C2 - L2;
satellites.CL_3 = C3 - L3;
signQualPlot(satellites, label_x_h, hours, isGPS, isGLO, isGAL, isBDS, isQZSS, settings, rgb);


% -+-+-+-+- Figure: Satellite Visibility Plot -+-+-+-+-
vis_plotSatConstellation(hours, epochs, label_x_h, satellites, storeData.exclude, isGPS, isGLO, isGAL, isBDS, isQZSS)


if obs.interval <= 15 	% this plots make only sense for high-rate observation data
    
    print_std = true;       % true to print observation difference standard devation
    
    % -+-+-+-+- Figure: Code Difference  -+-+-+-+-
    degree_C = settings.OTHER.mp_degree;
    mp_C1_diff_n = NaN(n,410); mp_C2_diff_n = NaN(n,410); mp_C3_diff_n = NaN(n,410);   	
    mp_C1_diff_n(degree_C+1:end,:) = diff(C1, degree_C,1); % code difference (C1) of last n epochs
    PlotObsDiff(epochs, mp_C1_diff_n, label_x_epc, rgb, 'C1' , settings, satellites.obs, settings.OTHER.mp_thresh, settings.OTHER.mp_degree, '[m]', print_std, obs);
    mp_C2_diff_n(degree_C+1:end,:) = diff(C2, degree_C,1);
    PlotObsDiff(epochs, mp_C2_diff_n, label_x_epc, rgb, 'C2' , settings, satellites.obs, settings.OTHER.mp_thresh, settings.OTHER.mp_degree, '[m]', print_std, obs);
    mp_C3_diff_n(degree_C+1:end,:) = diff(C3, degree_C,1);
    PlotObsDiff(epochs, mp_C3_diff_n, label_x_epc, rgb, 'C3' , settings, satellites.obs, settings.OTHER.mp_thresh, settings.OTHER.mp_degree, '[m]', print_std, obs);
    
    % -+-+-+-+- Figure: Phase Difference  -+-+-+-+-
    degree_L = settings.OTHER.CS.TD_degree;	
    cs_L1_diff = NaN(n,410); cs_L2_diff = NaN(n,410); cs_L3_diff = NaN(n,410); 
    cs_L1_diff(degree_L+1:end,:) = diff(L1, degree_L,1); % phase (L1) difference of last n epochs
    PlotObsDiff(epochs, cs_L1_diff, label_x_epc, rgb, 'L1' , settings, satellites.obs, settings.OTHER.CS.TD_threshold, settings.OTHER.CS.TD_degree, '[m]', print_std, obs);
    cs_L2_diff(degree_L+1:end,:) = diff(L2, degree_L,1);
    PlotObsDiff(epochs, cs_L2_diff, label_x_epc, rgb, 'L2' , settings, satellites.obs, settings.OTHER.CS.TD_threshold, settings.OTHER.CS.TD_degree, '[m]', print_std, obs);
    cs_L3_diff(degree_L+1:end,:) = diff(L3, degree_L,1); 
    PlotObsDiff(epochs, cs_L3_diff, label_x_epc, rgb, 'L3' , settings, satellites.obs, settings.OTHER.CS.TD_threshold, settings.OTHER.CS.TD_degree, '[m]', print_std, obs);
    
    % -+-+-+-+- Figure: Doppler Difference  -+-+-+-+-
    degree_D = 3;
    if isfield(satellites, 'D1')
        D1 = satellites.D1; D1(D1==0) = NaN;
        D1_diff = NaN(n,410);
        D1_diff(degree_D+1:end,:) = diff(D1, degree_D,1);  	% Doppler (D1) difference of last n epochs
        PlotObsDiff(epochs, D1_diff, label_x_epc, rgb, 'D1' , settings, satellites.obs, NaN, settings.OTHER.CS.TD_degree, '[Hz]', print_std, obs);
    end
    if isfield(satellites, 'D2')
        D2 = satellites.D2; D2(D2==0) = NaN;
        D2_diff = NaN(n,410);
        D2_diff(degree_D+1:end,:) = diff(D2, degree_D,1);
        PlotObsDiff(epochs, D2_diff, label_x_epc, rgb, 'D2' , settings, satellites.obs, NaN, settings.OTHER.CS.TD_degree, '[Hz]', print_std, obs);
    end
    if isfield(satellites, 'D3')
        D3 = satellites.D3; D3(D3==0) = NaN;
        D3_diff = NaN(n,410);
        D3_diff(degree_D+1:end,:) = diff(D3, degree_D,1);
        PlotObsDiff(epochs, D3_diff, label_x_epc, rgb, 'D3' , settings, satellites.obs, NaN, settings.OTHER.CS.TD_degree, '[Hz]', print_std, obs);
    end

    %     -+-+-+-+- Figures: Pseudorange Rate Check with Doppler  -+-+-+-+-
    PlotPseudorangeRateCheck(storeData, settings, satellites, epochs, label_x_epc, rgb)

end




% check for huge discrepancy between code and phase observations
bool_adjustphase2code = false;	fprintf('\n');
if any(satellites.CL_1(:) > 1e4)
    fprintf(2, 'Huge difference between code and phase on frequency 1!\n')
    bool_adjustphase2code = true;
end
if any(satellites.CL_2(:) > 1e4)
    fprintf(2, 'Huge difference between code and phase on frequency 2!\n')
    bool_adjustphase2code = true;
end
if any(satellites.CL_3(:) > 1e4)
    fprintf(2, 'Huge difference between code and phase on frequency 3!\n')
    bool_adjustphase2code = true;
end
if bool_adjustphase2code
    fprintf(2, 'Please activate "Adjust phase to code" (Run > Processing Options).\n')
end



% %% IGS satellite metadata file
% SATS = AnalyzeSatelliteMetadataFileIGS(obs.startdate(1), obs.doy);
% assignin('base', 'SATS', SATS)


fprintf('\n--------------------------------------------------------\n\n')


%% AUXILIARY FUNCTIONS
function [obs_count, obs_missing] = countObservations(obs_count, obs_missing, idx, bool_gnss, obsmatrix)
% add number of observation, which should exist (equals #sats)
obs_count(idx, :) = obs_count(idx, :) + sum(bool_gnss);     
% determine how many observations are missing for all observation types
obs_gnss = obsmatrix(bool_gnss, :);             % observation matrix for this GNSS
missing = isnan(obs_gnss) | obs_gnss == 0;      % check for missing observations
obs_missing(idx, :) = obs_missing(idx, :) + sum(missing);   % count missing observations

function [] = printObsPercentage(obs_types, perc)
% print the percentage of existing observations for all signals 
if isempty(obs_types); fprintf('\n'); return; end
% convert observation types to cell
obs_types = cellstr(reshape(obs_types, 3, numel(obs_types)/3)');
% extract the second character (RINEX frequency number)
char_2 = cellfun(@(x) x(2), obs_types);
% obtain the sorting index
[~, idx] = sort(char_2);
% Sort the observation types and percentages
obs_types_ = obs_types(idx);
perc = perc(idx);
perc(perc < 0 | isnan(perc)) = 0;   % replace NaN and negative percentages with zero
% loop to print to command window
curr_frq = '0'; cc = 0;     % initialize current printed frequency and counter
for i = 1 : numel(obs_types_)
    % get observation type
    type = obs_types_{i};
    % potentially go to next line
    if type(2) ~= curr_frq || mod(cc,5) == 0
        fprintf('\n  ');
        curr_frq = type(2); 
        cc = 0;
    end    
    % print observation type and percentage
    fprintf(type);
    fprintf('% 7.2f%%,  ', perc(i));
    cc = cc + 1;    % increase counter
end

function [] = print_obs_types(obs_type_string, v)
% print observation types from RINEX header
if isempty(obs_type_string) 
    fprintf('\n');      % GNSS was not recorded
    return
end
n = numel(obs_type_string);
for i = 1:v:n           % loop to print 
    fprintf('%s ', obs_type_string(i:i+v-1));
end
fprintf('\n');




