function [Epoch] = RawSensor2Epoch(RAW, IMURAW, epochheader, q, raw_variables, Epoch, settings, use_column, leap_sec)
% This function is called at the beginning of an epoch and gets all data 
% (e.g., raw GNSS measurements) from the raw sensor file (Android) for the 
% current epoch. The observations and additional data is saved in the 
% struct Epoch for epoch-wise processing.
% 
% INPUT:
%   RAW             matrix, gnss raw measurements from text file
%   IMURAW          struct, fields contain IMU-relevant data
%   epochheader     vector, indicating the lines where a new epoch starts
%   q               number of current epoch
%   raw_variable    cell array, contains the variables contained in each epoch
%   Epoch           struct, containing epoch-specific data
%   settings        struct, processing settings 
%   use_column      cell, indicating location of processed observations
%   leap_sec        [s], number of leap seconds between UTC and GPST
% OUTPUT:
%	Epoch           updated with data of currently processed epoch
%
% Revision:
% 2025/08/14, MFWG: switch to cal2gpstime
% 2026/07/24, MFWG: adding 3rd frequency (Galileo E5b, BeiDou B1AC)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Bits of gnssRaw.State (2^xxx):
% 0: Code Lock                      1: Bit Sync     
% 2: Subframe Sync                  3: Time Of Week Decoded State     
% 4: Millisecond Ambiguity          5: Symbol Sync 
% 6: GLONASS String Sync            7: GLONASS Time Of Day Decoded      
% 8: BEIDOU D2 Bit Sync             9: BEIDOU D2 Subframe Sync       
% 10: Galileo E1BC Code Lock       	11: Galileo E1C 2^nd Code Lock
% 12: Galileo E1B Page Sync         13: SBAS Sync
% 14: Time Of Week Known            15: GLONASS Time Of Day Known

% get data of first satellite in first epoch
row_1 = epochheader(settings.PROC.epochs(1)) + 1;
RAW_1 = RAW(row_1,:);

% get data of current epoch
q_idx = settings.PROC.epochs(1) + q - 1;                % index of data epoch which is now processed
range = epochheader(q_idx)+1 : epochheader(q_idx+1);    % data-lines of current epoch
RAW_epoch = RAW(range,:);                               % data of current epoch

% get GNSS raw data
[gnssRaw] = extractGnssRawVariables(RAW_epoch, raw_variables, settings, RAW_1);

% generate raPPPid satellite numbering
% ConstellationType:
% 0 = UNKNOWN, 1 = GPS, 2 = SBAS, 3 = GLO, 4 = QZSS, 5 = BDS, 6 = GAL, 7 = IRNSS
sats = gnssRaw.Svid + ...       	% satellite number
    (gnssRaw.ConstellationType == 3) * 100 + ...    % GLONASS
    (gnssRaw.ConstellationType == 6) * 200 + ...    % Galileo
    (gnssRaw.ConstellationType == 5) * 300 + ...    % BeiDou
    (gnssRaw.ConstellationType == 4) * 400;         % QZSS

% correct satellite numbers of BeiDou (||| explanation for this issue???)
adjust_QZSS_prn = (gnssRaw.ConstellationType == 4) & (gnssRaw.Svid > 100);
sats(adjust_QZSS_prn) = sats(adjust_QZSS_prn) - 192;


%% time and observations
% -) generate GPS time and week with the measurements of the first GPS satellite
idx = find(gnssRaw.ConstellationType, 1, 'first');
[gpsweek, gpstime] = generateGpsTimeWeek(gnssRaw.TimeNanos(idx), gnssRaw.FullBiasNanos(idx), gnssRaw.BiasNanos(idx), ...
    gnssRaw.ReceivedSvTimeNanos(idx), gnssRaw.TimeOffsetNanos(idx), gnssRaw.FullBiasNanos_1, gnssRaw.BiasNanos_1);

% -) generate code pseudorange for all satellites
PR = generateCodePseudorange(gnssRaw, leap_sec);
% MultipathIndicator:
% 0 ... presence or absence of multipath is unknown
% 1 ... multipath detected
% 2 ... no multipath detected
% PR(gnssRaw.MultipathIndicator == 1) = NaN;    	% exclude PRs with multipath detected

