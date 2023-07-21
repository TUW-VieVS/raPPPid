function [obs] = analyzeAndroidRawData(sensorlog_path, settings)
% This function reads a part of the Android raw sensor data file to
% determine important information for processing because such a file does
% not contain a header (like a RINEX file)
%
% INPUT:
%   sensorlog_path  string, path to Android raw sensor data file
%   settings        struct, processing settings from GUI
% OUTPUT:
%	obs             struct, updated with essential information for processing
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% INITIALIZE
version = 0; version_full = 0;
L_gps_3 = []; C_gps_3 = []; S_gps_3 = []; D_gps_3 = []; 
L_gps = []; C_gps = []; S_gps = []; D_gps = [];
L_rank_gps = []; C_rank_gps = []; S_rank_gps = []; D_rank_gps = [];
L_glo_3 = []; C_glo_3 = []; S_glo_3 = []; D_glo_3 = []; 
L_glo = []; C_glo = []; S_glo = []; D_glo = [];
L_rank_glo = []; C_rank_glo = []; S_rank_glo = []; D_rank_glo = [];
L_gal_3 = []; C_gal_3 = []; S_gal_3 = []; D_gal_3 = []; 
L_gal = []; C_gal = []; S_gal = []; D_gal = [];
L_rank_gal = []; C_rank_gal = []; S_rank_gal = []; D_rank_gal = [];
L_bds_3 = []; C_bds_3 = []; S_bds_3 = []; D_bds_3 = []; 
L_bds = []; C_bds = []; S_bds = []; D_bds = [];
L_rank_bds = []; C_rank_bds = []; S_rank_bds = []; D_rank_bds = [];
receiver_type = ''; antenna_type = ''; 
startdate = [];         enddate = [];
shift = []; 
glo_cod_phs_bis = [];
glo_channel = NaN(99,1);
stationname = ''; stationname_long = '';
vars_Raw = {};
% hardcode:
interval = 1;
leap_sec = 18;      % will be overwritten most likely
time_system = 'GPS';
ant_delta = zeros(3,1);


%% ANALYZE
fid = fopen(sensorlog_path,'rt');     	% open observation-file

i = 0; formatSpec = '';
isGPS_L1 = false; isGPS_L5 = false;  isGLO_G1 = false; 
isGAL_E1 = false; isGAL_E5a = false; isBDS_B1 = false; isBDS_B2 = false;

