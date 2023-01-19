function dt_clock = corr2brdc_clk(corr, clk_time, Ttr, prn, gnss, IODE_eph, toe)
% Calculates correction to broadcast clocks (from navigation message/file) 
% with data from correction stream.
% 
% INPUT:
%   corr        struct with corrections from broadcast stream
%   clk_time    time of clock corrections
%   Ttr         transmission time [seconds of week]
%   prn         satellite number, at the same time number of column
%   gnss        string for identifying GNSS, 'GPS' / 'GLO' / 'GAL' / 'BDS'
%   IODE_eph 	Issue of Data Ephemeris
%   toe         time of ephemeris [seconds of week]
% OUTPUT:
%   dt_clock	clock correction, [s]
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


i_clk_coeff = [];       % Index in correction stream data
dt_clock = 0;           % no clock-correction

% ---- Find index for GPS or Galileo clock correction with IOD ----
index = find(IODE_eph == corr.IOD_clk(:,prn));  % indices where IODC == IODE
if ~isempty(index)	% IODC == IODE is existing, find correct time
    index1 = find(clk_time(index)<=Ttr);      % find next smaller point in time
    if isempty(index1)
        i_clk_coeff = index(1);              	% if no point in time is smaller, take first
    else
        i_clk_coeff = index(index1(end));     	% else take last smaller point in time
    end
end



% ---- Get and calculate clock correction to broadcast ephemerides ----
if isempty(i_clk_coeff)
    dt_clock = 0;
    fprintf('WARNING: PRN %.2d (%s) has no SSR corrections at second %8.2f               \n', prn, gnss,  Ttr)
else
    time_corr = clk_time(i_clk_coeff); 	% get time of SSR correction from stream
    dt = Ttr - time_corr; 	% time difference between transmission time and clock correction from stream
    % threshold for max. distance to point of time of ephemeris:
    %    - for kinematic measurements: 120sec
    %    - for highly-precise positioning: 5sec or smaller
    if abs(dt) > DEF.THRESHOLD_corr2brdc_clk_dt
        dt_clock = 0;
        fprintf('WARNING: PRN %.2d (%s) has no closely in time SSR corrections at second %8.2f           \n', prn, gnss, Ttr)
    else
        a0 = corr.c0(i_clk_coeff,prn);
        a1 = corr.c1(i_clk_coeff,prn);
        a2 = corr.c2(i_clk_coeff,prn);
        dt_clock = a0 + a1*dt + a2*dt^2; % calculate 2nd degree polynomial clock correction, [m]
    end
end

dt_clock = dt_clock/Const.C;        % convert from [m] to [s]