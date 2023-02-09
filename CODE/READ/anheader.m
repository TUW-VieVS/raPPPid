function [obs] = anheader(settings)
% Analyzes the header of a RINEX file and outputs the list of observation 
% types and antenna offset.
%
% INPUT: 
%   settings        struct, settings for processing from GUI
%                   	
% OUTPUT:
%   obs.types_gps/_glo/_gal/_bds:   
%               string with obs-types without blank
%   obs.no_obs_types:    
%               [1x3], number of observations for [GPS, GLO, GAL, BDS]
%   obs.phase_shift:       
%               phase shift, matrix, each column one phase shift        
%               1st row: system (1,2,3,4) for (gps,glo,gal,bds)
%               2nd row: column of observation in observation-matrix
%               3rd row: value of phase shift
%   obs.rinex_version   version of rinex-observation-file
%   obs.interval       	data interval [s] (def=1)
%   obs.startdate      	start epoch vector [year, month, day, hour, min, sec]
%   obs.enddate        	end   epoch vector [year, month, day, hour, min, sec]
%   obs.time_system   	string, time system of the observations
%   obs.leap_sec      	leap seconds of observation-file
% 	obs.antenna_type  	antenna type, string
% 	obs.rec_type        receiver type, string
%  	obs.rec_ant_delta	1x3, antenna offset [H,E,N]
%   obs.glo_channel  	channel numbers for all Glonass satellites
% 
%   Revision:
%       MFG, 12 Aug 2020: changed input to settings
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Get variables from settings
% string, filename and path of RINEX observation file
path_file = settings.INPUT.file_obs;    
% vectors containing processed frequencies
gps_freq = settings.INPUT.gps_freq;     
glo_freq = settings.INPUT.glo_freq;
gal_freq = settings.INPUT.gal_freq;
bds_freq = settings.INPUT.bds_freq;
% ranking of observation types
gps_ranking = settings.INPUT.gps_ranking;   
glo_ranking = settings.INPUT.glo_ranking;
gal_ranking = settings.INPUT.gal_ranking;
bds_ranking = settings.INPUT.bds_ranking;
% labels for code, phase and signal strength
LABELS = [];   
% check if output is printed to command window
bool_print = ~settings.INPUT.bool_parfor;


%% PREPARATIONS
fid = fopen(path_file,'rt');         % open observation-file
obs_types_gps = [];     obs_types_glo = [];     obs_types_gal = [];     obs_types_bds = [];
obs_types_gps_3 = [];   obs_types_glo_3 = [];   obs_types_gal_3 = []; 	obs_types_bds_3 = [];
ranking_gps = [];       ranking_glo = [];     	ranking_gal = [];       ranking_bds = [];
receiver_type = ''; antenna_type = ''; ant_delta = zeros(3,1);
startdate = [];         enddate = [];
shift = [];     shiftlines = {};    i_shift = 1;
glo_cod_phs_bis = [];
glo_channel = NaN(99,1);
stationname = '';
time_system = 'GPS';        % GPS time system is default


