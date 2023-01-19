function [] = printElapsedTime(time)
% Print processing time into command window in a readable format (e.g.,
% long processing spans)
% 
% INPUT:
%   time        processing time [s]
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


fprintf('\n'); 
fprintf('Processing Time: ')

if time < 600           % print only seconds
    fprintf('%.3f seconds', time)
elseif time < 3600      % print minutes and seconds
    fprintf('%.0f minutes ', floor(time/60))
    fprintf('%.3f seconds', mod(time,60))
elseif time < 7200      % print hour, minutes, and seconds
    fprintf('%.0f hour ',   floor(time/3600))
    fprintf('%.0f minutes ', floor(mod(time,3600)/60))
    fprintf('%.3f seconds',  mod(time,60))
else                   % print hours, minutes, and seconds
    fprintf('%.0f hours ',   floor(time/3600))
    fprintf('%.0f minutes ', floor(mod(time,3600)/60))
    fprintf('%.3f seconds',  mod(time,60)) 
end

fprintf('\n'); 