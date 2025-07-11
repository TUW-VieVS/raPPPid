function [] = check_sp3()
% This function reads a *.sp3-file and creates a plot to show missing data.
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

[FileName, PathName] = uigetfile({'*.sp3*;*.eph*'}, 'Select sp3 to check', GetFullPath([Path.DATA '/ORBIT']));
path_sp3 = [PathName FileName];

if ~ischar(FileName) || ~ischar(PathName)
    return
end

[Eph_G, Eph_R, Eph_E, Eph_C] = read_precise_eph(path_sp3, false);

% creates plots for each GNSS
sp3_plot(Eph_G, 'GPS',      'G')
sp3_plot(Eph_R, 'GLONASS',  'R')
sp3_plot(Eph_E, 'Galileo',  'E')
sp3_plot(Eph_C, 'BeiDou',   'C')


function [] = sp3_plot(Eph, gnss_str, gnss_char)
if isempty(Eph); return; end
% get time vector of a satellite with data
T = Eph.t;
excl = all(T==0,1) | all(isnan(T),1);       % columns without data
T(:,excl) = [];
if isempty(T); return; end
sow = T(:,1);     % time in seconds of week

% get satellite coordinates
X = Eph.X'; Y = Eph.X'; Z = Eph.X';

% check for missing data
isData = (X~=0) & ~isnan(X) & (Y~=0) & ~isnan(Y) & (Z~=0) & ~isnan(Z);
isData = double(isData);

% manipulate hours of day for multiple values (e.g. zeros), this makes the
% timestamp approximate but makes plot correct
h = mod(sow, 86400)/3600;     % hours of day
int = mode(diff(abs(h)));
hh = min(h):int:max(h);
if numel(hh) ~= numel(h)
    hh(end+1) = h(end);
end

% prepare and plot   
figure('Name', 'Precise Orbits Check Plot', 'NumberTitle','off');
y = 1:size(X,1);
pl1 = pcolor(hh, y, isData);
set(pl1, 'EdgeColor', 'none');

color = flipud([0 1 0; 1 0 0]);
colormap(color);
% colorbar

xlabel('Hour of day')
ylabel('PRN')
title([gnss_str ', red = no orbit data'])

% print some information
bool = any(isData,2);   % satellites with data at some point
n = sum(bool);          % # satellites with orbit data at some point
prns = 1:numel(bool); prns = prns(bool);    % prns with data
fprintf('%d %s %s\n', n, gnss_str, 'satellites');
fprintf('%g ', prns);
fprintf('\n');

