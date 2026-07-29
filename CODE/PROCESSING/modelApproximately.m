function [model, Epoch] = modelApproximately(settings, input, Epoch, param, obs, iteration)
% This function is a simpler version of modelErrorSources.m and models error
% sources for modeling the observation for calculating an approximate
% position or velocity. 
% 
% INPUT:
%   settings    	settings from GUI  [struct]
%   input           input data (ephemeris, PCOs, etc.)   [struct]
%   Epoch           epoch-specific data for current epoch  [struct]
%   param           (simplified) parameter vector [vector]
%   obs             consisting observations and corresponding data   [struct]
%   iteration       step of iteration
% OUTPUT:
%   model           extended with modeled corrections to current satellite, [struct]
%   Epoch           updated with cutoff
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% receiver position in ECEF and geodetic coordinates
pos_XYZ = param(1:3);
pos_WGS84 = cart2geo(param(1:3));

% get some variables
n_num_frq  = settings.INPUT.num_freqs;      % number of input frequencies (e.g. 2 for IF-LC)
proc_frqs = settings.INPUT.proc_freqs;      % number of processed frequencies
frqs = 1:proc_frqs;                 % 1 : # processed frequencies
num_sat = numel(Epoch.sats);        % number of satellites in current epoch

% initialize the struct model
model = init_struct_model(num_sat, proc_frqs, n_num_frq);  	% Init struct model

% indices of processed frequencies
j_proc = 1:settings.INPUT.num_freqs;
idx_frqs_gps  = settings.INPUT.gps_freq_idx(j_proc);
idx_frqs_glo  = settings.INPUT.glo_freq_idx(j_proc);
idx_frqs_gal  = settings.INPUT.gal_freq_idx(j_proc);
idx_frqs_bds  = settings.INPUT.bds_freq_idx(j_proc);
idx_frqs_qzss = settings.INPUT.qzss_freq_idx(j_proc);

% remove frequencies set to OFF (if different number of frequencies is 
% processed for different GNSS)
idx_frqs_gps(idx_frqs_gps>DEF.freq_GPS(end)) = [];
idx_frqs_glo(idx_frqs_glo>DEF.freq_GLO(end)) = [];
idx_frqs_gal(idx_frqs_gal>DEF.freq_GAL(end)) = [];
idx_frqs_bds(idx_frqs_bds>DEF.freq_BDS(end)) = [];
idx_frqs_qzss(idx_frqs_qzss>DEF.freq_QZSS(end)) = [];


% ----- Epoch-specific corrections -----
% corrections which are valid for all satellites but only for a specific epoch
% --- Calculate hour and approximate sun and moon position for epoch ---
h = mod(Epoch.gps_time,86400)/3600;
model.sunECEF  = sunPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
model.moonECEF = moonPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
% --- Rotation Matrix from Local Level to ECEF ---
model.R_LL2ECEF = setupRotation_LL2ECEF(pos_WGS84.lat, pos_WGS84.lon);



