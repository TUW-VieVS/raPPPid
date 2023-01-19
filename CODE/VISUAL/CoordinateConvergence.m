function [] = CoordinateConvergence(dN, dE, dH, TIME, q68, q95, dT_all, PlotStruct, label)
% This function creates the Coordinate Convergence Multi Plot. The
% differences in UTM North, East and height coordinate are plotted over
% time and as a histogram.
% dN, dE, dH and Time are all of the same size: each row is a
% convergence period from processing and the columns depend on the number
% of epochs of each convergence period
% 
% INPUT:
%   dN            coordinate difference in UTM North [m]
%   dE            coordinate difference in UTM East [m]
%   dH            coordinate difference in ellips. height [m]
%   TIME          time since the beginning of the new convergence [s]
%   q68           0.68 quantiles of current labels (dN, dE, dH, 2D, 3D)
%   q95           0.95 quantiles of current labels (dN, dE, dH, 2D, 3D)
%   TIME_all      points in time which all convergence periods have [s]
%   PlotStruct    struct, settings of Multi-Plot
%   label         string, label of multi-plot
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


thresh_hor = PlotStruct.thresh_horiz_coord;
thresh_height = PlotStruct.thresh_height_coord;
fixed = PlotStruct.fixed;
TIME = TIME / 60;           % convert to [min]
dT_all = dT_all / 60;
t_max = max(TIME(:));   	% duration of longest convergence period

% Set title of convergence plot
if ~isempty(label)
    title_str = ['Coordinate Convergence for ' label ' (float)'];
    if fixed
        title_str = ['Coordinate Convergence for ' label ' (fixed)'];
    end
end
fig = figure('Name',title_str, 'NumberTitle','off');

% --- Plot dN
c1 = [1,0.6,0.4];
plot_convergences(TIME, abs(dN), c1, 'dN [m]', t_max, thresh_hor, dT_all, q68{1}, 1, ['Coordinate Convergences for ' label])
% --- Plot dE
c2 = [0.4, 0.6, 1];
plot_convergences(TIME, abs(dE), c2, 'dE [m]', t_max, thresh_hor, dT_all, q68{2}, 4, [])
% --- Plot dH
c3 = [0.4, 1, 0.6];
plot_convergences(TIME, abs(dH), c3, 'dH [m]', t_max, thresh_height, dT_all, q68{3}, 7, [])


% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_coord_multi)

end


% Auxiliary Function to plot
function [] = plot_convergences(time, values, coleur, y_string, dt, thresh, dT_all, quant, p, strtitle)

% Plot Coordinate Convergence
subplot(3,3, p:(p+1))
hold on
plot(time',values', 'color',coleur, 'linewidth',1);     % vectorized plot is faster
hline(thresh, 'r--');
plot(dT_all, quant, 'k-', 'linewidth',1)             % plot median
ylim([0 .5])
xlim([0 dt]);
ylabel(y_string, 'FontWeight','bold')
grid on;
if p == 7
    xlabel('[min]')
end
if p == 1
   title(strtitle) 
end

% Plot Histogram of Coordinate Differences
ax = subplot(3,3, p+2);
edges = [0:0.02:0.25 0.5];
histogram(values, edges, 'Normalization', 'probability', 'facecolor', coleur)
xlim([0 .3])
ylim([0 1])     % axis until 100%
vline(thresh, 'r--')     % vertical line for convergence threshold
yticklabels(yticks*100)
ylabel('[%]')
ax.YAxisLocation = 'right';
grid on
if p == 7
    xlabel('[m]')
end
end



function output_txt = vis_customdatatip_coord_multi(obj,event_obj)
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
xvalue = pos(1);      
yvalue = pos(2);
i = 1;
if strcmp(event_obj.Target.Type, 'line')  
    % create cell with strings as output (which will be shown when clicking)
    output_txt{i} = ['Minute: ', sprintf('%.2f', xvalue)];
    i = i+1;
    output_txt{i} = [obj.Parent.YLabel.String ': ' sprintf('%.3f', yvalue)];
else  
    output_txt{i} = [sprintf('%.2f', yvalue*100) ' %'];
%     edges = event_obj.Target.BinEdges;
%     e1 = edges(edges < xvalue);
%     e2 = edges(edges > xvalue);
%     i = i+1;
%     output_txt{i} = ['[' sprintf('%.2f', e1(end)) '; ' sprintf('%.2f', e2(1)) ']'];
end
end
