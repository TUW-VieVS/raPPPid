function [Epoch, n_removed] = postfit_exclude(Epoch, n_removed, i_bad, w, PF, label)
% Excludes the largest normalized post-fit residual at row i_bad and prints 
% information about it to the command window. 
%
% INPUT:
%   Epoch       struct, epoch-specific data
%   n_removed   [1x3], # of already-removed observations [code, phase, Doppler]
%   i_bad       row index of the observation to exclude
%   w           [n x 1], normalized post-fit residuals
%   PF          struct, carries variables of the post-fit residual check
%   label       string, printed to indicate which check found the outlier
% 
% OUTPUT:
%   Epoch       struct, updated fields
%   n_removed   [1x3], updated count of removed observations
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% identify and exclude observation
sat = PF.sat_number(i_bad); frq = PF.frq_number(i_bad); type = PF.obs_type(i_bad);
Epoch.sat_status(sat,frq) = 19;
switch type
    case 1      % code
        Epoch.useCode(sat,frq) = false;
        n_removed(1) = n_removed(1) + 1;
    case 2      % phase
        Epoch.usePhase(sat,:) = false;       % remove phase observations on all frequency to be safe
        n_removed(2) = n_removed(2) + 1;
    case 4      % Doppler
        Epoch.useDoppler(sat,frq) = false;
        n_removed(3) = n_removed(3) + 1;
end

% print information to command window
if PF.bool_print
    fprintf('PRN %03.0f, %s excluded by post-fit residual check (%s): w = %6.2f [%4.2f]            \n', ...
        Epoch.sats(sat), PF.obstypes{type}, label, w(i_bad), PF.factor)
end
