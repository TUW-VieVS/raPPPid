function [] = MPLC_Plots(storeData, satellites, cutoff, CN0_thresh, isGPS, isGLO, isGAL, isBDS, isQZSS)
% This function plots the Multipath linear combination (MP LC) over time,
% over elevation, and over the carrier-to-noise density (C/N0)
% 
% INPUT:
%   storeData       struct, data from processing
%   satellites      struct, satellite-specific data from processing        
%   cutoff          cutoff angle [°], processing settings from GUI
%   CN0_thresh      threshold for excluding observations with low C/N0
%   isGPS, isGLO, isGAL, isBDS, isQZSS
%                   boolean, plot GNSS?
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************


% ||| jumps during a satellite arc are not considered and jeopordize plot


% check if plot can be created
if ~isfield(storeData, 'mp1') || ~isfield(storeData, 'mp2')
    fprintf('MP LC can not be plotted (storeData.mp1/.mp2 are missing).   \n');
    return
end

% get Multipath linear combination, built in create_LC_observations.m
mp1 = full(storeData.mp1);          % 1st frequency    
mp2 = full(storeData.mp2);          % 2nd frequency

% get elevation and carrier-to-noise density
el = zero2nan(satellites.elev);       	% elevation [°]
CN0_1 = zero2nan(satellites.SNR_1);  	% C/N0, 1st frequency, [dB.Hz]
CN0_2 = zero2nan(satellites.SNR_2);  	% C/N0, 2nd frequency, [dB.Hz]

% get matrix indicating observed satellites in each epoch
observed = satellites.obs;

% remove GNSS which are not plotted
if ~isQZSS; observed(:,400:410) = false; end
if ~isBDS;  observed(:,300:399) = false; end
if ~isGAL;  observed(:,200:299) = false; end
if ~isGLO;  observed(:,100:199) = false; end
if ~isGPS;  observed(:,  1: 99) = false; end

% prepare legend
obs_bool = logical(full(observed));  	% true if satellite observed in the corresponding epoch
idx = 1:size(obs_bool,2);
obs_prns = idx(sum(obs_bool(:,idx),1) > 0);	% prns of observed satellites
str_prns = sprintfc('%03.0f', obs_prns);

% get data to plot
mp1 = mp1(:,obs_prns);
mp2 = mp2(:,obs_prns);
el  = el(:,obs_prns);
CN0_1 = CN0_1(:,obs_prns);
CN0_2 = CN0_2(:,obs_prns);

% remove constant part of MP LC for each satellite arc
mp1_ = RemoveMeanPerSatelliteArc(mp1);
mp2_ = RemoveMeanPerSatelliteArc(mp2);

% replace zeros with NaN
mp1_(mp1_ == 0) = NaN;
mp2_(mp2_ == 0) = NaN;

% plot over time
fig_mp_time = figure('Name','MP LC over time', 'NumberTitle','off');
subplot(2, 1, 1)
plot(mp1_, '.')
style_plot(fig_mp_time, 'MP LC_1 over Time', str_prns, 'Epochs', [])
subplot(2, 1, 2)
plot(mp2_, '.')
style_plot(fig_mp_time, 'MP LC_2 over Time', str_prns, 'Epochs', [])

% plot over elevation
fig_mp_elev = figure('Name','MP LC over elevation', 'NumberTitle','off');
subplot(2, 1, 1)
plot(el, abs(mp1_), '.')
style_plot(fig_mp_elev, 'MP LC_1 over Elevation', str_prns, 'Elevation [°]', cutoff)
subplot(2, 1, 2)
plot(el, abs(mp2_), '.')
style_plot(fig_mp_elev, 'MP LC_2 over Elevation', str_prns, 'Elevation [°]', cutoff)


% plot over C/N0
fig_mp_cn0 = figure('Name','MP LC over C/N0', 'NumberTitle','off');
subplot(2, 1, 1)
plot(CN0_1, abs(mp1_), '.')
style_plot(fig_mp_cn0, 'MP LC_1 over C/N0', str_prns, 'C/N0 [dB.Hz]', CN0_thresh)
subplot(2, 1, 2)
plot(CN0_2, abs(mp2_), '.')
style_plot(fig_mp_cn0, 'MP LC_2 over C/N0', str_prns, 'C/N0 [dB.Hz]', CN0_thresh)

function [] = style_plot(fig, str_title, str_prns, xlabelstring, thresh)
% This function styles the plots

% plot threshold (e.g., cutoff or C/N0)
if ~isempty(thresh)
    hold on
    vline(thresh, 'k--')
end

% create title
title(str_title)

% create legend
legend on
hleg = legend(str_prns);
title(hleg, 'PRN')          % title for legend

% style axes
ylabel('MP LC [m]')
xlabel(xlabelstring)

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_mp_lc)

function output_txt = vis_customdatatip_mp_lc(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

% get position of click (x-value = elevation [°], y-value = residual [m])
pos = get(event_obj,'Position');
epoch = pos(1);
val = pos(2);
% create cell with strings as output (which will be shown when clicking)
sat = event_obj.Target.DisplayName;
output_txt{1} = ['PRN: ' sat ];           % name of clicked line e.g. satellite
output_txt{2} = [event_obj.Target.Parent.XLabel.String ': '  sprintf('%.0f', epoch)];
output_txt{3} = ['MP LC: '  sprintf('%.3f', val) 'm'];    % epoch


