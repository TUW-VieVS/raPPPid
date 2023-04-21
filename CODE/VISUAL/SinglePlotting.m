function [] = SinglePlotting(satellites, storeData, obs, settings)
% Creating all the plots which are implemented. Function is started from
% GUI_PPP.m. Needs the following input which can be loaded from
% data4plot.mat:
% 
% INPUT:
%   satellites 	struct, satellite specific data
%   storeData  	struct, has collected data from each epoch
%   obs      	struct, observations and corresponding data from rinex-observation file
%   settings	struct, settings from GUI
% OUTPUT:
%   []
% 
% using distinguishable_colors.m (c) 2010-2011, Tim Holy
% 
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Preparations

fprintf('\n');      % Print empty line
global STOP_CALC
STOP_CALC = 0;

if ~any(storeData.float)
    return          % no float solution in any epoch
end  

epochs = 1:numel(storeData.gpstime);       % vector, 1:#epochs
% true if GNSS was processed and should be plotted 
isGPS = settings.INPUT.use_GPS;          
isGLO = settings.INPUT.use_GLO;
isGAL = settings.INPUT.use_GAL;
isBDS = settings.INPUT.use_BDS;

% take position depending on selected solution
if settings.PLOT.fixed && settings.AMBFIX.bool_AMBFIX
    try; pos_cart = storeData.xyz_fix(:,1:3); catch; pos_cart = storeData.param_fix(:,1:3); end
    pos_geo = storeData.posFixed_geo;
    pos_utm = storeData.posFixed_utm;
    floatfix = 'fixed';				% string to indicate in plots which solution
else 
    pos_cart = storeData.param(:,1:3);
    pos_geo = storeData.posFloat_geo;
    pos_utm = storeData.posFloat_utm;
    floatfix = 'float';
    if strcmp(settings.PROC.method, 'Code Only')
        floatfix = 'Code Only';
    elseif strcmp(settings.PROC.method, 'Code (Doppler Smoothing)')
        floatfix = 'Code smoothed';
    end
end

% get true position
bool_zero = all(pos_cart == 0,2);   % all three coordinates are zero
if isa(settings.PLOT.pos_true, 'double') || ~isfile(settings.PLOT.pos_true)
    pos_true = settings.PLOT.pos_true;
    bool_true_pos = true;
    if any(isnan(pos_true) | pos_true == 0 | pos_true == 1)     % no valid true position
        pos_cart(bool_zero, :) = [];        % remove those
        pos_true = median(pos_cart, 1, 'omitnan'); 	% take median position for coordinate differences
        bool_true_pos = false;
    end
    % transform true positions in phi, lambda, h of WGS84 and into UTM
    pos_true_geo = cart2geo(pos_true);   % true ellipsoidal coordinates
    [North_true, East_true] = ell2utm_GT(pos_true_geo.ph, pos_true_geo.la);   % true UTM North and East coordinates
else        % reference trajectory
    bool_true_pos = true;
    [pos_true_geo, North_true, East_true] = ...
        LoadReferenceTrajectory(settings.PLOT.pos_true, obs.leap_sec, storeData.gpstime);
end    

% time-related stuff
sow = storeData.gpstime;        % time of epochs in seconds of week
sow = round(10*sow)/10;         % needed if observation in RINEX are not to full second
seconds = sow - sow(1);
hours = seconds / 3600;
interval = storeData.obs_interval;

% time of resets in seconds of week
reset_sow = storeData.gpstime(storeData.float_reset_epochs);
% time of resets in seconds since beginning of processing
reset_sec = round(reset_sow - sow(1));
reset_h = reset_sec / 3600;

% create string for title of plot with station name and startdate (yyyy, doy)
station = obs.stationname;
[doy, yyyy] = jd2doy_GT(obs.startdate_jd(1));
station_date = [station, ' ', sprintf('%4.0f',yyyy), '/', sprintf('%03.0f',doy)];

rgb = distinguishable_colors(40);      % colors for plot, no GNSS has more than 40 satellites


