function [BDGIM, eph] = read_nav_bds(ephemerisfile, leap_sec)
% Reads a RINEX 3.x BeiDou Navigation Message file and reformats the data 
% into a matrix with 28 rows and a column for each satellite. This matrix 
% is returned. Units are either seconds, meters, or radians
% For details check the Rinex 3.x specification, there is a description for
% each row and variable.
% 
% INPUT:
%	ephemerisfile	string with path of RINEX navigation file
%   leap_sec        integer, leap seconds between UTC and GPS time
% OUTPUT:
%	eph             matrix with data from rinex-file 
%   BDGIM           coefficients of BeiDou global broadcast ionospheric
%                   delay correction model
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% open and read file
fide = fopen(ephemerisfile);
fData = textscan(fide,'%s','Delimiter','\n');   fData = fData{1};
fclose(fide);


%% LOOP OVER HEADER
iHeadBegin = 0;
iHeadEnd   = 0;

for i = 1:length(fData)     % find header start and version
    if contains(fData{i}, 'RINEX VERSION')
        temp = fData{i};
        version = sscanf(temp(1), '%f');
        iHeadBegin = i;
        break;
    end
end

if i > 0                   	% find header end
    for i = 1:length(fData)
        if contains(fData{i},'END OF HEADER')
            iHeadEnd = i;
            break;
        end
    end
    if iHeadEnd == 0
        error('"END OF HEADER" was not found in Beidou Navigation File.');
    end
end

if iHeadBegin
    fContent = iHeadEnd+1 : length(fData);
    if iHeadBegin > 1           % real-time data: maybe header in between
        fContent = [1:iHeadBegin-1, fContent];
    end
    fHeader = iHeadBegin:iHeadEnd;
else
    fContent = 1:length(fData);
    fHeader = [];
end


BDGIM_alpha = [];       BDGIM_beta = [];
for i = fHeader  % Read header info
    if contains(fData{i},'BDSA')     	% BDGIM, alpha coefficients
        lData = textscan(fData{i},'%*s %f %f %f %f %s %f');
        % convert char to start of hour of transmission time [sow]
        % ||| BDT or GPST?!
        char = lData{5}{1};
        hour = upper(char) - 65;
        BDGIM_alpha(end+1,:) = [1, cell2mat(lData(1:3)), hour, lData{6}];
    end
    if contains(fData{i},'BDSB')     	% BDGIM, alpha coefficients
        lData = textscan(fData{i},'%*s %f %f %f %f %s %f');
        % convert char to start of hour of transmission time [sow]
        % ||| BDT or GPST?!
        char = lData{5}{1};
        hour = upper(char) - 65;
        BDGIM_beta(end+1,:) = [2, cell2mat(lData(1:3)), hour, lData{6}];
    end
end     % end of read header info
BDGIM = [BDGIM_alpha; BDGIM_beta];



%% LOOP OVER DATA RECORDS
% get number of ephemeris
noeph = length(fContent)/8;         % 8 lines for each data record
eph   = zeros(28, noeph);

