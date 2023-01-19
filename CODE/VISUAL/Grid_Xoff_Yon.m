function [] = Grid_Xoff_Yon()
% function to turn the x-grid off and the y-grid on of the current plot
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

ax = gca;
ax.XGrid = 'off';
ax.YGrid = 'on';
end