function [] = settings2txt(settings, obs, rec_pco, rec_pcv, tStart)

% Function to write the processing settings from raPPPid (VieVS PPP) into a 
% settings.txt-file to be able to check them easily. Function is called 
% after the epoch-wise processing is finished 
%  
% INPUT:  
%   settings    struct, processing settings from GUI
%   obs         struct, information about observations
%   rec_pco     string, missing receiver PCO corrections in ANTEX
%   rec_pcv     string, missing receiver PCV corrections in ANTEX
%   tStart      uint64, start time of processing from Matlab tic
% OUTPUT:
%   settings.txt is written to results folder
% 
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



% get the name of the file
fileID = fopen([settings.PROC.output_dir,'/', 'settings_summary.txt'], 'w');



%% File - Set input file

fprintf(fileID,'%s\n','Input Data:');

fprintf(fileID,'  %s%s\n','Obs-File: ', settings.INPUT.file_obs);
fprintf(fileID,'  %s%.3f%s%.3f%s%.3f\n','Approx Pos [m]: ',settings.INPUT.pos_approx(1),' | ',settings.INPUT.pos_approx(2),' | ',settings.INPUT.pos_approx(3));
if settings.INPUT.bool_realtime
    fprintf(fileID,'  %s\n', ['Real-Time processing from ' settings.INPUT.realtime_start_GUI ' to ' settings.INPUT.realtime_ende_GUI]);
end
fprintf(fileID,'\n');



%% Selected Signals
switch settings.PROC.method
    case 'Code Only'
        fprintf(fileID,'%s\n\n','Processing Method: Code Only');
    case 'Code + Doppler'
        fprintf(fileID,'%s\n\n','Processing Method: Code + Doppler');
    case 'Code + Phase'
        fprintf(fileID,'%s\n\n','Processing Method: Phase + Code');
    case 'Code (Doppler Smoothing)'
        fprintf(fileID,'%s\n\n','Processing Method: Code (Doppler Smoothing)');
    otherwise
        fprintf(fileID,'%s\n\n','Processing Method: Error');
end
if settings.INPUT.use_GPS
    fprintf(fileID,'%s\n','Selected GPS Signals:');
    fprintf(fileID,'  Code:     %s, %s, %s\n', obs.GPS.C1,obs.GPS.C2,obs.GPS.C3);
    fprintf(fileID,'  Phase:    %s, %s, %s\n', obs.GPS.L1,obs.GPS.L2,obs.GPS.L3);
    fprintf(fileID,'  Strength: %s, %s, %s\n', obs.GPS.S1,obs.GPS.S2,obs.GPS.S3);
    fprintf(fileID,'  Doppler:  %s, %s, %s\n', obs.GPS.D1,obs.GPS.D2,obs.GPS.D3);
end
if settings.INPUT.use_GLO
    fprintf(fileID,'%s\n','Selected Glonass Signals:');
    fprintf(fileID,'  Code:     %s, %s, %s\n', obs.GLO.C1,obs.GLO.C2,obs.GLO.C3);
    fprintf(fileID,'  Phase:    %s, %s, %s\n', obs.GLO.L1,obs.GLO.L2,obs.GLO.L3);
    fprintf(fileID,'  Strength: %s, %s, %s\n', obs.GLO.S1,obs.GLO.S2,obs.GLO.S3);
    fprintf(fileID,'  Doppler:  %s, %s, %s\n', obs.GLO.D1,obs.GLO.D2,obs.GLO.D3);
end
if settings.INPUT.use_GAL
    fprintf(fileID,'%s\n','Selected Galileo Signals:');    
    fprintf(fileID,'  Code:     %s, %s, %s\n', obs.GAL.C1,obs.GAL.C2,obs.GAL.C3);
    fprintf(fileID,'  Phase:    %s, %s, %s\n', obs.GAL.L1,obs.GAL.L2,obs.GAL.L3);
    fprintf(fileID,'  Strength: %s, %s, %s\n', obs.GAL.S1,obs.GAL.S2,obs.GAL.S3);
    fprintf(fileID,'  Doppler:  %s, %s, %s\n', obs.GAL.D1,obs.GAL.D2,obs.GAL.D3);
