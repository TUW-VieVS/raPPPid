function [multiSats, multiData, multiObs, multiSetts] = stack_data4plot(paths, PLOT)
% This function puts the variable storeData from multiple processings
% together. This makes it possible to use single plots over multiple
% days/processings.
%
% INPUT:
%	paths       cell, containing file-paths to data4plot.mat as string
%   PLOT        struct, containing booleans which plots are enabled
% OUTPUT:
%   satellites
%	multiData   struct, stacked storeData´s from the files from paths
%   obs
%   settings
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| some plots are not working for different station:
% Coordinate, Three Coordinates, Map, UTM
% ||| some other make no sense (?) or there are lines fron end to beginning
% check and change (?)
% ||| also for the same station the same true coordinate is taken for the
% whole period


% initialize multiData
multiData = [];
% number of files
no_files = numel(paths);
% number of already stacked epochs
eps_stacked = 0;
% create waitbar
WBAR = waitbar(0, 'Stacking data4plot.mat...', 'Name','Progress of stacking data4plot.mat');
global STOP_CALC
STOP_CALC = 0;

% check which variables of the structs storeData and satellites are needed
% for plotting and only stack those
[l1,l2] = CheckNeededVariables(PLOT);


% loop over files
for i = 1:no_files
    % check for STOP from raPPPid GUI
    if STOP_CALC; break; end
    
    % load data4plot.mat ('storeData', 'obs', 'satellites', 'settings') of current processing
    try
        fpath = GetFullPath([paths{i} 'data4plot.mat']);
        load(fpath, 'storeData', 'obs', 'satellites', 'settings');
    catch;  	continue;    end
    
    % update waitbar
    if ishandle(WBAR)
        station_date = [obs.stationname, ' ', sprintf('%4.0f',obs.startdate(1)), '/', sprintf('%03.0f',floor(obs.doy))];
        mess1 = ['Current File: ' station_date];
        progress = i/no_files;      % 1/100 [%]
        mess2 = sprintf('%02.2f%s', progress*100, '% of data stacking are finished.');
        waitbar(progress, WBAR, {mess1 mess2})
    end
    
    % convert [sow] -> [s] of GPS time
    storeData.gpstime = storeData.gpstime + obs.startGPSWeek * 604800;
    
    % number of epochs current data
    eps = numel(storeData.gpstime);
    
    if i == 1           % multiData is empty
        multiData = storeData;
        multiSats = satellites;
        multiObs = obs;
        multiObs.file(1:eps,1) = 1;
        multiSetts = settings;
        eps_stacked = settings.PROC.timeFrame(2);
        continue
    end
    
    % check where this storeData has to be inserted into multiData
    if multiData.gpstime(end) < storeData.gpstime(1)
        % just append, all of multiData is before the new data
        idx = numel(multiData.gpstime) + 1;
    else
        % find location to insert
        bool = multiData.gpstime < storeData.gpstime(1);
        idx = find(bool, 1, 'last') - 1;
        if isempty(idx); idx = 1; end
    end
    
    
    %% stack storeData into multiData
    % insert: normal variables
    n = numel(l1);
    for f_i = 1:n
        field = l1{f_i};
        multiData = insertData(multiData, storeData, field, idx);
    end
    % reset variable
    add_reset_epochs = storeData.float_reset_epochs + eps_stacked;
    multiData.float_reset_epochs = [multiData.float_reset_epochs, add_reset_epochs];
    
    
    %% stack satellites into MultiSats
    n = numel(l2);
    for f_i = 1:n
        field = l2{f_i};
        multiSats = insertData(multiSats, satellites, field, idx);
    end
    
    
    %% stack obs into multiObs
    multiObs.startdate(end+1, :) = obs.startdate;
    multiObs.startdate_jd(end+1, :) = obs.startdate_jd;
    multiObs.doy(end+1) = obs.doy;
    if ~strcmp(multiObs.stationname, obs.stationname)
        multiObs.stationname = 'MULTI';
    end
    if settings.INPUT.use_GPS
        multiObs = checkString(multiObs, obs, 'GPS', 'C1');
        multiObs = checkString(multiObs, obs, 'GPS', 'C2');
        multiObs = checkString(multiObs, obs, 'GPS', 'C3');
        multiObs = checkString(multiObs, obs, 'GPS', 'L1');
        multiObs = checkString(multiObs, obs, 'GPS', 'L2');
        multiObs = checkString(multiObs, obs, 'GPS', 'L3');
    end
    if settings.INPUT.use_GLO
        multiObs = checkString(multiObs, obs, 'GLO', 'C1');
        multiObs = checkString(multiObs, obs, 'GLO', 'C2');
        multiObs = checkString(multiObs, obs, 'GLO', 'C3');
        multiObs = checkString(multiObs, obs, 'GLO', 'L1');
        multiObs = checkString(multiObs, obs, 'GLO', 'L2');
        multiObs = checkString(multiObs, obs, 'GLO', 'L3');
    end
    if settings.INPUT.use_GAL
        multiObs = checkString(multiObs, obs, 'GAL', 'C1');
        multiObs = checkString(multiObs, obs, 'GAL', 'C2');
        multiObs = checkString(multiObs, obs, 'GAL', 'C3');
        multiObs = checkString(multiObs, obs, 'GAL', 'L1');
        multiObs = checkString(multiObs, obs, 'GAL', 'L2');
        multiObs = checkString(multiObs, obs, 'GAL', 'L3');
    end
    if settings.INPUT.use_BDS
        multiObs = checkString(multiObs, obs, 'BDS', 'C1');
        multiObs = checkString(multiObs, obs, 'BDS', 'C2');
        multiObs = checkString(multiObs, obs, 'BDS', 'C3');
        multiObs = checkString(multiObs, obs, 'BDS', 'L1');
        multiObs = checkString(multiObs, obs, 'BDS', 'L2');
        multiObs = checkString(multiObs, obs, 'BDS', 'L3');
    end
    % save information of file number
    multiObs.file(idx:(idx-1+eps),1) = i;
    
    
    %% stack settings into multiSetts
    % logical variables
    multiSetts.INPUT.use_GPS = multiSetts.INPUT.use_GPS && settings.INPUT.use_GPS;
    multiSetts.INPUT.use_GLO = multiSetts.INPUT.use_GLO && settings.INPUT.use_GLO;
    multiSetts.INPUT.use_GAL = multiSetts.INPUT.use_GAL && settings.INPUT.use_GAL;
    multiSetts.INPUT.use_BDS = multiSetts.INPUT.use_BDS && settings.INPUT.use_BDS;
    multiSetts.AMBFIX.bool_AMBFIX =  multiSetts.AMBFIX.bool_AMBFIX &&  settings.AMBFIX.bool_AMBFIX;
    multiSetts.BIASES.estimate_rec_dcbs = multiSetts.BIASES.estimate_rec_dcbs && settings.BIASES.estimate_rec_dcbs;
    multiSetts.OTHER.CS.l1c1 = multiSetts.OTHER.CS.l1c1 && settings.OTHER.CS.l1c1;
    multiSetts.OTHER.CS.DF = multiSetts.OTHER.CS.DF && settings.OTHER.CS.DF;
    multiSetts.OTHER.CS.Doppler = multiSetts.OTHER.CS.Doppler && settings.OTHER.CS.Doppler;
    try
    multiSetts.OTHER.CS.TimeDifference = multiSetts.OTHER.CS.TimeDifference && settings.OTHER.CS.TimeDifference;
    end
    % other variables
    multiSetts = checkString(multiSetts, settings, 'PROC', 'method');
    multiSetts = checkString(multiSetts, settings, 'IONO', 'model');
    multiSetts = checkString3(multiSetts, settings, 'ADJ', 'filter','type');
    multiSetts = checkValue(multiSetts, settings, 'AMBFIX', 'start_WL');
    multiSetts = checkValue(multiSetts, settings, 'AMBFIX', 'start_NL');
    multiSetts = checkValue(multiSetts, settings, 'AMBFIX', 'cutoff');
    multiSetts = checkValue(multiSetts, settings, 'INPUT', 'proc_freqs');
    multiSetts = checkValue3(multiSetts, settings, 'ADJ', 'filter', 'var_amb');
    multiSetts = checkValue3(multiSetts, settings, 'OTHER', 'CS', 'l1c1_window');
    multiSetts = checkValue3(multiSetts, settings, 'OTHER', 'CS', 'l1c1_threshold');
    multiSetts = checkValue3(multiSetts, settings, 'OTHER', 'CS', 'DF_threshold');
    multiSetts = checkValue3(multiSetts, settings, 'OTHER', 'CS', 'D_threshold');
    
    % increase number of stacked epochs
    eps_stacked = eps_stacked + settings.PROC.timeFrame(2);
