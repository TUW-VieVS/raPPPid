function [] = plotAppliedBiases(storeData, use_GPS, use_GLO, use_GAL, use_BDS)
% Plots the applied Biases of all satellites and epochs
% INPUT:
%   storeData       data from all processed epochs
%   use_GPS         boolean
%   use_GLO         boolean
%   use_GAL         boolean
%   use_BDS         boolean
% OUTPUT:
%   []
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% create figure
fig_biases = figure('Name', 'Applied Satellite Biases Plot [m]', 'NumberTitle','off');

% plot applied bias
plotBiases(storeData.C1_bias, 1, 'C1 Biases', use_GPS, use_GLO, use_GAL, use_BDS)
plotBiases(storeData.C2_bias, 3, 'C2 Biases', use_GPS, use_GLO, use_GAL, use_BDS)
plotBiases(storeData.C3_bias, 5, 'C3 Biases', use_GPS, use_GLO, use_GAL, use_BDS)
plotBiases(storeData.L1_bias, 2, 'L1 Biases', use_GPS, use_GLO, use_GAL, use_BDS)
plotBiases(storeData.L2_bias, 4, 'L2 Biases', use_GPS, use_GLO, use_GAL, use_BDS)
plotBiases(storeData.L3_bias, 6, 'L3 Biases', use_GPS, use_GLO, use_GAL, use_BDS)

% add customized datatip
dcm = datacursormode(fig_biases);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_applBiases)

end


function [] = plotBiases(biases, n_plot, title_str, use_GPS, use_GLO, use_GAL, use_BDS)
% function to plot code or phase biases from a specific frequency

% replace zeros with NaN
biases = full(biases);
biases(biases==0) = NaN;

% check if there are any biases
if all(isnan(biases(:)))
    return
end

% choose subplot
subplot(3, 2, n_plot)
hold on

% GPS
if use_GPS
    ax = gca;
    ax.ColorOrder = distinguishable_colors(DEF.SATS_GPS);
    gps_biases = biases(:,   1:DEF.SATS_GPS);
    plot(gps_biases, '--')
    % prepare plotting text to each bias
    x = NaN(1,DEF.SATS_GPS);
    y = NaN(1,DEF.SATS_GPS);
    for i = 1:DEF.SATS_GPS
        sat_biases = gps_biases(:,i);
        if all(isnan(sat_biases))
            xi = NaN; y(i) = NaN;
        else
            xi = find(~isnan(sat_biases), 1, 'first');
            % some tuning to the text placement
            if xi == 1
                idx = 1:numel(sat_biases);
                idx = idx(~isnan(sat_biases));
                xi = floor(median(idx));
            end
            x(i) = xi;
            y(i) = sat_biases(x(i));
        end
        
    end
    % plot text to each bias
    text(x,y, strcat('G',sprintfc('%02.0f', 1:DEF.SATS_GPS)),  'FontSize',8);
end
% Glonass
if use_GLO
    ax = gca;
    ax.ColorOrder = distinguishable_colors(DEF.SATS_GLO);
    glo_biases = biases(:, 101:(100+DEF.SATS_GLO));
    plot(glo_biases, '-.')
    % prepare plotting text to each bias
    x = NaN(1,DEF.SATS_GLO);
    y = NaN(1,DEF.SATS_GLO);
    for i = 1:DEF.SATS_GLO
        sat_biases = glo_biases(:,i);
        if all(isnan(sat_biases))
            xi = NaN; y(i) = NaN;
        else
            xi = find(~isnan(sat_biases), 1, 'first');
            % some tuning to the text placement
            if xi == 1
                idx = 1:numel(sat_biases);
                idx = idx(~isnan(sat_biases));
                xi = floor(median(idx));
            end
            x(i) = xi;
            y(i) = sat_biases(x(i));
        end
        
    end
    % plot text to each bias
    text(x,y, strcat('R',sprintfc('%02.0f', 1:DEF.SATS_GLO)),  'FontSize',8);
end
% Galileo
if use_GAL
    ax = gca;
    ax.ColorOrder = distinguishable_colors(DEF.SATS_GAL);
    gal_biases = biases(:, 201:(200+DEF.SATS_GAL));
    plot(gal_biases, ':')
    % prepare plotting text to each bias
    x = NaN(1,DEF.SATS_GAL);
    y = NaN(1,DEF.SATS_GAL);
    for i = 1:DEF.SATS_GAL
        sat_biases = gal_biases(:,i);
        if all(isnan(sat_biases))
            xi = NaN; y(i) = NaN;
        else
            xi = find(~isnan(sat_biases), 1, 'first');
            % some tuning to the text placement
            if xi == 1
                idx = 1:numel(sat_biases);
                idx = idx(~isnan(sat_biases));
                xi = floor(median(idx));
            end
            x(i) = xi;
            y(i) = sat_biases(x(i));
        end
        
    end
    % plot text to each bias
    text(x,y, strcat('E',sprintfc('%02.0f', 1:DEF.SATS_GAL)),  'FontSize',8);
end
% BeiDou
if use_BDS
    ax = gca;
    ax.ColorOrder = distinguishable_colors(DEF.SATS_BDS);
    bds_biases = biases(:, 301:(300+DEF.SATS_BDS));
    plot(bds_biases, ':')
    % prepare plotting text to each bias
    x = NaN(1,DEF.SATS_BDS);
    y = NaN(1,DEF.SATS_BDS);
    for i = 1:DEF.SATS_BDS
        sat_biases = bds_biases(:,i);
        if all(isnan(sat_biases))
            xi = NaN; y(i) = NaN;
        else
            xi = find(~isnan(sat_biases), 1, 'first');
            % some tuning to the text placement
            if xi == 1
                idx = 1:numel(sat_biases);
                idx = idx(~isnan(sat_biases));
                xi = floor(median(idx));
            end
            x(i) = xi;
            y(i) = sat_biases(x(i));
        end
        
    end
    % plot text to each bias
    text(x,y, strcat('C',sprintfc('%02.0f', 1:DEF.SATS_BDS)),  'FontSize',8);
end



% style plot
title(title_str)
xlabel('Epochs')
ylabel('Bias [m]')
legend          % just for customdatatip
legend('off')

end



function output_txt = vis_customdatatip_applBiases(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

if isempty(event_obj.Target.DisplayName)
    output_txt = 'no info';
    return
end


% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
sod = pos(1);
value = pos(2);

% calculate epoch from sod (attention: missing epochs are not considered!)
epoch = find(event_obj.Target.XData == sod, 1, 'first');

% create cell with strings as output (which will be shown when clicking)
i = 1;
prn_str = strrep(event_obj.Target.DisplayName, 'data', '');
prn = str2double(prn_str);
output_txt{i} = ['Sat: ', sprintf('%02.0f', prn)];   % number of clicked line e.g. satellite
i = i + 1;
output_txt{i} = ['Epoch: ', sprintf('%.0f', epoch)];    % epoch
i = i + 1;
output_txt{i} = ['Value: ', sprintf('%.4f', value) ' [m]'];    % value

end