end
if settings.INPUT.use_BDS
    fprintf(fileID,'%s\n','Selected BeiDou Signals:');    
    fprintf(fileID,'  Code:     %s, %s, %s\n', obs.BDS.C1,obs.BDS.C2,obs.BDS.C3);
    fprintf(fileID,'  Phase:    %s, %s, %s\n', obs.BDS.L1,obs.BDS.L2,obs.BDS.L3);
    fprintf(fileID,'  Strength: %s, %s, %s\n', obs.BDS.S1,obs.BDS.S2,obs.BDS.S3);
    fprintf(fileID,'  Doppler:  %s, %s, %s\n', obs.BDS.D1,obs.BDS.D2,obs.BDS.D3);
end



%% Models - Orbit/Clock data

fprintf(fileID,'%s\n','Orbit/Clock Data:');
if settings.ORBCLK.bool_precise
    
    fprintf(fileID,'  %s\n','Precise products:');
    fprintf(fileID,'    %s%s%s\n',settings.ORBCLK.prec_prod,':   ',settings.ORBCLK.file_sp3);
    fprintf(fileID,'    %s%s%s\n',settings.ORBCLK.prec_prod,':   ',settings.ORBCLK.file_clk);
    if settings.ORBCLK.bool_obx
        fprintf(fileID,'    %s%s%s\n',settings.ORBCLK.prec_prod,':   ',settings.ORBCLK.file_obx);
    else
        fprintf(fileID,'    %s\n','No ORBEX File');
    end    
    
else
    
    fprintf(fileID,'  %s\n','Broadcast products + Correction stream');
    if settings.ORBCLK.bool_nav_multi
        fprintf(fileID,'    %s%s%s%s\n','Multi-GNSS Navigation file: ',settings.ORBCLK.multi_nav,':   ',settings.ORBCLK.file_nav_multi);
    end
    if settings.ORBCLK.bool_nav_single
        fprintf(fileID,'    %s%s\n','GPS Navigation file: ',settings.ORBCLK.file_nav_GPS);
        fprintf(fileID,'    %s%s\n','GLONASS Navigation file: ',settings.ORBCLK.file_nav_GLO);
        fprintf(fileID,'    %s%s\n','Galileo Navigation file: ',settings.ORBCLK.file_nav_GAL);
    end
    
    if ~strcmpi(settings.ORBCLK.CorrectionStream,'off')
        fprintf(fileID,'    %s%s%s%s\n','Correction stream file: ',settings.ORBCLK.CorrectionStream,':   ',settings.ORBCLK.file_corr2brdc);
        fprintf(fileID,'    %s%.0f%s%.0f%s%.0f%s\n','Corrections age limit [s]: ', settings.ORBCLK.CorrectionStream_age(1), ', ', settings.ORBCLK.CorrectionStream_age(2), ', ', settings.ORBCLK.CorrectionStream_age(3), ' (orbit, clock, biases)');
    else
        fprintf(fileID,'    %s\n','No correction stream file');
    end
    
end
fprintf(fileID,'\n');



%% Models - Biases

fprintf(fileID,'%s\n','Biases:');

fprintf(fileID,'  %s\n','Code: ');
switch settings.BIASES.code
    case 'CODE DCBs (P1P2, P1C1, P2C2)'
        fprintf(fileID,'    %s\n', settings.BIASES.code);
        fprintf(fileID,'%s%s\n','    P1P2: ', settings.BIASES.code_file{1});
        fprintf(fileID,'%s%s\n','    P1C1: ', settings.BIASES.code_file{2});
    case 'Correction Stream'
        fprintf(fileID,'%s\n','    Code biases from correction stream are applied');
    case 'manually'
        if settings.BIASES.code_manually_Sinex_bool
            fprintf(fileID,'    %s%s\n','manually, Sinex-Bias-File: ', settings.BIASES.code_file);
        elseif settings.BIASES.code_manually_DCBs_bool
            fprintf(fileID,'    %s\n', 'CODE DCBs manually');
            fprintf(fileID,'    %s%s\n','P1P2: ', settings.BIASES.code_file{1});
            fprintf(fileID,'    %s%s\n','P1C1: ', settings.BIASES.code_file{2});
            fprintf(fileID,'    %s%s\n','P2C2: ', settings.BIASES.code_file{3});
        end
    case 'off'
        fprintf(fileID,'    %s\n','no');
    case 'Broadcasted TGD'
        fprintf(fileID,'    %s\n','Broadcasted Time Group Delay');
    otherwise 
        fprintf(fileID,'    %s%s%s\n', settings.BIASES.code, ': ', settings.BIASES.code_file);
