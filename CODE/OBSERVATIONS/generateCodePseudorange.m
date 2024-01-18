function [PR] = generateCodePseudorange(gnssRaw, leap_seconds, ...
    GPS_L1, GPS_L5, GLO_G1, GAL_E1, GAL_E5a, BDS_B1, BDS_B2a, QZS_L1, QZS_L5)
% This function generates the code pseudorange observation for the current 
% epoch from the sensor data Android devices provide based on approach 1 
% (2.4.2.1) described in https://data.europa.eu/doi/10.2878/449581
% Most variables are in [nanoseconds] = 1e-9 [seconds]
% 
% based on:
%   ProcessGnssMeas.m from https://github.com/google/gps-measurement-tools
%   csv2rinex from https://github.com/FarzanehZangeneh/csv2rinex
% 
% INPUT:
%   gnssRaw         struct, contains raw GNSS data of current epoch
%   leap_sec        [s], number of leap seconds between UTC and GPST
%   GPS_L1, GPS_L5, GLO_G1, GAL_E1, ...
%                   boolean vectors indicating origin of measurement
% OUTPUT:
%	PR              code pseudorange for all satellites [m]
%
% Revision:
%   2024/01/08, MFWG: improving PR generation, adding BDS B2a and QZSS
%   2024/01/16, MFWG: repairing GPS week rollover 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% some constants
gpsweek_no_s = 604800;      % [s],   number of seconds in a week
MAX_PR_R_UNC = 10;          % [m/s], maximum pseudorange rate uncertainty
MAX_TOW_UNC = 500;          % [ns],  maximum Tow uncertainty

% get some variables
FullBiasNanos   = gnssRaw.FullBiasNanos;
FullBiasNanos_1 = gnssRaw.FullBiasNanos_1;
BiasNanos_1     = gnssRaw.BiasNanos_1;
ReceivedSvTimeNanos = gnssRaw.ReceivedSvTimeNanos;
TimeOffsetNanos     = gnssRaw.TimeOffsetNanos;
TimeNanos           = gnssRaw.TimeNanos;
ReceivedSvTimeUncertaintyNanos            = gnssRaw.ReceivedSvTimeUncertaintyNanos;
PseudorangeRateUncertaintyMetersPerSecond = gnssRaw.PseudorangeRateUncertaintyMetersPerSecond;
ConstellationType   = gnssRaw.ConstellationType;
State               = gnssRaw.State;

% check State
CODE_LOCK             = bitand(State, 2^0);
TOW_DECODED           = bitand(State, 2^3);
GLO_STRING_SYNC       = bitand(State, 2^6);
GLO_TOD_DECODED       = bitand(State, 2^7);
GAL_E1BC_CODE_LOCK    = bitand(State, 2^10);
GAL_E1C_2ND_CODE_LOCK = bitand(State, 2^11);
GAL_E1B_PAGE_SYNC     = bitand(State, 2^12);
TOW_KNOWN             = bitand(State, 2^14);


% keep only satellites with ReceivedSvTimeUncertaintyNanos < 5 ns and 
% PseudorangeRateUncertaintyMetersPerSecond < 10 m/s
remove = ReceivedSvTimeUncertaintyNanos > MAX_TOW_UNC | ...
    PseudorangeRateUncertaintyMetersPerSecond > MAX_PR_R_UNC;
% ||| investigate suitability of these conditions, just copied
% ||| investigate when and why these values are bad


% calculate current GPS Week number:
gps_week = floor(abs(double(FullBiasNanos))*1e-9 / gpsweek_no_s);  % []

% compute gps week's beginning time in nanoseconds for further calculations
gps_week_ns = int64(gps_week) * int64(gpsweek_no_s)*1e9;     % [ns]

% compute t_RX_ns (time signal received) using FullBiasNanos(1)
t_RX_ns = TimeNanos - FullBiasNanos_1;

% consider different states of GNSS engine, depending on GNSS and frequency:
% GPS L1, BeiDou B1, QZSS L1
keep_L1 = (GPS_L1 | BDS_B1 | QZS_L1 ) & CODE_LOCK & (TOW_DECODED | TOW_KNOWN);
% GLONASS G1
keep_G1 = GLO_G1 & GLO_STRING_SYNC & GLO_TOD_DECODED;
% Galileo E1
keep_E1 = GAL_E1 & GAL_E1BC_CODE_LOCK | GAL_E1C_2ND_CODE_LOCK;
% GPS L5, BeiDou B2a, QZSS L5, Galileo E5a
keep_L5 = (GPS_L5 | GAL_E5a | BDS_B2a | QZS_L5) & CODE_LOCK;
% put together
keep = keep_L1 | keep_G1 | keep_E1 | keep_L5;
remove = remove & ~keep;

% consider different GNSS time systems, everyting is calculated in [ns]:
% - GPS, Galileo, QZSS
GEJ = - gps_week_ns;                            
bool_GEJ = (ConstellationType == 1 | ConstellationType == 4 | ConstellationType == 6);
% - BeiDou
BDS = - gps_week_ns - Const.BDST_GPST*1e9;     
bool_BDS = (ConstellationType == 5);
% - GLONASS
DayNumber = idivide(-FullBiasNanos,int64(86400e9))*86400e9;     % integer division rounding towards zero
GLO = - DayNumber + (3*3600 - leap_seconds)*1e9;    % [ns]
bool_GLO = (ConstellationType == 3);
% - put together
add = t_RX_ns * 0;          % initialize
add(bool_GEJ) = GEJ(bool_GEJ);
add(bool_BDS) = BDS(bool_BDS);
add(bool_GLO) = GLO(bool_GLO);
t_RX_ns = t_RX_ns + add;            % t_RX_ns now since beginning of the week, unless we had a week rollover

% subtract the fractional offsets TimeOffsetNanos and BiasNanos:
t_RX_s  = t_RX_ns - TimeOffsetNanos - BiasNanos_1;      % [ns], received time (measurement time)
t_TX_s  = ReceivedSvTimeNanos;                          % [ns], transmitted time

% avoid large numbers
t_RX_s(remove) = 0;
t_TX_s(remove) = 0;

% compute pseudorange as difference between received and transmitted time
PR_s  = double(t_RX_s - t_TX_s)*1e-9;  	% [s]

% check for GPS week rollover here (practically, this never happens)
rollover = PR_s > gpsweek_no_s / 2;
if any(rollover)
    correct = round(PR_s / 604800) * 604800;
    PR_s(rollover) = PR_s(rollover) - correct(rollover);
end

% exclude unreasonable pseudoranges (longer than 0.5 seconds or negative)
% resulting, for example, from failed GPS week rollover repairing
remove = remove | PR_s > 0.5 |  PR_s < 0;


% convert pseudorange to meters:
PR = PR_s * Const.C;            % [m]

% remove bad measurements
PR(remove) = NaN;

% calculate uncertainty of generated pseudorange [m]
% PR_sigma    = double(ReceivedSvTimeUncertaintyNanos) * 1e-9 * Const.C;