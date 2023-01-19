function [UPDs_WL, UPDs_NL] = readSGGFCBs(filename)
% Function to read SGG FCBs (the Fractional Phase Biases from Wuhan
% University). They belong to the precise products of a certain analysis
% center and the unit is meters.
% 
% INPUT:
%   filename    string, path to file
% OUTPUT:
%   UPDs_WL     struct with
%       .sow        time in seconds of week
%       .UPDs       1 x sats
%   UPDs_NL   	struct with
%       .sow        vector, time in seconds of week for each epoch
%       .UPDs       matrix, epochs x sats
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% Read whole file
fid = fopen(filename,'r');
if fid < 0
    fprintf('\n!!! Wuhan Bias file not found !!!\n\n')
    return;
end
data = textscan(fid,'%s','delimiter','\n');
fclose(fid);
data = data{1};




%% WL UPDs
% Preparations
UPDs_WL.UPDs = NaN(1,450);
UPDs_WL.sow  = 0;
WL_bool = contains(data, 'COMMENT');
data_WL = data(WL_bool);
for i = 1:sum(WL_bool)      % loop over lines of WL corrections
    curr_line = data_WL{i};
    if contains(curr_line, '* ')        % epoch header
        date = sscanf(curr_line,'%*s %d %d %d %d %d %f %f');
        jd_WL = cal2jd_GT(date(1), date(2), date(3) + date(4)/24 + date(5)/1440 + date(6)/86400);
        [~, sow, ~] = jd2gps_GT(jd_WL);
        UPDs_WL.sow = sow;
    end
    if contains(curr_line, 'WL  ')
        sys = curr_line(5);
        line_WL = textscan(curr_line(6:end), '%f %f %f %f %s');
        sat = line_WL{1};
        sat = sat + 100*(sys == 'R') + 200*(sys == 'E') + 300*(sys == 'C') + 400*(sys == 'J');
        UPDs_WL.UPDs(1,sat) = line_WL{3};       % save WL value for current satellite
    end
end




%% NL UPDs
% initialize data
headers_bool = contains(data, '*') & ~contains(data, 'COMMENT');
no_epochs = sum(headers_bool);      % 96 for 15min interval a whole day
UPDs_NL.sow    = NaN(no_epochs,  1);
UPDs_NL.UPDs   = NaN(no_epochs, 450);

% find end of header
jump2line = find(contains(data,'END OF HEADER'));
% read each line
i = jump2line; ii = 0;
no_lines = length(data);
while i < no_lines
    i = i + 1;
    curr_line = data{i};                % get current line
    if contains(curr_line(1),'*')     	% epoch-header
        ii = ii + 1;
        date = sscanf(curr_line,'%*s %d %d %d %d %d %f %f');
        jd_NL = cal2jd_GT(date(1), date(2), date(3) + date(4)/24 + date(5)/1440 + date(6)/86400);
        [~, sow, ~] = jd2gps_GT(jd_NL);
        UPDs_NL.sow(ii) = sow;           % save time of epoch [sow]
    else                            	% NL bias entry
        sys = curr_line(2);
        line_NL = textscan(curr_line(3:end), '%f %f %f');
        sat = line_NL{1};
        sat = sat + 100*(sys == 'R') + 200*(sys == 'E') + 300*(sys == 'C') + 400*(sys == 'J');
        UPDs_NL.UPDs(ii,sat) = line_NL{2};       % save NL value for current satellite
    end
end