end
% Estimation of receiver DCBs
if settings.BIASES.estimate_rec_dcbs
    fprintf(fileID,'    %s\n','Receiver DCB Estimation is enabled');
end


fprintf(fileID,'  %s\n','Phase:');
switch settings.BIASES.phase
    case 'TUW (not implemented)'
        fprintf(fileID,'%s%s\n','    TUW-WL-File: ', settings.BIASES.phase_file{1});
        fprintf(fileID,'%s%s\n','    TUW-NL-File: ', settings.BIASES.phase_file{2});
    case {'WHU phase/clock biases', 'SGG FCBs'}
        fprintf(fileID,'    %s: %s\n',settings.BIASES.phase, settings.BIASES.phase_file);
    case {'NRCAN (not implemented)', 'manually (not implemented)'}
        fprintf(fileID,'    %s\n', settings.BIASES.phase);
    case 'Correction Stream'
        fprintf(fileID,'    %s\n','Phase biases from correction stream are applied');
    case 'off'
        fprintf(fileID,'    %s\n','no');
end
fprintf(fileID,'\n');



%% Models - Troposphere

fprintf(fileID,'%s\n', 'Troposphere:');
fprintf(fileID,'  %s%s\n','zhd: ',settings.TROPO.zhd);
if strcmpi(settings.TROPO.zhd,'p (in situ) + Saastamoinen')
    fprintf(fileID,'    %s%7.2f%s\n','p: ',settings.TROPO.p,' hPa');
elseif strcmpi(settings.TROPO.zhd,'Tropo file') && strcmpi(settings.TROPO.tropo_file,'manually')
    fprintf(fileID,'    %s: %s\n', 'manually', settings.TROPO.tropo_filepath);
end
fprintf(fileID,'  %s%s\n','zwd: ',settings.TROPO.zwd);
if strcmpi(settings.TROPO.zwd,'e (in situ) + Askne')
    fprintf(fileID,'    %s%5.2f%s\n','q: ',settings.TROPO.q,' %');
    fprintf(fileID,'    %s%6.2f%s\n','T: ',settings.TROPO.T,' °C');
elseif strcmpi(settings.TROPO.zwd,'Tropo file') && strcmpi(settings.TROPO.tropo_file,'manually')
    fprintf(fileID,'    %s: %s\n', 'manually', settings.TROPO.tropo_filepath);    
end
fprintf(fileID,'  %s%s\n','mfh: ',settings.TROPO.mfh);
fprintf(fileID,'  %s%s\n','mfw: ',settings.TROPO.mfw);
fprintf(fileID,'  %s%s\n','Gn_h & Ge_h: ',settings.TROPO.Gh);
fprintf(fileID,'  %s%s\n','Gn_w & Ge_w: ',settings.TROPO.Gw);
if settings.TROPO.estimate_ZWD
    fprintf(fileID,'  %s%5.2f\n','ZWD is estimated from minute ', settings.TROPO.est_ZWD_from);
else
    fprintf(fileID,'  %s\n','ZWD is not estimated');
end
fprintf(fileID,'\n');



%% Models - Ionosphere

fprintf(fileID,'%s\n','Ionosphere:');
fprintf(fileID,'  %s%s\n','Model: ',settings.IONO.model);
if strcmpi(settings.IONO.model,'Estimate with ... as constraint')   ||   strcmpi(settings.IONO.model,'Correct with ...')
    fprintf(fileID,'    %s%s\n','Ionosphere source: ',settings.IONO.source);
    if strcmp(settings.IONO.source,'IONEX File')
        if strcmp(settings.IONO.model_ionex, 'Source:')
            fprintf(fileID,'    %s%s%s%s%s\n',settings.IONO.model_ionex,' ', settings.IONO.file_source, ', ',settings.IONO.file_ionex);
        else
            fprintf(fileID,'    %s%s%s\n',settings.IONO.model_ionex,' ',settings.IONO.file_ionex);
        end
        if strcmpi(settings.IONO.model,'Correct with ...')
            fprintf(fileID,'    %s%s\n','TEC-Interpolation: ',settings.IONO.interpol);
        end
    end
    if strcmpi(settings.IONO.model,'Estimate with ... as constraint')
        fprintf(fileID,'    Constraint until minute: %.2f\n', settings.IONO.constraint_until);
        fprintf(fileID,'    Decrease stdev [m] to: %.2f\n', sqrt(settings.IONO.var_iono_decr));
    end