% -) get phase observations
Phase = gnssRaw.AccumulatedDeltaRangeMeters;        % [m]
ADR_state = gnssRaw.AccumulatedDeltaRangeState;     % state of phase, converted to decimal
% ADR state: 
% 0 ... invalid or unknown
% 1 ... valid
% 2 ... reset has been detected
% 4 ... cycle slip has been detected
ADR_reset = bitand(ADR_state, 2^1);     % 2 ... reset has been detected
ADR_cs    = bitand(ADR_state, 2^2);     % 4 ... cycle slip has been detected
Phase(ADR_reset | ADR_cs) = NaN;        % exclude observations with reset or cycle slip detected according to ADR state

% -) get C/N0
SNR = gnssRaw.Cn0DbHz;

% -) get Doppler shift in [m/s]
% conversion from [m/s] to [Hz] is not possible here because the signal 
% frequency determined by the smartphone deviates from the nominal values, 
% which are not yet calculated!
Doppler = -gnssRaw.PseudorangeRateMetersPerSecond;    % [m/s]


%% save everything into Epoch
% time variables
Epoch.gps_time = gpstime;
Epoch.gps_week = gpsweek;
Epoch.time = gpstime2cal(gpsweek, gpstime);
Epoch.mjd = 44244 + gpsweek*7 + gpstime/86400;
% satellite numbers
Epoch.sats = unique(sort(sats));

% determine GNSS and frequency using approximate frequency
isGPS_L1 = (gnssRaw.ConstellationType == 1) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GPS_F1 /1e4));
isGLO_G1 = (gnssRaw.ConstellationType == 3) & (round(gnssRaw.CarrierFrequencyHz/1e7) == round(Const.GLO_F1 /1e7));
isGAL_E1 = (gnssRaw.ConstellationType == 6) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GAL_F1 /1e4));
isBDS_B1 = (gnssRaw.ConstellationType == 5) & (round(gnssRaw.CarrierFrequencyHz/1e3) == round(Const.BDS_F1 /1e3));
isQZS_L1 = (gnssRaw.ConstellationType == 4) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.QZSS_F1/1e4));
first_frq = isGPS_L1 | isGLO_G1 | isGAL_E1 | isBDS_B1 | isQZS_L1;
isGPS_L5 = (gnssRaw.ConstellationType == 1) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GPS_F5 /1e4));
isGAL_E5a= (gnssRaw.ConstellationType == 6) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GAL_F5a/1e4));
isBDS_B2a= (gnssRaw.ConstellationType == 5) & (round(gnssRaw.CarrierFrequencyHz/1e3) == round(Const.BDS_F2a/1e3));
isQZS_L5 = (gnssRaw.ConstellationType == 4) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.QZSS_F5/1e4));
secnd_frq = isGPS_L5 | isGAL_E5a| isBDS_B2a| isQZS_L5;     % not considered: isGLO_G2
isGAL_E5b = (gnssRaw.ConstellationType == 6) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GAL_F5b /1e4));
isBDS_B1AC= (gnssRaw.ConstellationType == 5) & (round(gnssRaw.CarrierFrequencyHz/1e3) == round(Const.BDS_F1AC/1e3));
third_frq = isGAL_E5b | isBDS_B1AC;             % not considered: GPS L2, GLONASS G3, QZSS L6

% save observation data into Epoch.obs
nFreq = 3;
obs = NaN(numel(Epoch.sats),4*nFreq); Epoch.obs = obs;
[obs]  = save2obs(obs, 1, nFreq, Epoch.sats, sats, PR, Phase, SNR, Doppler, first_frq);
[obs]  = save2obs(obs, 2, nFreq, Epoch.sats, sats, PR, Phase, SNR, Doppler, secnd_frq);
[obs]  = save2obs(obs, 3, nFreq, Epoch.sats, sats, PR, Phase, SNR, Doppler, third_frq);
% obs is ordered the following at the moment (columns):
%     L1 L2 L3 C1 C2 C3 S1 S2 S3 D1 D2 D3

