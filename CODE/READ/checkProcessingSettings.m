function valid_settings = checkProcessingSettings(settings, prebatch)
% This function checks if the settings from the GUI are valid for the 
% processing. If something is wrong it throws an error message and the
% processing will not be started
% 
% INPUT:
%   settings        struct, settings for processing from GUI
%   prebatch        boolean, set to true if check should be performed 
%                       ONLY before batch processing or false if check
%                       should not be performed before batch processing
%                       (e.g., number of frequencies)
%
% OUTPUT:
%   valid_settings  boolean, false if processing can not be started
% 
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
valid_settings = true;          % set to true in assumption of valid settings

% boolean if GPS or Galileo is enabled
GPS_on = settings.INPUT.use_GPS;
GLO_on = settings.INPUT.use_GLO;
GAL_on = settings.INPUT.use_GAL;
BDS_on = settings.INPUT.use_BDS;

% number of processed frequencies for GPS and Galileo
no_freq_gps = GPS_on * length(settings.INPUT.gps_freq(~strcmpi(settings.INPUT.gps_freq,'OFF')));
no_freq_glo = GLO_on * length(settings.INPUT.glo_freq(~strcmpi(settings.INPUT.glo_freq,'OFF')));
no_freq_gal = GAL_on * length(settings.INPUT.gal_freq(~strcmpi(settings.INPUT.gal_freq,'OFF')));
no_freq_bds = BDS_on * length(settings.INPUT.bds_freq(~strcmpi(settings.INPUT.bds_freq,'OFF')));

% number of processed frequencies
num_freq = max([GPS_on * no_freq_gps, GLO_on * no_freq_glo, GAL_on * no_freq_gal, BDS_on * no_freq_bds]);
% names of processed frequencies
proc_frqs_gps = settings.INPUT.gps_freq;
proc_frqs_glo = settings.INPUT.glo_freq;
proc_frqs_gal = settings.INPUT.gal_freq;
proc_frqs_bds = settings.INPUT.bds_freq;

if ~prebatch
    % No observation file selected
    if isempty(settings.INPUT.file_obs) && ~prebatch
        errordlg('Single-File-Processing: No observation file defined!', 'Error');
        valid_settings = false;     return;
    end
    % extract some information from header of observation file
    try
        rheader = anheader_GUI(settings.INPUT.file_obs);
        rheader = analyzeAndroidRawData_GUI(settings.INPUT.file_obs, rheader);
    catch
        errordlg({'Wrong path to observation file!' 'Try to reload Observation File in GUI.'}, 'File Error');
        valid_settings = false;     return;
    end
    % observed frequencies
    obs_frqs_gps = DEF.freq_GPS_names(rheader.ind_gps_freq);
    obs_frqs_glo = DEF.freq_GLO_names(rheader.ind_glo_freq);
    obs_frqs_gal = DEF.freq_GAL_names(rheader.ind_gal_freq);
    obs_frqs_bds = DEF.freq_BDS_names(rheader.ind_bds_freq);
    % create some time-dependent variables
    jd = cal2jd_GT(rheader.first_obs(1), rheader.first_obs(2), rheader.first_obs(3));
    [doy, yyyy] = jd2doy_GT(jd);
    [gpsweek, ~, ~] = jd2gps_GT(jd);
    % create windowname for potential error
    windowname = [rheader.station ' ' sprintf('%04.0f', yyyy) '/' sprintf('%03.0f', doy)];
else
    windowname = 'Error';
end


% create some variables to make code more readable in the following
prec_prod_CODE_MGEX = strcmpi(settings.ORBCLK.prec_prod,'CODE') && settings.ORBCLK.MGEX;
prec_prod_CODE = strcmpi(settings.ORBCLK.prec_prod,'CODE') && ~settings.ORBCLK.MGEX;



%% Check different number of processed frequencies (only for IF LC PPP models)
if (strcmp(settings.IONO.model,'2-Frequency-IF-LCs') || strcmp(settings.IONO.model,'3-Frequency-IF-LC')) && ~prebatch
    % Different number of processed frequencies for GPS and Galileo
    if GPS_on && GAL_on
        if no_freq_gps ~= no_freq_gal
            errordlg({'Different #frequencies for GPS and Galileo.' 'Check settings of processed frequencies!'}, windowname);
            valid_settings = false; return
        end
    end
    % Different number of processed frequencies for GPS and Glonass
    if GPS_on && GLO_on
        if no_freq_gps ~= no_freq_glo
            errordlg({'Different #frequencies for GPS and Glonass.' 'Check settings of processed frequencies!'}, windowname);
            valid_settings = false; return
        end
    end
    % Different number of processed frequencies for GPS and BeiDou
    if GPS_on && BDS_on
        if no_freq_gps ~= no_freq_bds
            errordlg({'Different #frequencies for GPS and BeiDou.' 'Check settings of processed frequencies!'}, windowname);
            valid_settings = false; return
        end
    end
    % Different number of processed frequencies for Glonass and Galileo
    if GLO_on && GAL_on
        if no_freq_glo ~= no_freq_gal
            errordlg({'Different #frequencies for Glonass and Galileo.' 'Check settings of processed frequencies!'}, windowname);
            valid_settings = false; return
        end
    end
    % Different number of processed frequencies for Glonass and BeiDou
    if GLO_on && BDS_on
        if no_freq_glo ~= no_freq_bds
            errordlg({'Different #frequencies for Glonass and BeiDou.' 'Check settings of processed frequencies!'}, windowname);
            valid_settings = false; return
        end
    end
    % Different number of processed frequencies for Galileo and BeiDou
    if GAL_on && BDS_on
        if no_freq_gal ~= no_freq_bds
            errordlg({'Different #frequencies for Galileo and BeiDou.' 'Check settings of processed frequencies!'}, windowname);
            valid_settings = false; return
        end
    end