while true
    
    line = fgetl(fid);                  % get next line
    
    if feof(fid)                        % check if end of file is reached
        break
    end
    
    if contains(line, '# Version')      % detect smartphone model
        idx = strfind(line, 'Model:');
        receiver_type = line(idx+7:end);
    end
    
    if contains(line,'# Raw')         	% variables in raw data line
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
           % build gps time and week
           gpstime = TimeNanos - FullBiasNanos - BiasNanos;         % [ns]
           gpstime = double(mod(gpstime, 604800*1e9))*1e-9;         % convert to double and [s]
           gpsweek = floor(abs(double(FullBiasNanos))*1e-9 / 604800);    % gps week, []
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
       if idx_gnss == 1                 % GPS
           % determine frequency
           isGPS_L1 = (round(CarrierFrequencyHz/1e4) == round(Const.GPS_F1/1e4));
           isGPS_L5 = (round(CarrierFrequencyHz/1e4) == round(Const.GPS_F5/1e4));
           % create char of frequency
           frq_char = char('1'*isGPS_L1 + '5'*isGPS_L5);
           % create 3-digit name of observation (RINEX conventation)
           L = ['L' frq_char CodeType{1}];
           C = ['C' frq_char CodeType{1}];
           S = ['S' frq_char CodeType{1}];
           D = ['D' frq_char CodeType{1}];
           % check if observation type already saved
           if (isempty(C_gps_3) || ~contains(C_gps_3, C)) && (isGPS_L1 || isGPS_L5)
               % save 3-digit observation type
               L_gps_3 = [L_gps_3 L];
               C_gps_3 = [C_gps_3 C];
               S_gps_3 = [S_gps_3 S];
               D_gps_3 = [D_gps_3 D];
               % convert to 2-digit and check rank
               [L_type2, L_rank] = obs_convert(L, 'G', settings);
               [C_type2, C_rank] = obs_convert(C, 'G', settings);
               [S_type2, C_rank] = obs_convert(S, 'G', settings);
               [D_type2, C_rank] = obs_convert(D, 'G', settings);
               % save 2-digit observation type
               L_gps = [L_gps L_type2];
               C_gps = [C_gps C_type2];
               S_gps = [S_gps S_type2];
               D_gps = [D_gps D_type2];
               % save ranking
               L_rank_gps = [L_rank_gps L_rank];
               C_rank_gps = [C_rank_gps L_rank];
               S_rank_gps = [S_rank_gps L_rank];
               D_rank_gps = [D_rank_gps L_rank];
           end

           % other GNSS are handled identical (but different frequencies!)
           
       elseif idx_gnss == 3             % GLONASS
           isGLO_G1 = (round(CarrierFrequencyHz/1e7) == round(Const.GLO_F1/1e7));
           frq_char = char('1'*isGLO_G1);
           L = ['L' frq_char CodeType{1}];
           C = ['C' frq_char CodeType{1}];
           S = ['S' frq_char CodeType{1}];
           D = ['D' frq_char CodeType{1}];
           if (isempty(C_glo_3) || ~contains(C_glo_3, C)) && (isGLO_G1)
               L_glo_3 = [L_glo_3 L];
               C_glo_3 = [C_glo_3 C];
               S_glo_3 = [S_glo_3 S];
               D_glo_3 = [D_glo_3 D];
               [L_type2, L_rank] = obs_convert(L, 'R', settings);
               [C_type2, C_rank] = obs_convert(C, 'R', settings);
               [S_type2, C_rank] = obs_convert(S, 'R', settings);
               [D_type2, C_rank] = obs_convert(D, 'R', settings);
               L_glo = [L_glo L_type2];
               C_glo = [C_glo C_type2];
               S_glo = [S_glo S_type2];
               D_glo = [D_glo D_type2];
               L_rank_glo = [L_rank_glo L_rank];
               C_rank_glo = [C_rank_glo L_rank];
               S_rank_glo = [S_rank_glo L_rank];
               D_rank_glo = [D_rank_glo L_rank];
           end
           
       elseif idx_gnss == 6             % Galileo
           isGAL_E1 = (round(CarrierFrequencyHz/1e4) == round(Const.GAL_F1/1e4));
           isGAL_E5a= (round(CarrierFrequencyHz/1e4) == round(Const.GAL_F5a/1e4));
           frq_char = char('1'*isGAL_E1 + '5'*isGAL_E5a);
           L = ['L' frq_char CodeType{1}];
           C = ['C' frq_char CodeType{1}];
           S = ['S' frq_char CodeType{1}];
           D = ['D' frq_char CodeType{1}];
           if (isempty(C_gal_3) || ~contains(C_gal_3, C)) && (isGAL_E1 || isGAL_E5a)
               L_gal_3 = [L_gal_3 L];
               C_gal_3 = [C_gal_3 C];
               S_gal_3 = [S_gal_3 S];
               D_gal_3 = [D_gal_3 D];
               [L_type2, L_rank] = obs_convert(L, 'E', settings);
               [C_type2, C_rank] = obs_convert(C, 'E', settings);
               [S_type2, C_rank] = obs_convert(S, 'E', settings);
               [D_type2, C_rank] = obs_convert(D, 'E', settings);
               L_gal = [L_gal L_type2];
               C_gal = [C_gal C_type2];
               S_gal = [S_gal S_type2];
               D_gal = [D_gal D_type2];
               L_rank_gal = [L_rank_gal L_rank];
               C_rank_gal = [C_rank_gal L_rank];
               S_rank_gal = [S_rank_gal L_rank];
               D_rank_gal = [D_rank_gal L_rank];
           end
           
       elseif idx_gnss == 5             % BeiDou
           isBDS_B1 = (round(CarrierFrequencyHz/1e3) == round(Const.BDS_F1/1e3));
           isBDS_B2 = (round(CarrierFrequencyHz/1e3) == round(Const.BDS_F2/1e3));
           frq_char = char('1'*isBDS_B1 + '5'*isBDS_B2);
           L = ['L' frq_char CodeType{1}];
           C = ['C' frq_char CodeType{1}];
           S = ['S' frq_char CodeType{1}];
           D = ['D' frq_char CodeType{1}];
           if (isempty(C_bds_3) || ~contains(C_bds_3, C)) && (isBDS_B1 || isBDS_B2)
               L_bds_3 = [L_bds_3 L];
               C_bds_3 = [C_bds_3 C];
               S_bds_3 = [S_bds_3 S];
               D_bds_3 = [D_bds_3 D];
               [L_type2, L_rank] = obs_convert(L, 'C', settings);
               [C_type2, C_rank] = obs_convert(C, 'C', settings);
               [S_type2, C_rank] = obs_convert(S, 'C', settings);
               [D_type2, C_rank] = obs_convert(D, 'C', settings);
               L_bds = [L_bds L_type2];
               C_bds = [C_bds C_type2];
               S_bds = [S_bds S_type2];
               D_bds = [D_bds D_type2];
               L_rank_bds = [L_rank_bds L_rank];
               C_rank_bds = [C_rank_bds L_rank];
               S_rank_bds = [S_rank_bds L_rank];
               D_rank_bds = [D_rank_bds L_rank];
           end
           
       end
       
       i = i + 1;
    end
    
    
    if i > 200 || (isGPS_L1 && isGPS_L5 && isGLO_G1 && isGAL_E1 && isGAL_E5a && isBDS_B1 && isBDS_B2)
        % stop analyzing if all GNSS have been detected or 200 lines of
        % data have been analzed
        break
    end
    