end
fprintf(fileID,'\n');



%% Models - Other corrections

fprintf(fileID,'%s\n','Other Corrections:');
if ~isempty(settings.OTHER.file_antex)
    switch settings.OTHER.antex
        case 'Manual choice:'
            fprintf(fileID,'  %s%s\n','Manual Antex file: ', settings.OTHER.file_antex);
        otherwise 
            fprintf(fileID,'  %s%s\n','Antex file: ', settings.OTHER.file_antex);
    end
    if settings.OTHER.antex_rec_manual
        fprintf(fileID,'  %s\n','Manual receiver corrections from MyAntex.atx');
    end
    if ~isempty(rec_pco)        % print missing receiver PCO corrrections
        fprintf(fileID,'    %s%s\n','Missing receiver PCOs: ', rec_pco);
    end
    if ~isempty(rec_pcv)        % print missing receiver PCV corrrections
        fprintf(fileID,'    %s%s\n','Missing receiver PCVs: ', rec_pcv);
    end
end
if settings.OTHER.bool_rec_arp || settings.OTHER.bool_rec_pco || settings.OTHER.bool_sat_pco || ... % all other corrections
        settings.OTHER.bool_solid_tides || settings.OTHER.bool_wind_up || settings.OTHER.bool_eclipse          
    fprintf(fileID,'  %s\n','Activated Corrections: ');
    if settings.OTHER.bool_rec_arp
        fprintf(fileID,'    %s\n','o Antenna Reference Point');
    end
    if settings.OTHER.bool_rec_pco
        fprintf(fileID,'    %s\n','o Receiver Phase Center Offset');
    end
    if settings.OTHER.bool_rec_pcv
        fprintf(fileID,'    %s\n','o Receiver Phase Center Variations');
    end
    if settings.OTHER.bool_sat_pco
        fprintf(fileID,'    %s\n','o Satellite Phase Center Offset');
    end
    if settings.OTHER.bool_sat_pcv
        fprintf(fileID,'    %s\n','o Satellite Phase Center Variations');
    end    
    if settings.OTHER.bool_solid_tides
        fprintf(fileID,'    %s\n','o Solid Tides Correction');
    end
    if settings.OTHER.bool_wind_up
        fprintf(fileID,'    %s\n','o Phase Wind-Up Correction');
    end
    if settings.OTHER.bool_GDV
        fprintf(fileID,'    %s\n','o Group Delay Variation Correction');
    end    
    if settings.OTHER.ocean_loading
        fprintf(fileID,'    %s\n','o Ocean Loading');
    end
    if settings.OTHER.bool_eclipse && ~settings.ORBCLK.bool_obx
        fprintf(fileID,'    %s\n','o Eclipse condition is on');
    end    
else
    fprintf(fileID,'  %s\n','No Other Corrections');
end
if settings.OTHER.CS.l1c1 || settings.OTHER.CS.DF || settings.OTHER.CS.Doppler
    fprintf(fileID,'  %s\n','Cycle-Slip-Detection:');
    if settings.OTHER.CS.l1c1
        fprintf(fileID,'    %s%.2f%s%.2f%s%d%s\n','L1-C1: threshold = ',settings.OTHER.CS.l1c1_threshold,' [m], window-size = ',settings.OTHER.CS.l1c1_window,' [epochs]' );
    end
    if settings.OTHER.CS.DF
        fprintf(fileID,'    %s%.2f%s\n','dL1-dL2: threshold = ',settings.OTHER.CS.DF_threshold,' [m]');
    end
    if settings.OTHER.CS.Doppler
        fprintf(fileID,'    %s%.2f%s\n','Doppler-Shift: threshold = ',settings.OTHER.CS.D_threshold,' [cy]');
    end
    if settings.OTHER.CS.TimeDifference
        fprintf(fileID,'    %s%.2f%s%.2f%s%d\n','Time difference: threshold = ',settings.OTHER.CS.TD_threshold,' [m], degree = ',settings.OTHER.CS.TD_degree );
    end    
    if settings.PROC.LLI
        fprintf(fileID,'    %s\n','LLI from RINEX is used');
    end
