function [] = vis_res_sats(storeData, sys, settings, elev, SNR1)
% Plots residuals for each satellite over epochs together with elevation
% and carrier-to-noise-density on frequency 1.
%
% INPUT:
%   storeData       struct, collected data from all processed epochs
%   sys             1-digit-char which represents GNSS (G=GPS, R=Glonass, E=Galileo)
%   settings        struct, processing settings from GUI
%   el              elevation [°]
%   CN0_1           carrier-to-noise density on frequency 1 [dBHz]
% OUTPUT:
%   []
%
% Revision:
%   2023/11/09, MFWG: adding QZSS
%   2024/12/05, MFWG: create plots only for satellites with data
%   2025/11/24, MFWG: change from histogram to residuals over epochs
%   2026/10/09, MFWG: add datatip for residual, elevation and CN0 lines
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


proc_freq = settings.INPUT.proc_freqs; 	% number of processed frequencies

plot_phase = contains(settings.PROC.method, '+ Phase') && ...
    ~strcmp(settings.IONO.model, 'GRAPHIC');    % plot phase residuals?
fixed_on = settings.PLOT.fixed;                 % plot fixed residuals?


% create loop index
switch sys
    case 'G'            % GPS
        loop = 1:99;
        col = DEF.COLOR_G;
    case 'R'            % GLONASS
        loop = 101:199;
        col = DEF.COLOR_R;
    case 'E'            % Galileo
        loop = 201:299;
        col = DEF.COLOR_E;
    case 'C'            % BeiDou
        loop = 301:399;
        col = DEF.COLOR_C;
    case 'J'            % QZSS
        loop = 401:410;
        col = DEF.COLOR_J;
end

% get elevation and CN0
elev = elev(:, loop);
SNR1 = SNR1(:, loop);
gpstime = storeData.gpstime(:);     % time of epochs in seconds of week (for datatip)


% loop over frequencies to plot
for j = 1:proc_freq
    % get code residuals of current frequency (e.g. storeData.residuals_code_1)
    if ~fixed_on        % float residuals
        sol_str = 'Float';
        field = sprintf('residuals_code_%1.0f', j);
    else                % fixed residuals
        sol_str = 'Fixed';
        field = sprintf('residuals_code_fix_%1.0f', j);
    end
    code_res_j = full(storeData.(field));
    code_res_j = code_res_j(:, loop);
    code_res_j(code_res_j==0 ) = NaN;

    
    % CODE
    code_str = [sol_str ' Code ' sprintf('%d',j) ' Residuals'];
    % plot all satellites
    fig_title = [sol_str ' Code ' sprintf('%d',j) ' Residuals, ' char2gnss(sys)];
    plot_sat_res(code_res_j, elev, SNR1, mod(loop,100), sys, code_str, col*0.8, fig_title, gpstime)
    
    if plot_phase
        % get phase residuals of current frequency (e.g. storeData.residuals_phase_1)
        if ~fixed_on        % float residuals
            field = sprintf('residuals_phase_%1.0f', j);
        else                % fixed residuals
            field = sprintf('residuals_phase_fix_%1.0f', j);
        end
        phase_res_j = full(storeData.(field));
        phase_res_j = phase_res_j(:, loop);
        phase_res_j(phase_res_j==0 ) = NaN;
        % PHASE

        phase_str = [sol_str ' Phase ' num2str(j) ' Residuals'];
        % plot all satellites
        fig_title = [sol_str ' Phase ' sprintf('%d',j) ' Residuals, ' char2gnss(sys)];
        plot_sat_res(phase_res_j, elev, SNR1,  mod(loop,100), sys, phase_str, col/2, fig_title, gpstime)
    end
end



% Function to plot and style
function [] = plot_sat_res(RESID, ELEV, SNR1, loop, sys, codephase_fr, col, fig_title, gpstime)

