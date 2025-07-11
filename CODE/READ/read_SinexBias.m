function [BIAS] = read_SinexBias(BIAS, path, glo_channels)
% function to read Bias-Sinex-File into raPPPid intern format
% format details: http://ftp.aiub.unibe.ch/bcwg/format/draft/sinex_bias_100.pdf
%
% INPUT: 
%   BIAS            struct to store data
%   path            string, path to Sinex-Bias-File
%   glo_channels	channels of glonass satellites, necessary if
%                   Sinex-Bias-File contains Glonass Biases and they have to
%                   be converted from [cy] to [ns]
% OUTPUT:
%   BIAS            struct, with 3 fields: DSB, OSB, ISB 
%                   these three fields are structs with fields for all GPS,  
%                   Glonass, Galileo and BeiDou satellites and every 
%                   satellite-field has 5 fields: 
%                   .value [ns]; .start [sow]; .end [sow]; .start_gpsweek;
%                   .ende_gpsweek;
% constraint: different units - only cycles are handled and converted into [ns]
% constraint: header is not read at all
%
%   Revision:
%   2025/06/02, MFWG: detect columns with header line (instead of version)
%   2023/06/11, MFWG: adding QZSS 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparation

if isempty(BIAS) 	% initialize empty variable with needed fields
    BIAS.DSB = [];      % Differential Signal Bias
    BIAS.OSB = [];      % Observable-specific Signal Bias
    BIAS.ISB = [];      % Ionosphere-free (linear combination) Signal Bias
    for i = 1:DEF.SATS_GPS        % initialization of GPS satellites
        gps_field = ['G', sprintf('%02d', i)];
        BIAS.DSB.(gps_field) = [];
        BIAS.OSB.(gps_field) = [];
        BIAS.ISB.(gps_field) = [];
    end
    for i = 1:DEF.SATS_GLO        % initialization of GPS satellites
        glo_field = ['R', sprintf('%02d', i)];
        BIAS.DSB.(glo_field) = [];
        BIAS.OSB.(glo_field) = [];
        BIAS.ISB.(glo_field) = [];
    end
    for i = 1:DEF.SATS_GAL        % initialization of Galileo satellites
        gal_field = ['E', sprintf('%02d', i)];
        BIAS.DSB.(gal_field) = [];
        BIAS.OSB.(gal_field) = [];
        BIAS.ISB.(gal_field) = [];
    end
    for i = 1:DEF.SATS_BDS        % initialization of BeiDou satellites
        bds_field = ['C', sprintf('%02d', i)];
        BIAS.DSB.(bds_field) = [];
        BIAS.OSB.(bds_field) = [];
        BIAS.ISB.(bds_field) = [];
    end
    for i = 1:DEF.SATS_QZSS      % initialization of QZSS satellites
        bds_field = ['J', sprintf('%02d', i)];
        BIAS.DSB.(bds_field) = [];
        BIAS.OSB.(bds_field) = [];
        BIAS.ISB.(bds_field) = [];
    end
end


%% Open file

if ~exist(path, 'file')
    errordlg('Sinex-Bias file does not exist!', 'ERROR');
end
fid = fopen(path);          % open file
lines = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
lines = lines{1};
fclose(fid);
no_lines = length(lines);   % number of lines of file


%% Handle header

BIAS.Header.APC_MODEL = '';
BIAS.Header.SAT_ANT_PCC_APPLIED = '';
BIAS.Header.TimeSystem = '';

% loop over header
i = 1;
bool = true;
while bool
    curr_line = lines{i};
    
    if contains(curr_line, 'TIME_SYSTEM')
        BIAS.Header.TimeSystem = strtrim(curr_line(40:end));
    end
    
    if contains(curr_line, 'APC_MODEL')
        apcmodel_string = strrep(curr_line, 'APC_MODEL', '');
        BIAS.Header.APC_MODEL = strtrim(strrep(apcmodel_string, '*', ''));
    end
    
    if contains(curr_line, 'SATELLITE_ANTENNA_PCC_APPLIED_TO_MW_LC')
        BIAS.Header.SAT_ANT_PCC_APPLIED = strtrim(curr_line(40:end));
    end
    
    if contains(curr_line, '+BIAS/SOLUTION')
        bool = false;
    end
    i = i + 1;
end             % i is now the number of the line with the header for biases (*BIAS...)



%% Detect columns of data
headerline = lines{i};      % line indicating the columns of data entries
c_spaces = find(isspace(headerline));   % columns of whitespaces

