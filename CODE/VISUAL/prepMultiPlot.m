function [Q68, Q95, Q_time] = prepMultiPlot(d, Q68, Q95, Q_time, row)
% Prepares some stuff for Multi-Plots
% 
% INPUT:
%	d           struct, containing data for Multi Plots         
%   Q68         0.68 quantile of dN, dE, dH, 2D, 3D for all labels
%   Q95         0.95 quantile of dN, dE, dH, 2D, 3D for all labels
%   Q_time      points in time which all convergence periods of a label have
%   row         number of current label
% OUTPUT:
%	Q68, Q95, Q_time      
%               updated with data of current label
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% get variables
dN = d.N;           % coordinate difference in UTM North [m]
dE = d.E;           % coordinate difference in UTM East [m]
dH = d.H;           % coordinate difference in ellips. height [m]
dT = d.dT;          % time since the beginning of the new convergence [s]
dZTD = d.ZTD;       % ZTD difference [m]

% round to avoid numerical problems
Time_round = round(dT);	

% calculate absolute values
dN = abs(dN); dE = abs(dE); dH = abs(dH); dZTD = abs(dZTD);

% calculate horizontal position error
d2D = sqrt(dN.^2 + dE.^2);
% calculate 3d position error
d3D = sqrt(dN.^2 + dE.^2 + dH.^2);

% looking for points in time which all convergences have
n = size(Time_round, 1);        % number of convergence periods
time_all = Time_round(1,:);   
time_all(isnan(time_all)) = []; % remove points in time which are NaN
k = 1;
while k <= numel(time_all)
    time2check = time_all(k);
    bool_keep = any(Time_round == time2check,2);
    if sum(bool_keep)/n < 0.95      % check if point in time is removed
        % point in time is in less than 95% of all convergence periods,
        % therefore a small amount of datagaps is tolerated
        time_all(k) = [];     
    else 
        k = k + 1;
    end
end

% get position errors for common points in time
m = numel(time_all);        % number of common points in time
dN_all = NaN(n,m);    dE_all = NaN(n,m);  dH_all = NaN(n,m);  
d2D_all = NaN(n,m);  d3D_all = NaN(n,m); dZTD_all = NaN(n,m);
for i = 1:m       % loop over points in time which all processing have
    idx = (Time_round == time_all(i));      % indices of current point in time
    % get coordinates to current point in time
    t = sum(idx(:));        % number of equal points in time
    dN_all(1:t,i) = dN(idx);      
    dE_all(1:t,i) = dE(idx);      
    dH_all(1:t,i) = dH(idx);
    d2D_all(1:t,i) = d2D(idx);    
    d3D_all(1:t,i) = d3D(idx);
    if ~isempty(dZTD); dZTD_all(1:t,i) = dZTD(idx); end
end
% replace NaN values with maximum (otherwise NaN values are ignored)
%     dN_curr(isnan(dN_curr)) = max(dN_curr);
%     dE_curr(isnan(dE_curr)) = max(dE_curr);
%     dH_curr(isnan(dH_curr)) = max(dH_curr);
%     d2D_curr(isnan(d2D_curr)) = max(d2D_curr);
%     d3D_curr(isnan(d3D_curr)) = max(d3D_curr);
%     dZTD_curr(isnan(dZTD_curr)) = max(dZTD_curr);

% find quantiles of position differences
if n ~= 1
    % calculate 68% quantile
    dN_68   = quantile(dN_all , 0.68);       % quantile() is slow
    dE_68   = quantile(dE_all , 0.68);
    dH_68   = quantile(dH_all , 0.68);
    d2D_68  = quantile(d2D_all, 0.68);
    d3D_68  = quantile(d3D_all, 0.68);
    dZTD_68 = quantile(dZTD_all, 0.68);
    % calculate 95% quantile
    dN_95   = quantile(dN_all , 0.95);
    dE_95   = quantile(dE_all , 0.95);
    dH_95   = quantile(dH_all , 0.95);
    d2D_95  = quantile(d2D_all, 0.95);
    d3D_95  = quantile(d3D_all, 0.95);
    dZTD_95 = quantile(dZTD_all, 0.95);
else    % only one convergence period
    dN_68  = NaN(1,m);  dE_68 = NaN(1,m); dH_68  = NaN(1,m);
    d2D_68 = NaN(1,m); d3D_68 = NaN(1,m); dZTD_68 = NaN(1,m);
    dN_95  = NaN(1,m);  dE_95 = NaN(1,m); dH_95  = NaN(1,m);
    d2D_95 = NaN(1,m); d3D_95 = NaN(1,m); dZTD_95 = NaN(1,m);
end

% save 68% quantile
Q68{row, 1} = dN_68;
Q68{row, 2} = dE_68;
Q68{row, 3} = dH_68;
Q68{row, 4} = d2D_68;
Q68{row, 5} = d3D_68;
Q68{row, 6} = dZTD_68;
% save 95% quantile
Q95{row, 1} = dN_95;
Q95{row, 2} = dE_95;
Q95{row, 3} = dH_95;
Q95{row, 4} = d2D_95;
Q95{row, 5} = d3D_95;
Q95{row, 6} = dZTD_95;
% save time-stamp
Q_time{row} = time_all;