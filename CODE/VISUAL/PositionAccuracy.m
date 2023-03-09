function PositionAccuracy(dN, dE, label, MultiPlot)
% Creates a fanzy plot showing the accuarcy of the solution for the current
% label
%
% INPUT: 
%   dN            UTM-North-Coordinate as vector
%   dE            UTM-East-Coordinate  as vector
%   dH            UTM-Heigth-Coordinate as vector
%   MultiPlot     struct, Multi-Plot-settings
% OUTPUT:
%   []
% 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% reso_2D = [-Inf -.4:.003:.4 Inf];
% reso_3D = [-Inf -.4:.030:.4 Inf];
% if multi_plot.fixed
    reso_2D = [-Inf -.2:.002:.2 Inf];
    reso_3D = [-Inf -.2:.020:.2 Inf];
% end

floatfixed = char('float'*MultiPlot.float + 'fixed'*MultiPlot.fixed);
fig_coords = figure('Name',['Coordinate Accuracy for ' floatfixed ' solution'], 'NumberTitle','off');
dE = dE(:);
dN = dN(:);

% Plot 3D
subplot(2, 2, [1 3])
histogram2(dE,dN, reso_3D, reso_3D, 'Normalization','probability')
view(30,15)
zticklabels(zticks*100)
xlabel('East [m]', 'Rotation', 0)
ylabel('North [m]', 'Rotation', 0)
zlabel('Count [%]')

% Plot Top View
ax = subplot(2, 2, [2 4]);
% histogram2(dE,dN, reso_3D, reso_3D, 'Normalization','probability', 'FaceColor','flat')
% colormap(jet)
% view(2)
histogram2(dE,dN, reso_2D, reso_2D, 'Normalization','probability', 'DisplayStyle','tile');
colormap(jet)
ax.YAxisLocation = 'right';
hold on
plotEllipse_std(dE, dN)
axis equal
title({'Coordinate Accuracy Plots for '; label; '';''})
xlabel('East [m]')
ylabel('North [m]')

% add customized datatip
dcm = datacursormode(fig_coords);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_coordsacc)
end



function [] = plotEllipse_std(dE, dN)
% Plot ellipse with standard deviation of coordinates
std_dE = std(dE, 'omitnan');
std_dN = std(dN, 'omitnan');
t = linspace(0, 2*pi);
x_ell = std_dE*cos(t);
y_ell = std_dN*sin(t);
plot(x_ell, y_ell, 'g', 'LineWidth',1)
end



function output_txt = vis_customdatatip_coordsacc(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************


pos = get(event_obj,'Position');
x = pos(1);
y = pos(2);
z = pos(3);

x_idx1 = find(event_obj.Target.XBinEdges < x, 1,  'last');
x_idx2 = find(event_obj.Target.XBinEdges > x, 1,  'first');

y_idx1 = find(event_obj.Target.XBinEdges < y, 1,  'last');
y_idx2 = find(event_obj.Target.XBinEdges > y, 1,  'first');

x_1 = event_obj.Target.XBinEdges(x_idx1);
x_2 = event_obj.Target.XBinEdges(x_idx2);
y_1 = event_obj.Target.YBinEdges(y_idx1);
y_2 = event_obj.Target.YBinEdges(y_idx2);

if z == 0
    z = event_obj.Target.Values(x_idx1, y_idx1);
end

% create cell with strings as output (which will be shown when clicking)
i = 1;
output_txt{i} = ['Count [%]: ' sprintf('%.3f', z*100)];
% i = i + 1;
% output_txt{i} = 'East  [m]:';
% i = i + 1;
% output_txt{i} = [sprintf('%.3f', x_1) ' : ' sprintf('%.3f', x_2)];
% i = i + 1;
% output_txt{i} = 'North [m]:';
% i = i + 1;
% output_txt{i} = [sprintf('%.3f', y_1) ' : ' sprintf('%.3f', y_2)];


end