% get start and end column of relevant data entries
c_prn   = getColumn(headerline, c_spaces, 'PRN');
c_obs1  = getColumn(headerline, c_spaces, 'OBS1');
c_obs2  = getColumn(headerline, c_spaces, 'OBS2');
c_start = getColumn(headerline, c_spaces, 'BIAS_START');
c_ende  = getColumn(headerline, c_spaces, 'BIAS_END');
c_value = getColumn(headerline, c_spaces, 'ESTIMATED_VALUE');
c_unit  = getColumn(headerline, c_spaces, 'UNIT');



%% Handle data

while i < no_lines          % loop over data lines
    i = i + 1;
    curr_line = lines{i}; 	% current line
    if contains(curr_line, '%=ENDBIA') || contains(curr_line, '-BIAS/SOLUTION') || strcmp(curr_line, '*             ') || strcmp(curr_line, '*-------------') || contains(curr_line, '*BIAS')
        continue            % jump over these lines
    end
    
    bias_type = curr_line(2:4);
    if strcmpi(bias_type,'DCB')   % because DCB should actually mean DSB
        bias_type = 'DSB';
    end    
    bool_type = strcmpi(bias_type, 'DSB') || strcmpi(bias_type, 'OSB') || strcmpi(bias_type, 'ISB');
    if ~bool_type       % jump over lines which contains an unknown bias type
        continue
    end
    
    station = strtrim(curr_line(16:19));
    [prn, obs_1, obs_2, sow_start, sow_ende, value, gpsweek_start, gpsweek_ende] = ...
        read_line(curr_line, glo_channels, c_prn, c_obs1, c_obs2, c_start, c_ende, c_value, c_unit);        % get entries
    
    if contains(obs_1, '?') || contains(obs_2, '?') || (~isempty(station) && ~isvarname(station))
        % jump over lines which contains an unknown bias observable or
        % which have a station not suitable for a field (e.g., "10AN") 
        % -> the biases of such stations are ignored and not saved!
        continue       
    end
    
    if contains('GRECJ', prn(1))    % only GPS, GLONASS, Galileo, BeiDou, and QZSS are handled
        if isempty(station)
            % -) satellite entries:
            if ~isfield(BIAS.(bias_type), prn)      % check satellite-field
                BIAS.DSB.(prn) = [];
                BIAS.OSB.(prn) = [];
                BIAS.ISB.(prn) = [];
            end
            bias_field = strtrim([obs_1, obs_2]);  	% create field-name
            if ~isfield(BIAS.(bias_type).(prn), bias_field)
                BIAS.(bias_type).(prn).(bias_field) = [];         % create field for this bias
            end
            BIAS.(bias_type).(prn).(bias_field) = ...
                save_data_line(BIAS.(bias_type).(prn).(bias_field), value, round(sow_start), round(sow_ende), gpsweek_start, gpsweek_ende);
        else
            % -) station entries:
            bias_field = [prn(1), obs_1, obs_2];  	% create field-name
            bias_field(bias_field == ' ') = '';     % remove empty spaces
            if ~isfield(BIAS.(bias_type), station)
                BIAS.(bias_type).(station) = [];                % create field for this station
            end
            if ~isfield(BIAS.(bias_type).(station), bias_field)
                BIAS.(bias_type).(station).(bias_field) = []; 	% create field for this bias
            end
            BIAS.(bias_type).(station).(bias_field) = ...
                save_data_line(BIAS.(bias_type).(station).(bias_field), value, round(sow_start), round(sow_ende), gpsweek_start, gpsweek_ende);
        end
    end
    
end

end         % end of read_SinexBias



%% Auxialiary Functions
function [col] = getColumn(headerline, c_spaces, keyword)
% Detects the start and end column of a specific entry in the data block
pos = strfind(headerline, keyword);
a = c_spaces(c_spaces <= pos);
e = c_spaces(c_spaces >= pos);
col(1) = a(end);
col(2) = e(1);
end



function [BiaStruct] = save_data_line(BiaStruct, value, sow_start, sow_ende, gpsweek_start, gpsweek_ende)
% save values from one data line if there is a difference in bias value to
% the last entry in the struct

if isempty(BiaStruct)                       % first call  
    BiaStruct.value(1)         = value;
    BiaStruct.start(1)         = sow_start;
    BiaStruct.ende(1)          = sow_ende;
    BiaStruct.start_gpsweek(1) = gpsweek_start;
    BiaStruct.ende_gpsweek(1)  = gpsweek_ende;
    return
end
if BiaStruct.value(end) == value  	
    % bias value is the same as last entry
    BiaStruct.ende(end) = sow_ende;         % extend validity
    if BiaStruct.ende_gpsweek(end) ~= gpsweek_ende      
        % data of Sinex BIAS file runs over day and gps week
        BiaStruct.ende_gpsweek(end) = gpsweek_ende;
    end
