function string = sow2hhmm(sow)
% conversion of seconds of week into format hh:mm as string
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
    hh = sprintf('%02d', hour);
    mm = sprintf('%02d', min);
    string(i,:) = strcat(hh, ':', mm);
end