% variables with information of the Epoch
n = numel(Epoch.sats);      % number of satellites
Epoch.usable = true;
Epoch.rinex_header = createRinexHeader(Epoch.gps_week, Epoch.gps_time, Epoch.usable, n);
Epoch.LLI_bit_rinex  = zeros(n, 4*nFreq);
Epoch.ss_digit_rinex = zeros(n, 4*nFreq);

% boolean vectors for each GNSS
Epoch.gps  = Epoch.sats < 100;
Epoch.glo  = Epoch.sats > 100 & Epoch.sats < 200;
Epoch.gal  = Epoch.sats > 200 & Epoch.sats < 300;
Epoch.bds  = Epoch.sats > 300 & Epoch.sats < 400;
Epoch.qzss = Epoch.sats > 400 & Epoch.sats < 500;
Epoch.other_systems = ~Epoch.gps & ~Epoch.glo & ~Epoch.gal & ~Epoch.bds & ~Epoch.qzss;

% rearrange obs to Epoch.obs to make it consistent with obs.use_column and
% keep only processed frequencies
% first frequency:
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.gps, use_column(1,1:3:10), [1 4 7 10]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.glo, use_column(2,1:3:10), [1 4 7 10]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.gal, use_column(3,1:3:10), [1 4 7 10]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.bds, use_column(4,1:3:10), [1 4 7 10]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.qzss,use_column(5,1:3:10), [1 4 7 10]);
% second frequency:
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.gps, use_column(1,2:3:11), [2 5 8 11]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.glo, use_column(2,2:3:11), [2 5 8 11]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.gal, use_column(3,2:3:11), [2 5 8 11]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.bds, use_column(4,2:3:11), [2 5 8 11]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.qzss,use_column(5,2:3:11), [2 5 8 11]);
% third frequency:
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.gps, use_column(1,3:3:12), [3 6 9 12]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.glo, use_column(2,3:3:12), [3 6 9 12]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.gal, use_column(3,3:3:12), [3 6 9 12]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.bds, use_column(4,3:3:12), [3 6 9 12]);
Epoch.obs = rearranGeNSS(Epoch.obs, obs, Epoch.qzss,use_column(5,3:3:12), [3 6 9 12]);



%% IMU DATA FOR CURRENT EPOCH

epoch_utc = Epoch.time - seconds(leap_sec);
dt_imu    = 1.0;

% initialize blank values (e.g, no sensor data, no time overlap for interpolation)
Epoch.IMU.acc_raw = NaN(0,3); Epoch.IMU.acc = NaN(1,3);
Epoch.IMU.gyr_raw = NaN(0,3); Epoch.IMU.gyr = NaN(1,3);
Epoch.IMU.acc_bias = NaN(1,3); Epoch.IMU.gyr_drift = NaN(1,3);
Epoch.IMU.mag_raw = NaN(0,3);
Epoch.IMU.mag     = NaN(1,3);
Epoch.IMU.OrientationDeg = nan(0, 3);
Epoch.IMU.yaw_deg        = NaN;
Epoch.IMU.pitch_deg      = NaN;
Epoch.IMU.roll_deg       = NaN;


