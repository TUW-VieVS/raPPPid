function eph = read_nav_glo(navfile_glo, leap_sec)

% Reads a RINEX Navigation Message file for Glonass and reformats the data 
% into a matrix with 19 rows and a column for each satellite. This matrix 
% is returned. Time is converted into GPS time.
% 
% INPUT:
% 	navfile_glo     string, path to RINEX navigation file
%   leap_sec        integer, number of leap seconds between UTC and GPS time
%                                navigation file
% OUTPUT:
%	eph             matrix with glonass ephemeris
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Units are either seconds, meters, or radians
fide = fopen(navfile_glo);
fData = textscan(fide,'%s','Delimiter','\n','whitespace',''); fData = fData{1};
% whole RINEX-file is in fData
fData = strrep(fData,'D+','E+');    % replace D+ with E+
fData = strrep(fData,'D-','E-');    % replace D- with E-
fclose(fide);


%% LOOP OVER THE HEADER
for i = 1:length(fData) 
    line = fData{i};
    
    if contains(line, 'RINEX VERSION / TYPE')
        version = sscanf(line(6),  '%f');
    end
    
    if contains(line, 'LEAP SECONDS')
        for k = 1:4
            leap_sec = sscanf(line(5:6), '%f'); % Leap seconds between GPS and UTC
        end
    end

    if contains(line,'CORR TO SYSTEM TIME')     % Rinex 2.xx
            TauC = sscanf(line(22:40), '%f'); 	% [s], Correction to system time to UTC (SU)
    end
    
    if contains(line,'TIME SYSTEM CORR')        % Rinex 3.xx
            TauC = sscanf(line(6:22), '%f');  	% [s], Correction to system time to UTC (SU)
    end

    if contains(line,'END OF HEADER')
        break
    end
end


%% PREPARATION OF VARIABLES
i_main = i;                 % number of current line
noeph = length(fData) - i_main;
noeph = noeph/4;            % four lines for each ephemeris, number of ephemeris

% Initialize memory for the input
svprn = zeros(1,noeph);     % satellite number
toe   = zeros(1,noeph);     % epoch of ephemerides GPS time (sow), will be converted from UTC
woe   = zeros(1,noeph);     % gps-week, week of ephemerides

TauN   = zeros(1,noeph);    % [s], satellite clock offset, - TauN
GammaN = zeros(1,noeph);    % relative frequency bias, + GammaN
                            % not only drift but also relativistic effects
tk =     zeros(1,noeph);    % [sod UTC], message frame time tk

X      = zeros(1,noeph);    % [km], X-coordinate of satellite in PZ90
X_vel  = zeros(1,noeph);    % [km/s], X-velocity of satellite in PZ90
X_acc  = zeros(1,noeph);    % [km/s^2], X-acceleration of satellite in PZ90
health = zeros(1,noeph);    % health of satellite (0=OK)

Y =      zeros(1,noeph);    % [km], Y-coordinate of satellite in PZ90
Y_vel =  zeros(1,noeph);    % [km/s], Y-velocity of satellite in PZ90
Y_acc =  zeros(1,noeph);    % [km/s^2], Y-acceleration of satellite in PZ90
f_num =  zeros(1,noeph);    % frequency number/channel (-7, ..., 13)

Z     =  zeros(1,noeph);    % [km], Z-coordinate of satellite in PZ90
Z_vel =  zeros(1,noeph);    % [km/s], Z-velocity of satellite in PZ90
Z_acc =  zeros(1,noeph);    % [km/s^2], Z-acceleration of satellite in PZ90
age   =  zeros(1,noeph);    % [days], age of operation info

eph   =  zeros(19, noeph);  % matrix of results

IOD = zeros(1,noeph);       % Issue of Data



