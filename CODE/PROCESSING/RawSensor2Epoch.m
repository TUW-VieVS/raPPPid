function [Epoch] = RawSensor2Epoch(RAW, epochheader, q, raw_variables, Epoch, settings, use_column)
% This function is called at the beginning of an epoch and gets all data 
% (e.g., raw GNSS measurements) from the raw sensor file (Android) for the 
% current epoch. The observations and additional data is saved in the 
% struct Epoch for epoch-wise processing.
% 
% INPUT:
%   RAW             matrix, gnss raw measurements from textfile
%   epochheader     vector, indicating the lines where a new epoch starts
%   q               number of current epoch
%   raw_variable    cell array, contains the variables contained in each epoch
%   Epoch           struct, containing epoch-specific data
%   settings        struct, processing settings 
%   use_column      cell, indicating location of processed observations
% OUTPUT:
%	Epoch           updated with data of currently processed epoch
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| third-frequency is ignored because no triple-frequency smartphones exist

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
% 1 = GPS, 2 = SBAS, 3 = GLO, 4 = QZSS, 5 = BDS, 6 = GAL
sats = gnssRaw.Svid + ...       	% satellite number
    (gnssRaw.ConstellationType == 3) * 100 + ...    % GLONASS
    (gnssRaw.ConstellationType == 5) * 300 + ...    % BeiDou
    (gnssRaw.ConstellationType == 6) * 200;         % Galileo

% detect the origin of the measurement (GNSS and frequency) using approximate frequency
isGPS_L1 = (gnssRaw.ConstellationType == 1) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GPS_F1/1e4));
isGPS_L5 = (gnssRaw.ConstellationType == 1) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GPS_F5/1e4));
isGLO_G1 = (gnssRaw.ConstellationType == 3) & (round(gnssRaw.CarrierFrequencyHz/1e7) == round(Const.GLO_F1/1e7));
isGAL_E1 = (gnssRaw.ConstellationType == 6) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GAL_F1/1e4));
isGAL_E5a= (gnssRaw.ConstellationType == 6) & (round(gnssRaw.CarrierFrequencyHz/1e4) == round(Const.GAL_F5a/1e4));
isBDS_B1 = (gnssRaw.ConstellationType == 5) & (round(gnssRaw.CarrierFrequencyHz/1e3) == round(Const.BDS_F1/1e3));
isBDS_B2 = (gnssRaw.ConstellationType == 5) & (round(gnssRaw.CarrierFrequencyHz/1e3) == round(Const.BDS_F2/1e3));


%% time and observations
% -) generate GPS time and week with the measurements of the first GPS satellite
idx = find(gnssRaw.ConstellationType, 1, 'first');
gpstime = gnssRaw.TimeNanos(idx) - gnssRaw.FullBiasNanos(idx) - gnssRaw.BiasNanos(idx);     % [ns]
gpstime = double(mod(gpstime, 604800*1e9))*1e-9;        % convert to double and [s]
gpsweek = floor(abs(double(gnssRaw.FullBiasNanos(idx)))*1e-9 / 604800);    % gps week, []

% -) generate code pseudorange for all satellites
PR = generateCodePseudorange(gnssRaw, isGPS_L1, isGPS_L5, isGLO_G1, isGAL_E1, isGAL_E5a, isBDS_B1, isBDS_B2);
% MultipathIndicator:
% 0 ... presence or absence of multipath is unknown
% 1 ... multipath detected
% 2 ... no multipath detected
% PR(gnssRaw.MultipathIndicator == 1) = NaN;    	% exclude PRs with multipath detected

% -) get phase observations
Phase = gnssRaw.AccumulatedDeltaRangeMeters;        % [m]
ADR_state = gnssRaw.AccumulatedDeltaRangeState;     % state of phase
% ADR state: 
% 0 ... invalid or unknown
% 1 ... valid
% 2 ... reset has been detected
% 4 ... cycle slip has been detected
ADR_reset = bitand(ADR_state, 2^1);
ADR_cs    = bitand(ADR_state, 2^2);
Phase(ADR_reset | ADR_cs) = NaN;                    % exclude observations with reset or cycle slip detected

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
Epoch.mjd = gps2jd_GT(gpsweek, gpstime) - 2400000.5;
Epoch.gps_week = gpsweek;
% satellite numbers
Epoch.sats = unique(sort(sats));

