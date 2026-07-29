function [] = ConvAccurPlot(D, coleurs, PlotStruct)
% This function creates the CDF of the 2D convergence and the 3D position 
% accuracy after n minutes. 
% 
% INPUT:
%   D           cell, #labels x 3: 2D convergence | 3D final accuracy | label
%   coleurs     #labels x 3, colors to plot
%   PlotStruct  struct, settings of Multi Plot
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


solution = PlotStruct.solution;  	%   'float' or 'fixed'
strMinutes = sprintf('%.2f', PlotStruct.bar_position(end));     % specified point in time for 3D accuracy

% number of labels
n_labels = size(D,1);

% create figure
figure('Name', ['CDF of 2D convergence and 3D accuracy after ' strMinutes ' [min]: ' solution], 'NumberTitle','off');

% create subplots and store their handles in an array
ax(1) = subplot(2, 1, 1);
ax(2) = subplot(2, 1, 2);

% apply hold on to all handles
hold(ax, 'on'); 

% initialize upper limit of xlim
xmax1 = 0; xmax2 = 0;

% loop to plot for each label
for i = 1:n_labels

    % Get current data
    conv_2d = cell2mat(D(i,1));         	% [min]
    accu_3d  = cell2mat(D(i,2)) * 100;      % convert from [m] to [cm]
    lbels = D{i,3};                         % label for each datapoint
    lbel = lbels{1};

    
    % number of elements
    n_conv = length(conv_2d);
    n_accu = length(accu_3d);

    % sort the data
    sorted_conv_2d = sort(conv_2d);
    sorted_accu_3d = sort(accu_3d);

    % calculate CDF: Y is 1/n, 2/n, ..., n/n
    y_conv = (1:n_conv)' / n_conv;
    y_accu = (1:n_accu)' / n_accu;

     % Plot using a step function (standard for CDFs)
    subplot(2,1,1)
    hold on
    stairs(ax(1), sorted_conv_2d, y_conv, 'Color', coleurs(i,:), 'LineWidth', 2, 'DisplayName', lbel);   
    subplot(2,1,2)
    hold on
    stairs(ax(2), sorted_accu_3d, y_accu, 'Color', coleurs(i,:), 'LineWidth', 2, 'DisplayName', lbel);   

    % determine suitable upper limit of xlim
    % (calc_quantile instead of prctile to avoid the Statistics and Machine
    % Learning Toolbox; note the different scaling of the probability)
    xmax1 = max([xmax1, calc_quantile(sorted_conv_2d, 0.99)]);
    xmax2 = max([xmax2, calc_quantile(sorted_accu_3d, 0.99)]);
end


% style plot
xlabel(ax(1), '2D convergence [min]');
xlabel(ax(2), ['3D accuracy [cm] after ' strMinutes ' [min]']);
ylabel(ax(1), 'percentage [%]');
ylabel(ax(2), 'percentage [%]');
xlim(ax(1), [0, xmax1]);
xlim(ax(2), [0, xmax2]);
ylim(ax(1), [0, 1]);
ylim(ax(2), [0, 1]);
legend(ax(1))
legend(ax(2))