for i_sat = 1:num_sat                     
    % ----- Preparations -----
    prn = Epoch.sats(i_sat);       % [1-99] GPS, [101-199] GLO, [201-250] GAL, [301-399] BDS, [401-410] QZSS
    sv = mod(prn,100);
    isGLO  = Epoch.glo(i_sat);     % is current satellite a glonass sat.?
    isGPS  = Epoch.gps(i_sat);     % is current satellite a gps sat.?
    isGAL  = Epoch.gal(i_sat);     % is current satellite a galileo sat.?
    isBDS  = Epoch.bds(i_sat);     % is current satellite a beidou sat.?
    isQZSS = Epoch.qzss(i_sat);    % is current satellite a beidou sat.?
    f1 = Epoch.f1(i_sat);   f2 = Epoch.f2(i_sat);   f3 = Epoch.f3(i_sat);
    dT_rel = 0;
    exclude = false;                 % cutoff-angle
    status = Epoch.sat_status(i_sat,:);
    
    % get orbits and clocks
    if isGPS
        preciseEph = input.ORBCLK.preciseEph_GPS;
        preciseClk = input.ORBCLK.preciseClk_GPS;
        Eph_brdc = input.ORBCLK.Eph_GPS;
    elseif isGLO
        preciseEph = input.ORBCLK.preciseEph_GLO;
        preciseClk = input.ORBCLK.preciseClk_GLO;
        Eph_brdc = input.ORBCLK.Eph_GLO;
    elseif isGAL
        preciseEph = input.ORBCLK.preciseEph_GAL;
        preciseClk = input.ORBCLK.preciseClk_GAL;
        Eph_brdc = input.ORBCLK.Eph_GAL;
    elseif isBDS
        preciseEph = input.ORBCLK.preciseEph_BDS;
        preciseClk = input.ORBCLK.preciseClk_BDS;
        Eph_brdc = input.ORBCLK.Eph_BDS;
    elseif isQZSS
        preciseEph = input.ORBCLK.preciseEph_QZSS;
        preciseClk = input.ORBCLK.preciseClk_QZSS;
        Eph_brdc = input.ORBCLK.Eph_QZSS;
    end

    % determine receiver clock error [s]
    dt_rx = (isGPS*param(7) + isGLO*param(8) + isGAL*param(9) + isBDS*param(10))/Const.C;
    
    % --- Ttr....transmission time/time of emission
    dT_sat = 0; dT_rel = 0;
    code_dist = Epoch.code(i_sat);
    [Ttr, tau] = calcTimeOfTransmission(code_dist, Epoch.gps_time, dT_sat, dT_rel);
    if isnan(tau) 
        Epoch.exclude(i_sat,frqs) = true;       % eliminate satellite
        continue; 
    end

    % --- Get column of broadcast ephemerides for current satellite ---
    k = Epoch.BRDCcolumn(prn);
    if settings.ORBCLK.bool_brdc && isnan(k)      % no ephemeris
        if ~settings.INPUT.bool_parfor; fprintf('No broadcast orbit data for satellite %d in SOW %.3f              \n', prn, Ttr); end
        Epoch.exclude(i_sat,frqs) = true;       % eliminate satellite
        Epoch.status(:) = 15;
        Epoch.tracked(prn) = 1;
        continue
    end
    
    % --- Clock correction: with precise clocks from .clk-file or navigation data ---
    % Clock correction in seconds, accurate enough with approximate Ttr
    if settings.ORBCLK.bool_clk
        [dT_sat, noclock] = satelliteClock(sv, Ttr, preciseClk);
    else
        [dT_sat, noclock] = satelliteClockBrdc(Ttr, Eph_brdc(:,k), isGPS, isGLO, isGAL, isBDS, isQZSS, settings.ORBCLK.corr2brdc_clk, Epoch.corr2brdc_clk(:,prn));
    end
    if isnan(dT_sat) || dT_sat == 0 || noclock       % no clock correction
        if ~settings.INPUT.bool_parfor; fprintf('No precise clock data for satellite %.0f (%s)              \n', prn, Epoch.rinex_header); end
        exclude = true;                 % eliminate satellite
        status(:) = 5;
        Epoch.tracked(prn) = 1;         % set epoch counter for this satellite to 1
    end   
    
    for step = 1:2   % Iteration to estimate relativistic effect and interpolate satellite position
        dT_sat_rel = dT_sat + dT_rel;
        
        % --- correction of Time of emission ---
        [Ttr, tau] = calcTimeOfTransmission(code_dist, Epoch.gps_time, dT_sat, dT_rel);

        % --- Satellite-Orbit: precise ephemeris (.sp3-file) or broadcast navigation data (perhabs + correction stream) ---
        if settings.ORBCLK.bool_sp3
            [X, V, ~, exclude, status] = satelliteOrbit(prn, Ttr, preciseEph, settings, exclude, status);
        else
            [X, V, ~, exclude, status] = satelliteOrbitBrdc(Ttr, Eph_brdc(:,k), isGPS, isGLO, isGAL, isBDS, isQZSS, settings.ORBCLK.corr2brdc_orb, exclude, status, Epoch.corr2brdc_orb(:,prn));
        end
        % --- correction of satellite ECEF position for earth rotation during runtime tau ---
        tau = tau - dt_rx;  % Correct tau for receiver clock error to avoid jumps in sat position
        [X_rot, V_rot] = correctEarthRotation(tau, X, V);
        
        % --- Relativistic correction ---
        dT_rel = -2/Const.C^2 * dot2(X_rot, V_rot);