end

fclose(fid);        % close file


%% SAVE
% types of observations in 2-digit-form for gps/glonass/galileo/beidou
obs.types_gps = [L_gps C_gps S_gps D_gps];
obs.types_glo = [L_glo C_glo S_glo D_glo];
obs.types_gal = [L_gal C_gal S_gal D_gal];
obs.types_bds = [L_bds C_bds S_bds D_bds];
% types of observations in 3-digit-form for gps/glonass/galileo/beidou
obs.types_gps_3 = [L_gps_3 C_gps_3 S_gps_3 D_gps_3];
obs.types_glo_3 = [L_glo_3 C_glo_3 S_glo_3 D_glo_3];
obs.types_gal_3 = [L_gal_3 C_gal_3 S_gal_3 D_gal_3];
obs.types_bds_3 = [L_bds_3 C_bds_3 S_bds_3 D_bds_3];
% ranking of observations for gps/glonass/galileo /beidou
obs.ranking_gps = [L_rank_gps C_rank_gps S_rank_gps D_rank_gps];
obs.ranking_glo = [L_rank_glo C_rank_glo S_rank_glo D_rank_glo];
obs.ranking_gal = [L_rank_gal C_rank_gal S_rank_gal D_rank_gal];
obs.ranking_bds = [L_rank_bds C_rank_bds S_rank_bds D_rank_bds];
% Number of observation types for gps/glonass/galileo/beidou
obs.no_obs_types(1) = length(obs.types_gps_3)/3;
obs.no_obs_types(2) = length(obs.types_glo_3)/3;
obs.no_obs_types(3) = length(obs.types_gal_3)/3;
obs.no_obs_types(4) = length(obs.types_bds_3)/3;

% save observation relevant data
obs.phase_shift   = shift;
obs.startdate     = startdate;
obs.time_system   = time_system;
obs.enddate       = enddate;
obs.rinex_version = version;
obs.rinex_version_full = version_full;

% check and save observation interval
obs.interval = interval;

% check and save leap seconds
obs.leap_sec = leap_sec;

% Glonass channel numbers
obs.glo_channel = glo_channel;
% Glonass Code-Phase Alignment Header Record
obs.glo_cod_phs_bis = glo_cod_phs_bis;

% save station relevant data
obs.stationname 	= upper(stationname);
obs.station_long 	= upper(stationname_long);
obs.antenna_type 	= antenna_type;
obs.receiver_type   = receiver_type;
obs.rec_ant_delta 	= [ant_delta(3); ant_delta(2); ant_delta(1)];   % North / East / Height

% raw sensor data from smartphone
obs.vars_raw = vars_Raw;


