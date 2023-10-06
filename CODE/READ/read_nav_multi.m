function [klob, nequ, BDGIM, Eph_GPS, Eph_GLO, Eph_GAL, Eph_BDS] = ...
    read_nav_multi(NAV, leap_sec)
% Function to read in a multi GNSS broadcast message file (only for RINEX 3
% navigation files). GLONASS time is converted in GPS time, while BDS time 
% is considered during the PPP calculations. 
% 
% a detailed description can be found in the Rinex v3 format specifications
% e.g. RINEX Version 3.03, p.34, https://files.igs.org/pub/data/format/rinex304.pdf
% 
% INPUT:
%   fData           cell, containing data of multi-GNSS navigation file
%   leap_sec        integer, number of leap seconds between UTC and GPS time
% OUTPUT:
%   klob            2x4, coefficients of Klobuchar Model (GPS ionosphere model)
%   nequ            1x3, coefficients of Nequick Model (Galileo ionosphere model)
%   BDGIM           coefficients of BeiDou global broadcast ionosphere
%                   delay correction model (BeiDou ionosphere model)
%   Eph_GPS         GPS navigation data
%   Eph_GLO         Glonass navigation data
%   Eph_GAL         Galileo navigation data
%   Eph_BDS         BeiDou navigation data
%
%   Revision:
%       2023/09/22, MFWG: jump over broken epoch entries
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| read in of BDS iono model coefficients is only experimental

% check if data to read (real-time processing)
klob = []; nequ = []; BDGIM = []; 
Eph_GPS = []; Eph_GLO = []; Eph_GAL = []; Eph_BDS = [];
if isempty(NAV)
    return
end


%% LOOP OVER HEADER
iHeadBegin = 0;
iHeadEnd   = 0;
coeff_alpha = [];       coeff_beta  = [];
nequ  = [];
BDGIM_alpha = [];       BDGIM_beta = [];

for i = 1:length(NAV)     % find header start and version
    if contains(NAV{i}, 'RINEX VERSION')
        temp = NAV{i};
        version = str2double(temp(1));
        iHeadBegin = i;
        break;
    end
end

if i > 0                   	% find header end
    for i = 1:length(NAV)
        if contains(NAV{i},'END OF HEADER')
            iHeadEnd = i;
            break;
        end
    end
    if iHeadEnd == 0;        iHeadEnd = 0;    end
end

for i = iHeadBegin:iHeadEnd  % Read header info
    if i == 0; break; end                % no header data
    if contains(NAV{i},'IONOSPHERIC CORR')        % ionosphere correction entry, RINEX 3.x
        if contains(NAV{i},'GPSA')      	% Klobuchar-Model-alpha-Coefficients
            coeff_alpha = cell2mat(textscan(NAV{i},'%*s %f %f %f %f'));
        end
        if contains(NAV{i},'GPSB')      	% Klobuchar-Model-beta-Coefficients
            coeff_beta = cell2mat(textscan(NAV{i},'%*s %f %f %f %f'));
        end
        if contains(NAV{i},'GAL')         % Nequick-Model-Coefficients
            nequ = cell2mat(textscan(NAV{i},'%*s %f %f %f'));
        end
        if contains(NAV{i},'BDSA')     	% BDGIM, alpha coefficients
            lData = textscan(NAV{i},'%*s %f %f %f %f %s %f');
            % convert char to start of hour of transmission time [sow] 
            % ||| BDT or GPST?!
            char = lData{5}{1};
            hour = upper(char) - 65;
            BDGIM_alpha(end+1,:) = [1, cell2mat(lData(1:3)), hour, lData{6}];
        end
        if contains(NAV{i},'BDSB')     	% BDGIM, alpha coefficients
            lData = textscan(NAV{i},'%*s %f %f %f %f %s %f');
            % convert char to start of hour of transmission time [sow] 
            % ||| BDT or GPST?!
            char = lData{5}{1};
            hour = upper(char) - 65;
            BDGIM_beta(end+1,:) = [2, cell2mat(lData(1:3)), hour, lData{6}];
        end        
    end
    %     if contains(fData{i},'CORR TO SYSTEM TIME')     % NOT IMPLEMENTED
    %         % TauC = textscan(fData{i},'%f'); % [s] Correction to system time to
    %     end
    %     if contains(fData{i},'LEAP SECONDS')     % NOT IMPLEMENTED
    %     end
