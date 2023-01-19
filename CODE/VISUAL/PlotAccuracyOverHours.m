function [] = PlotAccuracyOverHours(Time, dN_, dE_, dH_, conv_2D, curr_label, PlotStruct)
% Plots statistic of position error and convergence time for each hour of
% the day
% 
% INPUT:
%	...        
% OUTPUT:
%	...
%
% Revision:
%   ...
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

d3D = sqrt(dN_.^2 + dE_.^2 + dH_.^2);
Hours = floor(mod(Time/3600, 24)); 

d3D_ = d3D(:);
Hours_ = Hours(:);

% Plot
txt = ['3D Position Error of ' PlotStruct.solution ' solution'];
figure('Name', txt, 'NumberTitle','off')
boxplot(d3D_, Hours_,'PlotStyle','compact')

% Style
title(txt)
ylabel('3D Position Error')
xlabel('Hour')



% Plot
txt = ['Convergence Time of ' PlotStruct.solution ' solution'];
figure('Name', txt, 'NumberTitle','off')
boxplot(conv_2D, Hours(:,1),'PlotStyle','compact')

% Style
title(txt)
ylabel('Convergence Time [min]')
xlabel('Hour')