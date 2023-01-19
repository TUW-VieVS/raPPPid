function rheader = anheader_GUI(file)
% Analyzes the header of a RINEX file and outputs some stuff for GUI_PPP
% Simplified version of anheader (e.g. it needs only the path to the
% observation file)
%
% INPUT:
%   file            string, path to observation file
% OUTPUT:
%   rheader         struct, with the following fields:
%       pos_approx      vector, approximate position from RINEX header
%       version_full    integer, RINEX version (e.g, 3.xx)
%       interval        integer, interval of observations in RINEX file
%       first_obs       vector [year, month, day, hour, min, sec], time of
%                       first observation in RINEX file
%       time_system     string, time system specified in header
%       no_eps          number of epochs
%       gps_ranking     string, ranking of gps observations types
%       glo_ranking     string, ranking of glonass observations types
%       gal_ranking     string, ranking of galileo observations types
%       bds_ranking     string, ranking of beidou observations types
%       ind_gps_freq    vector, numbers of observed gps frequencies
%       ind_glo_freq    vector, numbers of observed glonass frequencies
%       ind_gal_freq    vector, numbers of observed galileo frequencies
%       ind_bds_freq    vector, numbers of observed BeiDou frequencies
%       station         string, 4-digit name of station
%       antenna         string, antenna of RINEX file
%       receiver        string, receiver of RINEX file
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% PREPARATIONS
interval = [];
version_full = 0;
pos_approx = [0; 0; 0];
fid = fopen(file,'rt');         % open observation-file

first_obs = []; last_obs = []; rinex2_obs_types = [];
station = ''; antenna_type = ''; receiver_type = '';
% default ranking of observation types
gps_ranking = DEF.RANKING_GPS;
glo_ranking = DEF.RANKING_GLO;
gal_ranking = DEF.RANKING_GAL;
bds_ranking = DEF.RANKING_BDS;
% default naming of frequency
ind_gps_freq = [0 0 0];
ind_glo_freq = [0 0 0];
ind_gal_freq = [0 0 0];
ind_bds_freq = [0 0 0];


%% LOOP TO GOBBLE THE HEADER
while 1
    line = fgetl(fid);          % get next line
    
    if contains(line,'MARKER NAME')
        station = upper(strtrim(line(1:4)));        % make sure that uppercase
    end
    
    if contains(line,'END OF HEADER') || feof(fid)
        break                   % end of header or file reached
    end
    
    if contains(line,'RINEX VERSION / TYPE')      	% rinex version
        version_full = line(6:9);
        version_full = sscanf(version_full, '%f');
        if ~contains(upper(line), 'OBSERVATION')   	% check if this RINEX File contains observation data
            [~, obs_filename, ext] = fileparts(file);
            errordlg({[obs_filename ext ':'], 'Is not recognized as Rinex Observation File.'}, 'Wrong File-Format');
            ind_gps_freq = []; ind_gal_freq = [];
            return
        end
    end
    
    if contains(line,'ANT # / TYPE')                % Antenna type
        antenna_type = line(21:40);
    end
    
    if contains(line,'REC # / TYPE / VERS')         % Receiver type
        receiver_type = line(21:40);
    end
    
    if contains(line,'APPROX POSITION XYZ')      	% pos_approx
        for k = 1:3
            [approxpos_str, line] = strtok(line);
            approxpos_num = sscanf(approxpos_str, '%f');
            pos_approx(k) = approxpos_num;
        end
    end
    
    if contains(line,'INTERVAL')                    % interval
        [interval_str, line] = strtok(line);
        interval = sscanf(interval_str, '%f');
    end
    
    % Time of first observation
    if contains(line,'TIME OF FIRST OBS')
        cell_startdate = textscan(line(1:55), '%f %f %f %f %f %f %s' );
        first_obs = cell2mat(cell_startdate(1:6));
        time_system = cell2mat(cell_startdate{7});
    end
    
    % Time of last observation
    if contains(line,'TIME OF LAST OBS')
        cell_enddate = textscan(line(1:55), '%f %f %f %f %f %f %s' );
        last_obs = cell2mat(cell_enddate(1:6));
    end
    
    % get observed frequencies (RINEX 3 onwards)
    if floor(version_full) >= 3 && contains(line, 'SYS / # / OBS TYPES')
        gnss = line(1);   % get system identifier
        if gnss~='G' && gnss~='R' && gnss~='E' && gnss~='C'
            continue        % continue for other system than GPS, GLONASS, GALILEO or BEIDOU
        end
        NoObs = sscanf(line(5:6), '%f');         % number of observations
        obs_types = [];     ranking = [];
        % Check if multiple lines
        obslength = 4*NoObs;                    % length of all observations, each obs. has 4-digits
        maxlength = 79-19-7;                    % length of one line observation types
        nolines = ceil(obslength/maxlength);    % number of lines with observation types
        obs_line = line(7:60);                  % get only part of line with obs types
        for i=2:nolines                         % and also for the following lines
            nextline = fgetl(fid);
            obs_line = [obs_line, nextline(7:58)];
        end
        obs_types = regexprep(obs_line, ' ', ''); 	% delete empty spaces
        types = obs_types(3:3:length(obs_types));	% char of observation types
        freq = obs_types(2:3:length(obs_types));    % frequency numbers
        if gnss == 'G'
            gps_ranking = check_obs_types(gps_ranking, types);
            ind_gps_freq = check_freq(freq);
            ind_gps_freq = (ind_gps_freq ~= 0) .* [1 2 0 0 3 0 0 0];
        elseif gnss == 'R'
            glo_ranking = check_obs_types(glo_ranking, types);
            ind_glo_freq = check_freq(freq);
            ind_glo_freq = (ind_glo_freq ~= 0) .* [1 2 3 0 0 0 0 0];
        elseif gnss == 'E'
            gal_ranking = check_obs_types(gal_ranking, types);
            ind_gal_freq = check_freq(freq);
            ind_gal_freq = (ind_gal_freq ~= 0) .* [1 0 0 0 2 5 3 4];
        elseif gnss == 'C'
            bds_ranking = check_obs_types(bds_ranking, types);
            freq = strrep(freq, '1', '2');      % RINEX v3 specification says C1x = C2x, C1x should be treated as C2x
            ind_bds_freq = check_freq(freq);
            ind_bds_freq = (ind_bds_freq ~= 0) .* [0 1 0 0 0 3 2 0];
        end
    end
    
    % get observed frequencies RINEX 2
    if floor(version_full)==2 && contains(line,'# / TYPES OF OBSERV')
        % read first line and no. of obs. types
        if length(line) > 60
            line = line(1:60);
        end
        [NObs, line] = strtok(line);
        NoObs = sscanf(NObs, '%f');
        
        for k = 1:NoObs
            [ot, line] = strtok(line);
            rinex2_obs_types = [rinex2_obs_types ot];
        end
        if NoObs > 9 % 9 Obs types in einer Zeile
            line = fgetl(fid);
            if contains(line,'# / TYPES OF OBSERV') % 2nd line of observation-types
                ot = sscanf(line(1:60),'%s');
                rinex2_obs_types = [rinex2_obs_types ot];
            end
        end
    end
    
