function [RINEX, fid_obs, fid_navmess, fid_corr2brdc, input, obs] = ...
    ReadRinexRealTime(settings, input, obs, start_sow, fid_obs, fid_navmess, fid_corr2brdc)
% This function prepares the input data in the case of a real-time
% processing.
%
% INPUT:
%   ...
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


global STOP_CALC
RINEX = {}; line = '';


% run to end of RINEX file and check epochheaders for starting processing
while true
    
    if ~isempty(line) && line(1) == '>'
        % new observation record, check time
        linvalues = textscan(line,'%*c %f %f %f %f %f %f %d %2d %f');
        % convert date into gps-time [sow]
        h = linvalues{4} + linvalues{5}/60 + linvalues{6}/3600;             % fractional hour
        jd = cal2jd_GT(linvalues{1}, linvalues{2}, linvalues{3} + h/24);    % Julian date
        [~, gps_time,~] = jd2gps_GT(jd);                             % gps-time [sow] and gps-week
        gpstime = double(gps_time);
        
        if start_sow <= gpstime
            % processing start time reached
            break
        end 
    end
    
    % get next line
    line = fgetl(fid_obs);
    
    % check if processing was stopped
    if STOP_CALC
        break
    end
    
    % check if processing start is already reached
    if feof(fid_obs)
        % observation data not yet here, wait for new data
        pause(obs.interval)
        % read navigation message and correction stream in the meantime
        [input, obs] = RealTimeEphCorr2Brdc(settings, input, obs, fid_navmess, fid_corr2brdc);
        
    end    
          
end



% read RINEX data and prepare for RINEX2Epoch
RINEX{1,1} = line;
while true
    line = fgetl(fid_obs);
    if line(1) == '>'       % break loop if next epoch
        break
    end
    if feof(fid_obs)        % no observation data yet, wait for new data
        pause(obs.interval/10)
        continue
    end
    RINEX{end+1,1} = line;
end


