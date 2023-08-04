function [val_min, val_max, LUT] = vis_prepareColorCoding(Value, bool_def, val_max, val_min)
% Prepare color-coding of the skyplot
%
% INPUT:
%   Value       epochs x 399, C/N0 or residuals of all satellites and epochs, matrix
%   bool_def    boolean, true = use own thresholds for color-coding
%   val_max, val_min    thresholds from Skyplot GUI
% OUTPUT:
%   val_min     minimum of Value
%   val_max     maximum of Value
%   LUT         Look-Up-Table, colors for colorcoding of C/N0
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% replaces zeros with NaN
Value(Value==0) = NaN;

% overwrite thresholds if default calculation is used
if bool_def
    % color-coding of plot
    val_min = floor(min(Value(:)));       % lowest C/N0-value of all satellites
    val_max = floor(max(Value(:))+1);     % highest C/N0-value of all satellites
    if isnan(val_min)
        val_min = 0;
    end
    if isnan(val_max)
        val_max = val_min+1;
    end
else
    % check for stupid input
    val_min = round(val_min);
    val_max = round(val_max);
    if val_min < 0; val_min = 0; end
    if val_max <= val_min; val_max = val_min + 1; end
end
    

% create color Look-Up-Table
% LUT = jet(val_max-val_min);     
LUT = flipud(hot(val_max-val_min));       % white to red