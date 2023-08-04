function [model, Epoch] = modelApproximately(settings, input, Epoch, param, obs, iteration)
% This function is a simpler version of modelErrorSources.m and models error
% sources for modelling the observation for calculating an approximate
% position.
% 
% INPUT:
%   settings    	settings from GUI  [struct]
%   input           input data (ephemerides, PCOs, etc.)   [struct]
%   Epoch           epoch-specific data for current epoch  [struct]
%   model           model corrections for all visible sats [struct]
%   rx_pos          Receiver Position ECEF [3x1]
%   obs             consisting observations and corresponding data   [struct]
%   iteration       step of iteration
% OUTPUT:
%   model           extended with modelled corrections to current satellite, [struct]
%   Epoch           updated with cutoff
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


pos_XYZ = param(1:3);
pos_WGS84 = cart2geo(param(1:3));
n_num_frq  = settings.INPUT.num_freqs;  % number of input frequencies (e.g. 2 for IF-LC)
num_freq = settings.INPUT.proc_freqs;   % number of processed frequencies
frqs = 1:num_freq;              % 1 : # processed frequencies
num_sat = Epoch.no_sats;        % number of satellites in current epoch
% indices of processed frequencies
idx_frqs_gps = settings.INPUT.gps_freq_idx(frqs);
idx_frqs_glo = settings.INPUT.glo_freq_idx(frqs);
idx_frqs_gal = settings.INPUT.gal_freq_idx(frqs);
idx_frqs_bds = settings.INPUT.bds_freq_idx(frqs);
% remove frequencies set to OFF (if different number of frequencies is 
% processed for different GNSS)
idx_frqs_gps(idx_frqs_gps>DEF.freq_GPS(end)) = [];
idx_frqs_glo(idx_frqs_glo>DEF.freq_GLO(end)) = [];
idx_frqs_gal(idx_frqs_gal>DEF.freq_GAL(end)) = [];
idx_frqs_bds(idx_frqs_bds>DEF.freq_BDS(end)) = [];


% ----- Epoch-specific corrections -----
% corrections which are valid for all satellites but only for a specific epoch

model = init_struct_model(num_sat, num_freq, n_num_frq);  	% Init struct model
% --- Calculate hour and approximate sun and moon position for epoch ---
h = mod(Epoch.gps_time,86400)/3600;
model.sunECEF  = sunPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
model.moonECEF = moonPositionECEF(obs.startdate(1), obs.startdate(2), obs.startdate(3), h);
% --- Rotation Matrix from Local Level to ECEF ---
model.R_LL2ECEF = setupRotation_LL2ECEF(pos_WGS84.lat, pos_WGS84.lon);



for i_sat = 1:num_sat                     
    % ----- Preparations -----
    prn = Epoch.sats(i_sat);        % [1-99] GPS, [101-199] GLO, [201-250] GAL, [301-399] BDS
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
    dT_rel = 0;
    cutoff = false;                 % cutoff-angle
    status = Epoch.sat_status(i_sat,:);
    dt_rx = (isGAL*param(4) + isGLO*param(5) + isGAL*param(6) + isBDS*param(7))/Const.C;     % receiver clock offset, [s?]
    
    
    
    % ----- Clock and Orbit -----
    
    % --- Ttr....transmission time/time of emission
    tau = Epoch.code(i_sat)/Const.C;    % approximate signal runtime from sat. to rec.
    Ttr = Epoch.gps_time - tau;       	% time of emission [sow (seconds of week)] = time of obs. - runtime
    
    % --- Get column of broadcast ephemerides for current satellite ---
    k = Epoch.BRDCcolumn(prn);
    if settings.ORBCLK.bool_brdc && isnan(k)      % no ephemeris
        fprintf('No broadcast orbit data for satellite %d in SOW %.3f              \n', prn, Ttr);
        cutoff = true;      % eliminate satellite
        status(:) = 15;
        Epoch.tracked(prn) = 1;
        continue
    end
    
    % --- Clock correction: with navigation data or precise clocks from .clk-file ---
    % Clock correction in seconds, accurate enough with approximate Ttr
    dT_sat = 0;      % just for simulated data when satellite clock is perfect
    [dT_sat, cutoff] = satelliteClock(sv, Ttr, input, isGPS, isGLO, isGAL, isBDS, k, settings, Epoch.corr2brdc_clk(:,prn));
    if isnan(dT_sat) || dT_sat == 0 || cutoff       % no clock correction
        if ~settings.INPUT.bool_parfor; fprintf('No precise clock data for satellite %d in SOW %0.3f              \n', prn, Ttr); end
        cutoff = true;                      % eliminate satellite
        status(:) = 5;
        Epoch.tracked(prn) = 1;         % set epoch counter for this satellite to 1
    end   
    
    for step = 1:2   % Iteration to estimate relativistic effect and interpolate satellite position
        dT_sat_rel = dT_sat + dT_rel;
        
        % --- correction of Time of emission ---
        tau = (Epoch.code(i_sat) + Const.C*dT_sat_rel)/Const.C; % corrected signal runtime
        Ttr = Epoch.gps_time - tau;                             % time of emission = time of obs. - runtime
        
        % --- Satellite-Orbit: precise ephemeris (.sp3-file) or broadcast navigation data (perhabs + correction stream) ---
        [X, V, cutoff, status] = satelliteOrbit(prn, Ttr, input, isGPS, isGLO, isGAL, isBDS, k, settings, cutoff, status, Epoch.corr2brdc_orb(:,prn));
        % --- correction of satellite ECEF position for earth rotation during runtime tau ---
        tau = tau - dt_rx;  % Correct tau for receiver clock error to avoid jumps in sat position
        omegatau = Const.WE*tau;     % [rad]
        R3 = [  cos(omegatau) sin(omegatau)     0;
               -sin(omegatau) cos(omegatau)     0;
                0               0               1];
        Rot_X = R3*X;
        Rot_V = R3*V;
        
        % --- Relativistic correction ---
        dT_rel = -2/Const.C^2 * dot2(Rot_X, Rot_V);
