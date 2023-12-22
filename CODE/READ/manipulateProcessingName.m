function [settings] = manipulateProcessingName(settings)
% manipulateProcessingName makes sure that the beginning of the processing
% name consists of the chars of the processed GNSS e.g. if GPS and Beidou
% are processed the processing name should start with "GC-"
% 
% INPUT:
%   settings    struct, processing settings
% OUTPUT:
%   settings    struct, updated with correct processing name
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% to keep the processing name as it is in the GUI: save it
settings.PROC.name_GUI = settings.PROC.name;        

% replace some specific chars
settings.PROC.name = strrep(settings.PROC.name, '\', '/');      % replace "wrong" slashes
settings.PROC.name = strrep(settings.PROC.name, '_', '-');      % replace underline slashes


%% check for GNSS chars at the beginning of the processing name
gnss_str = '';
if settings.INPUT.use_GPS; gnss_str = [gnss_str 'G']; end
if settings.INPUT.use_GLO; gnss_str = [gnss_str 'R']; end
if settings.INPUT.use_GAL; gnss_str = [gnss_str 'E']; end
if settings.INPUT.use_BDS; gnss_str = [gnss_str 'C']; end
if settings.INPUT.use_QZSS;gnss_str = [gnss_str 'J']; end
gnss_str_ = [gnss_str '-'];
if ~isempty(settings.PROC.name) && ~contains(settings.PROC.name, '$gnss')
    if  ~contains('GREC', settings.PROC.name(1))    % GNSS chars are not existing, add them
        settings.PROC.name = [gnss_str_ settings.PROC.name];
    else    % check if GNSS chars are correct, if necessary change them
        idx_ = strfind(settings.PROC.name, '-');
        idx__ = strfind(settings.PROC.name, '/');
        if isempty(idx_);   idx_ = 0;   end
        if ~strcmp(gnss_str_, settings.PROC.name(1:idx_(1)))
            if ~isempty(idx__) && idx__(1) < idx_(1)
                settings.PROC.name = [gnss_str_ settings.PROC.name];
            else
                settings.PROC.name(1:idx_(1)) = '';
                settings.PROC.name = [gnss_str_ settings.PROC.name];
            end
        end
    end
end


%% replace pseudo-code
if contains(settings.PROC.name, '$')
    proc_name = settings.PROC.name;
    rheader = anheader_GUI(settings.INPUT.file_obs);    % get information about observation file
    rheader = analyzeAndroidRawData_GUI(settings.INPUT.file_obs, rheader);
    if isempty(rheader.station);    rheader.station  = 'none';      end
    if isempty(rheader.receiver);  	rheader.receiver = 'none';      end
    if isempty(rheader.interval);  	rheader.interval = 'none';      end
    % replace station
    proc_name = strrep(proc_name, '$stat', rheader.station);     
    % replace receiver
    proc_name = strrep(proc_name, '$rec', rheader.receiver);     
    % replace observation interval
    proc_name = strrep(proc_name, '$int', sprintf('%03.0f', rheader.interval));  
    % reaplace date pseudo-code
    [proc_name, ~] = ConvertStringDate(proc_name, rheader.first_obs(1:3));
    % replace processed gnss
    proc_name = strrep(proc_name, '$gnss', gnss_str);
    % replace number of input frequencies
    [num_freqs, ~] = CountProcessedFrequencies(settings);
    proc_name = strrep(proc_name, '$f', sprintf('%1.0f', num_freqs));
    % insert ionosphere model of processing
    if contains(proc_name, '$iono')
        switch settings.IONO.model
            case '2-Frequency-IF-LCs'
                iono_str = 'iflc';
            case '3-Frequency-IF-LC'
                iono_str = '3iflc';
            case 'Estimate with ... as constraint'
                iono_str = 'constr';
            case 'Correct with ...'
                iono_str = 'corr';
            case 'off'
                iono_str = 'off';
            case 'Estimate'
                iono_str = 'est';
        end
        proc_name = strrep(proc_name, '$iono', iono_str);
    end
    % save new manipulated version of processing name
    settings.PROC.name = proc_name;
end