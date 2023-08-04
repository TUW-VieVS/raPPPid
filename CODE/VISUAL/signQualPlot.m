function signQualPlot(satellites, label_xaxis, hours, isGPS, isGLO, isGAL, isBDS, settings)
% creates three different plots of the Signal Quality:
% -) Code-minus-Phase-Plot: for each frequency the difference between code
% and phase measurements in meters for all observed satellites
% -) Carrier-to-Noise density Plot: for each frequency the values of C/N0 from
% the RINEX-File for all observed satellites
% -) C/N0-over-Elevation-Plot: SNR over the elevation for each frequency and
% all observed satellites
% 
% INPUT:
%   satellites      struct, containing satellite-specific data from processing        
%   label_xaxis     label for x-axis of plots
%   hours           time from beginning of processing [h]
% 	isGPS, isGLO, isGAL, isBDS
%                   true if GNSS was processed and should be plotted
%   settings        struct, proceesing settings from GUI     
% OUTPUT
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get some variables
n = settings.INPUT.proc_freqs;          % number of processed frequencies
cutoff = settings.PROC.elev_mask;       % cutoff angle [°]
try
    snr_thresh = settings.PROC.SNR_mask;
    if numel(snr_thresh) == 1
        snr_thresh = [snr_thresh snr_thresh snr_thresh];
    end
catch
    snr_thresh = [NaN NaN NaN];
end
    
% get observed satellites prns
obs_prns = [];
if isGPS
    obs_prns = [obs_prns, 1:DEF.SATS_GPS];
end
if isGLO
    obs_prns = [obs_prns, 100+(1:DEF.SATS_GLO)];
end
if isGAL
    obs_prns = [obs_prns, 200+(1:DEF.SATS_GAL)];
end
if isBDS
    obs_prns = [obs_prns, 300+(1:DEF.SATS_BDS)];
end

% colors
hsv_color = hsv(33);               	% plot-colors
hsv_color = flipud(hsv_color);      % to have darker colors in background (high prn number has dark color)


%% Code minus Phase Plot
if contains(settings.PROC.method, 'Phase')
    % Preparations
    sats = 399;
    fig_CminusL = figure('name','Signal Quality: code minus phase', 'NumberTitle','off');
    % add customized datatip
    dcm = datacursormode(fig_CminusL);
    datacursormode on
    set(dcm, 'updatefcn', @vis_customdatatip_h)
    % Loop over Frequencies
    for j = 1:n
        subplot(n, 1, j)
        hold on
        xlabel(label_xaxis)
        ylabel('[m]')
        grid on
        prns = [];                      % to save the satellite prns with data
        % get code minus phase data for current frequency (e.g. satellites.CL_1)
        field = sprintf('CL_%1.0f', j);
        CL_j = full(satellites.(field));
        CL_j(CL_j==0 ) = NaN;
        % Loop over Satellites
        loop = intersect(1:sats, obs_prns);
        for s = loop
            if any(~isnan(CL_j(:,s)))
                % get data
                satdata = CL_j(:,s);
                
                % look for periods satellite is visible
                mask = ~isnan(satdata') & (satdata' ~= 0);  % row vector
                starts = strfind([false, mask], [0 1]);     % data begins
                stops = strfind([mask, false], [1 0]);      % data ends
                n_vis = numel(starts);
                for ii = 1:n_vis     	% loop over data series of current satellite
                    s1 = starts(ii);
                    s2 = stops(ii);
                    if s1 == s2         % ||| check condition!
                        satdata(s1:s2) = NaN;
                        continue        % skip if only one epoch observed
                    end
                    
                    % remove a polynom 3rd degree
                    coeff = polyfit(hours(s1:s2), satdata(s1:s2), 3);       % coefficients of polynom
                    satdata(s1:s2) = ...         % remove polynomial trend
                        satdata(s1:s2) - polyval(coeff, hours(s1:s2));             
                end
                % Plot and save satellite prn
                plot(hours, satdata, 'color', hsv_color(mod(s,33)+1,:), 'LineWidth', 1, 'LineStyle', '-')
                prns(end+1) = s;                
            end
        end
        prns = prns';       % create letters for legend:
        lettr = char( (prns<100)*71 + (prns<200&prns>100)*82 + (prns<300&prns>200)*69 + (prns<400&prns>300)*67 );
        content = strcat(lettr, num2str(mod(prns,100), '%02.0f'));                     % letters and prn-number
        hLeg = legend(cellstr(content),'location','EastOutside');       % create legend
        if j == 2
            set(hLeg,'visible','off')
        end
        title(sprintf('C%d - L%d - 3rd degree polynomial', j, j))           % title of plot
        xlim([0 hours(end)])
    end