%         if isGLO && ~settings.ORBCLK.bool_sp3 && input.Eph_GLO(3,k) ~= 0  % ||| GLO
%             dT_rel = 0; % for BRDC correction already applied in gamma
%         end
    end % end of for step = 1:2 - Iteration to estimate relativistic effect and interpolate satellite position
    
    
    
    % ----- Vectors, Angles, Distance between Receiver and Satellite -----
    
    % --- Azimuth, Elevation, zenith distance, cutoff-angle ---
    [az, el] = topocent(pos_XYZ,Rot_X-pos_XYZ);     % calculate azimuth and elevation [°]
    if el < settings.PROC.elev_mask         % elevation is under cut-off-angle
        cutoff = true;                      % eliminate satellite
        status(:) = 2;
    end
    % ||| geodetic2aer.m could be used instead (vectoriell)
    
    % --- Theoretical Range and Line-of-sight-Vector ---
    los  = Rot_X - pos_XYZ;         % vector from receiver to satellite, Line-of-sight-Vector
    rho  = norm(los);               % distance from receiver to satellite
    los0 = los/rho;                 % unit vector from receiver to satellite
    
    % --- Satellite Orientation ---
    SatOr_ECEF = getSatelliteOrientation(Rot_X, model.sunECEF*1000);    % satellite orientation in ECEF
    

    
    % ----- Troposphere -----
    trop = 0;
    if iteration > 1
        p = 1013.25; T = 15; q = 48.14;     % default values for pressure, temperature, relative humidity
        [trop, ~, ~] = tropo_hopfield(Ttr, el/180*pi, [T;p;q], 0);
    end
   
    
    
    % ----- Ionosphere -----
    iono(1:num_freq) = 0;
    if iteration > 1 && ((strcmpi(settings.IONO.model, 'Estimate with ... as constraint') || strcmpi(settings.IONO.model, 'Correct with ...'))  && ~isnan(Ttr))
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
                iono(1) = iono_klobuchar(pos_WGS84.lat*(180/pi), pos_WGS84.lon*(180/pi), az, el, Ttr, input.IONO.klob_coeff);
                iono(2) = iono(1) * ( f1.^2 ./ f2.^2 );     % convert Klobuchar correction from L1 to L2
                iono(3) = iono(1) * ( f1.^2 ./ f3.^2 );     % convert Klobuchar correction from L2 to L3
            case 'NeQuick model'
                stec = eval_NeQuick(obs.startdate(2), Epoch.gps_time, pos_WGS84, Rot_X, input.IONO.nequ_coeff);
                iono(1) = 40.3/f1^2 * stec;      % delta_iono [m]
                iono(2) = 40.3/f2^2 * stec;
                iono(3) = 40.3/f3^2 * stec;
            case 'CODE Spherical Harmonics'
                stec = iono_coeff_global(pos_WGS84.lat, pos_WGS84.lon, az, el, round(Ttr), input.IONO.ion, obs.leap_sec);
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
    
    
    % ----- Eclipsing satellites -----
    % satellite intersects the line between sun and earth; the consequence are
    % rapid rotations of satellite orientation; each Satellite has two Eclipse
    % periods in a year, each lasts for 7 weeks; in this time the yaw attitude
    % is random and orbits are degraded;
    cos_phi = dot(Rot_X,model.sunECEF*1000)/(norm(Rot_X,'fro')*norm(model.sunECEF,'fro')*1000);
    if cos_phi < 0 && (norm(Rot_X,'fro')*sqrt(1-cos_phi^2)) < Const.RE
