function [Epoch] = RINEX2Epoch(RINEX, epochheader, Epoch, n, ...
    no_obs_types, r_version, settings)
% This function is called at the beginning of the epoch-wise calculation. 
% It gets all data from the RINEX file for the current epoch and saves it 
% in the struct Epoch
% 
% INPUT:
%   RINEX           cell, content of RINEX-observation-file (without header-lines)
%   epochheader     vector, number of lines where header occurs
%   Epoch           struct, epoch-specific data for current epoch
%   n               epoch of RINEX-observation-file which should be treated 
%   no_obs_types	total number of observation types for [GPS, GLO, GAL, BDS, QZSS]
%   r_version       RINEX-version
%   settings        struct, processing settings from GUI
% OUTPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   eof             boolean, true if end of file is reached
%  
%   Revision:
%   2023/11/03, MFWG: adding QZSS
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Preparations
checkLLI = settings.PROC.LLI;
use_GPS  = settings.INPUT.use_GPS;
use_GLO  = settings.INPUT.use_GLO;
use_GAL  = settings.INPUT.use_GAL;
use_BDS  = settings.INPUT.use_BDS;
use_QZSS = settings.INPUT.use_QZSS;


% Find relevant data
if ~settings.INPUT.bool_realtime
    % post-processing
    strt = epochheader(n);              % no. line epoch-header current epoch
    try
        ende = epochheader(n+1);        % no. line epoch-header next epoch
    catch
        ende = length(RINEX) + 1;       % one line after the end of the RINEX
    end
    epoch_header = RINEX{strt};      	% epoch-header of current epoch
    data_epoch = RINEX(strt+1:ende-1); 	% data-lines of current epoch
else
    % real-time processing
    epoch_header = RINEX{1};
    data_epoch = RINEX(2:end);
end
lgth_epoch = length(data_epoch);  	% no. lines of current epoch