end     % end of read header info
klob = [coeff_alpha; coeff_beta];     % save Klobuchar coefficients
BDGIM = [BDGIM_alpha; BDGIM_beta];


%% Initialize Navigation Data Variables
CharGNSS = cellfun( @(a) a(1,1), NAV(iHeadEnd+1:end));
no_eph_gps = sum(CharGNSS == 'G');
no_eph_glo = sum(CharGNSS == 'R');
no_eph_gal = sum(CharGNSS == 'E');
no_eph_bds = sum(CharGNSS == 'C');

Eph_GPS = zeros(29, no_eph_gps);
Eph_GLO = zeros(19, no_eph_glo);
Eph_GAL = zeros(29, no_eph_gal);
Eph_BDS = zeros(28, no_eph_bds);



% LOOP OVER DATA RECORDS
i = iHeadEnd + 1;
i_gps = 1;      i_glo = 1;      i_gal = 1;     i_bds = 1;
while i <= length(NAV)            % loop from END OF HEADER to end of file
    line = NAV{i};
    
    if isempty(strtrim(line))
        % jump over empty lines
        continue
    end
    
    
    %% ------ GPS navigation message
    if line(1) == 'G'
        % -+-+- line 0 -+-+-
        line = line(2:end);
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        prn  = lData(1);            % PRN number of sat
        year = lData(2);            % year
        if year < 1900
            if year > 80
                year = year + 1900;
            else
                year = year + 2000;
            end
        end
        month  = lData(3);                          % month
        day    = lData(4);                          % day
        hour   = lData(5);                          % hour
        minute = lData(6);                          % min
        second = lData(7);                          % sec of clock
        af0    = lData(8);                          % sv clock bias [s]
        af1    = lData(9);                          % sv clock drift [s/s]
        af2    = lData(10);                         % sv clock drift rate [s/s^2]
        hour   = hour + minute/60 + second/3600;    % decimal hour of clock
        jd = cal2jd_GT(year,month,day+hour/24);        % Julian day of clock
        [~, toc, ~] = jd2gps_GT(jd);                   % ~, seconds of gps-week
        % -+-+- line 1 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        IODE   = lData(1);          % Issue of Data (IOD)
        crs    = lData(2);          % [m]
        Delta_n= lData(3);      	% [rad/s]
        M0     = lData(4);          % [rad]
        % -+-+- line 2 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        cuc   = lData(1);           % [rad]
        ecc   = lData(2);           % Eccentricity
        cus   = lData(3);           % [rad]
        roota = lData(4);           % sqrt(a) [sqrt(m)]
        % -+-+- line 3 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        toe = lData(1);             % time of ephemeris [sow]
        cic = lData(2);             % [rad]
        Omega0 = lData(3);          % [rad]
        cis = lData(4);             % [rad]
        % -+-+- line 4 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        i0       = lData(1);        % [rad]
        crc      = lData(2);        % [m]
        omega    = lData(3);        % [rad]
        Omegadot = lData(4);        % [rad/s]
        % -+-+- line 5 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        idot = lData(1);            % [rad/s]
        codes = int64(lData(2));    % GPS: codes on L2 channel
        weekno = lData(3);          % GPS week
        if size(lData,1) == 4
            L2flag = lData(4);      % GPS: L2 flag
        end
        % -+-+- line 6 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        accuracy = lData(1);        % sat in space accuracy [m]
        svhealth = int64(lData(2)); % GPS: bits 17-22 w 3 sf 1
        tgd = lData(3);             % GPS: time group delay [s]
        IODC = lData(4);            % GPS: IOD clocks
        % -+-+- line 7 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        tom = lData(1);             % transmission time of message [sow]
        % save data
        
        Eph_GPS( 1,i_gps) = prn;        % satellite number
        Eph_GPS( 2,i_gps) = af2;        % [s/s^2], sv clock drift rate
        Eph_GPS( 3,i_gps) = M0;         % [rad]
        Eph_GPS( 4,i_gps) = roota;      % [sqrt(m)]
        Eph_GPS( 5,i_gps) = Delta_n;    % [rad/s]
        Eph_GPS( 6,i_gps) = ecc;        % Eccentricity
        Eph_GPS( 7,i_gps) = omega;      % [rad]
        Eph_GPS( 8,i_gps) = cuc;        % [rad]
        Eph_GPS( 9,i_gps) = cus;        % [rad]
        Eph_GPS(10,i_gps) = crc;        % [m]
        Eph_GPS(11,i_gps) = crs;        % [m]
        Eph_GPS(12,i_gps) = i0;         % [rad]
        Eph_GPS(13,i_gps) = idot;       % [rad/s]
        Eph_GPS(14,i_gps) = cic;        % [rad]
        Eph_GPS(15,i_gps) = cis;        % [rad]
        Eph_GPS(16,i_gps) = Omega0;     % [rad]
        Eph_GPS(17,i_gps) = Omegadot;   % [rad/s]
        Eph_GPS(18,i_gps) = toe;        % [sow], time of ephemeris
        Eph_GPS(19,i_gps) = af0;        % [s], sv clock bias
        Eph_GPS(20,i_gps) = af1;        % [s/s], sv clock drift
        Eph_GPS(21,i_gps) = toc;        % [s], seconds of gps-week
        Eph_GPS(22,i_gps) = tgd;        % [s], time group delay
        Eph_GPS(23,i_gps) = svhealth;   % bits 17-22 w 3 sf 1
        Eph_GPS(24,i_gps) = IODE;       % Issue of Data Ephemeris
        Eph_GPS(25,i_gps) = IODC;       % Issue of Data Clocks
        Eph_GPS(26,i_gps) = codes;      % codes on L2 channel
        Eph_GPS(27,i_gps) = weekno;     % gps-week, continuos number
        Eph_GPS(28,i_gps) = accuracy;   % [m], sat in space accuracy
        Eph_GPS(29,i_gps) = tom;        % transmission time of message [sow]
        i_gps = i_gps + 1;
    end
    
    %% ------ GLONASS navigation message
    if line(1) == 'R'               % GLONASS-navigation message
        % -+-+- line 0 -+-+-
        line = line(2:end);
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        svprn  = lData(1);      	% PRN number of sat
        year = lData(2);            % year
        if year < 1900
            if year > 80
                year = year + 1900;
            else
                year = year + 2000;
            end
        end
        month  = lData(3);                          % month
        day    = lData(4);                          % day
        hour   = lData(5);                          % hour
        minute = lData(6);                          % min
        second = lData(7);                          % sec
        % calculation of toe in GPS time:
        jd = cal2jd_GT(year, month, day + hour/24 + minute/1440 + second/86400);
        [~,sow_utc,~] = jd2gps_GT(jd);
        sod_moscow = mod(round(sow_utc) + 3*3600,86400);
        IOD = floor(sod_moscow/900);
        jd = jd + leap_sec/(60*60*24);      % Introduction of leap second between GPS and UTC
        [week,sow,~] = jd2gps_GT(jd);
        toe = sow;                  % epoch of ephemerides GPS (converted from UTC)
        woe = week;
        % remaining entries
        TauN    = lData(8);         % SV clock bias [s]
        GammaN	= lData(9);         % SV relative frequency bias 
        tk      = lData(10);        % Meassage frame time in [s] of UTC week
        % -+-+- line 1 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        X       = lData(1);         % [km]
        X_vel	= lData(2);         % [km/s]
        X_acc   = lData(3);         % [km/s^2]
        health 	= lData(4);         % 0=OK
        % -+-+- line 2 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        Y       = lData(1);
        Y_vel   = lData(2);
        Y_acc   = lData(3);
        f_num   = lData(4);         % frequency number, integer number
        % -+-+- line 3 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        Z = lData(1);
        Z_vel = lData(2);
        Z_acc = lData(3);
        age = lData(4);
        
        % save data
        Eph_GLO( 1,i_glo)  = svprn;      % satellite number
        Eph_GLO( 2,i_glo)  = TauN;       % [s], satellite clock offset, - TauN
        Eph_GLO( 3,i_glo)  = GammaN;     % relative frequency bias, + GammaN, relativistic effects + ddrift
        Eph_GLO( 4,i_glo)  = tk;         % [sow UTC], message frame time tk
        Eph_GLO( 5,i_glo)  = X;          % [km], X-coordinate of satellite in PZ90
        Eph_GLO( 6,i_glo)  = Y;          % [km], Y-coordinate of satellite in PZ90
        Eph_GLO( 7,i_glo)  = Z;          % [km], Z-coordinate of satellite in PZ90
        Eph_GLO( 8,i_glo)  = X_vel;      % [km/s], X-velocity of satellite in PZ90
        Eph_GLO( 9,i_glo)  = Y_vel;      % [km/s], Y-velocity of satellite in PZ90
        Eph_GLO(10,i_glo)  = Z_vel;      % [km/s], Z-velocity of satellite in PZ90
        Eph_GLO(11,i_glo) = X_acc;       % [km/s^2], X-acceleration of satellite in PZ90
        Eph_GLO(12,i_glo) = Y_acc;       % [km/s^2], Y-acceleration of satellite in PZ90
        Eph_GLO(13,i_glo) = Z_acc;       % [km/s^2], Z-acceleration of satellite in PZ90
        Eph_GLO(14,i_glo) = health;      % health of satellite (0=OK)
        Eph_GLO(15,i_glo) = f_num;       % channel number (-7, ..., 13)
        TauC = 0;
        Eph_GLO(16,i_glo) = TauC;        % [s], -TauC, Correction system time to UTC (SU)
        Eph_GLO(17,i_glo) = woe;         % gps-week, week of ephemerides
        Eph_GLO(18,i_glo) = toe;         % epoch of ephemerides converted into GPS sow
        Eph_GLO(19,i_glo) = IOD;         % Issue of Data
        i_glo = i_glo + 1;
    end
    
    %% ------ GALILEO navigation message
    if line(1) == 'E'
        % -+-+- line 0 -+-+-
        line = line(2:end);
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        prn  = lData(1);            % PRN number of sat
        year = lData(2);            % year
        if year < 1900
            if year > 80
                year = year + 1900;
            else
                year = year + 2000;
            end
        end
        month  = lData(3);                          % month
        day    = lData(4);                          % day
        hour   = lData(5);                          % hour
        minute = lData(6);                          % min
        second = lData(7);                          % sec of clock
        af0    = lData(8);                          % sv clock bias [s]
        af1    = lData(9);                          % sv clock drift [s/s]
        af2    = lData(10);                         % sv clock drift rate [s/s^2]
        hour   = hour + minute/60 + second/3600;    % decimal hour of clock
        jd = cal2jd_GT(year,month,day+hour/24);        % Julian day of clock
        [~, toc, ~] = jd2gps_GT(jd);                   % ~, seconds of gps-week
        % -+-+- line 1 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        IODE   = lData(1);          % Issue of Data (IOD)
        crs    = lData(2);          % [m]
        Delta_n= lData(3);      	% [rad/s]
        M0     = lData(4);          % [rad]
        % -+-+- line 2 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        cuc   = lData(1);           % [rad]
        ecc   = lData(2);           % Eccentricity
        cus   = lData(3);           % [rad]
        roota = lData(4);           % sqrt(a) [sqrt(m)]
        % -+-+- line 3 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        toe = lData(1);             % time of ephemeris [sow]
        cic = lData(2);             % [rad]
        Omega0 = lData(3);          % [rad]
        cis = lData(4);             % [rad]
        % -+-+- line 4 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        i0       = lData(1);        % [rad]
        crc      = lData(2);        % [m]
        omega    = lData(3);        % [rad]
        Omegadot = lData(4);        % [rad/s]
        % -+-+- line 5 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        idot = lData(1);            % [rad/s]
        datasource=int64(lData(2));	% for GALILEO data sources (FLOAT->INT)
        % bit 0 set: I/NAV E1-B
        % bit 1 set: F/NAV E5a-I
        % bit 2 set: I/NAV E5b-I
        % bit 3 + 4 reserved for Galileo internal use
        % bit 8 set: af0-af2, toc, SISA are for E5a-E1
        % bit 9 set: af0-af2, toc, SISA are for E5b-E1
        weekno = lData(3);          % Galileo week
        % lData(4) is spare
        % -+-+- line 6 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        sisa = lData(1);         	% signal in space accuracy [m]
        svhealth = int64(lData(2));	% GALILEO:(FLOAT->INT)
        % bit 0:    E1-B DVS
        % bit 1-2:  E1-B HS
        % bit 3:    E5-A DVS
        % bit 4-5:  E5-A HS
        % bit 6:    E5-B DVS
        % bit 7-8:  E5-B HS
        bgd_a = lData(3);        	% Broadcasted Group Delay E5a/E1 [s]
        bgd_b = lData(4);          	% Broadcasted Group Delay E5b/E1 [s]
        % -+-+- line 7 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        tom = lData(1);             % transmission time of message [sow]
        
        % save data
        Eph_GAL( 1,i_gal) = prn;        % satellite number
        Eph_GAL( 2,i_gal) = af2;        % [s/s^2], sv clock drift rate
        Eph_GAL( 3,i_gal) = M0;         % [rad]
        Eph_GAL( 4,i_gal) = roota;      % [sqrt(m)]
        Eph_GAL( 5,i_gal) = Delta_n; 	% [rad/s]
        Eph_GAL( 6,i_gal) = ecc;        % Eccentricity
        Eph_GAL( 7,i_gal) = omega;      % [rad]
        Eph_GAL( 8,i_gal) = cuc;        % [rad]
        Eph_GAL( 9,i_gal) = cus;        % [rad]
        Eph_GAL(10,i_gal) = crc;        % [m]
        Eph_GAL(11,i_gal) = crs;        % [m]
        Eph_GAL(12,i_gal) = i0;         % [rad]
        Eph_GAL(13,i_gal) = idot;       % [rad/s]
        Eph_GAL(14,i_gal) = cic;        % [rad]
        Eph_GAL(15,i_gal) = cis;        % [rad]
        Eph_GAL(16,i_gal) = Omega0;     % [rad]
        Eph_GAL(17,i_gal) = Omegadot;   % [rad/s]
        Eph_GAL(18,i_gal) = toe;        % [sow], time of ephemeris
        Eph_GAL(19,i_gal) = af0;        % [s], sv clock bias
        Eph_GAL(20,i_gal) = af1;        % [s/s], sv clock drift
        Eph_GAL(21,i_gal) = toc;        % [s], seconds of galileo-week
        Eph_GAL(22,i_gal) = bgd_a;   	% Broadcasted Group Delay E5a/E1 [s]
        Eph_GAL(23,i_gal) = svhealth;   % ????
        Eph_GAL(24,i_gal) = IODE;       % Issue of Data Ephemeris
        Eph_GAL(25,i_gal) = bgd_b;    	% Broadcasted Group Delay E5b/E1 [s]
        Eph_GAL(26,i_gal) = datasource;	% ???????????
        Eph_GAL(27,i_gal) = weekno;     % galileo-week
        Eph_GAL(28,i_gal) = sisa;       % signal in space accuracy [m]
        Eph_GAL(29,i_gal) = tom;        % transmission time of message [sow]
        i_gal = i_gal + 1;
    end
    
    %% ------ BEIDOU navigation message
    if line(1) == 'C'
        % -+-+- line 0 -+-+-
        line = line(2:end);
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        prn  = lData(1);            % PRN number of sat
        year = lData(2);            % year
        if year < 1900
            if year > 80
                year = year + 1900;
            else
                year = year + 2000;
            end
        end
        month  = lData(3);                          % month
        day    = lData(4);                          % day
        hour   = lData(5);                          % hour
        minute = lData(6);                          % min
        second = lData(7) - 00;                   	% sec, ||| convert to GPS time
        af0    = lData(8);                          % sv clock bias [s]
        af1    = lData(9);                          % sv clock drift [s/s]
        af2    = lData(10);                         % sv clock drift rate [s/s^2]
        hour   = hour + minute/60 + second/3600;    % decimal hour of clock
        jd = cal2jd_GT(year,month,day+hour/24);        % Julian day of clock
        [~, toc, ~] = jd2gps_GT(jd);                   % ~, seconds of GPS week
        % -+-+- line 1 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        AODE   = lData(1);          % Age of Data
        crs    = lData(2);          % [m]
        Delta_n= lData(3);      	% [rad/s]
        M0     = lData(4);        	% [rad]
        % -+-+- line 2 -+-+-
        i = i+1;
        line  = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        cuc     = lData(1);           % [rad]
        ecc     = lData(2);           % Eccentricity
        cus     = lData(3);           % [rad]
        roota   = lData(4);           % sqrt(a) [sqrt(m)]
        % -+-+- line 3 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        toe = lData(1) - 00;       	% time of ephemeris, ||| [s of ??? week]
        IOD = mod(toe/720,240);     % calculate IOD (IGS SSR v1.00, 7.1)
        cic = lData(2);             % [rad]
        Omega0 = lData(3);          % [rad]
        cis = lData(4);             % [rad]
        % -+-+- line 4 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        i0       = lData(1);        % [rad]
        crc      = lData(2);        % [m]
        omega    = lData(3);        % [rad]
        Omegadot = lData(4);        % [rad/s]
        % -+-+- line 5 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        if numel(lData) ~= 2
            idot = lData(1);            % [rad/s]
            spare = lData(2);           % empty
            bdsweek = lData(3);     	% BDS week
            % spare = lData(4);      	% empty
        else
            idot = lData(1);            % [rad/s]
            bdsweek = lData(2);     	% BDS week
        end
        % -+-+- line 6 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        SV_acc = lData(1);          % SV accuracy [m]
        SatH1 = lData(2);           % satellite health, 0 = good, 1 = not
        tgd1 = lData(3);            % time group delay B1/B3 [s]
        tgd2 = lData(4);            % time group delay B2/B3 [s]
        % -+-+- line 7 -+-+-
        i = i+1;
        line = NAV{i};
        lData = textscan(line,'%f'); lData = lData{1}; if isempty(lData); continue; end
        tom = lData(1) - 00;     	% transmission time of message ||| [s of ?? week]
        AODC = lData(2);            % Age of Data Clock
