function BARS = prepConvergenceBars(conv_dN, conv_dE, conv_dH, conv_2D, BARS, idx, minutes)
% Function to prepare the bar plot adding the plot relevant information of
% the current label to the matrix BARS which will be used for the bar plot
% of the convergence later on
% 
% INPUT:
%   conv_dN     vector, time [min] when convergence is reached in dN
%   conv_dE     ...
%   conv_dH     ...
%   conv_2D     vector, time when convergence is reached in 2D position
%   BARS        matrix, data for the bar plot, each row = label, each
%               column = point in time specified in GUI
%   idx      	index of current label
%   minutes     vector, minutes after which convergence should be checked
% OUTPUT:
%   BARS        updated with the data of the current label
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% put coordinates together in multi-dimensional matrix
conv(:,:,1) = conv_dN;   conv(:,:,2) = conv_dE;   conv(:,:,3) = conv_dH;   conv(:,:,4) = conv_2D;

% number of bars
no_bars = numel(minutes);

ADD = zeros(1,no_bars+1,4);
% check if convergence is reached after n minutes:
for ii = 1:numel(minutes)
    ADD(1,ii,:) = sum(conv < minutes(ii),2);
end
% save number of convergence periods as last entry in ADD/BARS
for ii = 1:4
    ADD(1,no_bars+1,ii) = numel(conv(:,:,ii));
end

BARS(idx,:,:) = BARS(idx,:,:) + ADD;

end