end


% close waitbar
if ishandle(WBAR);        close(WBAR);    end


%% AUXILIARY FUNCTIONS

function [l_sto, l_sat, l3, l4] = CheckNeededVariables(PLOT)
% Checks which fields of storeData and satellites need to be stacked for the selected plots
% INPUT:
% PLOT              plot settings
% OUTPUT:
% l_sto, l_sat    	cell with string, needed fields for storeData, satellites
l_sto = {}; l_sto{1} = 'gpstime'; l_sto{2} = 'dt_last_reset';
l_sat = {}; l3 = {}; l4 = {};
% check for each plot for the structs storeData and satellites
if PLOT.coordinate
    l_sto{end+1} = 'posFloat_utm';
    l_sto{end+1} = 'posFixed_utm';
end
if PLOT.map
    l_sto{end+1} = 'posFixed_geo';
    l_sto{end+1} = 'posFloat_geo';
end
if PLOT.coordxyz
    l_sto{end+1} = 'posFloat_utm';
    l_sto{end+1} = 'posFixed_utm';
end
if PLOT.XYZ
    l_sto{end+1} = 'param';
    l_sto{end+1} = 'xyz_fix';
end
if PLOT.UTM
    l_sto{end+1} = 'posFloat_utm';
    l_sto{end+1} = 'posFixed_utm';
