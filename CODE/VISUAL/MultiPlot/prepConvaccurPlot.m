function [CA] = prepConvaccurPlot(CA, d, i, conv_2D, unique_labels)
% This function prepares the input data for the Convergence/Accuracy
% Multi-Plot (ConvAccurPlot.m)
%
% INPUT:
%   CA          cell, #labels x 3: 2D convergence | 3D final accuracy | label
%   d           struct, containing convergence period data
%   i           integer, index of current label
%   conv_2D     vector, indicating when convergence period has converged
%   minutes     time-points [min] from GUI
% OUTPUT:
%	CA          updated with data of current label
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************


val_1 = conv_2D';                   % 2D convergence
val_2 = sqrt(d.E(:,end).^2 + ...    % final 3D accuracy
    d.N(:,end).^2 + d.H(:,end).^2);
val_3 = cell(numel(conv_2D),1);
val_3(:) = unique_labels(i);        % current label
% save data for ConvAccur Plot
CA{i,1} = val_1;    CA{i,2} = val_2;    CA{i,3} = val_3;