k = 0;
for i = 1:noeph
    % -+-+- line 0 -+-+- 
    k = k+1;
    line = fData{fContent(k)};
    line = line(2:end);
    lData = textscan(line,'%f');
    if iscell(lData); lData = lData{1}; end
    svprn = lData(1);                       % PRN number of satellite
    year  = lData(2);                       % year
    if year < 1900
        if year > 80
            year = year+1900;
        else
            year = year+2000;
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
    [~,toc,~] = jd2gps_GT(jd);                     % week of clock, sow of clock [s]
    
    
    % -+-+- line 1 -+-+-
    k=k+1;
    line = fData{fContent(k)};	  
    lData = textscan(line,'%f'); lData = lData{1};
    
    AODE   = lData(1);      % Age of Data
    crs    = lData(2);      % [m]
    deltan = lData(3);    	% [rad/s]
    M0     = lData(4);   	% [rad]
    
    
    % -+-+- line 2 -+-+- 
    k=k+1;
    line = fData{fContent(k)};	  
    lData = textscan(line,'%f'); lData = lData{1};
    
    cuc = lData(1);         % [rad]
    ecc = lData(2);         % Eccentricity
    cus = lData(3);         % [rad]
    roota = lData(4);       % sqrt(a) [sqrt(m)]
    
    
    % -+-+- line 3 -+-+- 
    k=k+1;
    line = fData{fContent(k)};	  
    lData = textscan(line,'%f'); lData = lData{1};
    
    toe = lData(1);         % time of ephemeris, seconds of BDS week
    cic = lData(2);         % [rad]
    Omega0 = lData(3);      % [rad]
    cis = lData(4);         % [rad]
    
    
    % -+-+- line 4 -+-+- 
    k=k+1;
    line = fData{fContent(k)};	  
    lData = textscan(line,'%f'); lData = lData{1};
    
    i0       = lData(1); 	% [rad]
    crc      = lData(2);  	% [m]
    omega    = lData(3);    % [rad]
    Omegadot = lData(4);    % [rad/s]
    
    
    % -+-+- line 5 -+-+- 
    k=k+1;
    line = fData{fContent(k)};
    lData = textscan(line,'%f'); lData = lData{1};
    
    idot = lData(1);        % [rad/s]
    spare = lData(2);       % empty
    BDT_week = lData(3);  	% BeiDou Time Week, started at 1-Jan-2006
%     spare = lData(4);       % empty
    
    
    % -+-+- line 6 -+-+- 
    k=k+1;
    line = fData{fContent(k)};	  
    lData = textscan(line,'%f'); lData = lData{1};
    
    accuracy = lData(1);    % sat in space accuracy [m]
    satH1 = lData(2);       % no explanation
    TGD1 = lData(3);        % time group delay B1/B3
    TGD2 = lData(4);        % time group delay B2/B3
    
    
    % -+-+- line 7 -+-+- 
    k=k+1;
    line = fData{fContent(k)};	  
    lData = textscan(line,'%f'); lData = lData{1};
    
    tom = lData(1);         % transmission time od message, seconds of BDT week
    AODC = lData(2);     	% Age of Data Clock
%     spare = lData(3);   	% empty
%     spare = lData(4);    	% empty
    
    
    % -+-+- save data -+-+-
    eph(1,i)  = svprn;      % satellite number
    eph(2,i)  = af2;        % [s/s^2], sv clock drift rate 
    eph(3,i)  = M0;         % [rad]
    eph(4,i)  = roota;      % [sqrt(m)]
    eph(5,i)  = deltan;     % [rad/s]
    eph(6,i)  = ecc;        % [], Eccentricity 
    eph(7,i)  = omega;      % [rad]
    eph(8,i)  = cuc;        % [rad]
    eph(9,i)  = cus;        % [rad]
    eph(10,i) = crc;        % [m]
    eph(11,i) = crs;        % [m]
    eph(12,i) = i0;         % [rad]
    eph(13,i) = idot;       % [rad/s]
    eph(14,i) = cic;        % [rad]
    eph(15,i) = cis;        % [rad]
    eph(16,i) = Omega0;     % [rad]
    eph(17,i) = Omegadot;   % [rad/s]
    eph(18,i) = toe;        % [sow], time of ephemeris 
    eph(19,i) = af0;        % [s], sv clock bias 
    eph(20,i) = af1;        % [s/s], sv clock drift 
    eph(21,i) = toc;        % [s], seconds of gps-week
    eph(22,i) = 0;          % empty
    eph(23,i) = satH1;
    eph(24,i) = AODE;       % Issue of Data Ephemeris
    eph(25,i) = TGD1;       % [s], time group delay B1/B3
    eph(26,i) = TGD2;       % [s], time group delay B2/B3
    eph(27,i) = BDT_week;  	% BeiDou Time week
    eph(28,i) = accuracy;   % [m], sat in space accuracy
end     % end of loop over data records