else
    fprintf(fileID,'  %s\n','No Cycle-Slip-Detection');
end
if settings.OTHER.mp_detection
    fprintf(fileID,'  %s\n','Multipath Detection is on:');
    fprintf(fileID,'    %s%.2f%s%.2f%s%d%s%d\n','Code difference: threshold = ',settings.OTHER.mp_thresh,' [m], degree = ',settings.OTHER.mp_degree,', cooldown = ', settings.OTHER.mp_cooldown);
end

fprintf(fileID,'\n');



%% Estimation - Adjustment

fprintf(fileID,'%s\n','Adjustment:');
% Observation weighting scheme
fprintf(fileID,'  %s','Weighting Scheme for Observations: ');
if settings.ADJ.weight_mplc
    fprintf(fileID,'%s\n','Multipath-LC');
elseif settings.ADJ.weight_elev
    fprintf(fileID,'%s%s\n','Elevation, function: ', strrep(func2str(settings.ADJ.elev_weight_fun), '@(e)', ''));
elseif settings.ADJ.weight_sign_str
    if ischar(settings.ADJ.snr_weight_fun)
        fprintf(fileID,'%s%s\n','C/N0: ', settings.ADJ.snr_weight_fun);
    else
        fprintf(fileID,'%s%s\n','C/N0, function: ', strrep(func2str(settings.ADJ.snr_weight_fun), '@(snr)', ''));
    end
elseif settings.ADJ.weight_none
    fprintf(fileID,'%s\n','None');
end
fprintf(fileID,'  %s %4.2f %s %4.2f %s %4.2f %s %4.2f\n','GNSS weights (GREC):', ...
    settings.ADJ.fac_GPS, ':', settings.ADJ.fac_GLO, ':', settings.ADJ.fac_GAL, ':', settings.ADJ.fac_BDS);
% Standard deviation of observations
fprintf(fileID,'  %s\n','Standard deviation of observations [m]:');
fprintf(fileID, '%s%6.3f\n%s%6.3f\n', '    code   = ',sqrt(settings.ADJ.var_code),'    phase  = ',sqrt(settings.ADJ.var_phase));
if strcmpi(settings.IONO.model,'Estimate with ... as constraint') 
    fprintf(fileID, '%s%6.3f\n', '    ionosphere  = ',sqrt(settings.ADJ.var_iono));
end
% Filter and filter settings
fprintf(fileID,'  %s\n',settings.ADJ.filter.type);
if ~strcmp(settings.ADJ.filter.type,'No Filter')
    fprintf(fileID,'    %s\n', 'Filter-Settings (initial standard deviation [m] | system noise standard deviation [m] | dynamic model):');
    fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Coordinates:        ',sqrt(settings.ADJ.filter.var_coord),    ' | ',sqrt(settings.ADJ.filter.Q_coord),     ' | ',settings.ADJ.filter.dynmodel_coord);
    if settings.TROPO.estimate_ZWD
        fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Zenith Wet Delay:   ',sqrt(settings.ADJ.filter.var_zwd),      ' | ',sqrt(settings.ADJ.filter.Q_zwd),       ' | ', settings.ADJ.filter.dynmodel_zwd);
    end
    if settings.INPUT.use_GPS
        fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Receiver Clock GPS: ',sqrt(settings.ADJ.filter.var_rclk_gps),' | ',sqrt(settings.ADJ.filter.Q_rclk_gps),  ' | ',settings.ADJ.filter.dynmodel_rclk_gps);
    end
    if settings.INPUT.use_GLO
        fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Receiver Clock GLO: ',sqrt(settings.ADJ.filter.var_rclk_glo), ' | ',sqrt(settings.ADJ.filter.Q_rclk_glo),  ' | ',settings.ADJ.filter.dynmodel_rclk_glo);
    end
    if settings.INPUT.use_GAL
        fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Receiver Clock GAL: ',sqrt(settings.ADJ.filter.var_rclk_gal), ' | ',sqrt(settings.ADJ.filter.Q_rclk_gal),  ' | ',settings.ADJ.filter.dynmodel_rclk_gal);
    end
    if settings.INPUT.use_BDS
        fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Receiver Clock BDS: ',sqrt(settings.ADJ.filter.var_rclk_bds), ' | ',sqrt(settings.ADJ.filter.Q_rclk_bds),  ' | ',settings.ADJ.filter.dynmodel_rclk_bds);
    end
    if settings.BIASES.estimate_rec_dcbs
        fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Receiver DCBs:      ',sqrt(settings.ADJ.filter.var_DCB),      ' | ',sqrt(settings.ADJ.filter.Q_DCB),       ' | ', settings.ADJ.filter.dynmodel_DCB);
    end
    if strcmp(settings.PROC.method, 'Code + Phase')
        fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Float Ambiguities:  ',sqrt(settings.ADJ.filter.var_amb),      ' | ',sqrt(settings.ADJ.filter.Q_amb),       ' | ', settings.ADJ.filter.dynmodel_amb);
    end
    if contains(settings.IONO.model, 'Estimate')
        fprintf(fileID,'    %s%11.3f%s%11.3f%s%d\n','Ionosphere:         ',sqrt(settings.ADJ.filter.var_iono),     ' | ',sqrt(settings.ADJ.filter.Q_iono),      ' | ', settings.ADJ.filter.dynmodel_iono);
    end
