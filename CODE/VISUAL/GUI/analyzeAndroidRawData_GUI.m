function [rheader] = analyzeAndroidRawData_GUI(sensorlog_path, rheader)
% This function reads a part of the Android raw sensor data file to
% determine important information for processing because such a file does
% not contain a header (like a RINEX file)
% Simplified version of analyzeAndroidRawData.m
%
% INPUT:
%   sensorlog_path  string, path to Android raw sensor data file
% OUTPUT:
%	rheader         struct, essential information for processing
%
% Revision:
%   2023/11/08, MFWG: adding QZSS
%   2024/01/15, MFWG: repairing missing CodeType
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if isstruct(rheader)
    % contains already data! probably a RINEX file
    return
end

fid = fopen(sensorlog_path,'rt');     	% open observation-file

% check it this is a suitable file
line = fgetl(fid);
if fid == -1 || ~strcmp(line(1), '#')
    fclose(fid);
    return
end



%% INITIALIZE
version_full = 0;
receiver_type = ''; antenna_type = ''; station = ''; station_long = '';
startdate = []; last_obs = [];     
vars_Raw = {};
% hardcode:
interval = 1;
time_system = 'GPS';
pos_approx = [0; 0; 0];
% default naming of frequency
ind_gps_freq  = [];
ind_glo_freq  = [];
ind_gal_freq  = [];
ind_bds_freq  = [];
ind_qzss_freq = [];
% some variables for each GNSS
allGNSS = false; i = 0; formatSpec = '';
bool_GPS = false; bool_GLO = false; bool_GAL = false; bool_BDS = false; bool_QZSS = false;
obstypes_gps = ''; obstypes_glo = ''; obstypes_gal = ''; obstypes_bds = ''; obstypes_qzss = '';
isGPS_L1  = false;      isGPS_L5  = false;  
isGLO_G1  = false; 
isGAL_E1  = false;      isGAL_E5a = false; 
isBDS_B1  = false;      isBDS_B2a = false;
isQZSS_L1 = false;      isQZSS_L5 = false;


%% ANALYZE
while true
    
    line = fgetl(fid);                  % get next line
    
    if feof(fid)                        % check if end of file is reached
        break
    end
    
    if contains(line, '# Version')      % detect smartphone model
        idx = strfind(line, 'Model:');
        receiver_type = line(idx+7:end);
    end
    
    if contains(line, '# Raw GNSS measurements format:')        % GPSTest (?)
        line = fgetl(fid);              % skip this line
    end
    
    if contains(line,'# Raw') || contains(line,'#   Raw')       % variables in raw data line
        header_raw_string = strrep(line,' ','');
        header_raw_string = strrep(header_raw_string,'#','');
        vars_Raw = split(header_raw_string, ',');   % cell, contains fields with variables
        formatSpec = createRawFormat(vars_Raw);
        continue        % important!
    end
    
    if contains(line,'Raw,') && ~isempty(formatSpec)
        
       line_data = textscan(line, formatSpec, 'Delimiter', ',', 'EmptyValue', NaN);
       
       if isempty(startdate)
           % detect observation startdate with first data line
           TimeNanos = line_data{strcmp(vars_Raw, 'TimeNanos')};    % extract variables
           FullBiasNanos = line_data{strcmp(vars_Raw, 'FullBiasNanos')};
           BiasNanos = line_data{strcmp(vars_Raw, 'BiasNanos')};
           ReceivedSvTimeNanos = line_data{strcmp(vars_Raw, 'ReceivedSvTimeNanos')};
           TimeOffsetNanos = line_data{strcmp(vars_Raw, 'TimeOffsetNanos')};
           % build gps time and week
           [gpsweek, gpstime] = generateGpsTimeWeek(TimeNanos, FullBiasNanos, BiasNanos, ReceivedSvTimeNanos, TimeOffsetNanos);
           % convert to julian date and then to calendar data
           start_jd = gps2jd_GT(gpsweek,gpstime);
           [startdate(1), startdate(2), dd] = jd2cal_GT(start_jd);
           startdate(3) = floor(dd);
           ss = mod(dd,1)*86400;                % decimal part of day in [s]
           startdate(4) = floor(ss/3600);       % calculate hour
           startdate(5) = mod(floor(ss/60),60); % calculate minute
           startdate(6) = mod(ss,60);           % calculate second + fractional part
           % detect leap seconds with observation startdate
           leap_sec = GetLeapSec_UTC_GPS(start_jd);
       end
       
       % check which GNSS data the file contains
       idx_gnss = line_data{strcmp(vars_Raw, 'ConstellationType')};
       CodeType = line_data{strcmp(vars_Raw, 'CodeType')};
       CarrierFrequencyHz = line_data{strcmp(vars_Raw, 'CarrierFrequencyHz')};
       if idx_gnss == 1                     % GPS
           bool_GPS = true;
           isL1 = round(CarrierFrequencyHz/1e4) == round(Const.GPS_F1/1e4);
           isL5 = round(CarrierFrequencyHz/1e4) == round(Const.GPS_F5/1e4);
           frq_char = char('1'*isL1 + '5'*isL5);
           CodeType = checkSignalType(CodeType, 'G', frq_char);
           obstypes_gps = [obstypes_gps CodeType{1}];
           isGPS_L1 = isGPS_L1 || isL1;
           isGPS_L5 = isGPS_L5 || isL5;
       elseif idx_gnss == 3                 % GLONASS
           bool_GLO = true;
           isG1 = round(CarrierFrequencyHz/1e7) == round(Const.GLO_F1/1e7);
           frq_char = char('1'*isG1);
           CodeType = checkSignalType(CodeType, 'R', frq_char);
           obstypes_glo = [obstypes_glo CodeType{1}];
           isGLO_G1 = isGLO_G1 || isG1;
       elseif idx_gnss == 6                 % Galileo
           bool_GAL = true;
           isE1  = round(CarrierFrequencyHz/1e4) == round(Const.GAL_F1/1e4);
           isE5a = round(CarrierFrequencyHz/1e4) == round(Const.GAL_F5a/1e4);
           frq_char = char('1'*isE1 + '5'*isE5a);
           CodeType = checkSignalType(CodeType, 'E', frq_char);
           obstypes_gal = [obstypes_gal CodeType{1}];
           isGAL_E1 = isGAL_E1  || isE1;
           isGAL_E5a= isGAL_E5a || isE5a;
       elseif idx_gnss == 5                 % BeiDou
           bool_BDS = true;
           isB1  = round(CarrierFrequencyHz/1e3) == round(Const.BDS_F1/1e3);
           isB2a = round(CarrierFrequencyHz/1e3) == round(Const.BDS_F2a/1e3);
           frq_char = char('1'*isB1 + '5'*isB2a);
           CodeType = checkSignalType(CodeType, 'C', frq_char);
           obstypes_bds = [obstypes_bds CodeType{1}];
           isBDS_B1  = isBDS_B1  || isB1;
           isBDS_B2a = isBDS_B2a || isB2a;
       elseif idx_gnss == 4                 % QZSS
           bool_QZSS = true;
           isL1 = round(CarrierFrequencyHz/1e3) == round(Const.QZSS_F1/1e3);
           isL5 = round(CarrierFrequencyHz/1e3) == round(Const.QZSS_F5/1e3);
           frq_char = char('1'*isL1 + '5'*isL5);
           CodeType = checkSignalType(CodeType, 'J', frq_char);
           obstypes_qzss = [obstypes_qzss CodeType{1}];
           isQZSS_L1 = isQZSS_L1 || isL1;
           isQZSS_L5 = isQZSS_L5 || isL5;
       end       
       
       i = i + 1;
    end
    
    
    if i > 200 || (isGPS_L1 && isGPS_L5 && isGLO_G1 && isGAL_E1 && isGAL_E5a && isBDS_B1 && isBDS_B2a)
        % stop analyzing if all GNSS have been detected or 200 lines of
        % data have been analyzed
        % QZSS is ignored in this check
        break
    end
    
