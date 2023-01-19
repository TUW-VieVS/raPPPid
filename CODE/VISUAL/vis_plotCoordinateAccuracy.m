function vis_plotCoordinateAccuracy(dN, dE, label, floatfix)
% Plot the calculated horizontal coordinates as scatter-plot. Additional
% the true position (which is 0/0) and the mean position are plotted. The
% standard deviation is calculated.
%
% INPUT:
% dN            UTM North coordinate differences as vector
% dE            UTM East  coordinate differences as vector
% label         string, station and date
% floatfix      string, float or fixed solution
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| implement a clean version of error ellipse, covariance between
% coordinate components


fig_coords = figure('Name','Coordinate Accuracy', 'NumberTitle','off');
dE = dE(:);
dN = dN(:);
std_dE = nanstd(dE);
std_dN = nanstd(dN);
mean_dE = nanmean(dE);
mean_dN = nanmean(dN);


% % Plot ellipse with standard deviation of coordinates
% t = linspace(0, pi*2);
% x_ell = std_dE*cos(t);
% y_ell = std_dN*sin(t);
% pl_ell = plot(mean_dE+x_ell, mean_dN+y_ell, 'g', 'LineWidth',2);

% Plot difference of coordinates
hold on
pl_calc = scatter(dE, dN, 50, [1 .44 .44], '.');            % calculated positions
pl_mean = plot(mean_dE,mean_dN, 'bx', 'MarkerSize', 10); 	% mean position

% Style
title(['Coordinate Accuracy for ' label ', ' floatfix])
xlabel('East [m]')
ylabel('North [m]')
if any(dE~=0) && any(dN~=0)
    xlim([min([dE-std_dE/2; 0-std_dE/2]) max([dE+std_dE/2; 0+std_dE/2])])
    ylim([min([dN-std_dN/2; 0-std_dN/2]) max([dN+std_dN/2; 0+std_dN/2])])
end
axis equal
hline(0, 'k--')
vline(0, 'k--')

% add text with stdev and bias
str0 = 'EAST [m],      NORTH [m]';
str1 = ['bias=' sprintf('%02.3f', mean_dE) ', bias=' sprintf('%02.3f', mean_dN)];
str2 = ['std =' sprintf('%02.3f', std_dE) ',  std=' sprintf('%02.3f', std_dN)];
TextLocation({str0, str1, str2},'Location','best')

% add legend
legend([pl_calc pl_mean],{'Calculated', 'Mean', 'Text'}, 'Location','best')

% add customized datatip
dcm = datacursormode(fig_coords);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_coordsacc)




function output_txt = vis_customdatatip_coordsacc(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
%
% *************************************************************************

i = 1;
pos = get(event_obj,'Position');
x = pos(1);
y = pos(2);
switch event_obj.Target.DisplayName
    case 'Calculated'
        ep = find((obj.DataSource.XData == x) & (obj.DataSource.YData == y));
        % create cell with strings as output (which will be shown when clicking)
        output_txt{i} = ['dE: ', sprintf('%.3f', x)];        i = i + 1;
        output_txt{i} = ['dN: ', sprintf('%.3f', y)];        i = i + 1;
        output_txt{i} = ['Epoch: ', sprintf('%.0f', ep)];
        
    case 'Mean'
        output_txt{i} = ['dE: ', sprintf('%.3f', x)];        i = i + 1;
        output_txt{i} = ['dN: ', sprintf('%.3f', y)];        i = i + 1;
        
    otherwise
        output_txt = '';
end