%% LOOP TO GOBBLE THE HEADER
while 1
    line = fgetl(fid);          % get next line
    
    if contains(line,'END OF HEADER') || ~ischar(line) 
        break                   % end of header or file reached
    end
    
    % Rinex version
    if contains(line,'RINEX VERSION / TYPE')
        version = line(6);
        version_full = line(6:9);
    end
    
    % Antenna delta
    if contains(line,'ANTENNA: DELTA H/E/N')
        temp = textscan(line,'%f %f %f %s',1);
        ant_delta(1) = temp{1};
        ant_delta(2) = temp{2};
        ant_delta(3) = temp{3};
    end
    
    % Antenna type
    if contains(line,'ANT # / TYPE')
        antenna_type = line(21:40);
    end
    
    % Receiver type
    if contains(line,'REC # / TYPE / VERS')
        receiver_type = line(21:40);
    end
    
    % Marker name
    if contains(line,'MARKER NAME')
        stationname = upper(strtrim(line(1:4)));        % make sure that uppercase
    end
    
    % GLONASS Slot/Frequency Numbers
    if settings.INPUT.use_GLO && contains(line,'GLONASS SLOT / FRQ #')
        for i = 1:8             % loop over entries of current line
            idx_prn = [6: 7] + (i-1)*7;       	%#ok<NBRAK>, [] is necessary
            idx_cha = [9:10] + (i-1)*7;         %#ok<NBRAK>
            prn     = sscanf(line(idx_prn), '%f');
            channel = sscanf(line(idx_cha), '%f');
            if ~isempty(prn) && ~isempty(channel) && prn <= DEF.SATS_GLO && prn~=0
                glo_channel(prn) = channel;       	% save channel for current prn
            end
        end
    end
    
    % Types of observations in RINEX 2.xx
    if version=='2' && contains(line,'# / TYPES OF OBSERV')
        % read first line and no. of obs. types
        if length(line) > 60
            line = line(1:60);
        end
        [NObs, line] = strtok(line);
        NoObs = sscanf(NObs, '%f');
        
        for k = 1:NoObs
            [ot, line] = strtok(line);
            obs_types_gps = [obs_types_gps ot];
            obs_types_glo = [obs_types_glo ot];
        end
        if NoObs > 9 % 9 Obs types in einer Zeile
            line = fgetl(fid);
            if contains(line,'# / TYPES OF OBSERV') % 2nd line of observation-types
                ot = sscanf(line(1:60),'%s');
                obs_types_gps = [obs_types_gps ot];
                obs_types_glo = [obs_types_glo ot];
            end
        end
    end
    
    % Types of observations in RINEX 3.xx
    if (version=='4' || version=='3') && contains(line, 'SYS / # / OBS TYPES')
        system = line(1);   % get system identifier
        if system~='G' && system~='R' && system~='E' && system~='C' 
            continue        % continue for other system than GPS or GLONASS or GALILEO
        end
        NoObs = sscanf(line(5:6), '%f');         % number of observations
        obs_types = [];     ranking = [];
        % Calc if more than one line      
        obslength = 4*NoObs;                    % length of all observations, each obs. has 4-digits
        maxlength = 79-19-7;                    % length of one line observation types
        nolines = ceil(obslength/maxlength);    % number of lines with observation types
        obs_line = line(7:60);                  % get only part of line with obs types
        for i=2:nolines                         % and also for the following lines
            nextline = fgetl(fid);
            obs_line = [obs_line, nextline(7:58)];
        end
        obs_types_3 = regexprep(obs_line, ' ', '');     % delete empty spaces
        for i = 3:3:length(obs_types_3)         % loop over observation types
            type3 = obs_types_3(i-2:i);            
            [type2, rank] = obs_convert(type3, system, gps_freq, glo_freq, gal_freq, bds_freq, gps_ranking, glo_ranking, gal_ranking, bds_ranking, LABELS);
            obs_types = [obs_types, type2];
            ranking   = [ranking,    rank];
        end
        switch system
            case 'G'
                obs_types_gps = obs_types;
                obs_types_gps_3 = obs_types_3;
                ranking_gps = ranking;
            case 'R'
                obs_types_glo = obs_types;
                obs_types_glo_3 = obs_types_3;
                ranking_glo = ranking;
            case 'E'
                obs_types_gal = obs_types;
                obs_types_gal_3 = obs_types_3;
                ranking_gal = ranking;
            case 'C'
                obs_types_bds = obs_types;
                obs_types_bds_3 = obs_types_3;
                ranking_bds = ranking;
        end
    end
    
    % Phase shift (lines are saved for later)
    if contains(line,'SYS / PHASE SHIFT')
        shiftlines{i_shift,1} = line;
        i_shift = i_shift + 1;
    end
    
    % Observation interval
    if contains(line,'INTERVAL')
        [interval_str, line] = strtok(line);
        interval = sscanf(interval_str, '%f');
    end
    
    % Time of first observation
    if contains(line,'TIME OF FIRST OBS')
       cell_startdate = textscan(line(1:55), '%f %f %f %f %f %f %s' );
       startdate = cell2mat(cell_startdate(1:6));
       time_system = cell2mat(cell_startdate{7});
    end

    % Time of last observation
    if contains(line,'TIME OF LAST OBS')
        for k = 1:6
            [enddate_str, line] = strtok(line);
            enddate_num = sscanf(enddate_str, '%f');
            enddate = [enddate enddate_num];
        end
    end
    
    % Glonass Code-Alignment Header Record, this correction is already 
    % applied in the observations of the RINEX file
    if contains(line,'GLONASS COD/PHS/BIS')
        type_value = textscan(line(1:60), '%s %f %s %f %s %f %s %f');
        for i = 1:4
            type = type_value{2*i-1};
            value = type_value{2*i};
            if value ~= 0
                glo_cod_phs_bis.(type{1}) = value;
            end
        end
    end

    % Leap seconds
    if contains(line,'LEAP SECONDS')
        lData = textscan(line(1:60), '%f %f %f %f %s');
        leap_sec = lData{1};
        % lData{2}  future or past leap seconds
        % lData{3}  respective week number
        % lData{4}  respective day number
        % lData{5}  time system identifier (GPS or BDS), blank = GPS
    end
    
