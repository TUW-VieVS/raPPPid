function [RINEX, fid_obs, fid_nav, fid_corr, input, obs, t_RT_start] = ...
    ReadRinexRealTime(settings, input, obs, start_sow, q, fid_obs, fid_nav, fid_corr, t_RT_start)
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
%   t_RT_start      uint64, recorded when the real-time processing started
% OUTPUT:
%	RINEX           cell, updated with new data
%   fid_obs, fid_nav, fid_corr
%                   fileID of RINEX, navigation message, correction stream
%   input           struct, updated with new data
%   obs             struct, updated with new data
%   t_RT_start      uint64, recorded when the real-time processing started
%
% Revision:
%   2025/08/14, MFWG: switch to cal2gpstime
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
        lvalues = textscan(line,'%*c %f %f %f %f %f %f %d %2d %f');
        % convert date into gps-time [sow]
        [~, gpstime] = cal2gpstime([lvalues{1}, lvalues{2}, lvalues{3}, lvalues{4}, lvalues{5}, lvalues{6}]);
        
        if start_sow <= gpstime
            % no more waiting necessary -> go to epoch-wise processing
            break
        end
    end

    % get next line
    line = fgetl(fid_obs);
    
    % check user stopped processing
    if STOP_CALC
        break
    end
    
    % check if start of processing is reached
    if feof(fid_obs)            
        % observation data not yet here, wait for new data
        pause(obs.interval/2)
        % read navigation message and correction stream in the meantime
        [input, obs] = RealTimeEphCorr2Brdc(settings, input, obs, fid_nav, fid_corr);
        % print time until processing start to command window (only
        % relevant for q == 1 when waiting for the configured start time)
        if q == 1
            if first_print && round(start_sow-gpstime) > 3
                % first print to command window
                fprintf('Processing starts in [s]: ');
                estr = sprintf('%d', round(start_sow-gpstime));
                fprintf('%s', estr);
                l_estr = length(estr);
                first_print = false;
            elseif ~first_print
                % all other prints, delete old time and print new 
                estr = sprintf('%d', round(start_sow-gpstime));
                fprintf('%s%s', bspace(1:l_estr), estr);
                l_estr = length(estr);
            end
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


%% wait until this epoch has aged

if q == 1
    % save start time of epoch-wise processing for the delay in the
    % real-time processing
    t_RT_start = tic;    
end

% gives the (slower) SSR correction stream time to catch up before this
% epoch's data is handed off for processing.
elapsed = (gpstime - start_sow) + DEF.RT_buffer;     % processed epochs + delay

% check if processed epochs + delay is larger than elapsed time since processing start
while elapsed > toc(t_RT_start)
    if STOP_CALC
        break       % user stopped the processing from the GUI
    end
    pause(obs.interval/10)
    [input, obs] = RealTimeEphCorr2Brdc(settings, input, obs, fid_nav, fid_corr);   
end


 