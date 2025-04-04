function [proc_epochs, start_sow, ende_sow] = RealTimeEpochs(settings, obs)
% Determine approximate number of epochs to process in real-time (e.g.
% for initializing variables)
%
% INPUT:
%   settings        struct, processing settings from the GUI
%   obs             struct, contains observation-specific data
% OUTPUT:
%	proc_epochs     approximate number of epochs to process [start, end]
%   start_sow       start time of real-time processing [sow]
%   ende_sow        end time of real-time processing [sow]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% calculate gps time of defined real-time processing start
[hh, mm, ss] = getHourMinSec(settings.INPUT.realtime_start_GUI);
start_sow = hhmmss2sow(hh, mm, ss, obs.startdate);

% calculate gps time of defined real-time processing end
[hh, mm, ss] = getHourMinSec(settings.INPUT.realtime_ende_GUI);
ende_sow = hhmmss2sow(hh, mm, ss, obs.startdate);

% calculate and save approximate number of epochs to process
proc_epochs(1) = 1;
proc_epochs(2) = ceil((ende_sow-start_sow) / obs.interval);









