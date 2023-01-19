function [model, Epoch] = modelErrorSources(settings, input, Epoch, model, Adjust, obs)
% This functions models all relevant error sources for PPP and saves it
% into the struct model. This is used later for modelling the observations.
% 
% INPUT:
%   settings    	settings from GUI  [struct]
%   input           input data (ephemerides, PCOs, etc.)   [struct]
%   Epoch           epoch-specific data for current epoch  [struct]
%   model           model corrections for all visible sats [struct]
%   Adjust          adjustment/filter relevant variables [struct]
%   obs             consisting observations and corresponding data   [struct]
% OUTPUT:
%   model           extended with modelled corrections to current satellite, [struct]
%   Epoch           update of .excluded
%  
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


param = Adjust.param;
pos_XYZ = param(1:3);       % current estimation of receiver position [XYZ]
% ellipsoidal coordinates of WGS84 ellipsoid
% .ph = phi = latitude [rad]; .la = lambda = longitude [rad]; .h = height [m]
pos_WGS84 = cart2geo(pos_XYZ);	

n_proc_frq = settings.INPUT.proc_freqs; % number of processed frequencies (e.g. 1 for IF-LC)
n_num_frq  = settings.INPUT.num_freqs;  % number of input frequencies (e.g. 2 for IF-LC)
frqs = 1:n_proc_frq;
num_sat = Epoch.no_sats;                % number of satellites in current epoch
% indices of processed frequencies
j = 1:n_num_frq;
idx_frqs_gps = settings.INPUT.gps_freq_idx(j);
idx_frqs_glo = settings.INPUT.glo_freq_idx(j);
idx_frqs_gal = settings.INPUT.gal_freq_idx(j);
idx_frqs_bds = settings.INPUT.bds_freq_idx(j);
% remove frequencies set to OFF (if different number of frequencies is 
% processed for different GNSS)
idx_frqs_gps(idx_frqs_gps>DEF.freq_GPS(end)) = [];
idx_frqs_glo(idx_frqs_glo>DEF.freq_GLO(end)) = [];
idx_frqs_gal(idx_frqs_gal>DEF.freq_GAL(end)) = [];
idx_frqs_bds(idx_frqs_bds>DEF.freq_BDS(end)) = [];


%% Epoch-specific corrections
% corrections which are valid for all satellites but only for a specific epoch


