function [TTFF, TTCF] = prepTTFF(TTFF, TTCF, FIXED, thresh_2d, TIME, dE, dN, idx)
% Function to prepare the Time-to-First-Fix (TTFF) and Time-to-Correct-Fix
% (TTCF) Plot
%
% INPUT:
%   TTFF            cell, minutes of first fix are saved here
%   TTCF            cell, minutes of first correct fix are saved here
%   FIXED           asdf
%   thresh_2d       threshold for 2D position error
%   The following variables are matrices (row = convergence period, columns
%   = epochs) which contain all convergence periods of the current label:
%       FIXED    	boolean, true if fixed position was achieved
%       TIME    	time since reset [s]
%       dE       	UTM-East coordinate error
%       dN       	UTM-North coordinate error
%   idx             index of current label
% OUTPUT:
%   TTFF            updated with the data of the current label
%   TTCF            updated with the data of the current label
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

n = size(FIXED, 1);     % number of convergence periods
FIXED(isnan(FIXED)) = 0;
TTFF_new = NaN(1, n);   TTCF_new = TTFF_new;
CONV_2D = (sqrt(dE.^2 + dN.^2)) < thresh_2d;

% loop over convergence periods
for i = 1:n
    % get variables for current convergence period
    fixed = FIXED(i,:);
    conv_2d = CONV_2D(i,:);
    time = TIME(i,:);
    
    % find the point where convergence is reached and kept
    fixed = find_real_convergence(fixed);    
    conv_2d = find_real_convergence(conv_2d);
    
    % check for convergence and fixed (both until the end!)
    fixed_conv = fixed & conv_2d;
    
    % calculate time [min] of first fix and correct fix
    time_fix      = time(find(fixed,      1, 'first')) / 60;
    time_fix_conv = time(find(fixed_conv, 1, 'first')) / 60;
    if isempty(time_fix     ); time_fix = NaN;      end
    if isempty(time_fix_conv); time_fix_conv = NaN; end
    
    % save time [min] of first fix and correct fix
    TTFF_new(i) = time_fix;
    TTCF_new(i) = time_fix_conv;
end

% save time [min] of first fix and correct fix
TTFF{idx} = TTFF_new;
TTCF{idx} = TTCF_new;
end


% function to find the real convergence, the point where convergence is
% reached kept until the end of the convergence period
function bool = find_real_convergence(bool)
idx = find(bool == 0, 1, 'last');
bool(1:idx) = 0;
end