% create figure
fig = figure('Name', fig_title, 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
fig.UserData = codephase_fr;        % used as title in datatip
dcm = datacursormode(fig);
dcm.UpdateFcn = @datatip_res_sats;
ii = 1;         % counter of subplot number


for i = loop
    if any(~isnan(RESID(:,i)))

        % check if new figure is necessary
        if ii == 17
            set(findall(gcf,'type','text'),'fontSize',8)
            % 16 satellites have been plotted in this window -> full
            % -> create new figure
            fig = figure('Name', fig_title, 'units','normalized', 'outerposition',[0 0 1 1], 'NumberTitle','off');
            ii = 1; % set counter of subplot number to 1
            fig.UserData = codephase_fr;
            dcm = datacursormode(fig);
            dcm.UpdateFcn = @datatip_res_sats;
        end

        % get residuals, elevation and CN0 for current satellite
        res = RESID(:,i); 
        if all(isnan(res)); continue; end
        el = ELEV(:,i); 
        snr = SNR1(:,i); 

        % plot counter
        subplot(4, 4, ii)
        ii = ii + 1;  	% increase counter of plot number

        % plot elevation and CN0
        yyaxis right
        hold on
        h_el  = plot(el, '-',   'Color', [1 .6 0]);
        h_snr = plot(snr, '.', 'Color', [1 .4 0], 'MarkerSize', 5);
        ylabel('[°] and [dBHz]')

        % plot residuals
        yyaxis left
        h_res = plot(res, '.', 'Color', col);
        ylabel('[m]')

        % store data for the datatip
        h_res.UserData = 'res';
        h_el.UserData  = 'elev';
        h_snr.UserData = 'cn0';
        ax = gca;
        ax.UserData = struct('prn', sprintf('%s%02d', sys, i), ...
            'res', res, 'elev', el, 'cn0', snr, 'gpstime', gpstime);

        % calculate standard-deviation and bias
        std_ = std(res, 'omitnan');         % standard deviation of current satellite
        res(isnan(res)) = [];               % remove NaNs
        n = numel(res);                     % number of residuals (which are not NaN)
        bia_ = sum(res)/n;                  % bias of the residuals of current satellite

        % style plot
        title({[codephase_fr ': ' sys sprintf('%02d',i)]}, 'fontsize', 11);
        axis on
        xlabel(['Epochs, ' sprintf('%d res: std = %2.3f, bias = %2.3f [m]\n', n, std_, bia_)])       

    end
end
set(findall(gcf,'type','text'),'fontSize',8)        % change size of text



function txt = datatip_res_sats(~, event_obj)
% Datatip for the residual, elevation and CN0 lines of a satellite subplot.

ax = event_obj.Target.Parent;
d = ax.UserData;
kind = event_obj.Target.UserData;
ep = event_obj.DataIndex;               % epoch = index of clicked data point
fig_str = ancestor(ax, 'figure').UserData;

% time of day of the epoch
str_time = 'n/a';
if ep <= numel(d.gpstime)
    [~, hour, min, sec] = sow2dhms(d.gpstime(ep));
    str_time = sprintf('%02.0f:%02.0f:%02.0f', hour, min, sec);
end

% clicked value (first) and the other two values of this epoch as context
switch kind
    case 'res'
        head = 'Residual';
        main = sprintf('Residual: %.4f m', d.res(ep));
    case 'elev'
        head = 'Elevation';
        main = sprintf('Elevation: %.2f deg', d.elev(ep));
    case 'cn0'
        head = 'CN0';
        main = sprintf('CN0: %.1f dBHz', d.cn0(ep));
end
txt = {sprintf('%s, %s', d.prn, head), ...
    sprintf('Epoch: %d', ep), ...
    sprintf('Time: %s', str_time), ...
    main};
% context lines (zero means no data for elevation and CN0)
if ~strcmp(kind, 'res')
    txt{end+1} = ctx_str('Residual', d.res, ep, '%.4f m', false);
end
if ~strcmp(kind, 'elev')
    txt{end+1} = ctx_str('Elevation', d.elev, ep, '%.2f °', true);
end
if ~strcmp(kind, 'cn0')
    txt{end+1} = ctx_str('CN0', d.cn0, ep, '%.1f dBHz', true);
end


function s = ctx_str(name, v, ep, fmt, zero_is_nodata)
% string of one context value, 'n/a' if there is no data in this epoch
if ep > numel(v) || isnan(v(ep)) || (zero_is_nodata && v(ep) == 0)
    s = sprintf('%s: n/a', name);
else
    s = sprintf(['%s: ' fmt], name, v(ep));
end