end % end of loop to gobble the header
fclose(fid);        % close file


%% Relate phase shift to processed frequencies
% Needs obs_types for each GNSS so this part is done after gobbling the 
% header is finished
if ~isempty(shiftlines)
    for ii = 1:numel(shiftlines)
        % ||| specification of satellites is ignored !!!!
        line = shiftlines{ii,1};
        system = line(1);               % GNSS
        type3 = line(3:5);              % 3-digit-observation-type
        switch system
            case 'G'
                col = strfind(obs_types_gps_3, type3);
                index = 1;              % 1 for GPS, 2 for GLO, 3 for GAL, 4 for BDS
            case 'R'
                col = strfind(obs_types_glo_3, type3);
                index = 2;
            case 'E'
                col = strfind(obs_types_gal_3, type3);
                index = 3;
            case 'C'
                col = strfind(obs_types_bds_3, type3);
                index = 4;
            otherwise
                continue
        end
        [type2, ~] = obs_convert(type3, system, gps_freq, gal_freq, glo_freq, bds_freq, gps_ranking, glo_ranking, gal_ranking, bds_ranking, LABELS);
        if strcmp(type2, '??') || strcmp(type2, '?x') || isempty(col)    
            continue;           % observation-type of current phase-shift is not used
        end
        col = (col + 2)/3;      % column of observation in observation-matrix
        i = size(shift,2) + 1;
        value = sscanf(line(7:14), '%f');
        if ~isempty(value) && value ~= 0 	% shift of 0 is not saved
            % save in matrix: each column one phase-shift, rows:
            shift(1,i) = index;             % GNSS (1,2,3,4) = (gps,glo,gal,bds)
            shift(2,i) = col(1);        	% column in obs-matrix
            shift(3,i) = value;             % value
        end
    end
end


%% SAVE INFORMATION FROM HEADER
% types of observations in 2-digit-form for gps/glonass/galileo/beidou 
obs.types_gps = obs_types_gps;
obs.types_glo = obs_types_glo;
obs.types_gal = obs_types_gal;
obs.types_bds = obs_types_bds;
% types of observations in 3-digit-form for gps/glonass/galileo/beidou
obs.types_gps_3 = obs_types_gps_3;
obs.types_glo_3 = obs_types_glo_3;
obs.types_gal_3 = obs_types_gal_3;
obs.types_bds_3 = obs_types_bds_3;
% ranking of observations for gps/glonass/galileo /beidou
obs.ranking_gps = ranking_gps;
obs.ranking_glo = ranking_glo;
obs.ranking_gal = ranking_gal;
obs.ranking_bds = ranking_bds;
% Number of observation types for gps/glonass/galileo/beidou
obs.no_obs_types(1) = length(obs_types_gps)/2; 
obs.no_obs_types(2) = length(obs_types_glo)/2;
obs.no_obs_types(3) = length(obs_types_gal)/2;
obs.no_obs_types(4) = length(obs_types_bds)/2;

% save observation relevant data
obs.phase_shift   = shift;
obs.startdate     = startdate;
obs.time_system   = time_system; 
obs.enddate       = enddate;
obs.rinex_version = sscanf(version, '%f');
obs.rinex_version_full = sscanf(version_full, '%f');

% check and save observation interval
try
    obs.interval = interval;
catch
    obs.interval = extractObsInterval(path_file);
end

% check and save leap seconds
try
    obs.leap_sec = leap_sec;
catch
    [~, obs_filename, ext] = fileparts(path_file);
    if bool_print; fprintf([obs_filename ext ': contains no leap second information.\n']); end
    hour = obs.startdate(4) + obs.startdate(5)/60 + obs.startdate(6)/3660;
    start_jd = cal2jd_GT(obs.startdate(1),obs.startdate(2), obs.startdate(3) + hour/24);
    obs.leap_sec = GetLeapSec_UTC_GPS(start_jd);
    if bool_print; fprintf(['Used leap seconds: ' num2str(obs.leap_sec) ' \n']); end
end

% Glonass channel numbers
obs.glo_channel = glo_channel;
% Glonass Code-Phase Alignment Header Record
obs.glo_cod_phs_bis = glo_cod_phs_bis;

% save station relevant data
obs.stationname 	= upper(stationname);
obs.antenna_type 	= antenna_type;
obs.receiver_type   = receiver_type;
obs.rec_ant_delta 	= [ant_delta(3); ant_delta(2); ant_delta(1)];   % North / East / Height



end     % of anheader.m