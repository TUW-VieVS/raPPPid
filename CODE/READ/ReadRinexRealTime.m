function [RINEX, fid_obs, fid_nav, fid_corr, input, obs] = ...
    ReadRinexRealTime(settings, input, obs, start_sow, q, fid_obs, fid_nav, fid_corr)
% This function prepares the input data in the case of a real-time
% processing.
%
% INPUT:
%   settings        struct, processing settings from GUI
%   input           struct, contains input data in internal formats
%   obs             struct, observation-specific data
%   start_sow       start time of real-time processing [sow]
%   q               number of current epoch
%   fid_obs, fid_nav, fid_corr
%                   fileID of RINEX, navigation message, correction stream
% OUTPUT:
%	RINEX           cell, updated with new data
%   fid_obs, fid_nav, fid_corr
%                   fileID of RINEX, navigation message, correction stream
%   input           struct, updated with new data 
%   obs             struct, updated with new data
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


global STOP_CALC
RINEX = {}; line = '';
first_print = true; l_estr = 1; gpstime = NaN;
bspace = char(8,8,8,8,8,8,8,8,8,8,8,8,8,8);

%% run to end of RINEX file and check epochheaders for starting processing
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
            % processing has already started
            break
        end 
    end
    
    % get next line
    line = fgetl(fid_obs);
    
    % check if processing was stopped
    if STOP_CALC
        break
    end
    
    % check if start of processing is reached
    if feof(fid_obs)            
        % observation data not yet here, wait for new data
        pause(obs.interval/2)
        % read navigation message and correction stream in the meantime
        [input, obs] = RealTimeEphCorr2Brdc(settings, input, obs, fid_nav, fid_corr);
        % print time until processing start to command window
        if first_print && q == 1 && round(start_sow-gpstime) > 3
            % first print to command window
            fprintf('Processing starts in [s]: ');
            estr = sprintf('%d', round(start_sow-gpstime));
            fprintf('%s', estr);
            l_estr = length(estr);
            first_print = false;
        elseif exist('gpstime','var')
            % all other prints, delete old time and print new
            estr = sprintf('%d\n', round(start_sow-gpstime));
            fprintf('%s%s', bspace(1:l_estr), estr);
            l_estr = length(estr);
        end
    end    
          
end



%% read RINEX data and prepare for RINEX2Epoch
RINEX{1,1} = line;          % save epoch header of current RINEX epoch
while true
    
    line = fgetl(fid_obs);
    
    % break the loop if the next RINEX epoch header is reached
    if line(1) == '>'
        % jump one line backwards to read this RINEX epoch header in the 
        % next epoch of PPP processing
        c = numel(line) + 2;
        fseek(fid_obs, -c, 'cof');     
        break
    end
    
    % save line with observations of current RINEX epoch
    if ~isempty(line) && ischar(line)
        RINEX{end+1,1} = line;  
    end
    
    % end of file is reached, no new observation data yet, wait for new data
    if feof(fid_obs)       
        pause(obs.interval/10)
        continue
    end
    
end