% ----- Accelerometer and Gyroscope: UncalAccel and UncalGyro -----
if settings.KINE.bool_IMU && isfield(IMURAW, 'UncalAccel') && ~isempty(IMURAW.UncalAccel) && isfield(IMURAW, 'UncalGyro')  && ~isempty(IMURAW.UncalGyro)

    % find accelerations in the window [epoch - 1s, epoch]
    mask_acc = (IMURAW.UncalAccel.t > epoch_utc - seconds(dt_imu))   &   (IMURAW.UncalAccel.t <= epoch_utc);
    if ~any(mask_acc)
         % fallback: If no data found, look in the forward window [epoch, epoch + 1s]
        mask_acc = (IMURAW.UncalAccel.t > epoch_utc)   &   (IMURAW.UncalAccel.t <= epoch_utc + seconds(dt_imu));
    end
    % find gyroscope measurements in the window [epoch - 1s, epoch]
    mask_gyr = (IMURAW.UncalGyro.t > epoch_utc - seconds(dt_imu)) & (IMURAW.UncalGyro.t <= epoch_utc);
    if ~any(mask_gyr)
        % fallback: If no data found, look in the forward window [epoch, epoch + 1s]
        mask_gyr = (IMURAW.UncalGyro.t > epoch_utc)   &   (IMURAW.UncalGyro.t <= epoch_utc + seconds(dt_imu));
    end

    % extract the data in the time window
    TT_acc = IMURAW.UncalAccel(mask_acc, :);
    TT_gyr = IMURAW.UncalGyro(mask_gyr,  :);

    % --- Synchronization & Resampling ---
    if ~isempty(TT_acc) && ~isempty(TT_gyr)

        % Create a common time vector (0.01s steps) spanning the overlapping time range of both sensors
        t_common = (max(TT_acc.t(1), TT_gyr.t(1)):seconds(0.01):min(TT_acc.t(end), TT_gyr.t(end)))';
        if numel(t_common) >= 2

            % resample both sensors using linear interpolation
            TT_acc = retime(TT_acc, t_common, 'linear');
            TT_gyr = retime(TT_gyr, t_common, 'linear');

            % calculate raw motion by subtracting the bias/drift from the uncalibrated values
            Epoch.IMU.acc_raw = [TT_acc.UncalAccelXMps2 - TT_acc.BiasXMps2, ...
                                  TT_acc.UncalAccelYMps2 - TT_acc.BiasYMps2, ...
                                  TT_acc.UncalAccelZMps2 - TT_acc.BiasZMps2];
            Epoch.IMU.gyr_raw = [TT_gyr.UncalGyroXRadPerSec - TT_gyr.DriftXRadPerSec, ...
                                  TT_gyr.UncalGyroYRadPerSec - TT_gyr.DriftYRadPerSec, ...
                                  TT_gyr.UncalGyroZRadPerSec - TT_gyr.DriftZRadPerSec];

            % save mean biases/drifts for this specific epoch
            Epoch.IMU.acc_bias  = mean([TT_acc.BiasXMps2, TT_acc.BiasYMps2, TT_acc.BiasZMps2], 1);
            Epoch.IMU.gyr_drift = mean([TT_gyr.DriftXRadPerSec, TT_gyr.DriftYRadPerSec, TT_gyr.DriftZRadPerSec], 1);
            
            % calculate epoch-averaged motion values
            Epoch.IMU.acc = mean(Epoch.IMU.acc_raw, 1);
            Epoch.IMU.gyr = mean(Epoch.IMU.gyr_raw, 1);
        end
    end
end

% ----- Magnetometer: UncalMag -----
if settings.KINE.bool_IMU && isfield(IMURAW, 'UncalMag') && ~isempty(IMURAW.UncalMag)
    
    % find magnetometer measurements in the window [epoch - 1s, epoch]
    mask_raw = IMURAW.UncalMag.t > epoch_utc - seconds(dt_imu) & IMURAW.UncalMag.t <= epoch_utc;
    if ~any(mask_raw)
         % fallback: If no data found, look in the forward window [epoch, epoch + 1s]
        mask_raw = (IMURAW.UncalMag.t > epoch_utc)   &   (IMURAW.UncalMag.t <= epoch_utc + seconds(dt_imu));
    end

    if any(mask_raw)
        % extract X, Y, Z magnetometer components [MicroTesla]
        Epoch.IMU.mag_raw = [IMURAW.UncalMag.UncalMagXMicroT(mask_raw), ...
                              IMURAW.UncalMag.UncalMagYMicroT(mask_raw), ...
                              IMURAW.UncalMag.UncalMagZMicroT(mask_raw)];
        % calculate epoch-average
        Epoch.IMU.mag = mean(Epoch.IMU.mag_raw, 1);
    end
end

