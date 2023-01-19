function string = sow2hhmmss(sow)
% conversion of seconds of week into format hh:mm:ss as string
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

n = length(sow);
for i = 1:n
    sod = mod(sow(i),86400);
    hour = floor(sod/3600);
    min = round(floor(mod(sod,3600))/60);
    while min >= 60
        hour = hour + 1;
        min = min - 60;
    end
    sec = round(mod(sod,60));
    hh = sprintf('%02d', hour);
    mm = sprintf('%02d', min);
    ss = sprintf('%02d', sec);
    string(i,:) = strcat(hh, ':', mm, ':', ss);
end