end


%% Signal to Noise Ratio (C/N0) Plot
sats = 399;
fig_SNR = figure('Name', 'Signal Quality: SNR', 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig_SNR);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_h)

% Loop over frequencies
for j = 1:n
    subplot(n, 1, j)
    hold on
    xlabel(label_xaxis)
    ylabel('[dB.Hz]')
    grid on
    prns = [];          % to save the satellite prns with data
    % get C/N0 data for current frequency (e.g. satellites.SNR_1)
    field = sprintf('SNR_%1.0f', j);
    SNR_j = full(satellites.(field));
    SNR_j(SNR_j==0 ) = NaN;
    % Loop over Satellites
    loop = intersect(1:sats, obs_prns);
    for s = loop
        if any(~isnan(SNR_j(:,s)))
            plot(hours, SNR_j(:,s), 'color', hsv_color(mod(s,33)+1,:), 'LineWidth', 1, 'LineStyle', '-')
            prns(end+1) = s;            
        end
    end
    % find minimal and maximal SNR value for axes limits
    ymax = max(SNR_j(:));   if isnan(ymax);   ymax = Inf;   end
    axis([0 max(hours) 0 ymax+1])     % axes-limits
    prns = prns';       % create letters for legend:
    lettr = char( (prns<100)*71 + (prns<200&prns>100)*82 + (prns<300&prns>200)*69 + (prns<400&prns>300)*67 );
    content = strcat(lettr, num2str(mod(prns,100), '%02.0f'));                     % letters and prn-number
    hLeg = legend(cellstr(content),'location','EastOutside');       % create legend
    if j == 2
        set(hLeg,'visible','off')
    end
    title(sprintf('Carrier-to-Noise Density on Frequency %d', j))    	% title of plot
    hline(snr_thresh(j), 'k--')        % add cutoff angle as vertical line
end


%% C/N0-over-Elevation-Plot
sats = 399;
Elev = full(satellites.elev);	% [epochs x sats x frequencies], elevation of satellites
if ~any(Elev(:)~=0); return; end
fig_SNR_elev = figure('Name', 'SNR over Elevation', 'NumberTitle','off');
% add customized datatip
dcm = datacursormode(fig_SNR_elev);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_SNR_elev)
% Loop over frequencies
for j = 1:n
    subplot(n, 1, j)
    hold on
    xlabel('Elevation [°]')
    ylabel('C/N0 [dB-Hz]')
    grid on
    prns = [];          % to save the satellite prns with data
    % get C/N0 data for current frequency (e.g. satellites.SNR_1)
    field = sprintf('SNR_%1.0f', j);
    SNR_j = full(satellites.(field));
    SNR_j(SNR_j==0 ) = NaN;
    % Loop over Satellites
    loop = intersect(1:sats, obs_prns);
    for s = loop
        if any(~isnan(SNR_j(:,s)))
            plot(Elev(:,s), SNR_j(:,s), 'color', hsv_color(mod(s,33)+1,:), 'LineWidth', 1, 'LineStyle', '-')
            prns(end+1) = s;            
        end
    end
    xlim([0 90]) 
    limsy = get(gca,'YLim');        % set only lower limit of y-axis
    set(gca,'Ylim',[0 limsy(2)]);
    vline(cutoff, 'k--')            % add cutoff angle as vertical line
    hline(snr_thresh(j), 'k--')        % add cutoff angle as vertical line
    prns = prns';       % create letters for legend:
    lettr = char( (prns<100)*71 + (prns<200&prns>100)*82 + (prns<300&prns>200)*69 + (prns<400&prns>300)*67 );
    content = strcat(lettr, num2str(mod(prns,100), '%02.0f'));                     % letters and prn-number
    hLeg = legend(cellstr(content),'location','EastOutside');       % create legend
    if j == 2
        set(hLeg,'visible','off')
    end
    title(sprintf('C/N0 over Elevation on Frequency %d', j))         % title of plot
end



end



function output_txt = vis_customdatatip_SNR_elev(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
elev = pos(1);
value = pos(2);

% create cell with strings as output (which will be shown when clicking)
output_txt{1} = event_obj.Target.DisplayName;               % name of clicked line e.g. satellite
output_txt{2} = ['Elevation: ',  sprintf('%.3f', elev)];	% time of day
output_txt{3} = ['C/N0: ', sprintf('%.3f', value)];          % value

end