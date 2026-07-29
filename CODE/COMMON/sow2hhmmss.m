function string = sow2hhmmss(sow)
% conversion of seconds of week into format hh:mm:ss as string
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

n = length(sow);
for i = 1:n
    sod = mod(round(sow(i)), 86400);   % round once to whole sec, then cascade
    hour = floor(sod/3600);
    soh = mod(sod,3600);
    min = floor(soh/60);
    sec = mod(soh,60);
    hh = sprintf('%02d', hour);
    mm = sprintf('%02d', min);
    ss = sprintf('%02d', sec);
    string(i,:) = strcat(hh, ':', mm, ':', ss);
end