end


%% Check if frequencies == OFF are at the end
if num_freq ~= 3        
    % this check is only necessary of less than 3 frequencies are processed
    if GPS_on
        off_idx_G = strcmpi(proc_frqs_gps, 'OFF');
        if no_freq_gps >= 1 && off_idx_G(1) == 1
            errordlg({'Check order of processed GPS frequencies!', 'Disabled frequencies should be at the end.'}, windowname);
            valid_settings = false; return
        end
        if no_freq_gps >= 2 && off_idx_G(2) == 1
            errordlg({'Check order of processed GPS frequencies!', 'Disabled frequencies should be at the end.'}, windowname);
            valid_settings = false; return
        end
    end
    if GLO_on
        off_idx_R = strcmpi(proc_frqs_glo, 'OFF');
        if no_freq_glo >= 1 && off_idx_R(1) == 1
            errordlg({'Check order of processed Glonass frequencies!', 'Disabled frequencies should be at the end.'}, windowname);
            valid_settings = false; return
        end
        if no_freq_glo >= 2 && off_idx_R(2) == 1
            errordlg({'Check order of processed Glonass frequencies!', 'Disabled frequencies should be at the end.'}, windowname);
            valid_settings = false; return
        end
    end
    if GAL_on
        off_idx_E = strcmpi(proc_frqs_gal, 'OFF');
        if no_freq_gal >= 1 && off_idx_E(1) == 1
            errordlg({'Check order of processed Galileo frequencies!', 'Disabled frequencies should be at the end.'}, windowname);
            valid_settings = false; return
        end
        if no_freq_gal >= 2 && off_idx_E(2) == 1
            errordlg({'Check order of processed Galileo frequencies!', 'Disabled frequencies should be at the end.'}, windowname);
            valid_settings = false; return
        end
    end
    if BDS_on
        off_idx_C = strcmpi(proc_frqs_bds, 'OFF');
        if no_freq_bds >= 1 && off_idx_C(1) == 1
            errordlg({'Check order of processed BeiDou frequencies!', 'Disabled frequencies should be at the end.'}, windowname);
            valid_settings = false; return
        end
        if no_freq_bds >= 2 && off_idx_C(2) == 1
            errordlg({'Check order of processed BeiDou frequencies!', 'Disabled frequencies should be at the end.'}, windowname);
            valid_settings = false; return
        end
    end    
end



%% Check for errors

% Start and end of processing time span do not fit together or start is not valid
if settings.PROC.timeFrame(1) >= settings.PROC.timeFrame(2) 
    errordlg('Check time span to process (panel: Processing Options)!', windowname);
    valid_settings = false; return
end


% Start or end of processing is not valid
if (settings.PROC.timeSpan_format_epochs && settings.PROC.timeFrame(1) == 0)...
        || settings.PROC.timeFrame(1) < 0 || settings.PROC.timeFrame(2) < 0 || ...
        isnan(settings.PROC.timeFrame(1)) || isnan(settings.PROC.timeFrame(2))
    errordlg('Check settings of epochs!', windowname);
    valid_settings = false; return
end


% All GNSS are disabled
if ~GPS_on && ~GLO_on && ~GAL_on && ~BDS_on && ~prebatch
    errordlg('All GNSS are disabled!', windowname);
    valid_settings = false;     return;
end


% No manually selected IONEX file 
if strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Correct with ...')
    if strcmpi(settings.IONO.model_ionex,'manually') && isempty(settings.IONO.file_ionex)
        errordlg('Please select an IONEX-File!', windowname);
        valid_settings = false;     return
    end
end


% ESA precise products, IGS precise products are GPS only
% CODE DCBs are GPS+GLO only
if (GAL_on || BDS_on) && ~prebatch
    if settings.ORBCLK.bool_precise && strcmpi(settings.ORBCLK.prec_prod,'IGS')
        errordlg('IGS precise products are GPS only!', windowname);
        valid_settings = false;     return;
    end
    if settings.ORBCLK.bool_precise && strcmpi(settings.ORBCLK.prec_prod,'ESA')
        errordlg('ESA precise products are GPS only! Please choose ESM.', windowname);
        valid_settings = false;     return;
    end
end
if (GAL_on || BDS_on) && ~prebatch
    if strcmp(settings.BIASES.code, 'CODE DCBs (P1P2, P1C1, P2C2)')
        errordlg('CODE DCBs are for Dual-Frequency GPS+GLO only!', windowname);
        valid_settings = false;     return;
    end
end

% Final CODE products are for GPS and Glonass only
if BDS_on && settings.ORBCLK.bool_precise && prec_prod_CODE
    errordlg({'IGS operational products of CODE are for GPS+GLONASS+Galileo!',  'Please choose CODE MGEX.'}, windowname);
    valid_settings = false;     return;
end

% 3-Frequency-IF-LC but only two frequencies selected
if strcmp(settings.IONO.model,'3-Frequency-IF-LC') && ~prebatch
    if GPS_on && no_freq_gps < 3
        errordlg('Not enough GPS frequencies for 3-Frequency-IF-LC selected!', windowname);
        valid_settings = false;     return;
    end
    if GAL_on && no_freq_gal < 3
        errordlg('Not enough Galileo frequencies for 3-Frequency-IF-LC selected!', windowname);
        valid_settings = false;     return;
    end
    if BDS_on && no_freq_bds < 3
        errordlg('Not enough BeiDou frequencies for 3-Frequency-IF-LC selected!', windowname);
        valid_settings = false;     return;
    end