%% START PLOTTING FIGURES OF GENERAL RESULTS
% --------------------------------------------------------------------
[~, hour, min, sec] = sow2dhms(storeData.gpstime(1));
label_x_sec = ['[s], 1st Epoch: ', sprintf('%02d',hour),   'h:',   sprintf('%02d',min),   'm:',   sprintf('%02.0f',sec),   's'];
label_x_h   = ['[h], 1st Epoch: ', sprintf('%02d',hour),   'h:',   sprintf('%02d',min),   'm:',   sprintf('%02.0f',sec),   's'];
label_x_time =  ['Time, 1st Epoch: ', sprintf('%02d',hour),   'h:',   sprintf('%02d',min),   'm:',   sprintf('%02.0f',sec),   's'];
label_x_epc = 'Epochs';

if settings.PLOT.coordxyz || settings.PLOT.UTM || settings.PLOT.coordinate
    % calculate differences to true UTM position
    dN = pos_utm(:,1) - North_true;
    dE = pos_utm(:,2) - East_true;
    dH = pos_utm(:,3) - pos_true_geo.h;
end


% -+-+-+-+- Figure: Coordinate Plot -+-+-+-+-
% implemented as GUI
if settings.PLOT.coordinate
    dN(isnan(dN)) = 0;     dE(isnan(dE)) = 0;     dH(isnan(dH)) = 0;
    CoordinatePlot(epochs, dN', dE', dH', sow, label_x_sec, seconds, reset_sec, station_date, floatfix);
end
if STOP_CALC; return; end


% -+-+-+-+- Figure: Three Coordinates Plot -+-+-+-+-
% Coordinates over Time, dU & dN & dE in ONE Plot
if settings.PLOT.coordxyz
    % calculate differences to true UTM position
    ThreeCoordinatesPlot(interval, sow, dN, dE, dH, reset_sow, label_x_time, station_date, floatfix);
end
if STOP_CALC; return; end


% -+-+-+-+- Figure: Map Plot -+-+-+-+-
if settings.PLOT.map
    if true
        velocityPlot(pos_cart, seconds, bool_zero, label_x_sec)
    end
    vis_MaPlot(pos_geo(:,1)*180/pi, pos_geo(:,2)*180/pi, bool_true_pos, ...
        pos_true_geo.ph*180/pi, pos_true_geo.la*180/pi, station_date, floatfix)
end
if STOP_CALC; return; end


% -+-+-+-+- Figure: UTM Plot -+-+-+-+-
if settings.PLOT.UTM
    vis_plotCoordinateAccuracy(dN, dE, station_date, floatfix)
end
if STOP_CALC; return; end


% -+-+-+-+- Figure: DOP Plot -+-+-+-+-
% Plot DOPs
if settings.PLOT.DOP
    DOPS = [storeData.PDOP, storeData.HDOP, storeData.VDOP];
    DOPlot(DOPS', label_x_sec, seconds, reset_sec);
end
if STOP_CALC; return; end   %#ok<*UNRCH>


% -+-+-+-+- Figure: Clock Plot -+-+-+-+-
if settings.PLOT.clock
    vis_plotReceiverClock(hours, label_x_h, storeData.param', reset_h, ...
        isGPS, isGLO, isGAL, isBDS, settings.ORBCLK.file_clk, station, obs.startdate(1:3));
end
if STOP_CALC; return; end


% -+-+-+-+- Figure: DCB Plot -+-+-+-+- 
if settings.PLOT.dcb
    if settings.BIASES.estimate_rec_dcbs
        vis_plotReceiverDCBs(hours, label_x_h, storeData.param', reset_h, settings, obs);
    else
        fprintf('No DCBs estimated.\n');
    end  
end
if STOP_CALC; return; end


% -+-+-+-+- Figure: Wet Troposphere Plot -+-+-+-+-
if settings.PLOT.wet_tropo && settings.TROPO.estimate_ZWD
    TropoPlot(hours, label_x_h, storeData, reset_h, obs.startdate, obs.station_long)
%     vis_plotTroposphere(hours, label_x_h, storeData, reset_h);    % OLD
end
if STOP_CALC; return; end


% -+-+-+-+- Figure: Standard Deviation of Parameters -+-+-+-+-
if settings.PLOT.cov_info
    std_parameters = sqrt(storeData.param_var)';
    covParaPlot(hours, std_parameters, label_x_h, settings.BIASES.estimate_rec_dcbs, isGPS, isGLO, isGAL, isBDS)
end
if STOP_CALC; return; end


%% START PLOTTING FIGURES OF SAT SPECIFIC RESULTS

% -+-+-+-+- Figure: Satellite Visibility Plot -+-+-+-+-
if settings.PLOT.satvisibility
    if ~isfield (storeData, 'exclude')
        storeData.exclude = storeData.cutoff;       % old processing results
    end
    vis_plotSatConstellation(hours, epochs, label_x_h, satellites, storeData.exclude, isGPS, isGLO, isGAL, isBDS)
end
if STOP_CALC; return; end


if strcmpi(settings.PROC.method,'Code + Phase')
    %     -+-+-+-+- Figure: Float Ambiguity Plots -+-+-+-+-
    if settings.PLOT.float_amb
        if isGPS    % GPS processed
            FloatAmbPlot(hours, storeData, 1:DEF.SATS_GPS,       settings.INPUT.proc_freqs, label_x_h, 'G', reset_h, rgb);
        end
        if isGLO
            FloatAmbPlot(hours, storeData, 101:100+DEF.SATS_GLO, settings.INPUT.proc_freqs, label_x_h, 'R', reset_h, rgb)
        end
        if isGAL
            FloatAmbPlot(hours, storeData, 201:200+DEF.SATS_GAL, settings.INPUT.proc_freqs, label_x_h, 'E', reset_h, rgb)
        end
        if isBDS
            FloatAmbPlot(hours, storeData, 301:300+DEF.SATS_BDS, settings.INPUT.proc_freqs, label_x_h, 'C', reset_h, rgb)
        end
    end    
    %     -+-+-+-+- Figure: Fixed Ambiguity Plots -+-+-+-+-
    if settings.PLOT.fixed_amb && settings.AMBFIX.bool_AMBFIX
        printAmbiguityFixingRates(storeData, settings, satellites)
        vis_plotFixedAmbiguities(settings, isGPS, isGAL, isBDS, storeData, label_x_epc, satellites)
    end
end
if STOP_CALC; return; end


%     -+-+-+-+- Figure: Observation Residuals Plot  -+-+-+-+-
%                       for Code & Phase and for each GNSS
if settings.PLOT.residuals
    plotResiduals(storeData, settings, epochs, reset_h, hours, label_x_h, satellites, rgb);
end
if STOP_CALC; return; end


%     -+-+-+-+- Figure: Elevation Plot  -+-+-+-+-
if settings.PLOT.elevation
    if ~isfield (storeData, 'exclude')
        storeData.exclude = storeData.cutoff;       % old processing results
    end
    elevPlot(satellites.elev, storeData.exclude, settings, label_x_h, hours);
end
if STOP_CALC; return; end


%     -+-+-+-+- Figure: Standard Deviation of Ambiguities  -+-+-+-+-
if settings.PLOT.cov_amb && strcmpi(settings.PROC.method,'Code + Phase')
    std_amb = sqrt(full(storeData.N_var_1));      % standard deviations of estimated ambiguities
    if settings.INPUT.proc_freqs > 1; std_amb(:,:,2) = sqrt(full(storeData.N_var_2)); end
    if settings.INPUT.proc_freqs > 2; std_amb(:,:,3) = sqrt(full(storeData.N_var_3)); end
    vis_covAmbPlot(hours, std_amb, settings.ADJ.filter.var_amb, label_x_h, rgb, satellites.obs, isGPS, isGLO, isGAL, isBDS)
end
if STOP_CALC; return; end


%     -+-+-+-+- Figure: Skyplot  -+-+-+-+-
if settings.PLOT.skyplot
    % ||| only the first frequency is taken for color-coding, CHANGE!!!
    % ||| fixed residuals
    SkyPlot(satellites, storeData, epochs, station_date, isGPS, isGLO, isGAL, isBDS, settings.PROC.elev_mask, settings.PLOT.fixed);
end
if STOP_CALC; return; end


%     -+-+-+-+- Figure: Signal Quality Plots  -+-+-+-+-
if settings.PLOT.signal_qual
    % calculate code minus phase
    satellites.CL_1 = full(storeData.C1) - full(storeData.L1);
    satellites.CL_2 = full(storeData.C2) - full(storeData.L2);
    satellites.CL_3 = full(storeData.C3) - full(storeData.L3);
    signQualPlot(satellites, label_x_h, hours, isGPS, isGLO, isGAL, isBDS, settings);
end
if STOP_CALC; return; end


%     -+-+-+-+- Figures: Ionospheric Correction Plot  -+-+-+-+-
if settings.PLOT.iono
    if strcmpi(settings.IONO.model,'Correct with ...')   ||   strcmpi(settings.IONO.model,'Estimate with ... as constraint')   ||   strcmpi(settings.IONO.model,'Estimate')
        obs_bool = logical(full(satellites.obs));
        vis_iono_plot(settings, storeData, label_x_h, hours, reset_h, obs_bool, rgb);
        vis_ionodiff_histo(settings, storeData, obs_bool, full(satellites.elev));
    else
        fprintf('No Ionosphere correction was used.\n');
    end
end
if STOP_CALC; return; end


%     -+-+-+-+- Figures: Cycle Slip Detection Plot  -+-+-+-+-
if settings.PLOT.cs && strcmpi(settings.PROC.method,'Code + Phase')
    % L1-C1 Difference
    if settings.OTHER.CS.l1c1
        if isGPS; vis_cs_SF(storeData, settings.OTHER.CS, 'G'); end
        if isGLO; vis_cs_SF(storeData, settings.OTHER.CS, 'R'); end
        if isGAL; vis_cs_SF(storeData, settings.OTHER.CS, 'E'); end
        if isBDS; vis_cs_SF(storeData, settings.OTHER.CS, 'C'); end
    else
        fprintf('L1-C1 Cycle-Slip-Detection disabled.           \n')
    end
    % dLi-dLj Difference
    if settings.OTHER.CS.DF      
        if isGPS; vis_cs_DF(storeData, 'G', settings.OTHER.CS.DF_threshold, satellites.elev); end
        if isGLO; vis_cs_DF(storeData, 'R', settings.OTHER.CS.DF_threshold, satellites.elev); end
        if isGAL; vis_cs_DF(storeData, 'E', settings.OTHER.CS.DF_threshold, satellites.elev); end
        if isBDS; vis_cs_DF(storeData, 'C', settings.OTHER.CS.DF_threshold, satellites.elev); end
    else
        fprintf('dLi-dLj Cycle-Slip-Detection disabled.          \n')
    end
    % Doppler-Shift
    if settings.OTHER.CS.Doppler	
        if isGPS; vis_cs_Doppler(storeData, 'G', settings.OTHER.CS.D_threshold, settings.INPUT.proc_freqs); end
        if isGLO; vis_cs_Doppler(storeData, 'R', settings.OTHER.CS.D_threshold, settings.INPUT.proc_freqs); end
        if isGAL; vis_cs_Doppler(storeData, 'E', settings.OTHER.CS.D_threshold, settings.INPUT.proc_freqs); end
        if isBDS; vis_cs_Doppler(storeData, 'C', settings.OTHER.CS.D_threshold, settings.INPUT.proc_freqs); end
    else
        fprintf('Cycle-Slip-Detection with Doppler disabled.          \n')
    end
    % Time difference
    if isfield(settings.OTHER.CS, 'TimeDifference') && settings.OTHER.CS.TimeDifference	
        if isGPS; vis_cs_time_difference(storeData, 'G', settings.OTHER.CS.TD_degree, settings.OTHER.CS.TD_threshold); end
        if isGLO; vis_cs_time_difference(storeData, 'R', settings.OTHER.CS.TD_degree, settings.OTHER.CS.TD_threshold); end
        if isGAL; vis_cs_time_difference(storeData, 'E', settings.OTHER.CS.TD_degree, settings.OTHER.CS.TD_threshold); end
        if isBDS; vis_cs_time_difference(storeData, 'C', settings.OTHER.CS.TD_degree, settings.OTHER.CS.TD_threshold); end
    else
        fprintf('Cycle-Slip-Detection with time difference disabled.          \n')
    end
end
if STOP_CALC; return; end


%     -+-+-+-+- Figures: Multipath Detection  -+-+-+-+-
if settings.PLOT.mp
    if (isfield(settings.OTHER, 'mp_detection') || settings.OTHER.mp_detection)
        C1_diff = zero2nan(storeData.mp_C1_diff_n);
        PlotObsDiff(epochs, C1_diff, label_x_epc, rgb, 'C1 difference', settings, satellites.obs, settings.OTHER.mp_thresh, settings.OTHER.mp_degree, '', false);
    else
        fprintf('Multipath detection disabled.          \n')
        
    end
end
if STOP_CALC; return; end


%     -+-+-+-+- Figures: Residuals for each satellite  -+-+-+-+-
% ||| check division in float and fixed
if settings.PLOT.res_sats
    if isGPS
        vis_res_sats(storeData, 'G', settings.INPUT.proc_freqs, strcmp(settings.PROC.method, 'Code + Phase')', settings.PLOT.fixed);
    end
    if isGLO
        vis_res_sats(storeData, 'R', settings.INPUT.proc_freqs, strcmp(settings.PROC.method, 'Code + Phase')', settings.PLOT.fixed);
    end
    if isGAL
        vis_res_sats(storeData, 'E', settings.INPUT.proc_freqs, strcmp(settings.PROC.method, 'Code + Phase')', settings.PLOT.fixed);
    end
    if isBDS
        vis_res_sats(storeData, 'C', settings.INPUT.proc_freqs, strcmp(settings.PROC.method, 'Code + Phase')', settings.PLOT.fixed);
    end
end
if STOP_CALC; return; end


%     -+-+-+-+- Figures: Correlation Plot  -+-+-+-+-
if settings.PLOT.corr
    CorrelationPlot(storeData, satellites, settings, epochs);
end
if STOP_CALC; return; end


%     -+-+-+-+- Figures: Plot stream corrections  -+-+-+-+-
if settings.PLOT.stream_corr && settings.ORBCLK.bool_brdc && ~isempty(settings.ORBCLK.file_corr2brdc)
    % load in corrections
    filename = settings.ORBCLK.file_corr2brdc;
    if contains(filename, '$')
        % replace potential pseudo-code
        filename = ConvertStringDate(filename, obs.startdate(1:3));
    end
    if ~contains(filename, '.mat'); filename = [filename, '.mat']; end
    if isfile(filename)
        if isGPS	% Plot for GPS
            load(filename, 'corr2brdc_GPS');
            plotCorrection2BRDC(corr2brdc_GPS, obs, filename, 'G');
        end
        % ||| GLONASS is missing!!!
        if isGAL	% Plot for Galileo
            load(filename, 'corr2brdc_GAL');
            plotCorrection2BRDC(corr2brdc_GAL, obs, filename, 'E');
        end
        if isBDS	% Plot for BeiDou
            load(filename, 'corr2brdc_GAL');
            plotCorrection2BRDC(corr2brdc_GAL, obs, filename, 'E');
        end
    end
end
if STOP_CALC; return; end


%     -+-+-+-+- Figures: Applied Biases Plot  -+-+-+-+-
if settings.PLOT.appl_biases
    plotAppliedBiases(storeData, isGPS, isGLO, isGAL, isBDS)
end
if STOP_CALC; return; end





