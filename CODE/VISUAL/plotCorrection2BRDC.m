function [] = plotCorrection2BRDC(corr, obs, streamfile, sys, gpstime, sat_obs)
% Plots the Code Bias, Phase Bias, Clock and Orbit Corrections from
% a correction stream.
% INPUT:
%   corr        struct, read-in corrections from stream for current GNSS
%   streamfile	string, filename of correction-stream
%   sys         1-digit-char representing GNSS (G=GPS, R=Glonass, E=Galileo, C=BeiDou)
%   gpstime     vector, time of processed epochs (sow)
%   sat_obs     matrix, number of epochs satellite is tracked
%
% Revision:
%   2025/02/04, MFWG: include IOD into plots
%   2025/01/20, MFWG: plot only processed time period, prepare GLONASS
%   2024/12/06, MFWG: plotting only satellites with data
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| velocity and clock terms higher degree are completely disabled


%% Preparations
used_biases = {{} {}; {} {}; {} {}};
switch sys
    case 'G'
        if isfield(obs, 'used_biases_GPS'); used_biases = obs.used_biases_GPS; end
        prns = 1:32;            sats = prns;
        col = DEF.COLOR_G;
    case 'R'
        if isfield(obs, 'used_biases_GLO'); used_biases = obs.used_biases_GLO; end
        prns = 1:DEF.SATS_GLO;  sats = prns + 100;
        col = DEF.COLOR_R;
    case 'E'
        if isfield(obs, 'used_biases_GAL'); used_biases = obs.used_biases_GAL; end
        prns = 1:DEF.SATS_GAL;  sats = prns + 200;
        col = DEF.COLOR_E;
    case 'C'
        if isfield(obs, 'used_biases_BDS'); used_biases = obs.used_biases_BDS; end
        prns = 1:DEF.SATS_BDS;  sats = prns + 300;
        col = DEF.COLOR_C;
end

% extract filename
[~, file, ext] = fileparts(streamfile);
filename = [file, ext];

% time stamps
t_clk  = corr.t_clk;          % clock corrections
t_orb  = corr.t_orb;          % orbit corrections
t_cbia = corr.t_code;         % code biases
t_pbia = corr.t_phase;        % phase biases

% cut out processed period
t1 = gpstime(1);        % start of processing (sow)
t2 = gpstime(end);      % end of processing
bool_clk  = (t1 <= t_clk)  & (t_clk  <= t2);
bool_orb  = (t1 <= t_orb)  & (t_orb  <= t2);
bool_cbia = (t1 <= t_cbia) & (t_cbia <= t2);
bool_pbia = (t1 <= t_pbia) & (t_pbia <= t2);

bool = logical(full(sat_obs(:,sats)));
observ = any(bool);


%% Plotting
% Code Bias Correction Plots
if ~isempty(used_biases{1,2})
    % C1 Code Bias Corrections
    plotit(t_cbia(bool_cbia), obs.C1_corr(bool_cbia,prns), observ, filename, ...
        'Code Bias [m]', sys, ['Bias: ', used_biases{1,2}], '-', col, [])
end
if ~isempty(used_biases{2,2})
    % C2 Code Bias Corrections
    plotit(t_cbia(bool_cbia), obs.C2_corr(bool_cbia,prns), observ, filename, ...
        'Code Bias [m]', sys, ['Bias: ', used_biases{2,2}], '-', col, [])
end
if ~isempty(used_biases{3,2})
    % C3 Code Bias Corrections
    plotit(t_cbia(bool_cbia), obs.C3_corr(bool_cbia,prns), observ, filename, ...
        'Code Bias [m]', sys, ['Bias: ', used_biases{3,2}], '-', col, [])
end

% Phase Bias Correction Plots
if ~isempty(used_biases{1,1})
    % L1 Phase Bias Corrections
    plotit(t_pbia(bool_pbia), obs.L1_corr(bool_pbia,prns), observ, filename, ...
        'Phase Bias [m]', sys, ['Bias: ', used_biases{1,1}], '-', col, [])
end
if ~isempty(used_biases{2,1})
    % L2 Phase Bias Corrections
    plotit(t_pbia(bool_pbia), obs.L2_corr(bool_pbia,prns), observ, filename, ...
        'Phase Bias [m]', sys, ['Bias: ', used_biases{2,1}], '-', col, [])
