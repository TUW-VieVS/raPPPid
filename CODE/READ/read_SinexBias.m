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
%   2023/06/11, MFWG: adding QZSS 
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Check the SINEX version
% because the file format is anything but consistent

% for default if consecutive entries in the Sinex-Bias file have the same
% value the validity is extended but for certain products this might not
% working later-on as the number of entries is manipulated in this way
bool_extend = true;

version = 'Bias-SINEX';         % initialization
[~,name,~] = fileparts(path); 
if contains(name,'CAS0MGXRAP')   % if CAS
    
    if str2num(name(12:18)) > 2016262   % starting in Sep 19, 2016, the file are in Bias-SINEX format (before the format was simply SINEX) 
        version = 'Bias-SINEX';
    else
        version = 'SINEX';
    end
    
elseif contains(name,'DLR0MGXFIN')   % if DLR
    
    bool_extend = false;
    if strcmpi(name,'DLR0MGXFIN_20160010000_03L_01D_DCB')   % the first seasonal file exists in 2016, which is in SINEX format
        version = 'SINEX';
    elseif str2num(name(12:15)) < 2017   % after that, the Bias-SINEX file was invented, however with some format errors, which is why it is referred to as temporary
        version = 'Bias-SINEX_temp';
    else   % starting in 2017, the files are in normal Bias_SINEX format
        version = 'Bias-SINEX';
    end
    
elseif contains(name, 'com')
    version = 'SINEX';
    
end


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
        read_line(curr_line, version, glo_channels);        % get entries
    
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
                save_data_line(BIAS.(bias_type).(prn).(bias_field), value, round(sow_start), round(sow_ende), gpsweek_start, gpsweek_ende, bool_extend);
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
                save_data_line(BIAS.(bias_type).(station).(bias_field), value, round(sow_start), round(sow_ende), gpsweek_start, gpsweek_ende, bool_extend);
        end
    end
    
end

end         % end of read_SinexBias



%% Auxialiary Functions

function [BiaStruct] = save_data_line(BiaStruct, value, sow_start, sow_ende, gpsweek_start, gpsweek_ende, extend_validity)
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
if extend_validity && BiaStruct.value(end) == value  	
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
    read_line(curr_line, version, glo_channels)
% function to read data from one line and convert date

prn = curr_line(12:14);   % prn of current line

if strcmpi(version,'Bias-SINEX')
    
    obs_1 = curr_line(26:28);           % observation type 1, string
    obs_2 = curr_line(31:33);           % observation type 2, string
    start = curr_line(36:49);
    ende  = curr_line(51:64);
    value = sscanf(curr_line(70:91),'%f');
    unit  = strtrim(curr_line(65:69));
    
elseif strcmpi(version,'Bias-SINEX_temp')
    
    obs_1 = curr_line(26:28);           % observation type 1, string
    obs_2 = curr_line(31:33);           % observation type 2, string
    start = ['20' curr_line(36:47)];    % prepend '20' as the year is specified only by yy in the Bias-SINEX_temp file
    ende  = ['20' curr_line(49:60)];    % prepend '20' as the year is specified only by yy in the Bias_SINEX_temp file
    value = sscanf(curr_line(67:87),'%f');
    % ||| unit!
    
elseif strcmpi(version,'SINEX')
    
    obs_1 = curr_line(31:33);           % observation type 1, string
    obs_2 = curr_line(36:38);           % observation type 2, string
    start = ['20' curr_line(41:52)];    % prepend '20' as the year is specified only by yy in the SINEX file
    ende  = ['20' curr_line(54:65)];    % prepend '20' as the year is specified only by yy in the SINEX file
    value = sscanf(curr_line(72:92),'%f');
    unit  = strtrim(curr_line(67:69));
    
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