end

fclose(fid);        % close file

% remove multiple occurences
obstypes_gps  = unique(obstypes_gps);
obstypes_glo  = unique(obstypes_glo);
obstypes_gal  = unique(obstypes_gal);
obstypes_bds  = unique(obstypes_bds);
obstypes_qzss = unique(obstypes_qzss);
% default ranking of observation types
gps_ranking  = DEF.RANKING_GPS;
glo_ranking  = DEF.RANKING_GLO;
gal_ranking  = DEF.RANKING_GAL;
bds_ranking  = DEF.RANKING_BDS;
qzss_ranking = DEF.RANKING_QZSS;
% keep only observation types observed and in ranking
gps_ranking  = intersect(gps_ranking, obstypes_gps);
glo_ranking  = intersect(glo_ranking, obstypes_glo);
gal_ranking  = intersect(gal_ranking, obstypes_gal);
bds_ranking  = intersect(bds_ranking, obstypes_bds);
qzss_ranking = intersect(qzss_ranking, obstypes_qzss);

% determine indices of observed GNSS frequencies
if bool_GPS
    if isGPS_L1 && isGPS_L5
        ind_gps_freq = [1 3];
    elseif isGPS_L1
        ind_gps_freq = 1;
    end
end
if bool_GLO
    if isGLO_G1
        ind_glo_freq = 1;
    end
end
if bool_GAL
    if isGAL_E1 && isGAL_E5a
        ind_gal_freq = [1 2];
    elseif isGAL_E1
        ind_gal_freq = 1;
    end
end
if bool_BDS
    if isBDS_B1 && isBDS_B2a
        ind_bds_freq = [1 5];
    elseif isBDS_B1
        ind_bds_freq = 1;
    end
end
if bool_QZSS
    if isQZSS_L1 && isQZSS_L5
        ind_qzss_freq = [1 3];
    elseif isQZSS_L1
        ind_qzss_freq = 1;
    end
end


%% SAVE
rheader.pos_approx = pos_approx;
rheader.version_full = version_full;
rheader.interval = interval;
rheader.first_obs = startdate;
rheader.last_obs = last_obs;
rheader.time_system = time_system;
rheader.gps_ranking  = gps_ranking;
rheader.glo_ranking  = glo_ranking;
rheader.gal_ranking  = gal_ranking;
rheader.bds_ranking  = bds_ranking;
rheader.qzss_ranking = qzss_ranking;
rheader.ind_gps_freq  = ind_gps_freq;
rheader.ind_glo_freq  = ind_glo_freq;
rheader.ind_gal_freq  = ind_gal_freq;
rheader.ind_bds_freq  = ind_bds_freq;
rheader.ind_qzss_freq = ind_qzss_freq;
rheader.station = station;
rheader.station_long = station_long;
rheader.antenna = antenna_type;
rheader.receiver = receiver_type;