end

% some wrong input for the STD of code and phase and ionosphere observations
if isnan(settings.ADJ.var_code) || isnan(settings.ADJ.var_phase) || isnan(settings.ADJ.var_iono) || settings.ADJ.var_code == 0 || settings.ADJ.var_phase == 0 || settings.ADJ.var_iono == 0
    errordlg('Check your input for the STD of code and phase observations!', windowname);
    valid_settings = false; return
end

% some wrong input for filter settings
if strcmp(settings.ADJ.filter.type, 'Kalman Filter') || strcmp(settings.ADJ.filter.type, 'Kalman Filter Iterative')
    F = settings.ADJ.filter;
    if any(isnan([F.var_coord, F.var_zwd, F.var_rclk_gps, F.var_rclk_glo, ...
            F.var_rclk_gal, F.var_rclk_bds, F.var_DCB, F.var_amb, F.var_iono]))
        errordlg('Check the Filter settings for the initial standard deviation!', 'Error: Filter Settings');
        valid_settings = false;     return;
    end
    if any(isnan([F.Q_coord, F.Q_zwd, F.Q_rclk_gps, F.Q_rclk_glo, ...
            F.Q_rclk_gal, F.Q_rclk_bds, F.Q_DCB, F.Q_amb, F.Q_iono]))
        errordlg('Check the Filter settings for the system noise!', 'Error: Filter Settings');
        valid_settings = false;     return;
    end
end

% wrong selection in adjustment
if settings.ADJ.filter.dynmodel_coord == 0 && settings.ADJ.filter.Q_coord == 0
    errordlg('When using no dynamic model for the coordinates, the system noise Q must be set!', 'Error: Filter Settings');
    valid_settings = false; return
end
if settings.ADJ.filter.dynmodel_rclk_gps == 0 && settings.ADJ.filter.Q_rclk_gps == 0
    errordlg('When using no dynamic model for the receiver clock, the system noise Q must be set!', 'Error: Filter Settings');
    valid_settings = false; return
end
if settings.ADJ.filter.dynmodel_rclk_glo == 0 && settings.ADJ.filter.Q_rclk_glo == 0
    errordlg('When using no dynamic model for Glonass Receiver Clock, the system noise Q must be set!', 'Error: Filter Settings');
    valid_settings = false; return
end
if settings.ADJ.filter.dynmodel_rclk_gal == 0 && settings.ADJ.filter.Q_rclk_gal == 0
    errordlg('When using no dynamic model for Galileo Receiver Clock, the system noise Q must be set!', 'Error: Filter Settings');
    valid_settings = false; return
end
if settings.ADJ.filter.dynmodel_amb == 0 && settings.ADJ.filter.Q_amb == 0
    errordlg('When using no dynamic model for the ambiguities, the system noise Q must be set!', 'Error: Filter Settings');
    valid_settings = false; return
end
if settings.ADJ.filter.dynmodel_zwd == 0 && settings.ADJ.filter.Q_zwd == 0
    errordlg('When using no dynamic model for ZWD, the system noise Q must be set!', 'Error: Filter Settings');
    valid_settings = false; return
end
if settings.ADJ.filter.dynmodel_iono == 0 && settings.ADJ.filter.Q_iono == 0
    errordlg('When using no dynamic model for Ionosphere, the system noise Q must be set!', 'Error: Filter Settings');
    valid_settings = false; return
end

% Phase Biases are implemented only for correction stream
% (recorded/manually or from CNES Archive)
if strcmp(settings.BIASES.phase, 'TUW (not implemented)') || strcmp(settings.BIASES.phase, 'NRCAN (not implemented)')
    errordlg({'Phase Biases are implemented only for correction stream', '(CNES Archive or manually recorded)!'}, windowname);
    valid_settings = false; return
end

% User wants to process a frequency which is not observed
for j = 1:3
    if GPS_on && ~strcmp(settings.INPUT.gps_freq{j}, 'OFF') && ~prebatch
        if ~any(contains(obs_frqs_gps, proc_frqs_gps{j}))
            errordlg(['Frequency ' proc_frqs_gps{j} ' is not observed and can not be processed!'], windowname);
            valid_settings = false; return
        end
    end
    if GAL_on && ~strcmp(settings.INPUT.gal_freq{j}, 'OFF') && ~prebatch
        if ~any(contains(obs_frqs_gal, proc_frqs_gal{j}))
            errordlg(['Frequency ' proc_frqs_gal{j} ' is not observed and can not be processed!'], windowname);
            valid_settings = false; return
        end
    end
end

% check for errors related to estimation of receiver DCBs
if settings.BIASES.estimate_rec_dcbs && ~prebatch
    if num_freq == 1
        errordlg({'Only 1-Frequency is processed:', 'Please disable estimation of Receiver DCBs!'}, windowname);
        valid_settings = false; return
    end
    if num_freq == 2 && strcmp(settings.IONO.model,'2-Frequency-IF-LCs')
        errordlg({'Only one 2-Frequency-IF-LC is processed:', 'Please disable estimation of Receiver DCBs!'}, windowname);
        valid_settings = false; return
    end
    if strcmp(settings.IONO.model,'3-Frequency-IF-LC')
        errordlg({'3-Frequency-IF-LC is processed:', 'Please disable estimation of Receiver DCBs!'}, windowname);
        valid_settings = false; return
    end
end

%  Phase Biases need final precise products from CODE
if strcmp(settings.BIASES.phase(1:3), 'WHU') && ~(settings.ORBCLK.bool_precise && prec_prod_CODE)
    errordlg({'Phase biases from Wuhan University need CODE final precise products:', 'Please change source of precise products to CODE!'}, windowname);
    valid_settings = false; return
