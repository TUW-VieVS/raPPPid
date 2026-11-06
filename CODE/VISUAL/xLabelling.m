function [vec, txt] = xLabelling(tick_ival, x_vals, obs_ival)
% This functions creates based on a chosen tick interval a vector (vec) 
% with x-values and a cellstr (txt) with the corresponding ticks (format 
% hh:mm or hh:mm:ss) to create a nice looking annotation of the x axis. 
% Thresholds and numbers are rather arbitrary and based on experience 
% ("what looks nice?")
% 
% INPUT:
%   tick_ival   interval of the ticks [s]
%   x_vals      x values of plotting [s]
%   obs_ival    observation interval [s]
% OUTPUT:
%   vec         vector for xaxis
%   txt         cellstr with appropiate times
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% check if processed time is larger than the
if (x_vals(end)-x_vals(1)) > obs_ival
    % find indices where x-values are multiples of the interval with tolerance
    remainder = mod(x_vals, tick_ival);
    tol = obs_ival/10;
    idx = abs(remainder) < tol | abs(remainder - tick_ival) < tol;
    vec = x_vals(idx);      % x-values for ticks
    if isempty(vec) || isscalar(vec)
        % no or only one values found for vec, take first and last x value
        vec(1) = x_vals(1);
        vec(2) = x_vals(end);
    end
    if obs_ival > 15 && x_vals(end)-x_vals(1) > 300
        % observation interval > 15 and more than 5 minutes processed
        txt = sow2hhmm(vec);    % format hh:mm
        txt = cellstr(strcat(txt,'h'));
    else
        txt = sow2hhmmss(vec);  % format hh:mm:ss
        txt = cellstr(txt);
    end
else
    % processing time shorter than interval -> create ticks for first and
    % last place
    i_1 = 1;
    vec = [x_vals(i_1), x_vals(end)];
    if obs_ival > 15 && x_vals(end)-x_vals(1) > 300
         % observation interval > 15 and more than 5 minutes processed
        txt = sow2hhmm(vec);    % format hh:mm
        txt = cellstr(strcat(txt,'h'));
    else
        txt = sow2hhmmss(vec);  % format hh:mm:ss
        txt = cellstr(txt);
    end
end
end