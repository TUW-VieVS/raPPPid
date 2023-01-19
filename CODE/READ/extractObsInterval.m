function [obs_intv] = extractObsInterval(path_file)
% Extracts the observation interval from a RINEX observation file which has
% not observation interval information in the header
%
% INPUT:
%   path_file       string, path of RINEX observation file
% OUTPUT:
%   obs_intv        observation interval
%
%   Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

obs_intv = 0;
gps_time_1 = [];
gps_time_2 = [];
epochheader_v2 = '';
fid = fopen(path_file,'rt');         % open observation-file

% loop over header
while 1
    line = fgetl(fid);          % get next line
    if (line == -1)
        break                   % end of file reached
    end
    if contains(line,'END OF HEADER')
        break                   % end of header reached
    end
    if contains(line,'RINEX VERSION / TYPE')
        version = str2double(line(6));
    end
end

% loop to get time-stamp of the first two epochs
while 1
    line = fgetl(fid);          % get next line
    if version == 2 && contains(line, epochheader_v2)
        linvalues = textscan(line,'%f %f %f %f %f %f %d %2d%s','delimiter',',');
        epochheader_v2 = line(1:12);
        % convert date into gps-time [sow]
        h = linvalues{4} + linvalues{5}/60 + linvalues{6}/3600;             % fractional hour
        jd = cal2jd_GT(2000+linvalues{1}, linvalues{2}, linvalues{3} + h/24); % julian date
        [~, gps_time, ~] = jd2gps_GT(jd);                                      % gps-time [sow]
        % save and calculate observation interval
        if isempty(gps_time_1)
            gps_time_1 = gps_time;
        else
            gps_time_2 = gps_time;
            obs_intv = gps_time_2 - gps_time_1;
            break
        end
    end
    
    if version == 3 && contains(line, '> ')
        linvalues = textscan(line,'%*c %f %f %f %f %f %f %d %2d %f');
        % convert date into gps-time [sow]
        h = linvalues{4} + linvalues{5}/60 + linvalues{6}/3600;         % fractional hour
        jd = cal2jd_GT(linvalues{1}, linvalues{2}, linvalues{3} + h/24);   % Julian date
        [~, gps_time,~] = jd2gps_GT(jd);                                   % gps-time [sow]
        % save and calculate observation interval
        if isempty(gps_time_1)
            gps_time_1 = gps_time;
        else
            gps_time_2 = gps_time;
            obs_intv = gps_time_2 - gps_time_1;
            break
        end
    end
    
end

obs_intv = round(obs_intv);        % somehow necessary

% %% print result of this function
% [~, obs_filename, ext] = fileparts(path_file);
% if obs_intv == 0
%     errordlg({ [obs_filename, ext],...
%         'No observation interval could be detected. Default: 1 sec'},...
%         'Error');
%     obs_intv = 1;
% else
%     msgbox({[obs_filename ext ':'],...
%         'No observation interval in the Rinex header. Observation interval was extracted from the first two epochs:', ...
%         [sprintf('%.1f', obs_intv) ' seconds']}, ...
%         'Information', 'help')
% end