%         spare = lData(3);           % empty
%         spare = lData(3);           % empty

        % save data
        Eph_BDS( 1,i_bds) = prn;        % satellite number
        Eph_BDS( 2,i_bds) = af2;        % [s/s^2], sv clock drift rate
        Eph_BDS( 3,i_bds) = M0;         % [rad]
        Eph_BDS( 4,i_bds) = roota;      % [sqrt(m)]
        Eph_BDS( 5,i_bds) = Delta_n;    % [rad/s]
        Eph_BDS( 6,i_bds) = ecc;        % [], Eccentricity
        Eph_BDS( 7,i_bds) = omega;      % [rad]
        Eph_BDS( 8,i_bds) = cuc;        % [rad]
        Eph_BDS( 9,i_bds) = cus;        % [rad]
        Eph_BDS(10,i_bds) = crc;        % [m]
        Eph_BDS(11,i_bds) = crs;        % [m]
        Eph_BDS(12,i_bds) = i0;         % [rad]
        Eph_BDS(13,i_bds) = idot;       % [rad/s]
        Eph_BDS(14,i_bds) = cic;        % [rad]
        Eph_BDS(15,i_bds) = cis;        % [rad]
        Eph_BDS(16,i_bds) = Omega0;     % [rad]
        Eph_BDS(17,i_bds) = Omegadot;   % [rad/s]
        Eph_BDS(18,i_bds) = toe;        % [s of BDS week], time of ephemeris
        Eph_BDS(19,i_bds) = af0;        % [s], sv clock bias
        Eph_BDS(20,i_bds) = af1;        % [s/s], sv clock drift
        Eph_BDS(21,i_bds) = toc;        % [s], seconds of gps-week
        Eph_BDS(22,i_bds) = IOD;        % Issue of Data
        Eph_BDS(23,i_bds) = SatH1;      % satellite health, 0 = good, 1 = not
        Eph_BDS(24,i_bds) = AODE;       % Age of Data
        Eph_BDS(25,i_bds) = tgd1;       % [s], time group delay B1/B3
        Eph_BDS(26,i_bds) = tgd2;       % [s], time group delay B2/B3
        Eph_BDS(27,i_bds) = bdsweek;   	% bds-week
        Eph_BDS(28,i_bds) = SV_acc;     % [m], sat in space accuracy
        Eph_BDS(29,i_bds) = tom;        % transmission time of message [sow]
        i_bds = i_bds + 1;
    end
    
    i = i + 1;          % increase line counter
    
end


end
