function [] = check_clk()
% This function reads a *.clk-file and creates a plot to show missing data.
%
% INPUT:
%	[]
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

[FileName, PathName] = uigetfile({'*.clk*;*clk.mat*'}, 'Select clk file to check', GetFullPath([Path.DATA '/CLOCK']));
path_clk = [PathName FileName];

if ~ischar(FileName) || ~ischar(PathName)
    return
end

if contains(path_clk, '.mat')
    load(path_clk, 'preClk_GPS', 'preClk_GLO', 'preClk_GAL', 'preClk_BDS');
else
    [preClk_GPS, preClk_GLO, preClk_GAL, preClk_BDS] = read_precise_clocks(path_clk, false);
end

% creates plots for each GNSS
sp3_plot(preClk_GPS, 'GPS')
sp3_plot(preClk_GLO, 'GLONASS')
sp3_plot(preClk_GAL, 'Galileo')
sp3_plot(preClk_BDS, 'BeiDou')


function [] = sp3_plot(Clk, gnss_str)
if isempty(Clk); return; end
% get time vector of a satellite with data
T = Clk.t;
sow = T(:,1);     % time in seconds of week

% get clock data
dT = Clk.dT';

% check for missing data
isData = ~isnan(dT) & dT ~= 0;
isData = double(isData);

% manipulate hours of day for multiple values (e.g., zeros), this makes the
% timestamp approximate but makes plot correct
h = mod(sow, 86400)/3600;       % hours of day
int = mode(diff(abs(h)));       % interval of clock data
hh = min(h):int:max(h);
if numel(hh) ~= numel(h)
    hh(end+1) = h(end);
end

% prepare and plot   
figure('Name', 'Precise Clock Check Plot', 'NumberTitle','off');
y = 1:size(dT,1);
try
    pl1 = pcolor(hh, y, isData);
catch
    pl1 = pcolor(h, y, isData);     % interval of clock data changed at some point
end
set(pl1, 'EdgeColor', 'none');

color = flipud([0 1 0; 1 0 0]);
colormap(color);
% colorbar

xlabel('Hour of day')
ylabel('PRN')
title([gnss_str ', red = no clock data'])