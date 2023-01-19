function [] = plotCorrection2BRDC(corr, obs, filename, sys)
% Plots the Code Bias, Phase Bias, Clock and Orbit Corrections from 
% a correction stream.
% INPUT:
%   corr        struct, read-in corrections from stream for current GNSS
%   filename	string, filename of correction-stream
%   sys         1-digit-char representing GNSS (G=GPS, R=Glonass, E=Galileo, C=BeiDou)
% 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| at the moment the whole correction data is plotted maybe implement
% some slider or only partly plotting?

% ||| de-hardcode at some point
plot_code_biases = 1;       
plot_phase_biases = 1;
plot_orb_corr = 1;
plot_clk_corr = 1;
plot_time_diff = 0;
% ||| velocity and clock terms higher degree are completely disabled

if sys == 'G'
    used_biases = obs.used_biases_GPS;
    prns = 1:32;
    l_style = 'r.';
elseif sys == 'E'
    used_biases = obs.used_biases_GAL;
    prns = 201:232;
    l_style = 'b.';
elseif sys == 'C'
    used_biases = obs.used_biases_BDS;
    prns = 201:232;
    l_style = 'k.';
end

% Preparations
filename = filename(max(strfind(filename, '\'))+1:end-4);
time_clk = mod(corr.t_clk,86400);
time_orb = mod(corr.t_orb,86400);
time_dcb = mod(corr.t_dcb,86400);
time_upd = mod(corr.t_upd,86400);

% Code Bias Correction Plots
if plot_code_biases
    if ~isempty(used_biases{1,2})
        % C1 Code Bias Corrections
        plotit(time_dcb, obs.C1_corr(:,prns), filename, 'Used C1 Biases', ...
            'Code Bias [m]', sys, ['Bias: ', used_biases{1,2}], l_style)
    end
    if ~isempty(used_biases{2,2})
        % C2 Code Bias Corrections
        plotit(time_dcb, obs.C2_corr(:,prns), filename, 'Used C2 Biases', ...
            'Code Bias [m]', sys, ['Bias: ', used_biases{2,2}], l_style)
    end
    if ~isempty(used_biases{3,2})
        % C3 Code Bias Corrections
        plotit(time_dcb, obs.C3_corr(:,prns), filename, 'Used C3 Biases', ...
            'Code Bias [m]', sys, ['Bias: ', used_biases{3,2}], l_style)
    end
end

% Phase Bias Correction Plots
if plot_phase_biases
    if ~isempty(used_biases{1,1})
        % L1 Phase Bias Corrections
        plotit(time_upd, obs.L1_corr(:,prns), filename, 'Used L1 Biases', ...
            'Phase Bias [m]', sys, ['Bias: ', used_biases{1,1}], l_style)
    end
    if ~isempty(used_biases{2,1})
        % L2 Phase Bias Corrections
        plotit(time_upd, obs.L2_corr(:,prns), filename, 'Used L2 Biases', ...
            'Phase Bias [m]', sys, ['Bias: ', used_biases{2,1}], l_style)
    end
    if ~isempty(used_biases{3,1})
        % L3 Phase Bias Corrections
        plotit(time_upd, obs.L3_corr(:,prns), filename, 'Used L3 Biases', ...
            'Phase Bias [m]', sys, ['Bias: ', used_biases{3,1}], l_style)
    end
end

% Clock Plots
if plot_clk_corr
    % Clock c_0 component correction
    plotit(time_clk, corr.c0, filename, 'Clock c_0', '[m]', sys, 'Clock c0', l_style)
%     % Clock c_1 component correction
%     plotit(time_clk, corr.c1, filename, 'Clock c_1', '[m/s]', sys, 'Clock c1', l_style)
%     % Clock c_2 component correction
%     plotit(time_clk, corr.c2, filename, 'Clock c_2', '[m/s^2]', sys, 'Clock c2', l_style)
end

% Orbit Plots
if plot_orb_corr
    % along-track component correction
    plotit(time_orb, corr.along, filename, 'Along-Track', '[m]', sys, 'Along-Track', l_style)
    % across-track component correction
    plotit(time_orb, corr.outof, filename, 'Across-Track', '[m]', sys, 'Across-Track', l_style)
    % radial component correction
    plotit(time_orb, corr.radial, filename, 'Radial Component', '[m]', sys, 'Radial Component', l_style)
%     % along-track velocity correction
%     plotit(time_orb, corr.v_along, filename, 'Along-Track Velocity', '[m/s]', sys, 'Along-Track Velocity', l_style)
%     % across-track velocity correction
%     plotit(time_orb, corr.v_outof, filename, 'Across-Track Velocity', '[m/s]', sys, 'Across-Track Velocity', l_style)
%     % radial velocity correction
%     plotit(time_orb, corr.v_radial, filename, 'Radial Component Velocity', '[m/s]', sys, 'Radial Component Velocity', l_style)
end

% Missing corrections plot
if plot_time_diff
    figure('Name', sys)
    subplot(4,1,1)
    plot_correction_interval(time_orb, 'Orbit corrections')
    subplot(4,1,2)
    plot_correction_interval(time_clk, 'Clock corrections')
    subplot(4,1,3)
    plot_correction_interval(time_dcb, 'Code Bias corrections')
    subplot(4,1,4)
    plot_correction_interval(time_upd, 'Phase Bias corrections')
end

end % end of: plotCorrection2BRDC.m



% Plot-Function
function [] = plotit(time, y, filename, y_name, unit_y, gnss, title_str, l_style)
vec = 0:14400:86400;       % 4-h-legend
ticks = sow2hhmm(vec);

% plot the satellites G01-G16
fig1 = figure('Name', [y_name, ' ', gnss, '01-16 from ', filename], 'units','normalized', 'outerposition',[0 0 1 1]);
% add customized datatip
dcm = datacursormode(fig1);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip)
% loop for plotting over satellites 1:16
for i = 1:16
    try
        if ~all(y(:,i)==0)
            subplot(4,4,i)
            plot(time, y(:,i), l_style)
            grid on
            set(gca, 'XTick',vec, 'XTickLabel',ticks)
            set(gca, 'fontSize',8)
            title([title_str, ' for ', gnss, sprintf('%02d',i)])
            xlabel('Time [h]')
            ylabel(unit_y)
            xlim([min(time), max(time)])
            ylim('auto')
        end
    catch
        continue        
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

% plot the satellites G17-G32
fig2 = figure('Name', [y_name, ' ', gnss, '17-32 from ', filename], 'units','normalized', 'outerposition',[0 0 1 1]);
% add customized datatip
dcm = datacursormode(fig2);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip)
% loop for plotting over satellites 17:32
for i = 17:32
    try
        if ~all(y(:,i)==0)
            subplot(4,4,i-16)
            plot(time, y(:,i), l_style)
            grid on
            set(gca, 'XTick',vec, 'XTickLabel',ticks)
            set(gca, 'fontSize',8)
            title([title_str, ' for ', gnss, sprintf('%02d',i)])
            xlabel('Time [h]')
            ylabel(unit_y)
            xlim([min(time), max(time)])
            ylim('auto')
        end
    catch
        continue
    end
end
set(findall(gcf,'type','text'),'fontSize',8)

end             % end of plotit


function [] = plot_correction_interval(time_vector, title_string)
% plot time-difference of orbit corrections to see if there is data missing
start_ep = 5;       % skip first epochs because they could be from the day before
time_x = time_vector(start_ep:(end-1));
y = diff(time_vector(start_ep:end));
plot(time_x, y) 
title(title_string)
vec = 0:7200:86400;       % 4-h-legend
ticks = sow2hhmm(vec);
set(gca, 'XTick',vec, 'XTickLabel',ticks)
set(gca, 'fontSize',8)
xlabel('Time')
ylabel('Time Diff. [s]')
xlim([min(time_x), max(time_x)])
ylim('auto')
end