%        if mod(Epoch.q, 100) == 0
%            fprintf('Warning! Eclipsing Satellite PRN %d \t                \n', prn)
%        end
        cutoff = true;              % eliminate satellite
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
    dX_PCO_REC_ECEF_corr = zeros(num_freq,1);
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
        if strcmpi(settings.IONO.model,'2-Frequency-IF-LCs')
            dX_PCO_REC_ECEF_corr(1) = (f1^2*dX_los(1)-f2^2*dX_los(2)) / (f1^2-f2^2);
            if num_freq == 2
                dX_PCO_REC_ECEF_corr(2) = (f1^2*dX_los(1)-f3^2*dX_los(3)) / (f1^2-f3^2);
            end
        elseif strcmpi(settings.IONO.model,'3-Frequency-IF-LC')
            dX_PCO_REC_ECEF_corr(1) = e1.*dX_los(1) + e2.*dX_los(2) + e3.*dX_los(3);
        else                                        % no IF-LC
            dX_PCO_REC_ECEF_corr(frqs) = dX_los(idx_frqs);      % get values of processed frequencies
        end
    end

    % --- Satellite Antenna Phase Center Correction ---
    % convert observation from Antenna Phase Center to Center of Mass which
    % is necessary when orbit/clock product refers to the CoM
    % ||| check´n´change for not sp3
    dX_PCO_SAT_ECEF_corr = zeros(num_freq,1);
    if settings.OTHER.bool_sat_pco && settings.ORBCLK.bool_sp3 && ~cutoff   	
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
        end
        offset_LL = reshape(offset_LL,3,5,1);   % each column contains another frequency
        dX_PCO_SAT_ECEF = SatOr_ECEF*offset_LL;   	% transform offsets into ECEF site displacements
        dX_los = sum(los0.*dX_PCO_SAT_ECEF, 1); 	% project each frequency onto line of sight
        % missing satellite PCO corrections are replaced with the correction
        % of the 1st frequency:
        dX_los(dX_los==0) = dX_los(1);
        % convert to the processed frequencies
        if strcmpi(settings.IONO.model,'2-Frequency-IF-LCs')
            dX_PCO_SAT_ECEF_corr(1) = (f1^2*dX_los(1)-f2^2*dX_los(2)) / (f1^2-f2^2);
            if num_freq == 2
                dX_PCO_SAT_ECEF_corr(2) = (f1^2*dX_los(1)-f3^2*dX_los(3)) / (f1^2-f3^2);
            end
        elseif strcmpi(settings.IONO.model,'3-Frequency-IF-LC')
            dX_PCO_SAT_ECEF_corr(1) = e1.*dX_los(1) + e2.*dX_los(2) + e3.*dX_los(3);
        else                                        % no IF-LC
            dX_PCO_SAT_ECEF_corr(frqs) = dX_los(idx_frqs);
        end
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
    model.az(i_sat,frqs)   = az;                % Satellite azimuth [°]
    model.el(i_sat,frqs)   = el;                % Satellite elevation [°]
    % Phase center offsets and variations
    model.dX_ARP_ECEF_corr(i_sat,frqs)= dX_ARP_ECEF_corr;               % Receiver antenna reference point correction in ECEF
    model.dX_PCO_rec_corr(i_sat,frqs) = dX_PCO_REC_ECEF_corr(frqs);     % Receiver phase center offset correction in ECEF
    model.dX_PCO_sat_corr(i_sat,frqs) = dX_PCO_SAT_ECEF_corr(frqs);     % Satellite antenna phase center offset in ECEF
    % Satellite position and velocity:
    model.ECEF_X(:,i_sat) = X;          % Sat Position before correcting the earth rotation during runtime tau
    model.ECEF_V(:,i_sat) = V;          % Sat Velocity before correcting the earth rotation during runtime tau
    model.Rot_X(:,i_sat)  = Rot_X;      % Sat Position after correcting the earth rotation during runtime tau
    model.Rot_V(:,i_sat)  = Rot_V;  	% Sat Velocity after correcting the earth rotation during runtime tau 
    
    Epoch.exclude(i_sat,frqs) = cutoff;   	% boolean, true = do not use satellites (e.g. under cutoff angle)
    Epoch.sat_status(i_sat,:) = status;   	
    
end     % of loop over satellites