else                                        % save new bias
    BiaStruct.value(end+1)         = value; 
    BiaStruct.start(end+1)         = sow_start;
    BiaStruct.ende(end+1)          = sow_ende;
    BiaStruct.start_gpsweek(end+1) = gpsweek_start;
    BiaStruct.ende_gpsweek(end+1)  = gpsweek_ende;
end
end


function [prn, obs_1, obs_2, sow_start, sow_ende, value, week_start, week_ende] = ...
    read_line(curr_line, glo_channels, c_prn, c_obs1, c_obs_2, c_start, c_ende, c_value, c_unit)
% function to read data from one line and convert date

prn = strtrim(curr_line(c_prn(1):c_prn(2)));   % prn of current line

% extract data of current line
obs_1 = strtrim(curr_line(c_obs1(1) :c_obs1 (2))); 	% observation type 1, string
obs_2 = strtrim(curr_line(c_obs_2(1):c_obs_2(2))); 	% observation type 2, string
start = strtrim(curr_line(c_start(1):c_start(2)));  % start time of bias correction
ende  = strtrim(curr_line(c_ende(1) :c_ende (2)));  % end time of bias correction
value = sscanf(strtrim(curr_line(c_value(1):c_value(2))),'%f');     % value of bias
unit  = strtrim(curr_line(c_unit(1):c_unit(2)));          % unit of bias


% check and correct if year is only in 2-digit format
if ~strcmp(start(1:2), '20')
    start = ['20' start];
end
if ~strcmp(ende(1:2), '20')
    ende = ['20' ende];
end

% convert from [cycles] to [ns]
% ||| implemented only for OSB!!!!
if strcmp(unit, 'cyc')
    switch prn(1)
        case 'G'
            frqs = DEF.freq_GPS_names;
            wavelengths = Const.GPS_L;
            idx_frq = strcmp(obs_1(1:2), frqs);
            lambda = wavelengths(idx_frq);
            
        case 'R'
            channel = glo_channels(str2double(prn(2:3)));
            switch obs_1(2)
                case '1'        % Glonass G1 frequency
                    frq = Const.GLO_F1;
                    coeff = Const.GLO_k1;
                case '2'        % Glonass G2 frequency
                    frq = Const.GLO_F2;
                    coeff = Const.GLO_k2;
                case '3'      	% Glonass G3 frequency
                    frq = Const.GLO_F3;
                    coeff =  Const.GLO_k3;      % = 0, because of CMDA
            end
            frq = frq + channel * coeff  * 1e6;
            lambda = Const.C / frq;
            
        case 'E'
            frqs = {'L1'; 'L5'; 'L7'; 'L8'; 'L6'};
            wavelengths = Const.GAL_L;
            idx_frq = strcmp(obs_1(1:2), frqs);
            lambda = wavelengths(idx_frq);
            
        case 'C'
            if strcmp(obs_1(1:2), 'L1')
                obs_1(1:2) = 'L2';      % when reading a Rinex 3 file both L1x and L2x are L2x
            end
            frqs = {'L2'; 'L7'; 'L6';};
            wavelengths = Const.BDS_L;
            idx_frq = strcmp(obs_1(1:2), frqs);
            lambda = wavelengths(idx_frq);

        case 'J'
            frqs = {'L1'; 'L2'; 'L5'; 'L6'};
            wavelengths = Const.QZSS_L;
            idx_frq = strcmp(obs_1(1:2), frqs);
            lambda = wavelengths(idx_frq);

    end
    
    value = value * lambda / Const.C * 10^9;    % from [cycles] to [ns]
    
end


% convert start-date to sow
yyyy_1  = sscanf(start(1:4), '%f');
doy_1 = sscanf(start(6:8), '%f');
sod_1 = sscanf(start(10:14), '%f');
jd_1 = doy2jd_GT(yyyy_1, doy_1 + sod_1/86400);
[week_start, sow_start, ~] = jd2gps_GT(jd_1);       % seconds of week and gps week of bias start
% convert end-date to sow
yyyy_2  = sscanf(ende(1:4), '%f');
doy_2 = sscanf(ende(6:8), '%f');
sod_2 = sscanf(ende(10:14), '%f');
jd_2 = doy2jd_GT(yyyy_2, doy_2 + sod_2/86400);
[week_ende, sow_ende, ~] = jd2gps_GT(jd_2);             % seconds of week and gps week of bias end
sow_ende = sow_ende + (week_ende-week_start)*604800;     % handle week jump-over

end