if r_version == 2
    %% RINEX 2.x
    % --------- EPOCH HEADER ----------
    % linvales = year (2-digit) | month | day | hour | min | sec | epoch flag |
    %            string with satellites (e.g. 'G30G13G 2R 5E22J 7')
    linvalues = textscan(epoch_header,'%f %f %f %f %f %f %d %2d%s','delimiter',',');
    
    % convert date into gps-time [sow]
    h = linvalues{4} + linvalues{5}/60 + linvalues{6}/3600;             % fractional hour
    jd = cal2jd_GT(2000+linvalues{1}, linvalues{2}, linvalues{3} + h/24); % julian date
    mjd = jd-2400000.5;                                                 % modified Julian date
    [gps_week, gps_time, ~] = jd2gps_GT(jd);                           	% gps-time [sow] and gps-week 
        
    % check if epoch is usable
    usable = true;
    if strcmp(epoch_header(29),'0') ~= 1 
        usable = false;
    end
    
    % get number of observed satellites in current epoch
    No_Sv = linvalues{8};
    
    epoch_sats = linvalues{9}{1};       % only string with satellites
    if length(epoch_sats) > 36          % make sure only satellites are in string    
        epoch_sats = epoch_sats(1:36);        
    end
    if No_Sv > 12          	% multi line epoch-header
        handled_sv = 12;   	% each line contains 12 prns
        while No_Sv > handled_sv
            epoch_sats_2 = data_epoch{1};           % get 2nd line of header
            epoch_sats_2 = epoch_sats_2(33:end);    % remove empty spaces
            epoch_sats = strcat(epoch_sats, epoch_sats_2);  % add prns from current line
            data_epoch = data_epoch(2:end);     	% remove 2nd line of header from the epoch data lines
            handled_sv = handled_sv + 12;
        end
    end
    epoch_sats = strrep(epoch_sats,' ','0');  	% replace empty spaces with zero
    % create logical vectors
    sys = epoch_sats(1:3:end);                  % get system identifier
    is_gps = (sys' == 'G');
    is_glo = (sys' == 'R');
    is_gal = (sys' == 'E');                     % (Galileo does not exist in RINEX 2)
    is_bds = (sys' == 'C');                     % (BeiDou does not exist in RINEX 2)
    is_other = ~is_gps&~is_glo&~is_gal&~is_bds; % (other GNSS don´t exist in RINEX 2)
    % get satellite numbers
    sats = [epoch_sats(2:3:end)', epoch_sats(3:3:end)'];
    sats = str2num(sats);                       % str2num is slow but exclusively works here
    sats(is_glo) = sats(is_glo) + 100;
    sats(is_gal) = sats(is_gal) + 200;
    sats(is_bds) = sats(is_bds) + 300;

    % check for receiver clock offset is not implemented
    
    % --------- EPOCH DATA ----------
    no_lines = ceil(no_obs_types(1)/5);         % probably ceil(max(No_Obs)/5)
    OBS = NaN(No_Sv, no_obs_types(1));
    LLI_bit = zeros(No_Sv, no_obs_types(1));
    ss_digit = zeros(No_Sv, no_obs_types(1));
    MAX_LINE_LENGTH = 80;
    for i_SV = 1:No_Sv
        lines = [];
        for i = 1:no_lines      % loop to put together multiline records and fill it up with empty spaces
            line_temp = data_epoch{(i_SV-1)*no_lines + i};
            if isempty(line_temp)
                line_temp(1:MAX_LINE_LENGTH)=' ';
            else
                line_temp(end+1:MAX_LINE_LENGTH)=' ';
            end
            lines = [lines, line_temp];
        end             % end of loop over number of lines
        sat_data = textscan(lines, '%14c%1c%1c', no_obs_types(1), 'Whitespace', '');
        % observation value
        values = cellstr(sat_data{1});
        values(strcmp(values,''))={'NaN'};   	% replace missing observations with zero
        values = sscanf(cell2mat(values'), '%f');
        values(values==0) = NaN;                % necessary to replace zero observations from Rinex file
        OBS(i_SV,:) = values;
        % LLI bit
        values = cellstr(sat_data{2});
        values(strcmp(values,''))={'0'};     	% replace missing LLI with zero
        values = sscanf(cell2mat(values), '%1f');
        LLI_bit(i_SV,:) = values;
        % signal strength value (interval 1-9, 0 = not known)
        values = cellstr(sat_data{3});
        values(strcmp(values,''))={'0'};    	% replace missing signal strength with zero
        values = sscanf(cell2mat(values), '%1f');
        ss_digit(i_SV,:) = values;    
    end
    

elseif r_version == 3 || r_version == 4
    %% RINEX 3.x
    % --------- EPOCH HEADER ----------
    % linvalues = year | month | day | hour | minute | second |
    %             Epoch flag | number of observed satellites| empty |
    %             receiver clock offset
    linvalues = textscan(epoch_header,'%*c %f %f %f %f %f %f %d %2d %f');
    
    % convert date into gps-time [sow]
    h = linvalues{4} + linvalues{5}/60 + linvalues{6}/3600;             % fractional hour
    jd = cal2jd_GT(linvalues{1}, linvalues{2}, linvalues{3} + h/24);    % Julian date
    mjd = jd-2400000.5;                                                 % modified Julian date
    [gps_week, gps_time,~] = jd2gps_GT(jd);                             % gps-time [sow] and gps-week 
    gps_time = double(gps_time);     	
    
    % check if epoch is usable or number of satellites is zero
    usable = true;
    if isempty(linvalues{7}) || isempty(linvalues{8}) || linvalues{7} ~= 0 || linvalues{8} == 0 || isempty(data_epoch)
        % Epoch header says that epoch flag is not zero/OK or number of 
        % satellites = 0 or no data 
        Epoch.gps_time = gps_time;
        Epoch.usable = false;
        return
    end
    
    % get number of observed satellites
    no_Obs = linvalues{8};          % number of observed satellites in current epoch
    
%     % check for receiver clock offset
%     rx_offset = 0;                              % receiver clock offset
%     if ~isempty(linvalues{9})
%         rx_offset = linvalues{9};
%     end    
        
    % no_obs:       vector, number of observation types for [GPS, Glonass, Galileo]
    setlength = 16;         % in RINEX 3.x every observation has 16 spaces
    OBS = NaN(no_Obs, max(no_obs_types));
    LLI_bit = zeros(no_Obs, max(no_obs_types));
    ss_digit = zeros(no_Obs, max(no_obs_types));
    
    % --------- EPOCH DATA ----------
    
    % remove potentially empty lines (e.g., Google Smartphone Competition 2022)
    emptyCells = cellfun(@isempty,data_epoch);
    if any(emptyCells)
        fprintf('Empty line(s) in epoch %d                \n', n);
        data_epoch(emptyCells) = [];        % otherwise "get system identifier" fails
        lgth_epoch = length(data_epoch);  	% update length of epoch
    end
    
    sys = cellfun( @(a) a(1,1), data_epoch);  	% get system identifier
    % logical vectors
    is_gps  = (sys == 'G');                          
    is_glo  = (sys == 'R');
    is_gal  = (sys == 'E');
    is_bds  = (sys == 'C');
    is_qzss = (sys == 'J');
    is_other = ~is_gps & ~is_glo & ~is_gal & ~is_bds & ~is_qzss;
    % get satellite numbers and convert them to raPPPid notation
    sats = [cellfun( @(a) a(1,2), data_epoch), cellfun( @(a) a(1,3), data_epoch)];
    sats = str2num(sats);                       % str2num is slow but exclusively works here
    sats(is_glo)  = sats(is_glo)  + 100;
    sats(is_gal)  = sats(is_gal)  + 200;
    sats(is_bds)  = sats(is_bds)  + 300;
    sats(is_qzss) = sats(is_qzss) + 400;
    % create boolean vector for GNSS satellites which are processed and so
    % their observations should be extracted
    extract = use_GPS .* is_gps | use_GLO .* is_glo | use_GAL .* is_gal | use_BDS .* is_bds | use_QZSS .* is_qzss;
    
    
    for i_SV = 1:lgth_epoch            	% loop over the lines of current epoch
        if extract(i_SV)                    % improves performances a lot
            % ||| change to textscan at some point -> maybe faster?!
            line = data_epoch{i_SV};        % current line as string
            obsis = is_gps(i_SV)*no_obs_types(1) + is_glo(i_SV)*no_obs_types(2) + is_gal(i_SV)*no_obs_types(3) + is_bds(i_SV)*no_obs_types(4) + is_qzss(i_SV)*no_obs_types(5) + is_other(i_SV)*max(no_obs_types);
            line = line(4:end);             % remove beginning of line
            line(end+1:max(obsis)*setlength)=' ';       % fill line with empty spaces for missing observations at the end
            
            for j = 1:obsis            % loop over number of observations
                lines = line((j-1)*setlength+1 : j*setlength);  % cut observation from string
                
                % observation
                obs_value = sscanf(lines(1:14), '%f');
                if numel(obs_value) == 1 	% e.g. R103 (numel=2), checks also if empty (numel=0)
                    OBS(i_SV,j) = obs_value;
                end
                
                % signal strength, check RINEX 3.03 p.22
                sig_str = sscanf(lines(end), '%f'); 
                if ~isempty(sig_str)
                    ss_digit(i_SV,j) = sig_str;
                end
                
                % loss of lock indicator, check RINEX 3.03 A13
                if checkLLI
                    LLI = sscanf(lines(end-1), '%f');           
                    if ~isempty(LLI) && LLI == 1 	% only LLI == 1 is considered (e.g. LHAZ 001/2020, LLI = 4)
                        LLI_bit(i_SV,j) = LLI;
                    end
                end

            end
        end
    end
end


% save results in Epoch
Epoch.obs = OBS;
Epoch.LLI_bit_rinex = LLI_bit;
Epoch.ss_digit_rinex = ss_digit;
Epoch.gps_time = gps_time;
Epoch.gps_week = gps_week;
Epoch.mjd = mjd;
Epoch.sats = sats;
Epoch.gps  = is_gps;
Epoch.glo  = is_glo;
Epoch.gal  = is_gal;
Epoch.bds  = is_bds;
Epoch.qzss = is_qzss;
Epoch.other_systems = is_other;
Epoch.usable = usable;
Epoch.rinex_header = epoch_header;