end

% Wuhan Phase Biases contain code biases so no seperate code biases are needed
if strcmp(settings.BIASES.phase(1:3), 'WHU') && ~strcmp(settings.BIASES.code, 'off')
    errordlg({'Phase biases from Wuhan University contain code biases:', 'Please set code biases to off!'}, windowname);
    valid_settings = false; return
end

% Wuhan Phase Biases are GPS only
if strcmp(settings.BIASES.phase(1:3), 'WHU') && (GLO_on || GAL_on || BDS_on) && ~prebatch
    errordlg({'Phase biases from Wuhan University are for GPS only:', 'Please process only GPS!'}, windowname);
    valid_settings = false; return
end

% check if processing name is invalid
invalid_chars = '?!&%';
for i = 1:numel(invalid_chars)
    if contains(settings.PROC.name, invalid_chars(i))
        errordlg({'Subdirectory/Processing-Name is invalid:', ['Please remove suspicious characters like ' invalid_chars]}, windowname);
        valid_settings = false; return
    end
end

% Check use of CODE products
if strcmp(settings.BIASES.code, 'CODE OSBs')
    % CODE OSBs contain only IF-LC biases for GPS: C1C/C1W/C2W
    % As the processed signals can not be checked here only
    % the processed frequencies are checked here
    if GPS_on
        if any(strcmp(proc_frqs_gps, 'L5')) && ~prebatch
            errordlg({'CODE OSBs do not contain a bias for L5!', 'They are for the IF-LC of GPS: C1C/C1W/C2W only.'}, windowname);
            valid_settings = false;     return
        end
    end
end