% ----- Orientation/Attitude: OrientationDeg -----
if settings.KINE.bool_IMU && isfield(IMURAW, 'OrientationDeg') && ~isempty(IMURAW.OrientationDeg)
    mask_ori = IMURAW.OrientationDeg.t > epoch_utc - seconds(dt_imu)    & ...
               IMURAW.OrientationDeg.t <= epoch_utc;
    if ~any(mask_ori)
         % fallback: If no data found, look in the forward window [epoch, epoch + 1s]
        mask_ori = IMURAW.OrientationDeg.t > epoch_utc   & ...
                   IMURAW.OrientationDeg.t <= epoch_utc + seconds(dt_imu);
    end

    if any(mask_ori)
        % extract orientation angles [°]
        yaw_masked   = IMURAW.OrientationDeg.yawDeg(mask_ori);
        roll_masked  = IMURAW.OrientationDeg.rollDeg(mask_ori);
        pitch_masked = IMURAW.OrientationDeg.pitchDeg(mask_ori);
        Epoch.IMU.OrientationDeg = [yaw_masked, roll_masked, pitch_masked];
    
        % save last attitude of this epoch [°]
        Epoch.IMU.yaw_deg   = yaw_masked(end);
        Epoch.IMU.pitch_deg = pitch_masked(end);
        Epoch.IMU.roll_deg  = roll_masked(end);
    end
end

% motion state and ZUPT probability for current epoch
[Epoch.motionState, Epoch.ZUPT_prob] = detectMotionState(Epoch);




function [obs] = save2obs(obs, frq, nFreq, Epoch_sats, sats, C_data, L_data, S_data, D_data, bool_data)
% This function saves the read-in measurements into obs
% Therefore, the code matches satellites with measurement with all
% satellites of the current epoch.
%
% INPUT:
%   obs             matrix, measurements of current epoch
%   frq             frequency, 1, 2 or 3
%   nFreq           total number of frequency slots in obs (columns per obs type)
%   Epoch_sats  	vector, satellites observed in current epoch
%   sats            vector, satellites with raw GNSS data
%   C_data, L_data, S_data, D_data
%                   code, phase, SNR, Doppler data
%   bool_data       boolean, indicating frequency
% OUTPUT:
%	Epoch_obs       updated new data of current frequency
%
% *************************************************************************

% find indices to save data into Epoch.obs
data_sats = sats(bool_data);
[~, idx_a, idx_b] = intersect(Epoch_sats, data_sats);

% get observation data of current frequency
C_data_ = C_data(bool_data);
L_data_ = L_data(bool_data);
S_data_ = S_data(bool_data);
D_data_ = D_data(bool_data);

% save observation data into Epoch.obs
obs(idx_a, frq          ) = L_data_(idx_b);     % phase
obs(idx_a, frq +   nFreq) = C_data_(idx_b);     % code
obs(idx_a, frq + 2*nFreq) = S_data_(idx_b);     % C/N0
obs(idx_a, frq + 3*nFreq) = D_data_(idx_b);     % Doppler



function Epoch_obs = rearranGeNSS(Epoch_obs, obs, bool, use_column, idx)
% rearrange observations from raw sensor data to Epoch_obs to make it
% consistent with obs.use_column and the observation types detected at the 
% beginning of the processing
if ~isempty(use_column{1})      % phase
    Epoch_obs(bool, use_column{1}) = obs(bool, idx(1));
end
if ~isempty(use_column{2})      % code
    Epoch_obs(bool, use_column{2}) = obs(bool, idx(2));
end
if ~isempty(use_column{3})      % C/N0
    Epoch_obs(bool, use_column{3}) = obs(bool, idx(3));
end
if ~isempty(use_column{4})      % Doppler
    Epoch_obs(bool, use_column{4}) = obs(bool, idx(4));
end



function rinex_header = createRinexHeader(gps_week, gps_time, usable, n_sats)
% create RINEX observation record header (e.g., to simplify comparisons)
caldate = gpstime2cal(gps_week, gps_time);
y = year(caldate);  mn = month(caldate);    d = day(caldate);
h = hour(caldate);  m = minute(caldate);    s = second(caldate);
rinex_header = ['> ' sprintf('%4d ', y) sprintf('%02d ', mn) sprintf('%02d ', floor(d)) ...
    sprintf('%02d ', floor(h)) sprintf('%02d ', floor(m)) sprintf('%02.7f  ', s)...
    sprintf('%1d ', ~usable) sprintf('%2d ', n_sats)];

