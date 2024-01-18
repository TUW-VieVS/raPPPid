function [gpsweek, gpstime] = generateGpsTimeWeek(TimeNanos, FullBiasNanos, BiasNanos, ...
    ReceivedSvTimeNanos, TimeOffsetNanos, ...
    FullBiasNanos_1, BiasNanos_1)       % optional
% This function generates the GPS time and week for raw GNSS measurements 
% from Android devices and checks for GPS week rollover
% 
% INPUT:
%   TimeNanos       int64, [ns], difference between TimeNanos inside the GPS receiver and the true GPS time since 6 January 1980
%   FullBiasNanos   int64, [ns], GNSS receiver’s internal hardware clock value
%   BiasNanos       int64, [ns], clock’s sub-nanosecond bias
% 
%   the following variables are used for checking a GPS week rollover:
%       ReceivedSvTimeNanos 
%                   int64, [ns], received GNSS satellite time at the measurement time
%       TimeOffsetNanos
%                   int64, [ns], time offset at which the measurement was taken
%   optional:
%       FullBiasNanos_1 = FullBiasNanos from first processd epoch
%       BiasNanos_1 = TimeNanos from first processed epoch
% OUTPUT:
%	gpsweek         [], GPS week number
%   gpstime         [s], time since beginning of GPS week
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************

% ||| before calling this function the following checks should be performed
% ||| 1) (gnssRaw.ConstellationType == 1) if GPS satellite
% ||| 2) CODE_LOCK & (TOW_DECODED | TOW_KNOWN) from variable State


% constants
WEEK_s = 604800;      % [s],   number of seconds in a week



%% calculate GPS time and week
% calculate GPS time
gpstime_ns = TimeNanos - FullBiasNanos - BiasNanos;            % [ns]
gpstime = double(mod(gpstime_ns, WEEK_s*1e9))*1e-9;            % convert to double and [s]

% calculate GPS week
gpsweek = floor(abs(double(FullBiasNanos))*1e-9 / WEEK_s); 	% gps week, []



%% check for rollover
% check if variables from first epoch are existing
if ~exist('BiasNanos_1',     'var');     BiasNanos_1 = BiasNanos;     end
if ~exist('FullBiasNanos_1', 'var'); FullBiasNanos_1 = FullBiasNanos; end
     
% compute gps week's beginning time in nanoseconds for further calculations
gps_week_ns = int64(gpsweek) * int64(WEEK_s) * 1e9;  	% [ns]

% compute t_RX_ns (time signal received) using FullBiasNanos(1)
t_RX_ns = TimeNanos - FullBiasNanos_1;

% consider different GNSS time systems, everyting is calculated in [ns]:
t_RX_ns = t_RX_ns - gps_week_ns; 	% t_RX_ns now since beginning of the week, unless we had a week rollover

% subtract the fractional offsets TimeOffsetNanos and BiasNanos:
t_RX_s  = t_RX_ns - TimeOffsetNanos - BiasNanos_1;      % [ns], received time (measurement time)
t_TX_s  = ReceivedSvTimeNanos;                          % [ns], transmitted time

% compute pseudorange as difference between received and transmitted time
PR_s  = double(t_RX_s - t_TX_s)*1e-9;  	% [s]

% check for GPS week rollover here
n_rollover = floor(PR_s / 604800);      % ||| or round()?

% correct calculated GPS week
gpsweek = gpsweek + n_rollover;





