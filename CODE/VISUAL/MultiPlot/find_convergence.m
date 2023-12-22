function [conv_dN, conv_dE, conv_dH, conv_2D, conv_3D] = ...
    find_convergence(dN, dE, dH, dT, MultiPlot)
% Function to look for points in time where convergence is reached for all
% convergence periods of the current label
% 
% INPUT:
%   dN          coordinate difference UTM North, each row is one convergence period
%   dE          coordinate difference UTM East, ...
%   dH          coordinate difference ellipsoidal height, ...
%   dT          time [s] since start of convergence period
%   MultiPlot   struct, settings for Multi-Plots
% OUTPUT:
%   conv_dN/_dE/_dH/_2D/_3D
%                   vector, time when convergence is reached in dN/... for
%                   all convergence periods [min]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get thresholds
thresh_hor    = MultiPlot.thresh_horiz_coord;       % threshold for North+East coordinate
thresh_height = MultiPlot.thresh_height_coord;      % threshold for Height
thresh_2D     = MultiPlot.thresh_2D;                % threshold for 2D position
thresh_3D     = MultiPlot.thresh_3D;                % threshold for 3D position

% calculate absolute values
dN = abs(dN);
dE = abs(dE);
dH = abs(dH);

[n, no_cols] = size(dT);      % number of convergences
d2D = sqrt(dN.^2 + dE.^2);
d3D = sqrt(dN.^2 + dE.^2 + dH.^2);

% create boolean matrices for all three coordinates: true if under
% convergence threshold or no coordinate data
bool_dN = (dN < thresh_hor) | isnan(dT);
bool_dE = (dE < thresh_hor) | isnan(dT);
bool_dH = (dH < thresh_height) | isnan(dT);
bool_2D = (d2D < thresh_2D) | isnan(dT);
bool_3D = (d3D < thresh_3D) | isnan(dT);

% looking for the 1st point in time where convergence threshold is reached
% and all subsequent epochs are also under threshold
[conv_dN, conv_dN_idx] = find_conv(bool_dN, dT, n, no_cols);
[conv_dE, conv_dE_idx] = find_conv(bool_dE, dT, n, no_cols);
[conv_dH, conv_dH_idx] = find_conv(bool_dH, dT, n, no_cols);
[conv_2D, conv_2D_idx] = find_conv(bool_2D, dT, n, no_cols);
[conv_3D, conv_3D_idx] = find_conv(bool_3D, dT, n, no_cols);

% convert to minutes
conv_dN = conv_dN / 60;       
conv_dE = conv_dE / 60;   
conv_dH = conv_dH / 60;
conv_2D = conv_2D / 60;      
conv_3D = conv_3D / 60;   



function [conv_time, conv_idx] = find_conv(bool_coord, TIME, n, no_cols)
% function to find the epoch of each convergence period where convergence
% is reached and kept for the remaining epochs
conv_time = NaN(1,n);     conv_idx = NaN(1,n);
for i = 1:n         % loop over all convergence periods
    curr_row = bool_coord(i,:);     % extract current convergence period
    % look for last epoch which is not under convergence threshold -> so
    % the next epoch is the 1st epoch where convergence is reached and kept
    % for the remaining epochs
    idx_dN = find(curr_row == 0, 1, 'last') + 1;
    if idx_dN <= numel(curr_row)    % check if convergence is reached at all
        conv_idx(i) = idx_dN;               % save index of convergence
        conv_time(i) = TIME(i,idx_dN);      % save time of convergence
    elseif isempty(idx_dN)          % convergence is reached in 1st epoch
        conv_idx(i) = 1;                    % ...
        conv_time(i) = TIME(i,1);
%     elseif idx_dN > numel(curr_row) % no convergence until last epoch
%         conv_idx(i) = idx_dN; 
%         conv_time(i) = TIME(i,idx_dN-1); % time of epoch after last epoch
% %             + (TIME(i,idx_dN-1) - TIME(i,idx_dN-2));
    end
end