end
if ~isempty(used_biases{3,1})
    % L3 Phase Bias Corrections
    plotit(t_pbia(bool_pbia), obs.L3_corr(bool_pbia,prns), observ, filename, ...
        'Phase Bias [m]', sys, ['Bias: ', used_biases{3,1}], '-', col, [])
end

% Clock Plots
% Clock c_0 component correction
plotit(t_clk(bool_clk), corr.c0(bool_clk,prns), observ, filename, '[m]',     sys, 'Clock c_0', '.', col, corr.IOD_clk(bool_clk,prns))
% Clock c_1 component correction
plotit(t_clk(bool_clk), corr.c1(bool_clk,prns), observ, filename, '[m/s]',   sys, 'Clock c_1', '.', col, corr.IOD_clk(bool_clk,prns))
% Clock c_2 component correction
plotit(t_clk(bool_clk), corr.c2(bool_clk,prns), observ, filename, '[m/s^2]', sys, 'Clock c_2', '.', col, corr.IOD_clk(bool_clk,prns))

% Orbit Plots
% along-track component correction
plotit(t_orb(bool_orb), corr.along(bool_orb,prns),  observ, filename, '[m]', sys, 'Along-Track', '.',     col, corr.IOD_orb(bool_orb,prns))
% across-track component correction
plotit(t_orb(bool_orb), corr.outof(bool_orb,prns),  observ, filename, '[m]', sys, 'Across-Track', '.',    col, corr.IOD_orb(bool_orb,prns))
% radial component correction
plotit(t_orb(bool_orb), corr.radial(bool_orb,prns), observ, filename, '[m]', sys, 'Radial Component', '.', col, corr.IOD_orb(bool_orb,prns))
% along-track velocity correction
plotit(t_orb(bool_orb), corr.v_along(bool_orb,prns),  observ, filename, '[mm/s]', sys, 'Velocity: Along-Track', '.',      col, corr.IOD_orb(bool_orb,prns))
% across-track velocity correction
plotit(t_orb(bool_orb), corr.v_outof(bool_orb,prns),  observ, filename, '[mm/s]', sys, 'Velocity: Across-Track', '.',     col, corr.IOD_orb(bool_orb,prns))
% radial velocity correction
plotit(t_orb(bool_orb), corr.v_radial(bool_orb,prns), observ, filename, '[mm/s]', sys, 'Velocity: Radial Component', '.', col, corr.IOD_orb(bool_orb,prns))

% plot time difference of available corrections
figure('Name', char2gnss(sys))
plot_correction_interval(t_orb(bool_orb),   'Orbit corrections',      col, 1)
plot_correction_interval(t_clk(bool_clk),   'Clock corrections',      col, 2)
plot_correction_interval(t_cbia(bool_cbia), 'Code Bias corrections',  col, 3)
plot_correction_interval(t_pbia(bool_pbia), 'Phase Bias corrections', col, 4)






% Plot-Function
function [] = plotit(t, y, observ, filename, unit_y, gnss, str, lstyle, col, IOD)
% t ... vector, timestamps of correction (sow)
% y ... matrix, corrections to plot
% observ ... boolean, true if prn is observed during processing period
% filename ... string, filename of stream
% unit_y ... string, unit of plotted corrections
% gnss ... char, character indicating GNSS
% str ... string, indicating what is plotted (e.g., title)
% lstyle ... string, LineStyle
% col ... 3x1, color for plotting
% IOD ... matrix, issue of data (clock/orbit)

if isempty(t) || isempty(y) || all(y(:) == 0)
    % nothing to plot here (e.g., no corrections/biases during the processed period)
    return
end

% plot all satellites
fig1 = figure('Name', [str ' ' char2gnss('G') ' from ' filename], 'units','normalized', 'outerposition',[0 0 1 1]);
ii = 1;
% add customized datatip
dcm = datacursormode(fig1);
datacursormode on
if ~isempty(IOD)    % IOD is plotted (orbit, clock)
    set(dcm, 'updatefcn', @datatip_stream_IOD)