if isempty(model)
    model = init_struct_model(num_sat, n_proc_frq);  	% Init struct model
    % --- Calculate hour and approximate sun and moon position for epoch ---
    h = mod(Epoch.gps_time,86400)/3600;
    model.sunECEF  = sunPositionECEF (obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
    model.moonECEF = moonPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
    % --- Calculate epoch-dependent tide corrections (only approximate position needed) ---
    if settings.OTHER.bool_solid_tides
        model.solid_tides_ECEF = solid_tides(pos_XYZ, pos_WGS84.ph, model.sunECEF*1000, model.moonECEF);
    end
    if settings.OTHER.ocean_loading
        model.ocean_loading_ECEF = ocean_loading(Epoch.gps_time, pos_XYZ, input.OTHER.OcLoad, 19+obs.leap_sec, obs.startGPSWeek);
    end
    % --- Rotation Matrix from Local Level to ECEF ---
    model.R_LL2ECEF = setupRotation_LL2ECEF(pos_WGS84.ph, pos_WGS84.la);
end


% do the following only, if the a priori zenith delays should be modeled at all
if ~(strcmpi(settings.TROPO.zhd,'no')   &&   strcmpi(settings.TROPO.zwd,'no'))
    
    % VMF3: interpolate to the respective mjd
    if strcmpi(settings.TROPO.zhd,'VMF3')   ||   strcmpi(settings.TROPO.zwd,'VMF3')   ||   strcmpi(settings.TROPO.mfh,'VMF3')   ||   strcmpi(settings.TROPO.mfh,'VMF3')
        ah_VMF3  = interp1(input.TROPO.V3GR.data{2},input.TROPO.V3GR.data{3},Epoch.mjd,'spline',9999);
        aw_VMF3  = interp1(input.TROPO.V3GR.data{2},input.TROPO.V3GR.data{4},Epoch.mjd,'spline',9999);
        zhd_VMF3 = interp1(input.TROPO.V3GR.data{2},input.TROPO.V3GR.data{5},Epoch.mjd,'spline',9999);
        zwd_VMF3 = interp1(input.TROPO.V3GR.data{2},input.TROPO.V3GR.data{6},Epoch.mjd,'spline',9999);
        
        if ah_VMF3==9999   ||   aw_VMF3==9999   ||   zhd_VMF3==9999   ||   zwd_VMF3==9999      % actually, this should never happen
            errordlg('The interpolation of VMF3 failed because the mjd is out of bounds. Check the code in readAllInputFiles.m!')
            error('The interpolation of VMF3 failed because the mjd is out of bounds. Check the code in readAllInputFiles.m!')
        end
    end
    
    % GRAD: interpolate to the respective mjd
    if strcmpi(settings.TROPO.Gh,'GRAD')   ||   strcmpi(settings.TROPO.Gw,'GRAD')
        Gn_h_GRAD = interp1(input.TROPO.V3GR.data{2},input.TROPO.V3GR.data{10},Epoch.mjd,'spline',9999)/1000;   % [mm] --> [m]
        Ge_h_GRAD = interp1(input.TROPO.V3GR.data{2},input.TROPO.V3GR.data{11},Epoch.mjd,'spline',9999)/1000;   % [mm] --> [m]
        Gn_w_GRAD = interp1(input.TROPO.V3GR.data{2},input.TROPO.V3GR.data{12},Epoch.mjd,'spline',9999)/1000;   % [mm] --> [m]
        Ge_w_GRAD = interp1(input.TROPO.V3GR.data{2},input.TROPO.V3GR.data{13},Epoch.mjd,'spline',9999)/1000;   % [mm] --> [m]
        
        if Gn_h_GRAD==9999   ||   Ge_h_GRAD==9999   ||   Gn_w_GRAD==9999   ||   Ge_w_GRAD==9999      % actually, this should never happen
            errordlg('The interpolation of GRAD failed because the mjd is out of bounds. Check the code in readAllInputFiles.m!')
            error('The interpolation of GRAD failed because the mjd is out of bounds. Check the code in readAllInputFiles.m!')
        end
    end

    
    % GPT3: read the model values for the respective mjd
    if strcmpi(settings.TROPO.zhd,'p (GPT3) + Saastamoinen')   ||   strcmpi(settings.TROPO.zwd,'e (GPT3) + Askne')   ||   strcmpi(settings.TROPO.zwd,'e (in situ) + Askne')   ||   strcmpi(settings.TROPO.mfh,'GPT3')   ||   strcmpi(settings.TROPO.mfw,'GPT3')  ||   strcmpi(settings.TROPO.Gh,'GPT3')   ||   strcmpi(settings.TROPO.Gw,'GPT3')   ||   strcmpi(settings.TROPO.zhd,'Tropo file')
        [ p_GPT3, ~, ~, Tm_GPT3, e_GPT3, ah_GPT3, aw_GPT3, lambda_GPT3, ~, Gn_h_GPT3, Ge_h_GPT3, Gn_w_GPT3, Ge_w_GPT3 ] = ...
            gpt3_5_fast(Epoch.mjd, pos_WGS84.ph, pos_WGS84.la, pos_WGS84.h, 0, input.TROPO.GPT3.cell_grid );
    end

end



%% Loop over satellites


for i_sat = 1:num_sat                     
    %% Preparations
    prn = Epoch.sats(i_sat);       % [1-99] GPS, [101-199] GLO, [201-250] GAL, [301-399] BDS
    sv = mod(prn,100);
    isGLO = Epoch.glo(i_sat);      % is current satellite a glonass sat.?
    isGPS = Epoch.gps(i_sat);      % is current satellite a gps sat.?
    isGAL = Epoch.gal(i_sat);      % is current satellite a galileo sat.?
    isBDS = Epoch.bds(i_sat);      % is current satellite a beidou sat.?
    f1 = Epoch.f1(i_sat);   f2 = Epoch.f2(i_sat);   f3 = Epoch.f3(i_sat);
    if strcmpi(settings.IONO.model,'3-Frequency-IF-LC')
        y2 = f1.^2 ./ f2.^2;            % coefficients of 3-Frequency-IF-LC
        y3 = f1.^2 ./ f3.^2;
        e1 = (y2.^2 +y3.^2  -y2-y3) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
        e2 = (y3.^2 -y2.*y3 -y2 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
        e3 = (y2.^2 -y2.*y3 -y3 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
    end
    % initialize
    dT_rel = 0;     dt_rx = 0;      mfw_VMF3 = [];
    % get cutoff (could be already set!) and satellite status
    cutoff = Epoch.exclude(i_sat);	status = Epoch.sat_status(i_sat);
    % receiver clock offset [s]
	dt_rx = (param(5) + isGLO*param(8) + isGAL*param(11) + isBDS*param(14))/Const.C;      
    
    %% get input data and frequency indices depending on GNSS of satellite
    if isGPS
        j = idx_frqs_gps;                       % indices of processed frequencies
        PCO_rec = input.OTHER.PCO.rec_GPS;      % PCO receiver
        PCV_rec = input.OTHER.PCV.rec_GPS;      % PCV receiver
        PCV_sat = input.OTHER.PCV.sat_GPS(:,sv);% PCV satellite
        % PCO satellite
        offset_LL = input.OTHER.PCO.sat_GPS(sv, 2:4, 1:5);
        offset_LL = reshape(offset_LL,3,5,1);   % each column contains another frequency
    elseif isGLO
        j = idx_frqs_glo;
        PCO_rec = input.OTHER.PCO.rec_GLO;
        PCV_rec = input.OTHER.PCV.rec_GLO;
        PCV_sat = input.OTHER.PCV.sat_GLO(:,sv);
        % PCO satellite
        offset_LL = input.OTHER.PCO.sat_GLO(sv, 2:4, 1:5);
        offset_LL = reshape(offset_LL,3,5,1);
        
    elseif isGAL
        j = idx_frqs_gal;
        PCO_rec = input.OTHER.PCO.rec_GAL;
        PCV_rec = input.OTHER.PCV.rec_GAL;
        PCV_sat = input.OTHER.PCV.sat_GAL(:,sv);
        % PCO satellite
        offset_LL = input.OTHER.PCO.sat_GAL(sv, 2:4, 1:5);
        reshape(offset_LL,3,5,1);
        offset_LL = reshape(offset_LL,3,5,1);
        
    elseif isBDS
        j = idx_frqs_bds;
        PCO_rec = input.OTHER.PCO.rec_BDS;
        PCV_rec = input.OTHER.PCV.rec_BDS;
        PCV_sat = input.OTHER.PCV.sat_BDS(:,sv);
        % PCO satellite
        offset_LL = input.OTHER.PCO.sat_BDS(sv, 2:4, 1:5);
        offset_LL = reshape(offset_LL,3,5,1);
    end       
        
    
    %% Clock and Orbit
    
    % --- Ttr....transmission time/time of emission
    % code_dist = Epoch.code(i_sat);            % before 14.1.2021
    code_dist = nanmean(Epoch.code(i_sat,:));   % should be more stable
    tau = code_dist/Const.C;    % approximate signal runtime from sat. to rec.
    % time of emission [sow (seconds of week)] = time of obs. - runtime
    Ttr = Epoch.gps_time - tau;       	
    
    % --- Get column of broadcast ephemerides for current satellite ---
    k = Epoch.BRDCcolumn(prn);
    if settings.ORBCLK.bool_brdc && isnan(k)      % no ephemeris
        fprintf('No broadcast orbit data for satellite %d in SOW %.3f              \n', prn, Ttr);
        cutoff = true;      % eliminate satellite
        status = 15;
        Epoch.tracked(prn) = 1;
    end
    
    % --- Clock correction: with navigation data or precise clocks from .clk-file ---
    % Clock correction in seconds, accurate enough with approximate Ttr
    dT_sat = 0;      % just for simulated data when satellite clock is perfect
    [dT_sat, noclock] = satelliteClock(sv, Ttr, input, isGPS, isGLO, isGAL, isBDS, k, settings);
    if isnan(dT_sat) || dT_sat == 0 || noclock       % no clock correction
        % if ~settings.INPUT.bool_parfor; fprintf('No precise clock data for satellite %d in SOW %0.3f              \n', prn, Ttr); end
        cutoff = true;                      % eliminate satellite
        status = 5;
        Epoch.tracked(prn) = 1;             % set epoch counter for this satellite to 1
    end

    for step = 1:2   % Iteration to estimate relativistic effect and interpolate satellite position
        dT_sat_rel = dT_sat + dT_rel;
        
        % --- correction of Time of emission ---
        tau = (code_dist + Const.C*dT_sat_rel)/Const.C;     % corrected signal runtime 8s9
        Ttr = Epoch.gps_time - tau;   	% time of emission = time of obs. - runtime
        
        % --- Satellite-Orbit: precise ephemeris (.sp3-file) or broadcast navigation data (perhabs + correction stream) ---
        [X, V, cutoff, status] = satelliteOrbit(prn, Ttr, input, isGPS, isGLO, isGAL, isBDS, k, settings, cutoff, status);
        
        % --- correction of satellite ECEF position for earth rotation during runtime tau ---
        tau = tau - dt_rx;  % Correct tau for receiver clock error to avoid jumps in sat position
        omegatau = Const.WE*tau;     % [rad]
        R3 = [  cos(omegatau) sin(omegatau)     0;
               -sin(omegatau) cos(omegatau)     0;
                0               0               1];
        X_rot = R3*X;
        Rot_V = R3*V;
        
        % --- Relativistic correction ---
        dT_rel = -2/Const.C^2 * dot2(X_rot, Rot_V);     % [s], ICD GPS, 20.3.3.3.3.1
        if isGLO && settings.ORBCLK.bool_brdc %&& input.Eph_GLO(3,k) ~= 0  % ||| GLO
            dT_rel = 0;     % already applied in satelliteClock.m
        end
    end % end of for step = 1:2 - Iteration to estimate relativistic effect and interpolate satellite position

    
    
    %% Vectors, Angles, Distance between Receiver and Satellite
    
    % --- Azimuth, Elevation, zenith distance, cutoff-angle ---
    [az, el] = topocent(pos_XYZ,X_rot-pos_XYZ);     % calculate azimuth and elevation [°]
    if el < settings.PROC.elev_mask         % elevation is under cut-off-angle
        cutoff = true;                      % eliminate satellite
        status = 2;
    end   
    
    
    % ||| geodetic2aer.m could be used instead (vectoriell)
    
    % --- Theoretical Range and Line-of-sight-Vector ---
    los  = X_rot - pos_XYZ;         % vector from receiver to satellite, Line-of-sight-Vector
    rho  = norm(los);               % distance from receiver to satellite
    los0 = los/rho;                 % unit vector from receiver to satellite
    
    % --- Satellite Orientation ---
    if ~settings.ORBCLK.bool_obx
        SatOr_ECEF = getSatelliteOrientation(X_rot, model.sunECEF*1000);    % satellite orientation in ECEF
    else
        dt = abs(Ttr - input.ORBCLK.OBX.ATT.sow);
        if min(dt) < 60
            idx = (dt == min(dt));
            q0 = input.ORBCLK.OBX.ATT.q0(idx,prn);
            q1 = input.ORBCLK.OBX.ATT.q1(idx,prn);
            q2 = input.ORBCLK.OBX.ATT.q2(idx,prn);
            q3 = input.ORBCLK.OBX.ATT.q3(idx,prn);
        else  % ||| check interpolation for e.g. 1sec intervall
            q0 = interp1(input.ORBCLK.OBX.ATT.sow, input.ORBCLK.OBX.ATT.q0(:,prn), Ttr);
            q1 = interp1(input.ORBCLK.OBX.ATT.sow, input.ORBCLK.OBX.ATT.q1(:,prn), Ttr);
            q2 = interp1(input.ORBCLK.OBX.ATT.sow, input.ORBCLK.OBX.ATT.q2(:,prn), Ttr);
            q3 = interp1(input.ORBCLK.OBX.ATT.sow, input.ORBCLK.OBX.ATT.q3(:,prn), Ttr);
        end
        if isempty(q0) || isempty(q1) || isempty(q2) || isempty(q3)
            SatOr_ECEF = NaN(3,3);
        else
            SatOr_ECEF = Quaternion2Matrix(q0(1), q1(1), q2(1), q3(1))';
        end
        
    end
    
    
    
    %% Range Corrections
    
    % --- Windup Correction ---
    delta_windup = 0;   windupCorr = [0, 0, 0];
    if settings.OTHER.bool_wind_up        % Wind-Up correction is enabled
        delta_windup = PhaseWindUp(prn, Epoch, model, SatOr_ECEF, los0);
        % Conversion of windup in cycles to frequency
        windupCorr_L1 = delta_windup * Epoch.l1(i_sat);     % [m]
        windupCorr_L2 = delta_windup * Epoch.l2(i_sat);   	% [m]
        windupCorr_L3 = delta_windup * Epoch.l3(i_sat);   	% [m]
        if strcmpi(settings.IONO.model,'2-Frequency-IF-LCs')
            windupCorr(1) = (f1^2*windupCorr_L1 - f2^2*windupCorr_L2)/(f1^2 - f2^2);    % 1st IF-LC
            windupCorr(2) = (f2^2*windupCorr_L2 - f3^2*windupCorr_L3)/(f2^2 - f3^2);   	% 2nd IF-LC
        elseif strcmpi(settings.IONO.model,'3-Frequency-IF-LC')
            windupCorr(1) = e1.*windupCorr_L1 + e2.*windupCorr_L2 + e3.*windupCorr_L3;
        else
            windupCorr(1) = windupCorr_L1;
            windupCorr(2) = windupCorr_L2;
            windupCorr(3) = windupCorr_L3;
        end
    end
    
    
    %% Troposphere

    % Model of Hydrostatic Zenith Delay
    switch settings.TROPO.zhd       
        case 'VMF3'
            zhd = zhd_VMF3;
        case 'Tropo file'
            ztd = interp1(input.TROPO.tropoFile.data(:,3), input.TROPO.tropoFile.data(:,4), mod(round(Epoch.gps_time),86400),'cubic');    % Zenith Total Delay, [m]
            zhd = saasthyd(p_GPT3, pos_WGS84.ph, pos_WGS84.h );
            zwd = ztd - zhd;
        case 'p (GPT3) + Saastamoinen'
            zhd = saasthyd(p_GPT3, pos_WGS84.ph, pos_WGS84.h );
        case 'p (in situ) + Saastamoinen'
            zhd = saasthyd(settings.TROPO.p, pos_WGS84.ph, pos_WGS84.h );
        case 'no'
            zhd = 0;
        otherwise
            error('There is something wrong here...') 
    end
    
    % calculate mf and gradients only if there is a zenith delay modelled at all
    if ~strcmpi(settings.TROPO.zhd,'no')   
        switch settings.TROPO.mfh       % Model of hydrostatic mf
            case 'VMF3'
                if strcmpi(input.TROPO.V3GR.version,'sitewise')
                    [mfh, mfw_VMF3] = vmf3(ah_VMF3, aw_VMF3, Epoch.mjd, pos_WGS84.ph, pos_WGS84.la, el*pi/180 );
                elseif strcmpi(input.TROPO.V3GR.version,'gridwise')
                    [mfh, mfw_VMF3] = vmf3_ht(ah_VMF3, aw_VMF3, Epoch.mjd, pos_WGS84.ph, pos_WGS84.la, pos_WGS84.h, el*pi/180 );
                end
            case 'GPT3'
                [mfh, mfw_GPT3] = vmf3_ht(ah_GPT3, aw_GPT3, Epoch.mjd, pos_WGS84.ph, pos_WGS84.la, pos_WGS84.h, el*pi/180 );
            otherwise
                error('There is something wrong here...')
        end
        switch settings.TROPO.Gh        % Model of hydrostatic gradient
            case 'GRAD'
                Gn_h = Gn_h_GRAD;
                Ge_h = Ge_h_GRAD;
            case 'GPT3'
                Gn_h = Gn_h_GPT3;
                Ge_h = Ge_h_GPT3;
            case 'no'
                Gn_h = 0;
                Ge_h = 0;
            otherwise
                error('There is something wrong here...')
        end
    else        % no hydrostatic mf and hydrostatic gradient are needed
        mfh = 0;
        Gn_h = 0;
        Ge_h = 0;
    end
    
    
    % Model of zenith wet delay    
    switch settings.TROPO.zwd           
        case 'VMF3'
            zwd = zwd_VMF3;
        case 'Tropo file'
            % everything concerning the tropo file was already defined above
        case 'e (GPT3) + Askne'
            zwd   = asknewet ( e_GPT3 , Tm_GPT3 , lambda_GPT3 );
        case 'e (in situ) + Askne'
            e = 6.1078 * exp((17.1 * settings.TROPO.T) / (235 + settings.TROPO.T)) * settings.TROPO.q/100;   % formula by Magnus * relative humidity
            zwd   = asknewet ( e , Tm_GPT3 , lambda_GPT3 );
        case 'no'
            zwd = 0;
        otherwise
            error('There is something wrong here...')
    end

    if ~strcmpi(settings.TROPO.zwd,'no')   
        switch settings.TROPO.mfw       % Model of wet mapping function
            case 'VMF3'
                if ~isempty(mfw_VMF3)           % check if this was already calculated
                    mfw = mfw_VMF3;
                elseif strcmpi(input.TROPO.V3GR.version,'sitewise')
                    [~,mfw] = vmf3(ah_VMF3, aw_VMF3, Epoch.mjd, pos_WGS84.ph, pos_WGS84.la, el*pi/180);
                elseif strcmpi(input.TROPO.V3GR.version,'gridwise')
                    [~,mfw] = vmf3_ht(ah_VMF3, aw_VMF3, Epoch.mjd, pos_WGS84.ph, pos_WGS84.la, pos_WGS84.h, el*pi/180);
                end
            case 'GPT3'
                if exist('mfw_GPT3', 'var')     % check if this was already calculated
                    mfw = mfw_GPT3;
                else
                    [~,mfw] = vmf3_ht(ah_GPT3, aw_GPT3, Epoch.mjd, pos_WGS84.ph, pos_WGS84.la, pos_WGS84.h, el*pi/180 );
                end
            otherwise
                error('There is something wrong here...')
        end
        switch settings.TROPO.Gw        % Model of wet gradient
            case 'GRAD'
                Gn_w = Gn_w_GRAD;
                Ge_w = Ge_w_GRAD;
            case 'GPT3'
                Gn_w = Gn_w_GPT3;
                Ge_w = Ge_w_GPT3;
            case 'no'
                Gn_w = 0;
                Ge_w = 0;
            otherwise
                error('There is something wrong here...')
        end
    else        % no wet mf and wet gradient are needed
        mfw = 0;
        Gn_w = 0;
        Ge_w = 0;
    end
    
    % stick together the slant total delay
    mfg_h = 1 / ( sin(el*pi/180) * tan(el*pi/180)+0.0031 );
    mfg_w = 1 / ( sin(el*pi/180) * tan(el*pi/180)+0.0007 );
    az_ = az*pi/180;
    trop = zhd*mfh + zwd*mfw   +   mfg_h*( Gn_h*cos(az_)+Ge_h*sin(az_) ) + mfg_w*( Gn_w*cos(az_)+Ge_w*sin(az_) );
    
    % if estimate_ZWD is disabled, then set mfw = 0 for the design matrix in any case
    if ~Adjust.est_ZWD
        mfw = 0;
    end
    
    
    
    %% Ionosphere
    iono(1:n_proc_frq) = 0;
    if (strcmpi(settings.IONO.model, 'Estimate with ... as constraint') || strcmpi(settings.IONO.model, 'Correct with ...'))  && ~isnan(Ttr)
        switch settings.IONO.source
            case 'IONEX File'
                % calculate ionospheric correction from gim or klobuchar
                [mappingf, Lat_IPP, Lon_IPP] = ...      % get value of mapping-function and IPP
                    iono_mf(el, input.IONO.ionex.mf, pos_WGS84, az, input.IONO.ionex.radius, input.IONO.ionex.hgt);
                vtec = iono_gims(Lat_IPP, Lon_IPP, Ttr, input.IONO.ionex, settings.IONO.interpol);	% interpolate VTEC
                model.iono_mf(i_sat)   = mappingf;      % saving value of mapping-function
                model.iono_vtec(i_sat) = vtec;          % saving value of VTEC
                iono(1) = mappingf * 40.3e16/f1^2* vtec;      % delta_iono [m]
                iono(2) = mappingf * 40.3e16/f2^2* vtec;
                iono(3) = mappingf * 40.3e16/f3^2* vtec;
            case 'Klobuchar model'
                iono(1) = iono_klobuchar(pos_WGS84.ph*(180/pi), pos_WGS84.la*(180/pi), az, el, Ttr, input.IONO.klob_coeff);
                iono(2) = iono(1) * ( f1.^2 ./ f2.^2 );     % convert Klobuchar correction from L1 to L2
                iono(3) = iono(1) * ( f1.^2 ./ f3.^2 );     % convert Klobuchar correction from L2 to L3
            case 'NeQuick model'
                stec = eval_NeQuick(input, obs.startdate(2), Epoch.gps_time, pos_WGS84, X_rot, input.IONO.nequ_coeff);
                iono(1) = 40.3/f1^2 * stec;      % delta_iono [m]
                iono(2) = 40.3/f2^2 * stec;
                iono(3) = 40.3/f3^2 * stec;
                
%                 STEC = NTCM_Galileo(pos_WGS84, el, obs.doy, Ttr, input.nequ_coeff);
%                 iono(1) = 40.3e16/f1^2 * STEC;      % delta_iono [m]
%                 iono(2) = 40.3e16/f2^2 * STEC;
%                 iono(3) = 40.3e16/f3^2 * STEC;

            case 'CODE Spherical Harmonics'
                stec = iono_coeff_global(pos_WGS84.ph, pos_WGS84.la, az, el, round(Ttr), input.IONO.ion, obs.leap_sec);
                iono(1) = 40.3/f1^2 * stec;
                iono(2) = 40.3/f2^2 * stec;
                iono(3) = 40.3/f3^2 * stec;
            case 'VTEC from Correction Stream'
                dt_vtec = abs(input.ORBCLK.corr2brdc_vtec.t-Ttr);
                idx_vtec = find(dt_vtec==min(dt_vtec));         % find nearest vtec correction in stream data
                C_nm = input.ORBCLK.corr2brdc_vtec.Cnm(:,:,idx_vtec);  % get coefficients
                S_nm = input.ORBCLK.corr2brdc_vtec.Snm(:,:,idx_vtec);
                stec = corr2brdc_stec(C_nm, S_nm, az, el, pos_WGS84, mod(Ttr,86400));
                iono(1) = 40.3e16/f1^2 * stec;
                iono(2) = 40.3e16/f2^2 * stec;
                iono(3) = 40.3e16/f3^2 * stec;
            % otherwise is handled before switch
        end
        
    end
    
    
    
    %% Tide Displacement and eclipsing satellites
    
    % --- Correction for earth rotation ---
    % [09]: p61 if you calculate signal-travel-time with (5.134) the the 
    % Sagnac-Correction is applied automatically. Here only the measured
    % distance is used but this should make no difference and therefore the
    % correction is obsolete
    
    % --- Solid Tides: Calculate range correction for displacement ---
    dX_solid_tides_corr = 0;
    if settings.OTHER.bool_solid_tides
        dX_solid_tides_corr = dot2(los0, model.solid_tides_ECEF);	% project onto line of sight
    end
    
    % --- Ocean Loading: Calculate range correction for displacement ---
    dX_ocean_loading = 0;
    if settings.OTHER.ocean_loading
        dX_ocean_loading = dot2(los0, model.ocean_loading_ECEF); 	% project onto line of sight
    end    
   
    
    % --- Eclipsing Satellites ---
    % Check if satellite is in the shadow of the Earth:
    % https://gssc.esa.int/navipedia/index.php/Satellite_Eclipses
    if settings.OTHER.bool_eclipse && ~settings.ORBCLK.bool_obx
        cos_phi = dot(X_rot,model.sunECEF*1000) / (norm(X_rot)*norm(model.sunECEF)*1000);   % angle between satellite and sun
        if cos_phi < 0 && (norm(X_rot)*sqrt(1-cos_phi^2)) < Const.RE
            if mod(Epoch.q, 100) == 0 && ~settings.INPUT.bool_parfor
                fprintf('Warning! Eclipsing Satellite PRN %d \t                \n', prn)
            end
            cutoff = true;              % eliminate satellite
            status = 13;
        end
    end
    
    
    %% Phase Center Offset Corrections
    % --- Receiver Antenna Reference Point Correction ---
    % correct the measurement to the ARP with values from RINEX-File-Header
    
    dX_ARP_ECEF_corr = zeros(3,1);
    if settings.OTHER.bool_rec_arp        % Antenna Reference Point Correction is enabled
        dX_ARP_ECEF_corr = model.R_LL2ECEF*obs.rec_ant_delta;   % convert Local Level into ECEF
    end    
    dX_ARP_ECEF_corr = dot2(los0, dX_ARP_ECEF_corr);            % project onto line of sight
    
    % --- Receiver Antenna Phase Center Offset Correction---
    dX_PCO_REC_ECEF_corr = zeros(n_proc_frq,1);
    if settings.OTHER.bool_rec_pco        % Receiver Phase Center Offset is enabled
        dX_PCO_REC_ECEF = model.R_LL2ECEF * PCO_rec; 	% convert Local Level into ECEF   
        dX_los = sum(los0.*dX_PCO_REC_ECEF, 1);         % project onto line of sight, dot-product of each column        
        % missing receiver PCO correction are replaced with the correction
        % of the 1st frequency:
        dX_los(dX_los==0) = dX_los(1);
        % convert to the processed frequencies:
        if strcmpi(settings.IONO.model,'2-Frequency-IF-LCs')
            dX_PCO_REC_ECEF_corr(1) = (f1^2*dX_los(j(1))-f2^2*dX_los(j(2))) / (f1^2-f2^2);
            if n_proc_frq == 2
                dX_PCO_REC_ECEF_corr(2) = (f2^2*dX_los(j(2))-f3^2*dX_los(j(3))) / (f2^2-f3^2);
            end
        elseif strcmpi(settings.IONO.model,'3-Frequency-IF-LC')
            dX_PCO_REC_ECEF_corr(1) = e1.*dX_los(j(1)) + e2.*dX_los(j(2)) + e3.*dX_los(j(3));
        else                                        % no IF-LC
            dX_PCO_REC_ECEF_corr(j) = dX_los(j);      % get values of processed frequencies
        end
    end

    % --- Satellite Antenna Phase Center Correction ---
    % convert observation from Antenna Phase Center to Center of Mass which
    % is necessary when orbit/clock product refers to the CoM
    % ||| check´n´change for not sp3
    dX_PCO_SAT_ECEF_corr = zeros(n_proc_frq,1);
    if settings.OTHER.bool_sat_pco && settings.ORBCLK.bool_sp3 && ~cutoff   	
        % satellite Phase Center Offset and precise ephemerides are enabled
        % and satellite is not under cutoff
        dX_PCO_SAT_ECEF = SatOr_ECEF*offset_LL;                         % transform offsets into ECEF site displacements
        dX_los = sum(los0.*dX_PCO_SAT_ECEF, 1); 	% project each frequency onto line of sight
        % missing satellite PCO corrections are replaced with the correction
        % of the 1st frequency:
        dX_los(dX_los==0) = dX_los(1);
        % convert to the processed frequencies
        switch settings.IONO.model
            case '2-Frequency-IF-LCs'
                dX_PCO_SAT_ECEF_corr(1) = (f1^2*dX_los(j(1))-f2^2*dX_los(j(2))) / (f1^2-f2^2);
                if n_proc_frq == 2
                    dX_PCO_SAT_ECEF_corr(2) = (f2^2*dX_los(j(2))-f3^2*dX_los(j(3))) / (f2^2-f3^2);
                end
            case '3-Frequency-IF-LC'
                dX_PCO_SAT_ECEF_corr(1) = e1.*dX_los(j(1)) + e2.*dX_los(j(2)) + e3.*dX_los(j(3));
            otherwise        % uncombined signals are processed
                dX_PCO_SAT_ECEF_corr(j) = dX_los(j);
        end
    end
    
    
    %% Phase Center Variation Corrections
    % --- Receiver Antenna Phase Center Variation Correction---
    dX_PCV_rec = [0,0,0];
    if settings.OTHER.bool_rec_pcv
        if ~isempty(PCV_rec)    % check if PCV corrections are existing
            dX_PCV_rec = calc_PCV_rec(PCV_rec, j, el, az, settings.IONO.model, f1, f2, f3);
        end
    end
    
    % --- Satellite Antenna Phase Center Variation Correction---
    dX_PCV_sat = [0,0,0];
    if settings.OTHER.bool_sat_pcv && settings.ORBCLK.bool_sp3 
        dX_PCV_sat = calc_PCV_sat(PCV_sat, SatOr_ECEF, los0, j, settings.IONO.model, f1, f2, f3, X_rot, pos_XYZ);
    end
    
    
    %% Group Delay Variations
    dX_GDV = [0,0,0];
    if settings.OTHER.bool_GDV
        dX_GDV = calc_GDV(prn, el, f1, f2, f3, j, settings.IONO.model, n_proc_frq);
    end

    
    %% -+-+-+- Assign modelled values to struct 'model' -+-+-+-
    
    model.rho(i_sat,frqs)  	  = rho;            % theoretical range, maybe recalculated in iteration of epoch
    model.dT_sat(i_sat,frqs)  = dT_sat;         % Satellite clock correction
    model.dT_rel(i_sat,frqs)  = dT_rel;     	% Relativistic clock correction
    model.dT_sat_rel(i_sat,frqs) = dT_sat_rel;  % Satellite clock  + relativistic correction
    model.Ttr(i_sat,frqs)    = Ttr;             % Signal transmission time, [sow], gps-time
    model.k(i_sat,frqs)      = k;               % Column of ephemerides
    % Atmosphere
    model.trop(i_sat,frqs) = trop;              % Troposphere delay for elevation
    model.iono(i_sat,frqs) = iono(frqs);        % Ionosphere delay
    model.mfw(i_sat,frqs)  = mfw;               % Wet tropo mapping function
    model.zwd(i_sat,frqs)  = zwd;               % zenith wet delay (need for building a priori + estimated zwd later)
    model.zhd(i_sat,frqs)  = zhd;               % modelled zenith hydrostativ delay
    % Observation direction
    model.az(i_sat,frqs)   = az;                % Satellite azimuth [°]
    model.el(i_sat,frqs)   = el;                % Satellite elevation [°]
    % Windup
    model.delta_windup(i_sat,frqs) = delta_windup;          % Phase windup effect in cycles
    model.windup(i_sat,frqs)       = windupCorr(frqs);      % Phase windup effect, scaled to frequency
    % tides
    model.dX_solid_tides_corr(i_sat,frqs) = dX_solid_tides_corr; 	% Solid tides range correction
    model.dX_ocean_loading(i_sat,frqs)    = dX_ocean_loading;     	% Ocean loading range correction
    % group delay variation
    model.dX_GDV(i_sat,frqs)  = dX_GDV(frqs);                           % Group delay variation correction
    % phase center offsets and variations
    model.dX_ARP_ECEF_corr(i_sat,frqs)= dX_ARP_ECEF_corr;               % Receiver antenna reference point correction in ECEF
    model.dX_PCO_rec_corr(i_sat,frqs) = dX_PCO_REC_ECEF_corr(frqs);     % Receiver phase center offset correction in ECEF
    model.dX_PCV_rec_corr(i_sat,frqs) = dX_PCV_rec(frqs);            	% Receiver phase center variation correction
    model.dX_PCO_sat_corr(i_sat,frqs) = dX_PCO_SAT_ECEF_corr(frqs);     % Satellite antenna phase center offset in ECEF
    model.dX_PCV_sat_corr(i_sat,frqs) = dX_PCV_sat(frqs);           	% Satellite phase center variation correction
    % Sat position and velocity:
    model.ECEF_X(:,i_sat) = X;          % Sat Position before correcting the earth rotation during runtime tau
    model.ECEF_V(:,i_sat) = V;          % Sat Velocity before correcting the earth rotation during runtime tau
    model.Rot_X(:,i_sat)  = X_rot;      % Sat Position after correcting the earth rotation during runtime tau
    model.Rot_V(:,i_sat)  = Rot_V;  	% Sat Velocity after correcting the earth rotation during runtime tau  
    
    Epoch.exclude(i_sat,frqs) = cutoff;   	% boolean, true = do not use satellite (e.g. cutoff angle)
    Epoch.sat_status(i_sat) = status;   
    
end     % of loop over satellites

end     % of modelErrorSources.m