%% LOOP OVER DATA RECORDS
for i = 1:noeph 
    i_main = i_main + 1;
    line = fData{i_main};
    
    % -+-+- get header-line of this data-record -+-+-
    if version == 2         % for RINEX 2.x
        svprn(i) =   sscanf(line(1:2), '%f');     % satellite number
        year     =   sscanf(line(3:6), '%f');
        if year <= 80       % be careful: works only until 31.01.2080
            year = year + 2000;
        else
            year = year + 1900;
        end                 % year is now definitely 4-digit
        % get month, day, hour, minute and second:
        month  =  sscanf(line(7:8), '%f');
        day    =  sscanf(line(10:11), '%f');
        hour   =  sscanf(line(13:14), '%f');
        minute =  sscanf(line(16:17), '%f');
        second =  sscanf(line(19:22), '%f');
        % calculation of toe (time of ephemerides) in GPS time:
        jd = cal2jd_GT(year, month, day + hour/24 + minute/1440 + second/86400);
        [~,sow_utc,~] = jd2gps_GT(jd);      % conversion to GPS-time
        sod_moscow = mod(round(sow_utc) + 3*3600,86400);
        IOD(i) = floor(sod_moscow/900);
        jd = jd + leap_sec/(60*60*24);      % Introduction of leap second between GPS and UTC
        [week,sow,~] = jd2gps_GT(jd);
        % save results from this epoch:
        toe(i)    = sow;    % epoch of ephemerides GPS (converted from UTC)
        woe(i)    = week;   % week of ephemerides (?)
        TauN(i)   = sscanf(line(23:41), '%f');    % [s], clock bias
        GammaN(i) = sscanf(line(42:60), '%f');    % relative frequency bias
        tk(i)     = sscanf(line(61:79), '%f');    % message frame time
    
    elseif version == 3     % for RINEX 3.x
        svprn(i)  = sscanf(line(2:3), '%f');      % satellite number
        year      = sscanf(line(5:8), '%f');
        month     = sscanf(line(10:11), '%f');
        day       = sscanf(line(13:14), '%f');
        hour      = sscanf(line(16:17), '%f');
        minute    = sscanf(line(19:20), '%f');
        second    = sscanf(line(22:23), '%f');
        % calculation of toe in GPS time:
        jd = cal2jd_GT(year, month, day + hour/24 + minute/1440 + second/86400);
        [~,sow_utc,~] = jd2gps_GT(jd);
        sod_moscow = mod(round(sow_utc) + 3*3600,86400);
        IOD(i) = floor(sod_moscow/900); 
        
        jd = jd + leap_sec/(60*60*24); % Introduction of leap second between GPS and UTC
        [week,sow,~] = jd2gps_GT(jd);
        toe(i) = sow; % epoch of ephemerides GPS (converted from UTC)
        woe(i) = week;
        TauN(i)   =  sscanf(line(24:42), '%f');    % [s], clock bias
        GammaN(i) =  sscanf(line(43:61), '%f');    % relative frequency bias
        tk(i)     =  sscanf(line(62:80), '%f');    % message frame time
    end
    
    % -+-+- get 1st line of this data-record -+-+-    
    i_main = i_main + 1;
    line = fData{i_main};
    if version == 2
        X(i)      =  sscanf(line( 4:22), '%f');
        X_vel(i)  =  sscanf(line(23:41), '%f');
        X_acc(i)  =  sscanf(line(42:60), '%f');
        health(i) =  sscanf(line(61:79), '%f');
    elseif version == 3
        X(i)      =  sscanf(line(4:23), '%f');
        X_vel(i)  =  sscanf(line(24:42), '%f');
        X_acc(i)  =  sscanf(line(43:61), '%f');
        health(i) =  sscanf(line(62:80), '%f');
    end
    
    % -+-+- get 2nd line of this data-record -+-+-       
    i_main = i_main + 1;
    line = fData{i_main};
    if version == 2
        Y(i)      =  sscanf(line( 4:22), '%f');
        Y_vel(i)  =  sscanf(line(23:41), '%f');
        Y_acc(i)  =  sscanf(line(42:60), '%f');
        f_num(i)  =  sscanf(line(61:79), '%f');
    elseif version == 3
        Y(i)      =  sscanf(line(4:23), '%f');
        Y_vel(i)  =  sscanf(line(24:42), '%f');
        Y_acc(i)  =  sscanf(line(43:61), '%f');
        f_num(i)  =  sscanf(line(62:80), '%f');
    end
    
    % -+-+- get 3rd line of this data-record -+-+-       
    i_main = i_main + 1;
    line = fData{i_main};
    if version == 2
        Z(i)      =  sscanf(line( 4:22), '%f');
        Z_vel(i)  =  sscanf(line(23:41), '%f');
        Z_acc(i)  =  sscanf(line(42:60), '%f');
        age(i)    =  sscanf(line(61:79), '%f');
    elseif version == 3
        Z(i)      =  sscanf(line(4:23), '%f');
        Z_vel(i)  =  sscanf(line(24:42), '%f');
        Z_acc(i)  =  sscanf(line(43:61), '%f');
        age(i)    =  sscanf(line(62:80), '%f');
    end
end     % end of loop over data-records


%% SAVE RESULTS
%  Description of variable eph.
eph(1,:)  = svprn;
eph(2,:)  = TauN;
eph(3,:)  = GammaN;
eph(4,:)  = tk;
eph(5,:)  = X;
eph(6,:)  = Y;
eph(7,:)  = Z;
eph(8,:)  = X_vel;
eph(9,:)  = Y_vel;
eph(10,:) = Z_vel;
eph(11,:) = X_acc;
eph(12,:) = Y_acc;
eph(13,:) = Z_acc;
eph(14,:) = health;
eph(15,:) = f_num;
eph(16,:) = TauC;
eph(17,:) = woe;
eph(18,:) = toe;        % converted into GPS sow
eph(19,:) = IOD;