%         if isGLO && ~settings.ORBCLK.bool_sp3 && input.ORBCLK.Eph_GLO(3,k) ~= 0  % ||| GLO
%             dT_rel = 0; % for BRDC correction already applied in gamma
%         end
    end % end of for step = 1:2 - Iteration to estimate relativistic effect and interpolate satellite position
    
    
    
    % ----- Vectors, Angles, Distance between Receiver and Satellite -----
    
    % --- Azimuth, Elevation, zenith distance, cutoff-angle ---
    [az, el] = topocent(pos_XYZ,X_rot-pos_XYZ);     % calculate azimuth and elevation [degree]
    if el < settings.PROC.elev_mask         % elevation is under cut-off-angle
        exclude = true;                     % eliminate satellite
        status(:) = 2;
    end

    % --- Boresight angle ---
    bore = 0;
    if settings.ADJ.weight_bore
        % For Earth pointing only
        Los_Body = ECEF2RWS(X_rot, Epoch.time, param(1:6), obs.leap_sec);
        Ant_BoreSight = [-1; 0; 0];
        bore = acosd(dot((Los_Body/norm(Los_Body)), Ant_BoreSight));
    end    
    
    % --- Theoretical Range and Line-of-sight-Vector ---
    los  = X_rot - pos_XYZ;         % vector from receiver to satellite, Line-of-sight-Vector
    rho  = norm(los);               % distance from receiver to satellite
    los0 = los/rho;                 % unit vector from receiver to satellite
    
    % --- Satellite Orientation ---
    SatOr_ECEF = getSatelliteOrientation(X_rot, model.sunECEF*1000);    % satellite orientation in ECEF
    

    
    % ----- Troposphere -----
    trop = 0;
    if iteration > 2 	% ignore atmosphere during the first two iterations (more stable)
        p = 1013.25; T = 15; q = 48.14;     % default values for pressure, temperature, relative humidity
        [trop, ~, ~] = tropo_hopfield(Ttr, el/180*pi, [T; p; q]);
    end
   
    
    
    % ----- Ionosphere -----
    iono = zeros(1, proc_frqs);
    if iteration > 2 && ((strcmpi(settings.IONO.model, 'Estimate with ... as constraint') || strcmpi(settings.IONO.model, 'Correct with ...'))  && ~isnan(Ttr))
        switch settings.IONO.source
            case 'IONEX File'
                % calculate ionospheric pierce point
                [Lat_IPP, Lon_IPP] = calculate_IPP(pos_WGS84.lat, pos_WGS84.lon, az*pi/180, el*pi/180, input.IONO.ionex.hgt(1)*1e3);
                % convert at_IPP and Lon_IPP from radiant to degree
                Lat_IPP = Lat_IPP/pi*180; Lon_IPP = Lon_IPP/pi*180;
                % get value of mapping-function
                mf = iono_mf(el, input.IONO.ionex.mf, az, input.IONO.ionex.radius, input.IONO.ionex.hgt);
                vtec = iono_gims(Lat_IPP, Lon_IPP, Ttr, input.IONO.ionex, settings.IONO.interpol);	% interpolate VTEC
                model.iono_mf(i_sat)   = mf;      % saving value of mapping-function
                model.iono_vtec(i_sat) = vtec;          % saving value of VTEC
                iono(1) = mf * 40.3e16/f1^2* vtec;      % delta_iono [m]
                iono(2) = mf * 40.3e16/f2^2* vtec;
                iono(3) = mf * 40.3e16/f3^2* vtec;
            case 'Klobuchar model'
                iono(1) = iono_klobuchar(pos_WGS84.lat*(180/pi), pos_WGS84.lon*(180/pi), az, el, Ttr, input.IONO.klob_coeff);
                iono(2) = iono(1) * ( f1.^2 ./ f2.^2 );     % convert Klobuchar correction from L1 to L2
                iono(3) = iono(1) * ( f1.^2 ./ f3.^2 );     % convert Klobuchar correction from L2 to L3
            case 'NeQuick model'
				stec = call_NeQuick_G(input.IONO.nequ_coeff, obs.startdate(2), Ttr-obs.leap_sec, pos_WGS84, X_rot);
                iono = stec2iono(stec, f1, f2, f3);
            case 'CODE Spherical Harmonics'
                stec = iono_coeff_global(pos_WGS84.lat, pos_WGS84.lon, az, el, round(Ttr), input.IONO.ion, obs.leap_sec);
                iono(1) = 40.3/f1^2 * stec;
                iono(2) = 40.3/f2^2 * stec;
                iono(3) = 40.3/f3^2 * stec;
            case 'VTEC from Correction Stream'
                % find nearest VTEC data in correction stream       ||| interpolate
                dt = Ttr - input.ORBCLK.corr2brdc_vtec.t;      % time difference [sow]
                if any(dt > 0); dt(dt<0) = []; end      % ignore future data to maintain real-time conditions
                dt = abs(dt);
                idx = find(dt == min(dt));  	% index of nearest VTEC data
                C_nm = input.ORBCLK.corr2brdc_vtec.Cnm(:,:,idx);	% cosine coefficients [TECU]
                S_nm = input.ORBCLK.corr2brdc_vtec.Snm(:,:,idx); 	% sine coefficients [TECU]
                % calculate STEC and ionospheric delay on signal frequencies
                stec = corr2brdc_stec(C_nm, S_nm, input.ORBCLK.corr2brdc_vtec.height, az, el, pos_WGS84.lat, pos_WGS84.lon, pos_WGS84.h, Ttr);
                iono = stec2iono(stec, f1, f2, f3); 	% calculate ionospheric delay from STEC
                
            % otherwise is handled before switch
            
        end
    end    
    
    
    % ----- Eclipsing satellites -----
    % satellite intersects the line between sun and earth; the consequence are
    % rapid rotations of satellite orientation; each Satellite has two Eclipse
    % periods in a year, each lasts for 7 weeks; in this time the yaw attitude
    % is random and orbits are degraded;
    cos_phi = dot(X_rot,model.sunECEF*1000)/(norm(X_rot,'fro')*norm(model.sunECEF,'fro')*1000);
    if cos_phi < 0 && (norm(X_rot,'fro')*sqrt(1-cos_phi^2)) < Const.RE
        exclude = true;              % eliminate satellite
        status(:) = 13;
    end
    
    
    % ----- Phase Center Offset Corrections -----
    % --- Receiver Antenna Reference Point Correction ---
    % correct the measurement to the ARP with values from RINEX-File-Header
    
    dX_ARP_ECEF_corr = zeros(3,1);
    if iteration > 1 && settings.OTHER.bool_rec_arp        % Antenna Reference Point Correction is enabled
        dX_ARP_ECEF_corr = model.R_LL2ECEF*obs.rec_ant_delta;   % convert Local Level into ECEF
    end    
    dX_ARP_ECEF_corr = dot2(los0, dX_ARP_ECEF_corr);            % project onto line of sight
    
    % ----- Receiver Antenna Phase Center Offset Correction -----
    % PCV are no applied, Glonass is not implemented
    dX_PCO_REC_ECEF_corr = zeros(proc_frqs,1);
    if iteration > 1 && settings.OTHER.bool_rec_pco        % Receiver Phase Center Offset is enabled
        if isGPS
            PCO_rec = input.OTHER.PCO.rec_GPS;
            idx_frqs = idx_frqs_gps;
        elseif isGLO
            PCO_rec = input.OTHER.PCO.rec_GLO;
            idx_frqs = idx_frqs_glo; 
        elseif isGAL
            PCO_rec = input.OTHER.PCO.rec_GAL;
            idx_frqs = idx_frqs_gal;
        elseif isBDS
            PCO_rec = input.OTHER.PCO.rec_BDS;
            idx_frqs = idx_frqs_bds;
        end
        dX_PCO_REC_ECEF = model.R_LL2ECEF * PCO_rec; 	% convert Local Level into ECEF   
        dX_los = sum(los0.*dX_PCO_REC_ECEF, 1);         % project onto line of sight, dot-product of each column        
        % missing receiver PCO correction are replaced with the correction
        % of the 1st frequency:
        dX_los(dX_los==0) = dX_los(1);
        % convert to the processed frequencies:
        dX_PCO_REC_ECEF_corr = Convert2ProcFrqs(settings, idx_frqs, dX_los, f1, f2, f3, dX_PCO_REC_ECEF_corr);
    end

    % --- Satellite Antenna Phase Center Correction ---
    % convert observation from Antenna Phase Center to Center of Mass which
    % is necessary when orbit/clock product refers to the CoM
    % ||| check and change for not sp3
    dX_PCO_SAT_ECEF_corr = zeros(proc_frqs,1);
    if settings.OTHER.bool_sat_pco && settings.ORBCLK.bool_sp3 && ~exclude   	
        % satellite Phase Center Offset and precise ephemerides are enabled
        % and satellite is not under cutoff
        if isGPS        % get offsets for current satellite
            offset_LL = input.OTHER.PCO.sat_GPS(input.OTHER.PCO.sat_GPS(:,1) == sv, 2:4, 1:5); 
            idx_frqs = idx_frqs_gps;
        elseif isGLO
            offset_LL = input.OTHER.PCO.sat_GLO(input.OTHER.PCO.sat_GLO(:,1) == sv, 2:4, 1:5);
            idx_frqs = idx_frqs_glo;
        elseif isGAL
            offset_LL = input.OTHER.PCO.sat_GAL(input.OTHER.PCO.sat_GAL(:,1) == sv, 2:4, 1:5);
            idx_frqs = idx_frqs_gal;
        elseif isBDS
            offset_LL = input.OTHER.PCO.sat_BDS(input.OTHER.PCO.sat_BDS(:,1) == sv, 2:4, 1:5);
            idx_frqs = idx_frqs_bds;
        elseif isQZSS
            offset_LL = input.OTHER.PCO.sat_QZSS(input.OTHER.PCO.sat_QZSS(:,1) == sv, 2:4, 1:5);
            idx_frqs = idx_frqs_qzss;
        end
        offset_LL = reshape(offset_LL,3,5,1);       % each column contains another frequency
        dX_PCO_SAT_ECEF = SatOr_ECEF*offset_LL;   	% transform offsets into ECEF site displacements
        dX_los = sum(los0.*dX_PCO_SAT_ECEF, 1); 	% project each frequency onto line of sight
        % missing satellite PCO corrections are replaced with the correction
        % of the 1st frequency:
        dX_los(dX_los==0) = dX_los(1);
        % convert to the processed frequencies
        dX_PCO_SAT_ECEF_corr = Convert2ProcFrqs(settings, idx_frqs, dX_los, f1, f2, f3, dX_PCO_SAT_ECEF_corr);
    end
    
    
    
    %% -+-+-+- Assign modelled values to struct 'model' -+-+-+-
    
    % General stuff
    model.rho(i_sat,frqs)  	 = rho;             % theoretical range, maybe recalculated in iteration of epoch
    model.dT_sat(i_sat,frqs)  = dT_sat;         % Satellite clock correction
    model.dT_rel(i_sat,frqs)  = dT_rel;     	% Relativistic clock correction
    model.dT_sat_rel(i_sat,frqs) = dT_sat_rel;  % Satellite clock  + relativistic correction
    model.Ttr(i_sat,frqs)    = Ttr;             % Signal transmission time
    model.k(i_sat,frqs)      = k;               % Column of ephemerides
    % Atmosphere
    model.trop(i_sat,frqs) = trop;              % Troposphere delay for elevation
    model.iono(i_sat,frqs) = iono(frqs);        % Ionosphere delay
    % Observation direction
    model.az(i_sat,frqs)   = az;                % Satellites' azimuth [degree]
    model.el(i_sat,frqs)   = el;                % Satellites' elevation [degree]
    model.bore(i_sat,frqs) = bore;              % Satellites' boresight angle [degree]
    % Phase center offsets and variations
    model.dX_ARP_ECEF_corr(i_sat,frqs)= dX_ARP_ECEF_corr;               % Receiver antenna reference point correction in ECEF
    model.dX_PCO_rec_corr(i_sat,frqs) = dX_PCO_REC_ECEF_corr(frqs);     % Receiver phase center offset correction in ECEF
    model.dX_PCO_sat_corr(i_sat,frqs) = dX_PCO_SAT_ECEF_corr(frqs);     % Satellite antenna phase center offset in ECEF
    % Satellite position and velocity:
    model.ECEF_X(:,i_sat) = X;          % Sat Position before correcting the earth rotation during runtime tau
    model.ECEF_V(:,i_sat) = V;          % Sat Velocity before correcting the earth rotation during runtime tau
    model.Rot_X(:,i_sat)  = X_rot;      % Sat Position after correcting the earth rotation during runtime tau
    model.Rot_V(:,i_sat)  = V_rot;  	% Sat Velocity after correcting the earth rotation during runtime tau 
    
    Epoch.exclude(i_sat,frqs) = exclude;   	% boolean, true = do not use satellites (e.g. under cutoff angle)
    Epoch.sat_status(i_sat,:) = status;   	
    
end     % of loop over satellites


