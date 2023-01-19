function [iono_coeff, eph] = read_nav_gps(ephemerisfile)

% Reads a RINEX GPS Navigation Message file and reformats the data into a 
% matrix with 28 rows and a column for each satellite. This matrix is 
% returned. Units are either seconds, meters, or radians
% based on (c) by Kai Borre: $Revision: 1.0 $  $Date: 1997/09/24  $
%
% INPUT:
% 	ephemerisfile:  string with path of RINEX navigation file
% OUTPUT:
% 	iono_coeff: 	ionosphere coefficients for Klobuchar model
%	eph:            matrix with data from rinex-file  
%
%   Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



coeff_alpha = [];
coeff_beta = [];

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
        error('No END of Header found in GPS n-File.');
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

for i = fHeader  % Read header info
    if contains(fData{i},'ION ALPHA')           % RINEX 2.x
        coeff_alpha = textscan(fData{i},'%f');
        coeff_alpha = coeff_alpha{1}';
    end
    if contains(fData{i},'ION BETA')            % RINEX 2.x
        coeff_beta = textscan(fData{i},'%f');
        coeff_beta = coeff_beta{1}';
    end
    if contains(fData{i},'IONOSPHERIC CORR') 	% RINEX 3.x
        if contains(fData{i},'GPSB')
            coeff_beta = cell2mat(textscan(fData{i},'%*s %f %f %f %f'));
        elseif contains(fData{i},'GPSA')
            coeff_alpha = cell2mat(textscan(fData{i},'%*s %f %f %f %f'));
        end
    end
    
    if contains(fData{i},'CORR TO SYSTEM TIME')
        % TauC = textscan(fData{i},'%f'); % [s] Correction to system time to
    end
    
end     % end of read header info

iono_coeff = [coeff_alpha; coeff_beta];


%% LOOP OVER DATA RECORDS
% get number of ephemeris:
noeph = length(fContent)/8;         % 8 lines for each data record
eph   = zeros(28, noeph);

k = 0;
for i = 1:noeph
    % -+-+- line 0 -+-+- 
    k = k + 1;
    line = fData{fContent(k)};
    if version == 3
        line = line(2:end);
    end
    lData = textscan(line,'%f');
    if iscell(lData); lData = lData{1}; end
    svprn = lData(1);       % PRN number of sat
    year  = lData(2);       % year
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
    jd = cal2jd_GT(year,month,day+hour/24);        % Jul. day of clock
    [~, toc, ~] = jd2gps_GT(jd);                   % ~, seconds of gps-week
    
    
    % -+-+- line 1 -+-+-
    k = k+1;
    line = fData{fContent(k)};	  %
    lData = textscan(line,'%f'); lData = lData{1};
    
    IODE   = lData(1); 	% Issue of Data (IOD)
    crs    = lData(2); 	% [m]
    deltan = lData(3); 	% [rad/s]
    M0     = lData(4); 	% [rad]
    
    
    % -+-+- line 2 -+-+- 
    k = k+1;
    line = fData{fContent(k)};	  %
    lData = textscan(line,'%f'); lData = lData{1};
    
    cuc   = lData(1);   % [rad]
    ecc   = lData(2);   % Eccentricity
    cus   = lData(3);   % [rad]
    roota = lData(4);   % sqrt(a) [sqrt(m)]
    
    
    % -+-+- line 3 -+-+- 
    k = k+1;
    line = fData{fContent(k)};	  %
    lData = textscan(line,'%f'); lData = lData{1};
    
    toe = lData(1);     % time of ephemeris [sow]
    cic = lData(2);     % [rad]
    Omega0 = lData(3);  % [rad]
    cis = lData(4);     % [rad]
    
    
    % -+-+- line 4 -+-+- 
    k = k+1;
    line = fData{fContent(k)};	 
    lData = textscan(line,'%f'); lData = lData{1};
    
    i0       = lData(1);        % [rad]
    crc      = lData(2);        % [m]
    omega    = lData(3);        % [rad]
    Omegadot = lData(4);        % [rad/s]
    
    
    % -+-+- line 5 -+-+- 
    k = k+1;
    line = fData{fContent(k)};
    lData = textscan(line,'%f'); lData = lData{1};
    
    idot = lData(1);            % [rad/s]
    codes = int64(lData(2));    % GPS: codes on L2 channel
    weekno = lData(3);          % GPS week
    if size(lData,1) == 4
        L2flag = lData(4);      % GPS: L2 flag
    end
    
    
    % -+-+- line 6 -+-+- 
    k = k+1;
    line = fData{fContent(k)}; 
    lData = textscan(line,'%f'); lData = lData{1};
    
    accuracy = lData(1);        % sat in space accuracy [m]
    svhealth = int64(lData(2)); % GPS: bits 17-22 w 3 sf 1
    tgd = lData(3);             % GPS: time group delay [s]
    IODC = lData(4);            % GPS: IOD clocks
    
    
    % -+-+- line 7 -+-+- 
    k = k+1;
    line = fData{fContent(k)};	  
    lData = textscan(line,'%f'); lData = lData{1};
    
    tom = lData(1);         % transmission time of message [sow]
    
    % save data
    eph(1,i)  = svprn;      % satellite number
    eph(2,i)  = af2;        % [s/s^2], sv clock drift rate 
    eph(3,i)  = M0;         % [rad]
    eph(4,i)  = roota;      % [sqrt(m)]
    eph(5,i)  = deltan;     % [rad/s]
    eph(6,i)  = ecc;        % Eccentricity 
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
    eph(22,i) = tgd;        % [s], time group delay 
    eph(23,i) = svhealth;   % bits 17-22 w 3 sf 1
    eph(24,i) = IODE;       % Issue of Data Ephemeris
    eph(25,i) = IODC;       % Issue of Data Clocks
    eph(26,i) = codes;      % codes on L2 channel
    eph(27,i) = weekno;     % gps-week, continuos number
    eph(28,i) = accuracy;   % [m], sat in space accuracy
end     % end of loop over data records


end     % end of read_nav_gps
