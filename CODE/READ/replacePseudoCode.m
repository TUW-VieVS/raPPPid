function [rplcd] = replacePseudoCode(settings, proc_name, bool_gnss_chars)
% This functions makes sure that, for example, at the beginning of the 
% processing name the processing name consists of the chars of the 
% processed GNSS (e.g., if GPS and Beidou are processed the processing name
% should start with "GC-"). Furthermore, this function replaced pseudo-code
% within the provided string with the correct values (e.g., $rec might be 
% replaced by "SEPT POLARX5        ")
% 
% INPUT:
%   settings    struct, processing settings
%   proc_name   string, name of processing (e.g., from GUI)
% OUTPUT:
%   rplcd       string, correct processing name, pseudo-code replaced
% 
% Revision:
%   2025/120222, MFWG: change in/output to make function more flexible
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

  

% replace some specific chars
rplcd = strrep(proc_name, '\', '/');    % replace "wrong" slashes
rplcd = strrep(rplcd, '_', '-');        % replace underline slashes


%% check for GNSS chars at the beginning of the processing name
gnss_str = '';
if settings.INPUT.use_GPS; gnss_str = [gnss_str 'G']; end
if settings.INPUT.use_GLO; gnss_str = [gnss_str 'R']; end
if settings.INPUT.use_GAL; gnss_str = [gnss_str 'E']; end
if settings.INPUT.use_BDS; gnss_str = [gnss_str 'C']; end
if settings.INPUT.use_QZSS;gnss_str = [gnss_str 'J']; end
gnss_str_ = [gnss_str '-'];
if bool_gnss_chars && ~isempty(rplcd) && ~contains(rplcd, '$gnss')
    if  ~contains('GREC', rplcd(1))    % GNSS chars are not existing, add them
        rplcd = [gnss_str_ rplcd];
    else    % check if GNSS chars are correct, if necessary change them
        idx_ = strfind(rplcd, '-');
        idx__ = strfind(rplcd, '/');
        if isempty(idx_);   idx_ = 0;   end
        if ~strcmp(gnss_str_, rplcd(1:idx_(1)))
            if ~isempty(idx__) && idx__(1) < idx_(1)
                rplcd = [gnss_str_ rplcd];
            else
                rplcd(1:idx_(1)) = '';
                rplcd = [gnss_str_ rplcd];
            end
        end
    end
end


%% replace pseudo-code
if contains(rplcd, '$')
    
    % preparations
    pseudo = rplcd;
    rheader = anheader_GUI(settings.INPUT.file_obs);    % get information about observation file
    rheader = analyzeAndroidRawData_GUI(settings.INPUT.file_obs, rheader);
    if isempty(rheader.station);    rheader.station  = 'none';      end
    if isempty(rheader.receiver);  	rheader.receiver = 'none';      end
    if isempty(rheader.interval);  	rheader.interval = 'none';      end

    % replace raPPPid version
    pseudo = strrep(pseudo, '$ver', DEF.ver);         
    
    % replace station
    pseudo = strrep(pseudo, '$stat', rheader.station);     
    
    % replace station (long name)
    pseudo = strrep(pseudo, '$statl', rheader.station_long);

    % replace receiver
    pseudo = strrep(pseudo, '$rec', strtrim(rheader.receiver));   

    % replace antenna
    pseudo = strrep(pseudo, '$ant', strtrim(rheader.antenna));       
    
    % replace observation interval
    pseudo = strrep(pseudo, '$int', sprintf('%03.0f', rheader.interval));  
    
    % replace date pseudo-code
    [pseudo, ~] = ConvertStringDate(pseudo, rheader.first_obs(1:3));
    
    % replace processed gnss
    pseudo = strrep(pseudo, '$gnss', gnss_str);
    
    % replace number of input frequencies
    [num_freqs, ~] = CountProcessedFrequencies(settings);
    pseudo = strrep(pseudo, '$f', sprintf('%1.0f', num_freqs));
    
    % insert ionosphere model of processing
    if contains(pseudo, '$iono')
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
            case 'Estimate, decoupled clock'
                iono_str = 'dcm';
            case 'GRAPHIC'
                iono_str = 'graphic';                
        end
        pseudo = strrep(pseudo, '$iono', iono_str);
    end
    
    % insert filter direction
    if contains(pseudo, '$dir')
        switch settings.ADJ.filter.direction
            case 'Forwards'
                dir_str = 'fwd';
            case 'Fwd-Bwd'
                dir_str = 'fwd-bwd';
			case 'Forwards + RTS'
				dir_str = 'fwd-RTS';
            case 'Bwd-Fwd'
                dir_str = 'bwd-fwd';
            case 'Backwards'
                dir_str = 'bwd';
            otherwise
                dir_str = '';
        end
        pseudo = strrep(pseudo, '$dir', dir_str);
    end
    
    % insert real-time or postprocessed
    rt_pp = 'pp';
    if settings.INPUT.bool_realtime; rt_pp = 'rt'; end
    pseudo = strrep(pseudo, '$rt', rt_pp);     
    
    % save new manipulated version of processing name
    rplcd = pseudo;
end