end
if PLOT.elevation
    l_sto{end+1} = 'cutoff';
    l_sat{end+1} = 'elev';
end
if PLOT.satvisibility
    l_sto{end+1} = 'cutoff';
    l_sat{end+1} = 'obs';
end
if PLOT.float_amb                   % Float Ambiguity plots
    l_sto{end+1} = 'N_1';
    l_sto{end+1} = 'N_2';
    l_sto{end+1} = 'N_3';
end
if PLOT.fixed_amb                   % Fixed Ambiguity plots
    l_sto{end+1} = 'refSatGPS';
    l_sto{end+1} = 'refSatGAL';
    l_sto{end+1} = 'N_EW';
    l_sto{end+1} = 'N_WL';
    l_sto{end+1} = 'N_NL';
    l_sto{end+1} = 'N_EN';
    l_sto{end+1} = 'N_WL_12';
    l_sto{end+1} = 'N_NL_12';
    l_sto{end+1} = 'N_WL_23';
    l_sto{end+1} = 'N_NL_23';
    l_sto{end+1} = 'N_3';
    l_sto{end+1} = 'N_2';
    l_sto{end+1} = 'N_1';
    l_sat{end+1} = 'obs';
    l_sat{end+1} = 'elev';
end
if PLOT.clock                       % Clock plot
    l_sto{end+1} = 'param';
end
if PLOT.dcb
    l_sto{end+1} = 'param';         % DCB plot
end
if PLOT.wet_tropo
    l_sto{end+1} = 'param';
    l_sto{end+1} = 'zhd';
    l_sto{end+1} = 'zwd';
end
if PLOT.cov_info
    l_sto{end+1} = 'param_var';
end
if PLOT.cov_amb
    l_sat{end+1} = 'obs';
    l_sto{end+1} = 'N_var_1';
    l_sto{end+1} = 'N_var_2';
    l_sto{end+1} = 'N_var_3';
end
if PLOT.corr
    l_sto{end+1} = 'param_sigma';
    l_sat{end+1} = 'obs';
end
if PLOT.skyplot
    l_sat{end+1} = 'az';
    l_sat{end+1} = 'elev';
    l_sat{end+1} = 'SNR_1';
    l_sat{end+1} = 'SNR_2';
    l_sat{end+1} = 'SNR_3';
    l_sto{end+1} = 'residuals_code_1';
    l_sto{end+1} = 'residuals_phase_1';
    l_sto{end+1} = 'residuals_code_fix_1';
    l_sto{end+1} = 'residuals_phase_fix_1';
    l_sto{end+1} = 'residuals_code_2';
    l_sto{end+1} = 'residuals_phase_2';
    l_sto{end+1} = 'residuals_code_fix_2';
    l_sto{end+1} = 'residuals_phase_fix_2';
    l_sto{end+1} = 'residuals_code_3';
    l_sto{end+1} = 'residuals_phase_3';
    l_sto{end+1} = 'residuals_code_fix_3';
    l_sto{end+1} = 'residuals_phase_fix_3';
    l_sto{end+1} = 'mp1';
    l_sto{end+1} = 'mp2';
    l_sto{end+1} = 'iono_corr';
    l_sto{end+1} = 'iono_est';
end
if PLOT.residuals
    l_sto{end+1} = 'residuals_code_1';
    l_sto{end+1} = 'residuals_phase_1';
    l_sto{end+1} = 'residuals_code_fix_1';
    l_sto{end+1} = 'residuals_phase_fix_1';
    l_sto{end+1} = 'residuals_code_2';
    l_sto{end+1} = 'residuals_phase_2';
    l_sto{end+1} = 'residuals_code_fix_2';
    l_sto{end+1} = 'residuals_phase_fix_2';
    l_sto{end+1} = 'residuals_code_3';
    l_sto{end+1} = 'residuals_phase_3';
    l_sto{end+1} = 'residuals_code_fix_3';
    l_sto{end+1} = 'residuals_phase_fix_3';
    l_sat{end+1} = 'elev';
    l_sat{end+1} = 'obs';
end
if PLOT.DOP
    l_sto{end+1} = 'VDOP';
    l_sto{end+1} = 'PDOP';
    l_sto{end+1} = 'HDOP';
