function [CA] = prepConvaccurPlot(CA, d, i, conv_2D, unique_labels, point)
% This function prepares the input data for the Convergence/Accuracy
% Multi-Plot (ConvAccurPlot.m)
%
% INPUT:
%   CA          cell, #labels x 3: 2D convergence | 3D accuracy | label
%   d           struct, containing convergence period data
%   i           integer, index of current label
%   conv_2D     vector, indicating when convergence period has converged
%   minutes     time-points [min] from GUI
%   point       [min], point in time to take 3D accuracy
% OUTPUT:
%	CA          updated with data of current label
%
% Revision:
%   2024/02/01, MFWG: take specified 3D accuracy
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************

% find indices with minimum difference to specified point in time
dT = d.dT/60;       % time from last reset [min]
dT_diff = abs(dT - point);      % difference to specificed point in time for 3D accuracy
min_diff = min(dT_diff, [], 2, 'omitnan');      % minimum difference for each row
bool = (dT_diff == min_diff);   % check where minum difference occurs
% extract correct column
dE = d.E(bool); dE = dE(:,1);
dN = d.N(bool); dN = dN(:,1);
dH = d.H(bool); dH = dH(:,1);

% get convergence, 3D accuracy and current label
val_1 = conv_2D';                       % 2D convergence
val_2 = sqrt(dE.^2 + dN.^2 + dH.^2);	% 3D accuracy
val_3 = cell(numel(conv_2D),1);         % initialize and ...
val_3(:) = unique_labels(i);            % get current label

% save data for ConvAccur Plot
CA{i,1} = val_1;    CA{i,2} = val_2;    CA{i,3} = val_3;