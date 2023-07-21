function [PR] = generateCodePseudorange(gnssRaw, isGPS_L1, isGPS_L5, isGLO_G1, isGAL_E1, isGAL_E5a, isBDS_B1, isBDS_B2)
% This function generates the code pseudorange observation for the current 
% epoch from the sensor data Android devices provide based on approach 1 
% (2.4.2.1) described in https://data.europa.eu/doi/10.2878/449581
% Most variables are in [nanoseconds] = 1e-9 [seconds]
% 
% based on:
%   ProcessGnssMeas.m from https://github.com/google/gps-measurement-tools
% 
% INPUT:
%   gnssRaw         struct, contains raw GNSS data of current epoch
%   isGPS_L1, isGPS_L5, isGLO_G1, isGAL_E1, isGAL_E5a, isBDS_B1, isBDS_B2
%                   boolean vectors indicating origin of measurement
% OUTPUT:
%	PR              code pseudorange for all satellites [m]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get some variables
FullBiasNanos = gnssRaw.FullBiasNanos;
FullBiasNanos_1 = gnssRaw.FullBiasNanos_1;
BiasNanos_1 = gnssRaw.BiasNanos_1;
ReceivedSvTimeNanos = gnssRaw.ReceivedSvTimeNanos;
TimeOffsetNanos = gnssRaw.TimeOffsetNanos;
TimeNanos = gnssRaw.TimeNanos;
State = gnssRaw.State;
ReceivedSvTimeUncertaintyNanos = gnssRaw.ReceivedSvTimeUncertaintyNanos;
PseudorangeRateUncertaintyMetersPerSecond = gnssRaw.PseudorangeRateUncertaintyMetersPerSecond;
ConstellationType = gnssRaw.ConstellationType;

% some constants
Const.C = 299792458;        % [m/s], speed of light
gpsweek_no_s = 604800;      % [s],   number of seconds in a week
MAX_PR_R_UNC = 10;          % [m/s], maximum pseudorange rate uncertainty
MAX_TOW_UNC = 500;          % [ns],  maximum Tow uncertainty
leap_seconds = 18;          % [s], leap seconds UTC - GPST ||| dehardcode


% keep only satellites with ReceivedSvTimeUncertaintyNanos < 5 ns and 
% PseudorangeRateUncertaintyMetersPerSecond < 10 m/s
exclude = ReceivedSvTimeUncertaintyNanos > MAX_TOW_UNC | ...
    PseudorangeRateUncertaintyMetersPerSecond > MAX_PR_R_UNC;
% check code lock for GPS and BeiDou 
exclude = exclude | ((ConstellationType == 1 | ConstellationType == 5) & ~bitand(State, 2^0));
% ||| investigate suitability of these conditions, just copied
% ||| investigate when and why these values are bad



% calculate current GPS Week number:
gps_week = floor(abs(double(FullBiasNanos))*1e-9 / gpsweek_no_s);  % []

% compute gps week's beginning time in nanoseconds for further calculations
gps_week_ns = int64(gps_week) * int64(gpsweek_no_s)*1e9;     % [ns]

% compute t_RX_ns using FullBiasNanos(1)
t_RX_ns = TimeNanos - FullBiasNanos_1;

% consider different GNSS time systems and different states of GNSS engine 
% (e.g., TOW decoded), calculated in [ns]
% - GPS and Galileo, TOW decoded
idx1 = (ConstellationType == 1 | ConstellationType == 6) & bitand(State, 2^3);
GPSGAL_tow_decoded = - gps_week_ns;
% - BeiDou, TOW decoded
idx2 = (ConstellationType == 5) & bitand(State, 2^3);
BDS_tow_decoded = - gps_week_ns - 14*1e9;
% - Galileo, E1C 2nd code status
idx3 = (ConstellationType == 6) & bitand(State, 2^11);
GAL_E1C_2nd = - gps_week_ns ;    % somehow this works although it should not
% GAL_E1C_2nd = - floor(-FullBiasNanos/1e8) * 1e8 ;  % ||| PR generation described in https://data.europa.eu/doi/10.2878/449581
% - GLONASS
idx4 = (ConstellationType == 3) & bitand(State, 2^6) & bitand(State, 2^7);
DayNumber = idivide(-FullBiasNanos,int64(86400e9))*86400e9;     % integer division rounding towards zero
GLO_tod_decoded = - DayNumber + (3*3600 - leap_seconds)*1e9;    % [ns]
% - GPS L5
idx5 = isGPS_L5;                % do not check bit 2^3 (tow known)
GPS_L5_tow = GPSGAL_tow_decoded;
% -- put together
add = t_RX_ns * 0;          % initialize
add(idx1) = GPSGAL_tow_decoded(idx1);
add(idx2) = BDS_tow_decoded(idx2);
add(idx3) = GAL_E1C_2nd(idx3);
add(idx4) = GLO_tod_decoded(idx4);
add(idx5) = GPS_L5_tow(idx5);
exclude = exclude | ~(idx1 | idx2 | idx3 | idx4 | idx5);  	% exclude unconvertable measurements at the end
% --- convert all to GPS/Galileo time
t_RX_ns = t_RX_ns + add;


% ||| check for GPS week rollover (practically, this never happens)
% t_RX_ns now since beginning of the week, unless we had a week rollover


% subtract the fractional offsets TimeOffsetNanos and BiasNanos:
t_RX_s  = t_RX_ns - TimeOffsetNanos - BiasNanos_1;      % [ns], received time (measurement time)
t_TX_s  = ReceivedSvTimeNanos;                          % [ns], transmitted time

% avoid large numbers
t_RX_s(exclude) = 0;
t_TX_s(exclude) = 0;

% ||| check for GPS week rollover in t_RX_s (practically, this never happens)


% compute pseudorange as difference between received and transmitted time
PR_s  = double(t_RX_s - t_TX_s)*1e-9;  	% [s]

% convert pseudorange to meters:
PR = PR_s * Const.C;            % [m]

% remove bad measurements
PR(exclude) = NaN;

% uncertainty of generated pseudorange [m]
% PR_sigma    = double(ReceivedSvTimeUncertaintyNanos) * 1e-9 * Const.C;