end
if PLOT.MPLC
    l_sto{end+1} = 'mp1';
    l_sto{end+1} = 'mp2';
    l_sat{end+1} = 'SNR_1';
    l_sat{end+1} = 'SNR_2';
    l_sat{end+1} = 'obs';
    l_sat{end+1} = 'elev';
end
if PLOT.iono
    l_sto{end+1} = 'iono_corr';
    l_sto{end+1} = 'iono_est';
    l_sat{end+1} = 'obs';    
    l_sat{end+1} = 'elev';
end
if PLOT.cs
    l_sto{end+1} = 'cs_pred_SF';
    l_sto{end+1} = 'cs_L1C1';
    l_sto{end+1} = 'cs_dL1dL2';
    l_sto{end+1} = 'cs_dL1dL3';
    l_sto{end+1} = 'cs_dL2dL3';
    l_sto{end+1} = 'cs_L1D1_diff';
    l_sto{end+1} = 'cs_L2D2_diff';
    l_sto{end+1} = 'cs_L3D3_diff';
end
if PLOT.appl_biases
    l_sto{end+1} = 'C1_bias';
    l_sto{end+1} = 'C2_bias';
    l_sto{end+1} = 'C3_bias';
    l_sto{end+1} = 'L1_bias';
    l_sto{end+1} = 'L2_bias';
    l_sto{end+1} = 'L3_bias';
end
if PLOT.signal_qual
    l_sat{end+1} = 'elev';
    l_sat{end+1} = 'CL_1';
    l_sat{end+1} = 'CL_2';
    l_sat{end+1} = 'CL_3';
    l_sat{end+1} = 'SNR_1';
    l_sat{end+1} = 'SNR_2';
    l_sat{end+1} = 'SNR_3';
end
if PLOT.res_sats
    l_sto{end+1} = 'residuals_code_1';
    l_sto{end+1} = 'residuals_phase_1';
    l_sto{end+1} = 'residuals_code_fix_1';
    l_sto{end+1} = 'residuals_phase_fix_1';
    l_sto{end+1} = 'residuals_code_2';
    l_sto{end+1} = 'residuals_phase_2';
    l_sto{end+1} = 'residuals_code_fix_2';
    l_sto{end+1} = 'residuals_phase_fix_2';
    l_sto{end+1} = 'residuals_code_3';
    l_sto{end+1} = 'residuals_phase_3';
    l_sto{end+1} = 'residuals_code_fix_3';
    l_sto{end+1} = 'residuals_phase_fix_3';
end
if PLOT.stream_corr
    % nothing needed
end
% remove multiple entries
l_sto = unique(l_sto);
l_sat = unique(l_sat);


function MultiStruct = checkString(MultiStruct, struct, f1, f2)
% checks if the fields are equal
if isfield(struct.(f1), f2)
    if ~strcmp(MultiStruct.(f1).(f2), struct.(f1).(f2))
        MultiStruct.(f1).(f2) = '';
    end
end

function MultiStruct = checkValue(MultiStruct, struct, f1, f2)
% checks if the fields are equal
if isfield(struct.(f1), f2)
    if MultiStruct.(f1).(f2) ~= struct.(f1).(f2)
        MultiStruct.(f1).(f2) = [];
    end
end

function MultiStruct = checkString3(MultiStruct, struct, f1, f2, f3)
% checks if the fields are equal
if isfield(struct.(f1).(f2), f3)
    if MultiStruct.(f1).(f2).(f3) ~= struct.(f1).(f2).(f3)
        MultiStruct.(f1).(f2).(f3) = '';
    end
end

function MultiStruct = checkValue3(MultiStruct, struct, f1, f2, f3)
% checks if the fields are equal
if isfield(struct.(f1).(f2), f3)
    if MultiStruct.(f1).(f2).(f3) ~= struct.(f1).(f2).(f3)
        MultiStruct.(f1).(f2).(f3) = [];
    end
end

function [multi] = insertData(multi, single, field, idx)
% Inserts the data of one field from storeData into the field of multiData
if ~isfield(single, field)
    return
end
% get fields of structs
old = multi.(field);
new = single.(field);
% determine sizes
[n_old, m_old] = size(old);
[n_new, m_new] = size(new);
% make sure that the amount of columns is identical
if m_new ~= m_old
    m_max = max([m_new m_old]);     % determine maximum number of columns
    old(:,m_old+1:m_max) = 0;       % add additional columns if necessary
    new(:,m_new+1:m_max) = 0;
end
% put data together into the struct multi
if n_old > m_old    % more rows than columns, epochs are rows most likely
    A = old(1:idx-1, :);
    B = new;
    C = old(idx:n_old,   :);
    M = [A; B; C];
else    	% epochs = columns
    A = old(:, 1:idx-1);
    B = new;
    C = old(:, idx:m_old  );
    M = [A, B, C];
end
multi.(field) = M;