else                % IOD is not plotted (biases)
    set(dcm, 'updatefcn', @datatip_stream) 
end
% loop for plotting over all satellites with data
for i = 1:99
    try         % plot if satellite has been observed and has correction
        if observ(i) && any(y(:,i)~=0)      
            if ii == 17
                set(findall(gcf,'type','text'),'fontSize',8)
                % 16 satellites have been plotted in this window -> it is full
                % -> create new figure
                fig1 = figure('Name', [str ' ' gnss ' from ' filename], 'units','normalized', 'outerposition',[0 0 1 1]);
                ii = 1; % set counter of subplot number to 1
                dcm = datacursormode(fig1);
                datacursormode on
                set(dcm, 'updatefcn', @datatip_stream_IOD)
            end
            subplot(4,4,ii)
            ii = ii + 1;  	% increase counter of plot number
            if ~isempty(IOD)
                % plot issue of data
                plot(t, IOD(:,i)/100, lstyle, 'Color', col/3)
                hold on
            end
            plot(t, y(:,i), lstyle, 'Color', col)   % plot correction
            grid on
            % change x-ticks to something useful
            vec_xticks = get(gca, 'XTick');
            xtickslabel = sow2hhmmss(vec_xticks);
            set(gca, 'XTick',vec_xticks, 'XTickLabel',xtickslabel)
            % style the rest of the plot
            set(gca, 'fontSize',8)
            title([str ' ' gnss sprintf('%02d',i)])
            xlabel('Time [hh:mm:ss]')
            ylabel(unit_y)
        end
    catch
        continue
    end
end

set(findall(gcf,'type','text'),'fontSize',8)



function [] = plot_correction_interval(t, title_string, col, idx)
% plot time-difference of orbit corrections to see if there is data missing
% t .... vector, timestamps of corrections
% title_string ... string, title of plot
% col ... color to plot
% idx ... number of subplot

if isempty(t)
    return
end

subplot(4, 1, idx)

time_x = t(1:(end-1));
y = diff(t);

% plot
plot(time_x, y, '.', 'Color', col)

% style plot
title(title_string)

% change x-ticks to something useful
vec_xticks = get(gca, 'XTick');
xtickslabel = sow2hhmmss(vec_xticks);
set(gca, 'XTick',vec_xticks, 'XTickLabel',xtickslabel)

% style x and y axis
xlabel('Time')
ylabel('Time Diff. [s]')



function output_txt = datatip_stream_IOD(obj,event_obj)
% Display the position of the data cursor with relevant information
%
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
sod = pos(1);
value = pos(2);

% multiply IOD with 100 to get actual value
if event_obj.Target.SeriesIndex == 1
    value = value * 100;
end

% calculate epoch from sod (attention: missing epochs are not considered!)
epoch = find(event_obj.Target.XData == sod, 1, 'first');

% calculate time of day from sod
[~, hour, min, sec] = sow2dhms(sod);
% create string with time of day
str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];

% create cell with strings as output (which will be shown when clicking)
i = 1;
output_txt{i} = ['Time: ',  str_time];                  % time of day
i = i + 1;
output_txt{i} = ['#: ', sprintf('%.0f', epoch)];        % epoch
i = i + 1;
if event_obj.Target.SeriesIndex == 2
    output_txt{i} = ['Value: ', sprintf('%.3f', value)];	% value
elseif event_obj.Target.SeriesIndex == 1
    output_txt{i} = ['IOD: ', sprintf('%.0f', value)];	% value
end


function output_txt = datatip_stream(obj,event_obj)
% Display the position of the data cursor with relevant information
%
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
sod = pos(1);
value = pos(2);

% calculate epoch from sod (attention: missing epochs are not considered!)
epoch = find(event_obj.Target.XData == sod, 1, 'first');

% calculate time of day from sod
[~, hour, min, sec] = sow2dhms(sod);
% create string with time of day
str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];

% create cell with strings as output (which will be shown when clicking)
i = 1;
output_txt{i} = ['Time: ',  str_time];                  % time of day
i = i + 1;
output_txt{i} = ['#: ', sprintf('%.0f', epoch)];        % epoch
i = i + 1;
output_txt{i} = ['Bias [m]: ', sprintf('%.3f', value)];	% value


