function settings = PPP_main(settings)

% Main function for PPP processing and calculations
% raPPPid intern numbering of frequencies:
% GPS:      1 | 2 | 3         = L1 | L2  | L5
% Glonass:  1 | 2 | 3         = G1 | G2  | G3
% Galileo:  1 | 2 | 3 | 4 | 5 = E1 | E5a | E5b | E5 | E6
% BeiDou:   1 | 2 | 3         = B1 | B2  | B3
% raPPPid intern numbering of satellites and acronyms:
% GPS:      001-099     gps     G
% Glonass:  101-199     glo     R
% Galileo:  201-299     gal     E
% BeiDou:   301-399     bds     C
% This function is a component of raPPPid, VieVS PPP.
% 
% INPUT:
%   settings      struct, settings from GUI for PPP processing 
% OUTPUT:        
%   settings      struct, updated
%   results folder in ..\RESULTS containing output files
% 
% Revision:
%       ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% -+-+-+-+-+-PREPARATIONS-+-+-+-+-+-

% Create path of results folder, the folder itself is created after the processing
if exist('settings', 'var')     % PPP_main.m started from GUI or with settings as input
    settings.PROC.output_dir = createResultsFolder(settings.INPUT.file_obs, settings.PROC.name);
else                            % PPP_main.m started without settings as input
    [FileName, PathName] = uigetfile('*.mat', 'Select a Settings File', Path.RESULTS');
    if ~FileName;       return;         end         % stop if no file selected
    PathName = relativepath(PathName);              % convert absolute path to relative path
    load([PathName, '/', FileName], 'settings');    % load selected settings.mat-file
    settings.PROC.output_dir = createResultsFolder(settings.INPUT.file_obs, settings.PROC.name);
end

tStart = tic; warning off; fclose all;

% check if output should be printed to command window
bool_print = ~settings.INPUT.bool_parfor;

% Prepare waitbar and print out of epochs to command window 
if bool_print
    WBAR = waitbar(0, 'Reading data, wait for processing start...', 'Name', 'Preparing...');
end

% Initialization and definition of global variable
global STOP_CALC;	% for stopping calculations before last epoch, set to zero in GUI_PPP

% number of processed frequencies
[settings.INPUT.num_freqs, settings.INPUT.proc_freqs] = CountProcessedFrequencies(settings);

% number of processed GNSS
settings.INPUT.use_GNSS = settings.INPUT.use_GPS + settings.INPUT.use_GLO + settings.INPUT.use_GAL + settings.INPUT.use_BDS;

% check which biases are applied
bool_sinex = strcmp(settings.BIASES.phase(1:3), 'WHU') || ...
    any(strcmp(settings.BIASES.code, {'CAS Multi-GNSS DCBs','CAS Multi-GNSS OSBs','DLR Multi-GNSS DCBs','CODE OSBs','CNES OSBs','CODE MGEX','WUM MGEX','CNES MGEX','GFZ MGEX','CNES postprocessed'}));
bool_manual_sinex = strcmp(settings.BIASES.code, 'manually') && settings.BIASES.code_manually_Sinex_bool;
bool_CODE_dcb = strcmp(settings.BIASES.code, 'CODE DCBs (P1P2, P1C1, P2C2)') || ... 
    (strcmp(settings.BIASES.code, 'manually') && settings.BIASES.code_manually_DCBs_bool);
bool_CNES_archive = settings.ORBCLK.bool_precise~=1   &&   strcmpi(settings.ORBCLK.CorrectionStream, 'CNES Archive');
bool_brdc_TGD = strcmp(settings.BIASES.code, 'Broadcasted TGD');



%% -+-+-+-+-+-READ/PREPARE INPUT DATA-+-+-+-+-+-

% Read Input Data from Files (Ephemerides, Station Data, etc.)
[input, obs, settings, OBSDATA] = readAllInputFiles(settings);

% open files for real-time processing
fid_obs = []; fid_navmess = []; fid_corr2brdc = [];
q_update = 17;      % [epochs], update rate of, for example, waitbar 
if settings.INPUT.bool_realtime
    % open files for reading in real-time and jump to somewhere at the end of the file
    fid_obs = fopen(settings.INPUT.file_obs, 'r');              % fseek(fid_obs,-100,'eof');
    fid_navmess = fopen(settings.ORBCLK.file_nav_multi);    % do not jump
    fid_corr2brdc = fopen(settings.ORBCLK.file_corr2brdc, 'r'); % fseek(fid_corr2brdc,-100,'eof');
    input.Eph_GPS = []; input.Eph_GLO = []; input.Eph_GAL = []; input.Eph_BDS = [];
    q_update = 1; 
end


% if necessary convert time frame to epochs of RINEX observation file 
% ||| missing data epochs are not considered
if settings.INPUT.bool_realtime
    % determine approximate number of epochs to process in real-time (e.g.
    % for initializing variables)
    [settings.PROC.epochs, start_sow, ende_sow] = RealTimeEpochs(settings, obs);    
elseif settings.PROC.timeSpan_format_epochs
    settings.PROC.epochs(1) = floor(settings.PROC.timeFrame(1));    % round to be on the safe side
    settings.PROC.epochs(2) = ceil (settings.PROC.timeFrame(2));
elseif settings.PROC.timeSpan_format_SOD
    settings.PROC.epochs = sod2epochs(OBSDATA, obs.newdataepoch, settings.PROC.timeFrame, obs.rinex_version);  
elseif settings.PROC.timeSpan_format_HOD
    settings.PROC.epochs = sod2epochs(OBSDATA, obs.newdataepoch, settings.PROC.timeFrame*3600, obs.rinex_version);   % *3600 in order to convert from seconds to hours
end
% convert start of fixing from minutes (GUI) to epochs for calculations
if settings.AMBFIX.bool_AMBFIX
    settings.AMBFIX.start_WL = settings.AMBFIX.start_WL_sec/obs.interval;
    settings.AMBFIX.start_NL = settings.AMBFIX.start_NL_sec/obs.interval;
    settings.AMBFIX.start_fixing = [settings.AMBFIX.start_WL, settings.AMBFIX.start_NL];
end


    
%% -+-+-+-+-+-INITIALIZATION OF PROCESSING -+-+-+-+-+-

% create Epoch, satellites, storeData and update obs
[Epoch, satellites, storeData, obs, model_save, Adjust] = initProcessing(settings, obs);

% create init_ambiguities
init_ambiguities = NaN(3, 399);     % columns = satellites, rows = frequencies

% initialize matrices for Hatch-Melbourne-Wübbena (HMW) LC between
% different frequencies, e.g., for GPS L1-L2-L5 processing
HMW_12 = []; HMW_23 = []; HMW_13 = [];
if settings.AMBFIX.bool_AMBFIX
    HMW_12 = zeros(settings.PROC.epochs(2)-settings.PROC.epochs(1)+1, 399);  % e.g., Wide-Lane (WL)
    HMW_23 = zeros(settings.PROC.epochs(2)-settings.PROC.epochs(1)+1, 399);  % e.g., Extra-Wide-Lane (EW)
    HMW_13 = zeros(settings.PROC.epochs(2)-settings.PROC.epochs(1)+1, 399);  % e.g., Medium-Lane (ML)
end

% Creating q for loop of epoch calculations, q is used for indexing the epochs
q_range = 1:settings.PROC.epochs(2)-settings.PROC.epochs(1)+1; % one epoch more than the settings in GUI

% time which is needed for reading all input data and going to start-epoch
read_time = toc(tStart);

% check if P-code is processed for GPS and Glonass
% ||| does not work for P1 on 2nd freq or P2 on 1st freq
if bool_CODE_dcb
    idx_c = obs.use_column{1, 4};
    bool_P1_GPS = strcmp('P1', obs.types_gps(2*idx_c-1:2*idx_c));
    idx_c = obs.use_column{1, 5};
    bool_P2_GPS = strcmp('P2', obs.types_gps(2*idx_c-1:2*idx_c));
    idx_c = obs.use_column{2, 4};
    bool_P1_GLO = strcmp('P1', obs.types_glo(2*idx_c-1:2*idx_c));
    idx_c = obs.use_column{2, 5};
    bool_P2_GLO = strcmp('P2', obs.types_glo(2*idx_c-1:2*idx_c));
end

% check for which satellites no precise orbits or clocks exist
if settings.ORBCLK.bool_precise
    settings = checkPreciseOrbitClock(settings, input);
end

% Print stuff for epoch 0
if bool_print
    bspace = char(8,8,8,8,8,8,8,8,8,8,8,8,8,8);     % backspaces for printing actual epoch
    estr = sprintf('Epoch %d\n', 0);
    fprintf('%s',estr);
    l_estr = length(estr);
    if ishandle(WBAR)
        WBAR.Name = ['Processing ' obs.stationname sprintf(' %04.0f', obs.startdate(1)) sprintf('/%03.0f',obs.doy)];
    end
end


%% -+-+-+-+-+-EPOCH-WISE CALCULATION-+-+-+-+-+-
for q = q_range         % loop over epochs
    
    if bool_print       % printing out the number of the epoch
        estr = sprintf('\nEpoch %d\n', q);
        fprintf('%s%s', bspace(1:l_estr), estr);
        l_estr = length(estr);
    end
    % save data from last epoch (step q-1) and reset Epoch
    Epoch.old = Epoch;  
    Epoch.q = q;            % save number of epoch 
    [Epoch] = EpochlyReset_Epoch(Epoch);
    
    n = settings.PROC.epochs(1) + q - 1;        
    if ~settings.INPUT.bool_realtime && ~settings.INPUT.rawDataAndroid
        % post-processing: check if end of file is reached
        if n > length(obs.newdataepoch)
            settings.PROC.epochs(2) = settings.PROC.epochs(1) + q - 2;
            q = q - 1;          %#ok<FXSET>
            Epoch.q = q;
            errordlg({['Epoch: ' sprintf(' %.0f',q)], 'End of Observation File reached!'}, ...
                [obs.stationname sprintf(' %04.0f', obs.startdate(1)) sprintf('/%03.0f',obs.doy)]);
            break;
        end
    end
       
    % ----- real-time processing: get RINEX observation data -----
    if settings.INPUT.bool_realtime
        [OBSDATA, fid_obs, fid_navmess, fid_corr2brdc, input, obs] = ...
            ReadRinexRealTime(settings, input, obs, start_sow, fid_obs, fid_navmess, fid_corr2brdc);        
    end
    
    % ----- read in epoch data -----
    if ~settings.INPUT.rawDataAndroid       % from RINEX observation file
        [Epoch] = RINEX2Epoch(OBSDATA, obs.newdataepoch, Epoch, n, obs.no_obs_types, obs.rinex_version, settings);
    else                                % from Android raw sensor data
        [Epoch] = RawSensor2Epoch(OBSDATA, obs.newdataepoch, q, obs.vars_raw, Epoch, settings, obs.use_column);
    end
    
    % ----- check usability of epoch -----
    if ~Epoch.usable
        if bool_print
            fprintf('Epoch %d is skipped (not usable based on RINEX header)            \n', q)
        end
        [Epoch, storeData, Adjust] = SkipEpoch(Epoch, storeData, Adjust);
        continue
    end
    
    % ----- reset solution -----
    [Adjust, Epoch, settings, HMW_12, HMW_23, HMW_13, storeData, init_ambiguities] = ...
        resetSolution(Adjust, Epoch, settings, HMW_12, HMW_23, HMW_13, storeData, obs.interval, init_ambiguities);
    
    % ----- Find column of broadcast-ephemeris of current satellite -----
    % check if satellites have broadcast ephemerides and are healthy, otherwise satellite is excluded
    if settings.ORBCLK.bool_brdc
        if settings.INPUT.bool_realtime
            [input, obs] = RealTimeEphCorr2Brdc(settings, input, obs, fid_navmess, fid_corr2brdc);
        end
        Epoch = findEphCorr2Brdc(Epoch, input, settings);
    end 
    
    % ----- prepare observations -----
    [Epoch, obs] = prepareObservations(settings, obs, Epoch, q);
    
    % ----- check, if enough satellites -----
    bool_enough_sats = check_min_sats(settings.INPUT.use_GPS, settings.INPUT.use_GLO, settings.INPUT.use_GAL, settings.INPUT.use_BDS, ...
        sum(Epoch.gps), sum(Epoch.glo), sum(Epoch.gal), sum(Epoch.bds), settings.INPUT.use_GNSS);
    if ~bool_enough_sats 
        if bool_print
            fprintf('Less than %d usable satellites in epoch %d (%s)        \n', DEF.MIN_SATS, q, Epoch.rinex_header);
        end
        [Epoch, storeData, Adjust] = SkipEpoch(Epoch, storeData, Adjust);
        continue
    end

    % ----- check, if epoch is excluded from processing -----
    if ~isempty(settings.PROC.excl_eps) && any(q == settings.PROC.excl_eps)
        [settings, Epoch, Adjust, storeData, HMW_12, HMW_23, HMW_13] = ...
            ExcludeEpoch(settings, Epoch, Adjust, storeData, HMW_12, HMW_23, HMW_13, bool_print);
        continue
    end

    % number of satellites in current epoch
    Epoch.no_sats = numel(Epoch.sats);
    % frequency
    f1 = Epoch.gps .* Const.GPS_F(strcmpi(DEF.freq_GPS_names,settings.INPUT.gps_freq{1})) + Epoch.gal .* Const.GAL_F(strcmpi(DEF.freq_GAL_names,settings.INPUT.gal_freq{1})) + Epoch.bds .* Const.BDS_F(strcmpi(DEF.freq_BDS_names,settings.INPUT.bds_freq{1}));
    f2 = Epoch.gps .* Const.GPS_F(strcmpi(DEF.freq_GPS_names,settings.INPUT.gps_freq{2})) + Epoch.gal .* Const.GAL_F(strcmpi(DEF.freq_GAL_names,settings.INPUT.gal_freq{2})) + Epoch.bds .* Const.BDS_F(strcmpi(DEF.freq_BDS_names,settings.INPUT.bds_freq{2}));
    f3 = Epoch.gps .* Const.GPS_F(strcmpi(DEF.freq_GPS_names,settings.INPUT.gps_freq{3})) + Epoch.gal .* Const.GAL_F(strcmpi(DEF.freq_GAL_names,settings.INPUT.gal_freq{3})) + Epoch.bds .* Const.BDS_F(strcmpi(DEF.freq_BDS_names,settings.INPUT.bds_freq{3}));
    f1(Epoch.glo) = Epoch.f1_glo;
    f2(Epoch.glo) = Epoch.f2_glo;
    f3(Epoch.glo) = Epoch.f3_glo;
    Epoch.f1 = f1;   Epoch.f2 = f2;   Epoch.f3 = f3;        
    % wavelength
    lam1 = Const.C ./ f1;
    lam2 = Const.C ./ f2;
    lam3 = Const.C ./ f3;
    Epoch.l1 = lam1;   Epoch.l2 = lam2;   Epoch.l3 = lam3;
    % get prn: GPS [0-99], Glonass [100-199], Galileo [200-299], BeiDou [300-399]
    prn_Id = Epoch.sats;
    % increase epoch counter
    Epoch.tracked(prn_Id) = Epoch.tracked(prn_Id) + 1;
    
    % --- check C/N0 and signal strength threshold  ---
    [Epoch] = check_SNR(Epoch, settings, obs.use_column);
    
    % --- perform multipath detection ---
    if settings.OTHER.mp_detection
        [Epoch] = checkMultipath(Epoch, settings, obs.use_column, obs.interval, Adjust.reset_time);
    end
    
    % --- insert artificial cycle slip or multipath
    % Epoch = cycleSlip_articifial(Epoch, obs.use_column);
    % Epoch = multipath_articifial(Epoch, obs.use_column);
    
    % --- perform Cycle-Slip detection ---
    if contains(settings.PROC.method,'Phase')   &&   (settings.OTHER.CS.l1c1 || settings.OTHER.CS.DF || settings.OTHER.CS.Doppler || settings.OTHER.CS.TimeDifference || settings.PROC.LLI)
        [Epoch] = cycleSlip(Epoch, settings, obs.use_column);
    end
    
    % --- Adjust phase data to Code to limit the ambiguities ---
    if strcmpi(settings.PROC.method, 'Code + Phase') && settings.PROC.AdjustPhase2Code
        [init_ambiguities, Epoch] = AdjustPhase2Code(Epoch, init_ambiguities);
    end
    
    % --- get and apply satellite biases for current epoch ---
    % get from correction stream (real-time code and phase biases)
    if strcmp(settings.ORBCLK.CorrectionStream,'manually') && (settings.BIASES.code_corr2brdc_bool || settings.BIASES.phase_corr2brdc_bool)
        Epoch = apply_corr2brdc_biases(Epoch, settings, input, obs);
    % get from *.bia-file
    elseif bool_sinex || bool_manual_sinex || bool_CNES_archive
        Epoch = apply_biases(Epoch, obs, settings);
    % get from *.DCB-file
    elseif bool_CODE_dcb
        Epoch = apply_DCBs(input, settings, Epoch, bool_P1_GPS, bool_P2_GPS, bool_P1_GLO, bool_P2_GLO);
    % get Broadcasted Time Group Delays
    elseif bool_brdc_TGD
        Epoch = apply_TGDs(input, settings, Epoch);
    end
    % apply satellite biases [m]
    Epoch.C1 = Epoch.C1 + Epoch.C1_bias;
    Epoch.C2 = Epoch.C2 + Epoch.C2_bias;
    Epoch.C3 = Epoch.C3 + Epoch.C3_bias;
    Epoch.L1 = Epoch.L1 + Epoch.L1_bias;
    Epoch.L2 = Epoch.L2 + Epoch.L2_bias;
    Epoch.L3 = Epoch.L3 + Epoch.L3_bias;   
    
    % --- correct receiver biases ---
    if settings.INPUT.proc_freqs > 1 && ~settings.BIASES.estimate_rec_dcbs
        Epoch = correct_rec_biases(Epoch, obs);
    end
    
    % --- Build LCs and processed observations -> Epoch.code/.phase ---
    [Epoch, storeData] = create_LC_observations(Epoch, settings, storeData, q);
    
    
    % -+-+-+-+-+-START CALCULATION EPOCH-WISE SOLUTION-+-+-+-+-+- 
    [Adjust, Epoch, model, obs, HMW_12, HMW_23, HMW_13] = ...
        ZD_processing(HMW_12, HMW_23, HMW_13, Adjust, Epoch, settings, input, satellites, obs);
      
    % Save results from epoch-wise processing
    [satellites, storeData, model_save] = ...
        saveData(Epoch, q, satellites, storeData, settings, Adjust, model, model_save, HMW_12, HMW_23, HMW_13);
    Epoch.delta_windup = model.delta_windup;        % [cycles], for calculation of Wind-Up correction in next epoch
      
    % update waitbar
    if bool_print && mod(q,q_update) == 0 && ishandle(WBAR)
        progress = q/q_range(end);
        if ~settings.INPUT.bool_realtime
            remains = (toc(tStart)-read_time)/q*q_range(end) - ...
                (toc(tStart)-read_time); 	% estimated remaining time for epoch-wise processing in seconds
            mess = sprintf('%s%s\n%02.0f%s%d%s%d',...
                'Estimated remaining time: ',datestr(remains/(24*60*60), 'HH:MM:SS'), progress*100, '% processed, current epoch: ', q, ' of ', q_range(end));
        else        % real-time processing
            remains = ende_sow - Epoch.gps_time;
            mess = sprintf('%s%s%s%s', 'Real-time processing until ', settings.INPUT.realtime_ende_GUI, ' (remaining ', datestr(remains/(24*60*60), 'HH:MM:SS'), ')');
        end
        waitbar(progress, WBAR, mess)
    end
  
    % Stop processing: if user stopped manually or end of real-time processing
    if ~(settings.INPUT.bool_batch && settings.INPUT.bool_parfor)
        if mod(q,q_update) == 0;   drawnow;   end
        realtime_ende = settings.INPUT.bool_realtime && Epoch.gps_time >= ende_sow;
        if STOP_CALC || realtime_ende
            settings.PROC.epochs(2) = q + (settings.PROC.epochs(1)-1);
            break;
        end
    end
 
end             % end of loop over epochs / epoch-wise calculations


%% -+-+-+-+-+-VISUALS AND OUTPUT-+-+-+-+-+-

mess = sprintf('Processing finished, opening plots...');
if bool_print
    % update waitbar
    if ishandle(WBAR);  waitbar(1,WBAR, mess);  end
end

% close files of real-time processing
if settings.INPUT.bool_realtime
    fclose(fid_obs);
end

% % Ambiguities are reduced by the following values of cycles
% % (calculated from difference to C1 code) for numerical reasons:
% fprintf('\n\nAmbiguities are reduced by the following values of cycles\n(calculated from difference to C1 code) for numerical reasons:\n')
% if settings.INPUT.use_GPS
%     fprintf('GPS\n')
%     for i=1:size(init_ambiguities_gps,1)
%         fprintf('%02d %16.1f %16.1f\n', i, init_ambiguities_gps(i,1), init_ambiguities_gps(i,2))
%     end
% end
% if settings.INPUT.use_GLO
%     fprintf('GLONASS\n')
%     for i=1:size(init_ambiguities_glo,1)
%         fprintf('%02d %16.1f %16.1f\n', i, init_ambiguities_glo(i,1), init_ambiguities_glo(i,2))
%     end
% end
% if settings.INPUT.use_GAL
%     fprintf('GALILEO\n')
%     for i=1:size(init_ambiguities_gal,1)
%         fprintf('%02d %16.1f %16.1f\n', i, init_ambiguities_gal(i,1), init_ambiguities_gal(i,2))
%     end
% end

% save epochs of reset
storeData.float_reset_epochs = Adjust.float_reset_epochs;
storeData.fixed_reset_epochs = Adjust.fixed_reset_epochs;

% if processing was finished before the timespan defined in the GUI -> shrink variables
[satellites, storeData, model_save, obs] = ...
    shrinkVariables(satellites, storeData, model_save, obs, settings, q);

% sparse variables
[satellites, storeData, model_save, obs] = ...
    sparseVariables(satellites, storeData, model_save, obs, settings);


% create results folder
[~, ~] = mkdir(settings.PROC.output_dir);

% write settings from GUI into settings_summary.txt and settings.mat
if settings.EXP.settings_summary
    settings2txt(settings, obs, input, input.OTHER.PCO.rec_error, input.OTHER.PCV.rec_error, tStart);
end
if settings.EXP.settings
    save(fullfile(settings.PROC.output_dir, 'settings.mat'),'settings')
end

% Create Output Files
[storeData] = create_output(storeData, obs, settings, Epoch.q );

% write data4plot.mat
if settings.EXP.data4plot
    save([settings.PROC.output_dir, '/data4plot.mat'],     'obs', 'settings');
    if settings.EXP.storeData
        save([settings.PROC.output_dir, '/data4plot.mat'], 'storeData', '-append')
    end
    if settings.EXP.satellites
        save([settings.PROC.output_dir, '/data4plot.mat'], 'satellites', '-append')
    end
    if settings.EXP.model_save
        save([settings.PROC.output_dir, '/data4plot.mat'], 'model_save', '-append')
    end
end

% push to workspace
assignin('base',     'obs',         obs        )
assignin('base',     'settings',    settings   )
if settings.EXP.satellites
    assignin('base', 'satellites',  satellites )
end
if settings.EXP.storeData
    assignin('base', 'storeData',   storeData  )
end
if settings.EXP.model_save
    assignin('base', 'model_save',  model_save )
end

% close waitbar
if bool_print && ishandle(WBAR);	close(WBAR);	end

% print current time   
fprintf('%s', datestr(datetime('now')))

% Print final processing time
tProcessed = toc(tStart); printElapsedTime(tProcessed);

% Open enabled plots after processing is finished
SinglePlotting(satellites, storeData, obs, settings)    % open enabled plots


% end of PPP_main(...)
% *************************************************************************