% save observation data into Epoch.obs
obs = NaN(numel(Epoch.sats),8); Epoch.obs = obs;
first_frq = isGPS_L1 | isGLO_G1 | isGAL_E1 | isBDS_B1;
secon_frq = isGPS_L5 | isGAL_E5a| isBDS_B2;     % not considered: isGLO_G2
[obs]  = save2obs(obs, 1, Epoch.sats, sats, PR, Phase, SNR, Doppler, first_frq);
[obs]  = save2obs(obs, 2, Epoch.sats, sats, PR, Phase, SNR, Doppler, secon_frq);
% obs is ordered the following at the moment:
%     1 2 [] 3 4 [] 5 6 [] 7 8 []; ...    % GPS
%     1 2 [] 3 4 [] 5 6 [] 7 8 []; ...    % GLONASS
%     1 2 [] 3 4 [] 5 6 [] 7 8 []; ...    % Galileo
%     1 2 [] 3 4 [] 5 6 [] 7 8 [];        % BeiDou

% variables with information of the Epoch
n = numel(Epoch.sats);      % number of satellites
Epoch.usable = true;
Epoch.rinex_header = '';
Epoch.LLI_bit_rinex = zeros(n, 8);
Epoch.ss_digit_rinex = zeros(n, 8);

% boolean vectors for each GNSS
Epoch.gps = Epoch.sats < 100;
Epoch.glo = Epoch.sats > 100 & Epoch.sats < 200;
Epoch.gal = Epoch.sats > 200 & Epoch.sats < 300;
Epoch.bds = Epoch.sats > 300;
Epoch.other_systems = ~Epoch.gps & ~Epoch.glo & ~Epoch.gal & ~Epoch.bds;

% rearrange obs to Epoch.obs to make it consistent with obs.use_column and
% keep only processed frequencies
% first frequency:
Epoch.obs = rearrangGNSS(Epoch.obs, obs, Epoch.gps, use_column(1,1:3:10), [1 3 5 7]);
Epoch.obs = rearrangGNSS(Epoch.obs, obs, Epoch.glo, use_column(2,1:3:10), [1 3 5 7]);
Epoch.obs = rearrangGNSS(Epoch.obs, obs, Epoch.gal, use_column(3,1:3:10), [1 3 5 7]);
Epoch.obs = rearrangGNSS(Epoch.obs, obs, Epoch.bds, use_column(4,1:3:10), [1 3 5 7]);
% second frequency:
Epoch.obs = rearrangGNSS(Epoch.obs, obs, Epoch.gps, use_column(1,2:3:11), [2 4 6 8]);
Epoch.obs = rearrangGNSS(Epoch.obs, obs, Epoch.glo, use_column(2,2:3:11), [2 4 6 8]);
Epoch.obs = rearrangGNSS(Epoch.obs, obs, Epoch.gal, use_column(3,2:3:11), [2 4 6 8]);
Epoch.obs = rearrangGNSS(Epoch.obs, obs, Epoch.bds, use_column(4,2:3:11), [2 4 6 8]);





function [obs] = save2obs(obs, frq, Epoch_sats, sats, C_data, L_data, S_data, D_data, bool_data)
% This function saves the read-in measurements into obs 
% Therefore, the code matches satellites with measurement with all 
% satellites of the current epoch.
% 
% INPUT:
%   obs             matrix, measurements of current epoch
%   frq             frequency, 1 or 2
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

% save observatio data into Epoch.obs
obs(idx_a, frq    ) = L_data_(idx_b);     % phase
obs(idx_a, frq + 2) = C_data_(idx_b);     % code
obs(idx_a, frq + 4) = S_data_(idx_b);     % C/N0
obs(idx_a, frq + 6) = D_data_(idx_b);     % Doppler



function Epoch_obs = rearrangGNSS(Epoch_obs, obs, bool, use_column, idx)
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