end
fclose(fid);


%% Handle exceptions

if isempty(first_obs)        % exception: header has no TIME OF FIRST OBS entry
    first_obs = [0 0 0 0 0 0];
end

% check for RINEX 2 observed frequencies
if floor(version_full) == 2
    % GPS
    if contains(rinex2_obs_types, 'C1') || contains(rinex2_obs_types, 'L1')
        ind_gps_freq(1) = 1;    % check for L1 frequency
        ind_glo_freq(1) = 1;
    end
    if contains(rinex2_obs_types, 'C2') || contains(rinex2_obs_types, 'P2') || contains(rinex2_obs_types, 'L2')
        ind_gps_freq(2) = 2;    % check for L2 frequency
        ind_glo_freq(2) = 2;
    end
end


% remove zeros to give back only raPPPid internal numbers of contained frequencies
ind_gps_freq = ind_gps_freq(ind_gps_freq~=0);
ind_glo_freq = ind_glo_freq(ind_glo_freq~=0);
ind_gal_freq = ind_gal_freq(ind_gal_freq~=0);
ind_bds_freq = ind_bds_freq(ind_bds_freq~=0);
% sort ascending
ind_gps_freq = sort(ind_gps_freq);
ind_glo_freq = sort(ind_glo_freq);
ind_gal_freq = sort(ind_gal_freq);
ind_bds_freq = sort(ind_bds_freq);


%% Save into struct
rheader.pos_approx = pos_approx;
rheader.version_full = version_full;
rheader.interval = interval;
rheader.first_obs = first_obs;
rheader.last_obs = last_obs;
rheader.time_system = time_system;
rheader.gps_ranking = gps_ranking;
rheader.glo_ranking = glo_ranking;
rheader.gal_ranking = gal_ranking;
rheader.bds_ranking = bds_ranking;
rheader.ind_gps_freq = ind_gps_freq;
rheader.ind_glo_freq = ind_glo_freq;
rheader.ind_gal_freq = ind_gal_freq;
rheader.ind_bds_freq = ind_bds_freq;
rheader.station = station;
rheader.antenna = antenna_type;
rheader.receiver = receiver_type;


end % end of anheader_GUI.m





%% AUXILIARY FUNCTION
function ranking = check_obs_types(ranking, types)
% loop over default ranking to exclude those letters of observation types
% which are not observed in the currently selected RINEX file
i = 1;
while i <= length(ranking)
    number = count(types, ranking(i));
    if number == 0
        ranking(i) = [];
    else
        i = i + 1;
    end
end
end

function gnss_freq = check_freq(freq)
% loop to find the RINEX 3 numbers of the observed frequencies
gnss_freq = 1:8;
for i = 1:8
    if count(freq, num2str(gnss_freq(i))) == 0
        gnss_freq(i) = 0;
    end
end
end