end
fprintf(fileID,'\n');



%% Estimation - Ambiguity Fixing

fprintf(fileID,'%s\n','Ambiguity Fixing: ');
if settings.AMBFIX.bool_AMBFIX
    fprintf(fileID,'  %s%.0f%s%.0f%s\n','Fixing-Start [seconds]: WL = ',settings.AMBFIX.start_WL_sec,', NL = ',settings.AMBFIX.start_NL_sec);
    fprintf(fileID,'  %s%.2f%s%.2f%s%.0f%s\n','HMW fixing: threshold = ', settings.AMBFIX.HMW_thresh, ' [cy], releasing threshold = ', settings.AMBFIX.HMW_release, ' [cy], window = ', settings.AMBFIX.HMW_window, ' [s]');
    fprintf(fileID,'  %s%d\n','Fixing cutoff [°]: ', settings.AMBFIX.cutoff);
    fprintf(fileID,'  %s%s\n','Choice of Reference Satellite: ', settings.AMBFIX.refSatChoice);
    if strcmp(settings.AMBFIX.refSatChoice, 'manual choice (list):')
        fprintf(fileID,'    %s%d\n','Manual reference satellite list for GPS: ', settings.AMBFIX.refSatGPS);
        fprintf(fileID,'    %s%d\n','Manual reference satellite list for Galileo: ', settings.AMBFIX.refSatGAL);
		fprintf(fileID,'    %s%d\n','Manual reference satellite list for BeiDou: ', settings.AMBFIX.refSatBDS);
    end
    if isempty(settings.AMBFIX.exclude_sats_fixing)
        fprintf(fileID,'  %s\n','No satellites excluded from fixing.');
    else
        fprintf(fileID,'  %s%s\n','Excluded satellites from fixing: ', num2str(settings.AMBFIX.exclude_sats_fixing'));
    end
    fprintf(fileID,'  %s%s\n','Detection of Wrong Fixes: ', settings.AMBFIX.wrongFixes);
else
    fprintf(fileID,'  %s\n','Off');
end
fprintf(fileID,'\n');


%% Run - Processing Options

fprintf(fileID,'%s\n','Processing Options:');

fprintf(fileID,'  %s%s\n','Output: ', settings.PROC.output_dir);
if settings.PROC.timeSpan_format_epochs
    fprintf(fileID,'  %s%d%s%d\n','Epochs: ',settings.PROC.timeFrame(1),' - ',settings.PROC.timeFrame(2));
elseif settings.PROC.timeSpan_format_SOD
    fprintf(fileID,'  %s%d%s%d\n','Seconds of Day: ',settings.PROC.timeFrame(1),' - ',settings.PROC.timeFrame(2));
elseif settings.PROC.timeSpan_format_HOD
    fprintf(fileID,'  %s%d%s%d\n','Hours of Day ',settings.PROC.timeFrame(1),' - ',settings.PROC.timeFrame(2));
end
if settings.PROC.reset_float || settings.PROC.reset_fixed
    if settings.PROC.reset_bool_min
        fprintf(fileID,'  %s%d%s\n','Reset solution after ', settings.PROC.reset_after, ' minutes');
    elseif settings.PROC.reset_bool_epoch
        fprintf(fileID,'  %s%d%s\n','Reset solution after ', settings.PROC.reset_after, ' epochs');
    end
end
if settings.INPUT.use_GPS
    fprintf(fileID,'  %s%s%s%s%s%s\n','GPS-Frequencies: ',settings.INPUT.gps_freq{1},', ',settings.INPUT.gps_freq{2},', ',settings.INPUT.gps_freq{3});
    fprintf(fileID,'  GPS-Ranking: %s\n', settings.INPUT.gps_ranking);
end
if settings.INPUT.use_GLO
    fprintf(fileID,'  %s%s%s%s%s%s\n','Glonass-Frequencies: ',settings.INPUT.glo_freq{1},', ',settings.INPUT.glo_freq{2},', ',settings.INPUT.glo_freq{3});
    fprintf(fileID,'  Glonass-Ranking: %s\n', settings.INPUT.glo_ranking);
end
if settings.INPUT.use_GAL
    fprintf(fileID,'  %s%s%s%s%s%s\n','Galileo-Frequencies: ',settings.INPUT.gal_freq{1},', ',settings.INPUT.gal_freq{2},', ',settings.INPUT.gal_freq{3});
    fprintf(fileID,'  %s%s\n','Galileo-Ranking: ', settings.INPUT.gal_ranking);
end
if settings.INPUT.use_BDS
    fprintf(fileID,'  %s%s%s%s%s%s\n','BeiDou-Frequencies: ',settings.INPUT.bds_freq{1},', ',settings.INPUT.bds_freq{2},', ',settings.INPUT.bds_freq{3});
    fprintf(fileID,'  %s%s\n','BeiDou-Ranking: ', settings.INPUT.bds_ranking);
end

% adjust phase to code
if settings.PROC.AdjustPhase2Code
    fprintf(fileID,'  %s\n','Adjust phase to code is ON');
else
    fprintf(fileID,'  %s\n','Adjust phase to code is OFF');
end



% print excluded satellites from processing
fprintf(fileID,'  Excluded Satellites:\n');
excl_matrix_sats = settings.PROC.exclude;
n = size(excl_matrix_sats,1);
bool = false;
for i = 1:n
    prn =   excl_matrix_sats{i,1};
    start = excl_matrix_sats{i,2};
    ende =  excl_matrix_sats{i,3};
    if isempty(prn)
        continue
    end
    if isempty(start)
        start = 0;
    end
    if isempty(ende)
        ende = Inf;
    end
    if ischar(prn)
        fprintf(fileID, '    %s%s','PRN ',  prn);
    else
        fprintf(fileID, '    %s%s','PRN ',  sprintf('%03d', prn));
    end
    fprintf(fileID, '%s%s',', from ', sprintf('%6d', start));
    fprintf(fileID, '%s%s',' to ', sprintf('%6d', ende));
    fprintf(fileID,'\n');
    bool = true;
end
if ~bool
    fprintf(fileID, '    None\n');
end

% print from processing excluded epochs 
fprintf(fileID,'  Excluded Epochs:\n');
excl_matrix_eps = settings.PROC.exclude_epochs;
n = size(excl_matrix_eps,1);
bool = false;
for i = 1:n
    start =  excl_matrix_eps{i,1};
    ende  =  excl_matrix_eps{i,2};
    reset =  excl_matrix_eps{i,3};
    if isempty(start)
        continue
    end
    if isempty(ende)
        ende = Inf;
    end
    fprintf(fileID, '    %s%s','From ', sprintf('%6d', start));
    fprintf(fileID, '%s%s',' to ', sprintf('%6d', ende));
    if reset
        fprintf(fileID,', with reset\n');
    else
        fprintf(fileID,', no reset\n');
    end
    bool = true;
end
if ~bool
    fprintf(fileID, '    None\n');
end

fprintf(fileID,'  Satellite Exclusion Criteria:\n');
fprintf(fileID,'    %s%d%s\n', 'Elevation Cutoff: ',settings.PROC.elev_mask,' [°]');
fprintf(fileID,'    %s%s%s\n', 'C/N0 Cutoff: ', num2str(settings.PROC.SNR_mask),' [db-Hz]');
fprintf(fileID,'    %s%d\n', 'Signal Strength Threshold: ',settings.PROC.ss_thresh);
if settings.PROC.check_omc
    fprintf(fileID,'    %s\n', 'Check of observed minus (omc) computed is ON.');
    fprintf(fileID,'      %s%06.3f\n', 'Threshold Code  [m]: ', settings.PROC.omc_code_thresh);
    fprintf(fileID,'      %s%06.3f\n', 'Threshold Phase [m]: ', settings.PROC.omc_phase_thresh);
    fprintf(fileID,'      %s%d%s%d\n', 'Factor: ', settings.PROC.omc_factor, '; Window: ', settings.PROC.omc_window);

else
    fprintf(fileID,'    %s\n', 'Check of observed minus (omc) computed is OFF.');
end
fprintf(fileID,'\n');



%% Station information
fprintf(fileID,'General Information:\n');  
fprintf(fileID,'  Station name: %s\n', obs.stationname);
fprintf(fileID,'  Observation interval: %02.2f seconds\n', obs.interval);
fprintf(fileID,'  Antenna:  %s\n', obs.antenna_type);
fprintf(fileID,'  Receiver: %s\n', obs.receiver_type);
fprintf(fileID,'  Receiver antenna delta (H/E/N): %02.4f / %02.4f / %02.4f\n', obs.rec_ant_delta(1), obs.rec_ant_delta(2), obs.rec_ant_delta(3));

fprintf(fileID,'  Time of 1st observation (y, m, d, h, min, sec): ');
fprintf(fileID,'%04.0f %02.0f %02.0f %02.0f %02.0f %02.0f', obs.startdate(1), obs.startdate(2), obs.startdate(3), obs.startdate(4), obs.startdate(5), obs.startdate(6));
fprintf(fileID,', jd: %13.5f', obs.startdate_jd);
fprintf(fileID,', doy: %01.0f', floor(obs.doy));
fprintf(fileID,', gps-date: %04.0f / %02.0f\n', obs.startGPSWeek, floor(obs.startSow/86400));

fprintf(fileID,'  Leap seconds: %02.2f\n', obs.leap_sec);
fprintf(fileID,'\n');


%% Export options
fprintf(fileID,'Export options:\n');
fprintf(fileID,'  Output\n');
if settings.EXP.data4plot
    fprintf(fileID,'    data4plot.mat is exported\n');
end
if settings.EXP.model_save
    fprintf(fileID,'    model_save is saved to data4plot.mat\n');
end
if settings.EXP.results_float
    fprintf(fileID,'    results_float.txt is written\n');
end
if settings.AMBFIX.bool_AMBFIX && settings.EXP.results_fixed
    fprintf(fileID,'    results_fixed.txt is written\n');
end
if settings.EXP.settings
    fprintf(fileID,'    settings.mat is exported\n');
end
if settings.EXP.settings_summary
    fprintf(fileID,'    settings_summary.txt is written\n');
end
fprintf(fileID,'  Variables\n');
if settings.EXP.obs_bias
    fprintf(fileID,'    C1_/.../L1_/.../L3_bias is saved to obs\n');
end
if settings.EXP.obs_epochheader
    fprintf(fileID,'    epochheader is saved to obs\n');
end
if settings.EXP.storeData_iono_mf
    fprintf(fileID,'    iono_mf is saved to storeData\n');
end
if settings.EXP.storeData_vtec
    fprintf(fileID,'    vtec is saved to storeData\n');
end
if settings.EXP.storeData_mp_1_2
    fprintf(fileID,'    mp1, mp2 is saved to storeData\n');
end



%% Processing end and time
fprintf(fileID,'\n\n');
fprintf(fileID,'Processing:\n');
if ~settings.INPUT.bool_batch
    fprintf(fileID,'  Type: Single File\n');
else
    if settings.INPUT.bool_parfor
        fprintf(fileID,'  Type: Batch, parfor loop\n');
    else
        fprintf(fileID,'  Type: Batch, for loop\n');
    end
end
proc_time = toc(tStart);
sec = mod(proc_time,60);
min = floor(proc_time/60);
proc_string = ['  Duration: ' sprintf('%.0f', min) 'min ' sprintf('%02.02f',sec) 'sec'];
fprintf(fileID,'%s\n',proc_string);
fprintf(fileID,'  End: %s\n', datestr(clock));



%% raPPPid version
try
    [~,git_hash_str] = system('git rev-parse HEAD');
    git_hash_str = strtrim(git_hash_str);
    fprintf(fileID,'  Version: %s', git_hash_str);
catch
    fprintf(fileID,'  Version: %s', 'detection failed');
end



%% close file
fclose(fileID);