% CODE MGEX Biases are not suitable for estimating or constraining ionosphere
if strcmp(settings.BIASES.code, 'CODE MGEX')&& (strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Estimate'))
    errordlg({'CODE MGEX Biases are not suitable for', 'estimating or constraining the ionosphere.'}, windowname);
    valid_settings = false;     return
end

% Check consistency of CODE products, combination does not work properly
if (prec_prod_CODE_MGEX && strcmp(settings.BIASES.code, 'CODE OSBs')) ...
        || (prec_prod_CODE && strcmp(settings.BIASES.code, 'CODE MGEX'))
    errordlg({'Please use CODE orbit/clock with consistent biases!', 'CODE + CODE OSBs or CODE MGEX + CODE MGEX.'}, windowname);
    valid_settings = false;     return
end

% 3-frequencies enabled, 2xIF-LC is processed and receiver DCB estimation is disabled
if strcmp(settings.IONO.model, '2-Frequency-IF-LCs') && num_freq == 3 && ~settings.BIASES.estimate_rec_dcbs && ~prebatch
    errordlg({'Three frequencies and 2-Frequency-IF-LCs selected:', 'Please enable the receiver DCB estimation or deactivate the 3rd frequency!'}, windowname);
    valid_settings = false; return
end

% WL Fixing needs at least two epochs
if ~prebatch && settings.AMBFIX.bool_AMBFIX && ~isempty(rheader.interval) && (settings.AMBFIX.start_WL_sec/rheader.interval < 2)
    errordlg({'Check start of Fixing!', 'For WL-Fixing at least 2 epochs are needed.'}, windowname);
    valid_settings = false; return
end

% check time system of observations, until now only GPS seen
if ~prebatch && ~strcmp(rheader.time_system, 'GPS') && ~isempty(rheader.time_system)
    errordlg({'Observation time system error:', ['Only GPS is implemented, found: ' rheader.time_system]}, windowname);
    valid_settings = false; return
end

% Processing with broadcasted satellite position and clocks should use
% broadcasted TGDs also
if ~settings.ORBCLK.bool_precise && strcmp(settings.ORBCLK.CorrectionStream, 'off') && ~strcmp(settings.BIASES.code, 'off')
    % For IF-LC it does not matter if TGDs are used or not
    if ~strcmp(settings.IONO.model,'2-Frequency-IF-LCs') && ~strcmp(settings.BIASES.code, 'Broadcasted TGD')
        errordlg({'Processing with navigation message:', 'Please use "Broadcasted TGD" as Code Biases.'}, windowname);
        valid_settings = false; return
    end
end

% Check correct use of SGG FCBs
if strcmp(settings.BIASES.phase, 'SGG FCBs')
    % SGG FCBs need CODE MGEX as code bias
    if ~strcmp(settings.BIASES.code, 'CODE MGEX')
        errordlg({'Wrong code bias for SGG FCB phase bias!', 'Please select CODE MGEX as code bias.'}, windowname);
        valid_settings = false; return
    end
    
    % SGG need precise orbits and clocks from MGEX products from CNES, CODE or GFZ
    if ~(prec_prod_CODE_MGEX || strcmp(settings.ORBCLK.prec_prod, 'CNES') || ...
            strcmp(settings.ORBCLK.prec_prod, 'GFZ') || strcmp(settings.ORBCLK.prec_prod, 'IGS') ...
            || strcmp(settings.ORBCLK.prec_prod, 'WUM'))
        errordlg({'SGG FCBs need (MGEX) orbit/clock data from:', 'CNES, CODE, GFZ, IGS, or WUM'}, windowname);
        valid_settings = false; return
    end
end

% Input for the threshold of the signal strength value in the Rinex file is
% useless (e.g. negative)
if (settings.PROC.ss_thresh <= 0) || (settings.PROC.ss_thresh > 9)
    errordlg({'Please enter a sensible value', 'for the Signal Strength Threshold.'}, windowname);
    valid_settings = false; return
end

% Input for the C/N0 cutoff is useless (e.g. negative)
if any(settings.PROC.SNR_mask <= 0) || any(settings.PROC.SNR_mask > 99)
    errordlg('Please enter sensible values for the SNR Cutoff [db-Hz].', windowname);
    valid_settings = false; return
end

% C/N0 cutoff does not fit to the number of input frequencies
n_SNR_mask = numel(settings.PROC.SNR_mask);
if n_SNR_mask ~= 1 && num_freq > n_SNR_mask
    errordlg({'Define a single SNR cutoff or a', 'SNR cutoff for each processed frequency!'}, windowname);
    valid_settings = false; return
end

% Hydrostatic AND wet delay have to be used together from tropo file
if strcmp(settings.TROPO.zwd, 'Tropo file') && ~strcmp(settings.TROPO.zhd, 'Tropo file') ...
        || strcmp(settings.TROPO.zhd, 'Tropo file') && ~strcmp(settings.TROPO.zwd, 'Tropo file')
    errordlg('Troposphere: Please use "Tropo file" for the hydrostatic AND wet delay.', windowname);
    valid_settings = false; return
end

% Check GNSS weights
if any([settings.ADJ.fac_GPS settings.ADJ.fac_GLO settings.ADJ.fac_GAL settings.ADJ.fac_BDS] < 1) || ...
        any([settings.ADJ.fac_GPS settings.ADJ.fac_GLO settings.ADJ.fac_GAL settings.ADJ.fac_BDS] >= 10)
    errordlg('Check GNSS weights!', windowname);
    valid_settings = false; return
end

% Check settings of HMW fixing
if settings.AMBFIX.bool_AMBFIX
    if settings.AMBFIX.HMW_thresh <= 0 || settings.AMBFIX.HMW_release <= 0 || settings.AMBFIX.HMW_window <= 0
        errordlg('Check settings of HMW fixing!', windowname)
        valid_settings = false; return
    end
end

% check if elevation weighting function is valid
if settings.ADJ.weight_elev
    % check if conversion was successful with elev = 45°
    try 
        settings.ADJ.elev_weight_fun([pi/4 pi/5]);
    catch
        errordlg({'Please check the elevation weighting function!', 'To allow elementwise operations, use "."'}, windowname)
        valid_settings = false; return
    end
end

% check if C/N0 weighting function is valid
if settings.ADJ.weight_sign_str && isa(settings.ADJ.snr_weight_fun,'function_handle')
    % check the variable used in the function string
    if ~(contains(func2str(settings.ADJ.snr_weight_fun), 'snr') || contains(func2str(settings.ADJ.snr_weight_fun), 'SNR'))
        errordlg({'Please check the SNR weighting function!', 'Use "SNR" as variable.'}, windowname)
        valid_settings = false; return
    end
    % check if conversion was successful with C/N0 = 30 and 40
    try
        settings.ADJ.snr_weight_fun([30 40]);
    catch
        errordlg({'Please check the C/N0 weighting function!', 'To allow elementwise operations, use "."'}, windowname)
        valid_settings = false; return
    end
end

% check is reset of solution is valid
if settings.PROC.reset_float && isnan(settings.PROC.reset_after)
    errordlg('Check reset of solution.', windowname)
    valid_settings = false; return
end

% Calculation of ionospheric delay or VTEC from correction stream is not
% fully implemented
if (contains(settings.IONO.model, 'Correct') || contains(settings.IONO.model, 'Estimate')) ...
        && strcmp(settings.IONO.source, 'VTEC from Correction Stream')
    errordlg('VTEC from Correction Stream is not implemented (yet)', windowname)
    valid_settings = false; return
end

% Observation weighting based on MP LC works only for two input frequencies
if settings.ADJ.weight_mplc && num_freq ~= 2
    errordlg({'Observation weighting based on MP LC', 'works only for two input frequencies.'}, windowname)
    valid_settings = false; return
end

% Stream Archive IGC01 contains only GPS data
if (GLO_on || GAL_on || BDS_on) && settings.ORBCLK.bool_brdc && strcmp(settings.ORBCLK.CorrectionStream, 'IGC01 Archive')
    errordlg({'Stream Archive IGC01 contains only GPS data.', 'Process only GPS!'}, windowname)
    valid_settings = false; return
end

% NeQuick model is implemented, but absurdly slow and not tested
if (strcmpi(settings.IONO.model,'Estimate with ... as constraint')   ||   strcmpi(settings.IONO.model,'Correct with ...')) ...
        && strcmpi(settings.IONO.source,'NeQuick model')  
    errordlg({'NeQuick is implemented but absurdly slow.', 'Use another ionosphere model!'}, windowname)
    valid_settings = false; return
end

% Multipath detection makes only sense with high observation interval
if settings.OTHER.mp_detection && ~isempty(rheader.interval) && rheader.interval > 5
    msgbox({'Be careful: Observation interval might',  'be too low for Multipath detection!'}, 'MP Detection', 'help')
end

% Galileo HAS does not provide phase biases (yet)
if contains(settings.PROC.method, 'Phase') && settings.ORBCLK.bool_brdc && strcmp(settings.ORBCLK.CorrectionStream, 'manually') && ...
    contains(settings.ORBCLK.file_corr2brdc, 'SSRA00EUH0') && strcmp(settings.BIASES.phase, 'Correction Stream')
    errordlg({'Galileo HAS does not provide phase biases (yet).', 'Set phase biases to off!'}, windowname)
    valid_settings = false; return
end

% Real-time processing, check if all selected options are real-time capable
if settings.INPUT.bool_realtime
    bool_RT = true;
    % Orbits/clocks
    if settings.ORBCLK.bool_precise
        fprintf(2, 'Orbit/Clock: Change to broadcast products.\n');
        bool_RT = false;
    end
    % Biases
    if ~settings.BIASES.code_corr2brdc_bool && ~strcmp(settings.BIASES.code, 'off') && ~strcmp(settings.BIASES.code, 'Broadcasted TGD')
        fprintf(2, 'Code Biases: Change to correction stream, broadcasted TGD, or off.\n');
        bool_RT = false;
    end
    if ~settings.BIASES.phase_corr2brdc_bool && ~strcmp(settings.BIASES.phase, 'off')
        fprintf(2, 'Phase Biases: Change to correction stream, broadcasted TGD, or off.\n');
        bool_RT = false;
    end
    % Ionosphere
    if strcmp(settings.IONO.model, 'Estimate with ... as constraint') || ...
            strcmp(settings.IONO.model, 'Correct with ...')
        if strcmp(settings.IONO.source, 'IONEX File')
            if ~strcmp(settings.IONO.file_source, 'IGS RT GIM') && ~strcmp(settings.IONO.file_source, 'GIOMO predicted')
                fprintf(2, 'Ionosphere: Change to real-time capable product.\n')
                bool_RT = false;
            end
        end
        if strcmp(settings.IONO.source, 'CODE Spherical Harmonics')
            fprintf(2, 'Ionosphere: Change to real-time capable product.\n')
            bool_RT = false;
        end
    end
    % Troposphere
    if strcmp(settings.TROPO.zhd, 'VMF3') || strcmp(settings.TROPO.zwd, 'VMF3') || ...
            strcmp(settings.TROPO.mfh, 'VMF3') || strcmp(settings.TROPO.mfw, 'VMF3') || ...
            strcmp(settings.TROPO.Gh, 'GRAD') || strcmp(settings.TROPO.Gw, 'GRAD')
        fprintf(2, 'Troposphere: Change to real-time capable model (e.g., GPT3).\n')
        bool_RT = false;
    end
    if ~bool_RT
        errordlg({'Your settings are not suitable for real-time processing!', ...
            'Check the command window for details.'}, windowname)
        valid_settings = false; return
    end
end

% Batch-Processing and real-time processing activated
if settings.INPUT.bool_batch && settings.INPUT.bool_realtime
    errordlg({'Batch-processing and real-time processing activated!', ...
        'Disable one of them.'}, windowname)
    valid_settings = false; return
end

% Galileo HAS stream is used: GPS W should be placed at the end of the
% observation ranking
if ~prebatch && settings.ORBCLK.bool_brdc && strcmp(settings.ORBCLK.CorrectionStream, 'manually') ...
        && contains(settings.ORBCLK.file_corr2brdc, 'SSRA00EUH') && ...
        settings.INPUT.gps_ranking(1) == 'W'
    errordlg({'Galileo HAS does not provide C1W and C2W biases!', ...
        'Move W at the end of the GPS observation ranking.'}, windowname)
    valid_settings = false; return
end

% Check if the in situ meteo values are realistic
if (settings.TROPO.p < 300 || settings.TROPO.p > 1150)
    answer = questdlg('The inserted in situ pressure is unrealistic. Do you really want to continue?');
    if ~strcmpi(answer,'yes')
        valid_settings = false; return
    end
end
if (settings.TROPO.T < -60 || settings.TROPO.T > 55)
    answer = questdlg('The inserted in situ temperature is unrealistic. Do you really want to continue?');
    if ~strcmpi(answer,'yes')
        valid_settings = false; return
    end
end
if (settings.TROPO.q < 0 || settings.TROPO.q > 100)
    answer = questdlg('The inserted in situ relative humidity is unrealistic. Do you really want to continue?');
    if ~strcmpi(answer,'yes')
       valid_settings = false; return
    end
end





% ||| to be continued





%% Errors depending on number of processed frequencies
if num_freq == 0 && ~prebatch       % all frequencies are off
    errordlg({'All frequencies are OFF:', 'Please select frequencies to process!'}, windowname);
    valid_settings = false; return
end
% 1 Frequency Processing
if num_freq == 1 && ~prebatch
    % Cycle Slip Detection with dL1-dL2-difference is not possible
    if settings.OTHER.CS.DF && contains(settings.PROC.method, 'Phase')
        errordlg({'Only 1-Frequency is processed:', 'Cycle-Slip Detection dL1-dL2 is not possible!'}, windowname);
        valid_settings = false; return
    end
    if strcmp(settings.IONO.model,'2-Frequency-IF-LCs')
        errordlg({'Only 1-Frequency is processed:', 'Processing with 2-Frequency-IF-LC is not possible!'}, windowname);
        valid_settings = false; return
    end    
    % 2-Frequency-IF-LC is not possible with only one frequency
    if strcmp(settings.IONO.model,'2-Frequency-IF-LCs')
        errordlg('Not enough frequencies selected for building the 2-Frequency-IF-LC!', windowname);
        valid_settings = false; return
    end
    % observation weighting with the MP LC is not possible for single
    % frequency processing
    if settings.ADJ.weight_mplc
        errordlg('The selected observation weighting method is not possible for processing a single frequency!', windowname);
        valid_settings = false; return
    end
end
% 2 or 3 Frequencies are processed
if (num_freq == 2 || num_freq == 3) && ~prebatch
    if settings.OTHER.CS.l1c1
        errordlg('Cycle-Slip Detection with L1-C1 Difference only implemented for Single-Frequency-Processing.', windowname);
        valid_settings = false; return
    end
end
% 3 Frequency-Processing
if num_freq == 3 && ~prebatch
    % CODE DCBs are only for two frequencies
    if strcmp(settings.BIASES.code, 'CODE DCBs (P1P2, P1C1, P2C2)')
        errordlg('CODE DCBs are only for two frequencies of GPS+GLO !', windowname);
        valid_settings = false;     return;
    end
    
end


%% Error concerning PPP-AR
if settings.AMBFIX.bool_AMBFIX
    % PPP-AR is not possible if no phase is processed
    if ~contains(settings.PROC.method, 'Phase')
        errordlg('PPP-AR is not possible without processing phase observations!', windowname);
        valid_settings = false; return
    end
    
    % PPP-AR is not implemented for 3-Frequency-IF-LC only
    if strcmp(settings.IONO.model,'3-Frequency-IF-LC')
        errordlg('PPP-AR is not implemented for 3-Frequency-IF-LC!', windowname);
        valid_settings = false; return
    end
    
    % For PPP-AR EW has to start before WL-Fixing and WL before NL-Fixing
    if settings.AMBFIX.start_WL_sec > settings.AMBFIX.start_NL_sec
        errordlg({'Check settings for start of fixing!' 'EW has to start before WL-Fixing and WL before NL-Fixing.'}, windowname);
        valid_settings = false; return
    end
    
    % PPP-AR and phase is not processed
    if ~strcmp(settings.PROC.method, 'Code + Phase')
        errordlg('PPP-AR without Phase Observations is not possible!', windowname);
        valid_settings = false; return
    end
    
    % CNES integer recovery clock PPP-AR (for GPS and Galileo) might need CODE MGEX biases
    if settings.ORBCLK.bool_precise && ~strcmp(settings.BIASES.phase, 'SGG FCBs') && ...
            strcmp(settings.ORBCLK.prec_prod, 'CNES') && ~strcmp(settings.BIASES.code, 'CODE MGEX')
        msgbox('CNES integer recovery clock approach might need CODE MGEX biases!', windowname);
    end
    
    %     % CNES postprocessed biases need GFZ orbits and clocks
    %     if settings.ORBCLK.bool_precise && strcmp(settings.BIASES.code, 'CNES postprocessed')&& ~strcmp(settings.ORBCLK.prec_prod, 'GFZ')
    %         errordlg('CNES postprocessed biases need GFZ orbit and clock products!', windowname);
    %         valid_settings = false; return
    %     end
    
    % CNES started providing postprocessed product in an archive containing
    % all necessary files.
    if strcmp(settings.BIASES.code, 'CNES postprocessed')
        errordlg({'CNES now provides post-processed products as an archive!', 'Download that archive, extract it, and manually select the files.', 'Try the link in command window.'}, windowname);
        fprintf(['\nhttp://www.ppp-wizard.net/products/POST_PROCESSED/post_' sprintf('%04.0f', yyyy) sprintf('%03.0f', doy) '.tgz\n\n'])
        valid_settings = false; return
    end


    % CODE MGEX needs its own ANTEX file
    if ~strcmp(settings.BIASES.phase, 'SGG FCBs') && settings.ORBCLK.bool_precise && prec_prod_CODE_MGEX 
        if ~strcmp(settings.OTHER.antex, 'Manual choice:')
            % [IGS-MGEX] CODE MGEX switch from IGb14 to IGS14R3 (starting from GPS week 2156)
            % However, this seems not totally true...
            if gpsweek >= 2156
                errordlg({'PPP-AR with CODE MGEX needs ', 'its own ANTEX File: Please select M20.ATX!'}, windowname);
                valid_settings = false; return
            else
                errordlg({'PPP-AR with CODE MGEX needs ', 'its own ANTEX File: Please select M14.ATX!'}, windowname);
                valid_settings = false; return
            end
        end
    end
    
    % PPP-AR is not implemented for Glonass only (just in addition to other GNSS)
    if GLO_on && ~GPS_on && ~GAL_on && ~BDS_on
        errordlg({'PPP-AR is not possible for Glonass only!'}, windowname);
        valid_settings = false; return
    end
    
    % PPP-AR is not possible for mGNSS biases from CAS or DLR
    if contains(settings.BIASES.code, 'CAS Multi-GNSS') || strcmp(settings.BIASES.code, 'DLR Multi-GNSS DCBs')
        errordlg({'The selected code biases are not suitable for PPP-AR:', settings.BIASES.code}, windowname);
        valid_settings = false; return
    end
    
end


%% Check if all file-paths are correct and the needed files are existing

% Observation File
if ~prebatch
    valid_settings = checkFileExistence(settings.INPUT.file_obs, 'RINEX Observation File', valid_settings);
end

% Orbits and Clocks
if settings.ORBCLK.bool_precise         % precise products
    if strcmp(settings.ORBCLK.prec_prod, 'manually')
        valid_settings = checkFileExistence(settings.ORBCLK.file_sp3, 'Precise Orbit (*.sp3) File', valid_settings);
    end
elseif settings.ORBCLK.bool_brdc   % broadcast products
    if settings.ORBCLK.bool_nav_multi && strcmp(settings.ORBCLK.multi_nav, 'manually')
        valid_settings = checkFileExistence(settings.ORBCLK.file_nav_multi, ' Multi-GNSS Navigation File', valid_settings);
    end
    if settings.ORBCLK.bool_nav_single
        if GPS_on
            valid_settings = checkFileExistence(settings.ORBCLK.file_nav_GPS, 'GPS Navigation File', valid_settings);
        end
        if GLO_on
            valid_settings = checkFileExistence(settings.ORBCLK.file_nav_GLO, 'Glonass Navigation File', valid_settings);
        end
        if GAL_on
            valid_settings = checkFileExistence(settings.ORBCLK.file_nav_GAL, 'Galileo File', valid_settings);
        end
    end
    if strcmp(settings.ORBCLK.CorrectionStream, 'manually')
        valid_settings = checkFileExistence(settings.ORBCLK.file_corr2brdc, 'Correction Stream File', valid_settings);
    end
end

% Tropo file
if strcmp(settings.TROPO.zhd, 'Tropo file') || strcmp(settings.TROPO.zwd, 'Tropo file')
    if strcmp(settings.TROPO.tropo_file, 'manually')
        valid_settings = checkFileExistence(settings.TROPO.tropo_filepath, 'Tropo File', valid_settings);
    end
end

% Ionosphere
if strcmp(settings.IONO.model, 'Estimate with ... as constraint') || strcmp(settings.IONO.model, 'Correct with ...')
    if strcmp(settings.IONO.source, 'IONEX File') && strcmp(settings.IONO.model_ionex, 'manually:')
        valid_settings = checkFileExistence(settings.IONO.file_ionex, 'IONEX File', valid_settings);
    end
end

% Biases
if strcmp(settings.BIASES.code, 'manually')
    if settings.BIASES.code_manually_DCBs_bool
        valid_settings = checkFileExistence(settings.BIASES.code_file{1}, 'P1P2 DCB File', valid_settings);
        valid_settings = checkFileExistence(settings.BIASES.code_file{2}, 'P1C1 DCB File', valid_settings);
    elseif settings.BIASES.code_manually_Sinex_bool
        valid_settings = checkFileExistence(settings.BIASES.code_file, 'Sinex Bias File', valid_settings);
    end
end

% Manual selection of ANTEX File
if strcmp(settings.OTHER.antex,'Manual choice:')
    if isempty(settings.OTHER.file_antex)
        errordlg({'Manual choice of ANTEX file:', 'Please select a file!'}, windowname);
        valid_settings = false;
    else
        valid_settings = checkFileExistence(settings.OTHER.file_antex, 'manual ANTEX File', valid_settings);
    end
end






%% Message Boxes

% Print out information if no cycle-slip detection method is enabled
if ~settings.OTHER.CS.TimeDifference && ~settings.OTHER.CS.l1c1 && ~settings.OTHER.CS.DF && ~settings.OTHER.CS.Doppler && strcmp(settings.PROC.method, 'Code + Phase')
    msgbox('Be careful: All cycle-slip detection methods are disabled!', 'Cycle-Slip-Detection', 'help')
end

% Intervall is (maybe?) too long for Cycle-Slip Detection with Doppler
if ~prebatch && ~isempty(rheader.interval) && rheader.interval > 5 && settings.OTHER.CS.Doppler  
    msgbox('Be careful: Observation intervall may be too long for Cycle-Slip-Detection with Doppler!', 'Cycle-Slip-Detection', 'help')
end

% Reprocessed TUG products need their corresponding antex file
if settings.ORBCLK.bool_precise && strcmp(settings.ORBCLK.prec_prod, 'manually') && contains(settings.ORBCLK.file_sp3, 'TUG') && ~strcmp(settings.OTHER.antex, 'Manual choice:')
    msgbox('You should use the corresponding ANTEX-File!', 'ANTEX-File', 'help')
end

% Broadcasted Time Group Delays make only sense with broadcast orbits and
% clocks
if settings.ORBCLK.bool_precise && strcmp(settings.BIASES.code, 'Broadcasted TGD')
    msgbox({'Processing precise orbits and clocks with broadcasted TGD:','Precise products should make use of precise biases!'}, 'Think about it!', 'help')
end

% Batch processing and manually selected for only one day selected orbits, 
% clocks or biases. This could lead to errors if observation files from
% multiple days are processd
if prebatch
    if settings.ORBCLK.bool_precise && strcmp(settings.ORBCLK.prec_prod, 'manually') ...
            && (~contains(settings.ORBCLK.file_sp3, '$') || ~contains(settings.ORBCLK.file_clk, '$'))
        msgbox({'Batch processing and manual selected satellite orbit & clocks:','File(s) only for one day defined, be careful!'}, 'Potential error', 'help')
    end
    if settings.BIASES.code_manually_Sinex_bool && ~contains(settings.BIASES.code_file, '$')
        msgbox({'Batch processing and manually selected biases:','File only for one day defined, be careful!'}, 'Potential error', 'help')        
    end    
end

% CODE MGEX PPP-AR for Galileo needs its own ANTEX file
if GAL_on && settings.ORBCLK.bool_precise && prec_prod_CODE_MGEX && ~strcmp(settings.OTHER.antex, 'Manual choice:') && ~strcmp(settings.BIASES.phase, 'SGG FCBs')
    msgbox({'Galileo with CODE MGEX performs better with ', 'its own ANTEX File: Please select M14.ATX!'}, windowname);
end

% check if RINEX files continues over day boundary
if ~prebatch && ~isempty(rheader.first_obs) && ~isempty(rheader.last_obs)
    if ~all(rheader.first_obs(1:3) == rheader.last_obs(1:3))
        msgbox({'Be careful: RINEX file contains observation of multiple days.', 'Processing over the day boundary might fail!'}, windowname);
    end
end




%%
% ||| check if processed frequencies are in ascending order!?!?!?



end





%% Auxiliary Functions
% Function to check the existence of a for the processing needed file
function valid = checkFileExistence(filepath, string, valid)
if ~exist(filepath, 'file') && ~contains(filepath, '$')
    errordlg({['Invalid File-Path to ' string '.'] 'Try reloading file in GUI.'}, 'File Error');
    valid = false;
end
end