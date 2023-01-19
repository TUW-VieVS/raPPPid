function R = rot(ax, alpha)
% Creates rotation matrix
% 
% INPUT:
%   ax        number of axis
%   alpha     angle to rotate
% OUTPUT:
%   rotation matrix
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

switch ax
    case 3      % z-axis
        R = [ cos(alpha)  sin(alpha)  0
             -sin(alpha)  cos(alpha)  0
                  0            0      1];
    case 2      % y-axis
        R = [ cos(alpha)  0  sin(alpha)
                  0       1      0
             -sin(alpha)  0  cos(alpha)];
    case 1      % x-axis
        R = [1       0           0
             0   cos(alpha)  sin(alpha)
             0  -sin(alpha)  cos(alpha)];
end