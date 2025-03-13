function [vec, txt] = xLabelling(tick_ival, x_vals, obs_ival)
% This functions creates based on a choosen tick interval a vector (vec) 
% with x-values and a cellstr (txt) with the corresponding ticks (format 
% hh:mm or hh:mm:ss) to create a nice looking annotation of the x axis. 
% Thresholds and numbers are rather arbitraty and based on experience 
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
    % find indices where x-values are multiples of the interval
    x_round = round(x_vals*20)/20;          % round to two decimals for next line
    idx = mod(x_round/tick_ival,1) == 0;         
    vec = x_vals(idx);      % x-values for ticks
    if isempty(vec) || numel(vec) == 1
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
    % processing time shorter than intervall -> create ticks for first and
    % last place
    i_1 = 1;
    vec = [x_vals(i_1), x_vals(end)];
    txt = [x_vals(i_1), length(x_vals)];
    if obs_ival > 15 && x_vals(end)-x_vals(1) > 300
         % observation interval > 15 and more than 5 minutes processed
        txt = sow2hhmm(txt);    % format hh:mm
        txt = cellstr(strcat(txt,'h'));
    else
        txt = sow2hhmmss(vec);  % format hh:mm:ss
        txt = cellstr(txt);
    end
end
end