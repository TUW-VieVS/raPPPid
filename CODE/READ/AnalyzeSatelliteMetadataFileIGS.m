function SATS = AnalyzeSatelliteMetadataFileIGS(year, doy)
% This function takes a specific date and the IGS satellite metadata file.
% Then a cell is created containing information about the active PRNs on 
% this day for GPS, GLONASS, Galileo, BeiDou, and QZSS.
% 
% Format description of the IGS satellite metadata file: 
% https://files.igs.org/pub/resource/working_groups/multi_gnss/Metadata_SINEX_1.10.pdf
% 
% 
% INPUT:
%   year        number, specified year
%   doy         number, specified day of year (can include fractions od day)
% OUTPUT:
%   SATS        cell, containing (columns):
%                PRN | raPPPid number | SVN | satellite block | description | plane
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


% ||| download newest version of metadata file if necessary


if nargin == 2
    % calculate the julian date for the specified date
    curr_jd = doy2jd_GT(year, doy);
else
    % calculate the julian date for the current date
    now = datetime('now', 'Format','yyyy-MM-dd');
    curr_jd = cal2jd_GT(now.Year, now.Month, now.Day + now.Hour/24);
end

% define file path to IGS satellite metadata file in raPPPid folder
filepath = [Path.DATA 'igs_satellite_metadata.snx'];

% initialize output
SATS = {};      % PRN | raPPPid number | SVN | satellite block | description

% download IGS satellite metadata file if not existing
if ~isfile(filepath)
    download_IGS_SatelliteMetadataFile()
end

% open, read and close file
fid = fopen(filepath);
MDATA = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
MDATA = MDATA{1};
fclose(fid);

% extract specifix SINEX blocks
SAT_ID = getBlock(MDATA, 'SATELLITE/IDENTIFIER');
SAT_PRN = getBlock(MDATA, 'SATELLITE/PRN');
SAT_PLANE = getBlock(MDATA, 'SATELLITE/PLANE');



%% "SATELLITE/PRN"

n_PRN = numel(SAT_PRN);
for i = 1:n_PRN     % loop over lines

    tline = SAT_PRN{i};     % get current line
    
    if tline(1) == '*' || tline(1) == '+'  || tline(1) == '-'  
        continue;   % jump over unnecessary lines
    end
    
    C = strsplit(strip(tline));     % get data of current line
    
    if strcmp(C{3}, '0000:000:00000')
        C{3} = '2500:000:00000';        % be careful: this works only until year 2500
    end
    
    % convert launch and decomission date to julian date
    yeardoy_1 = convertTimeStamp(C{2});
    yeardoy_2 = convertTimeStamp(C{3});
    jd_1 = doy2jd_GT(yeardoy_1(1), yeardoy_1(2));
    jd_2 = doy2jd_GT(yeardoy_2(1), yeardoy_2(2));
    
    % determine and save only prns active on the specified date
    if (jd_1 <= curr_jd && curr_jd < jd_2)
        svn = C{1};         % space vehicle number
        prn = C{4};         % pseudo-random noise
        if any(prn(1) == 'GRECJ')       % save only GRECJ satellites
            SATS{end+1, 1} = prn;
            SATS{end,   2} = char2gnss_number(prn(1)) + str2double(prn(2:3));
            SATS{end,   3} = svn;
        end
    end
end

% sort table with raPPPid internal satellite number
SATS = sortrows(SATS, 2);



%% "SATELLITE/IDENTIFIER"

n_ID = numel(SAT_ID);
for i = 1:n_ID          % loop over lines
    
    tline = SAT_ID{i};      % get current line
    
    if tline(1) == '*' || tline(1) == '+'  || tline(1) == '-'
        continue;   % jump over unnecessary lines
    end
    
    C = strsplit(strip(tline));     % get data of current line
    
    block = C{4};   % information about satellite block
    
    % save information if satellite belongs to prns active on the specified day
    bool = contains(SATS(:,3), C{1});
    if any(bool)
        SATS(bool, 4) = cellstr(block);
        SATS(bool, 5) = cellstr(block2descr(block)); 	% get description of block
    end
end



%% "SATELLITE/PLANE"

n_PLANE = numel(SAT_PLANE);
for i = 1:n_PLANE           % loop over lines
    
    tline = SAT_PLANE{i};       % get current line
    
    if tline(1) == '*' || tline(1) == '+'  || tline(1) == '-'
        continue;   % jump over unnecessary lines
    end
    
    C = strsplit(strip(tline));     % get data of current line
    
    plane = C{4};   % information about satellite block
    
    % save information if satellite belongs to prns active on the specified day
    bool = contains(SATS(:,3), C{1});
    if any(bool)
        SATS(bool, 6) = cellstr(plane2descr(plane));    % get description of plane
    end
end




function [] = download_IGS_SatelliteMetadataFile()
% This function downloads the IGS satellite metadata file from the IGS site
% IGS server is slow -> increase timeout
woptions = weboptions;
woptions.Timeout = 60;      % use 60s (usually 5s is the default value)
% download file
file = 'igs_satellite_metadata.snx';
websave([Path.DATA file], ['https://files.igs.org/pub/station/general/' file], woptions);

function DATA = getBlock(MDATA, block_id)
% This function extracts a specified block of the metadata file
% INPUT:
%   MDATA       cell, all lines of metadata file
%   block_id    string, identifier of block to extract
% OUTPUT:
%   DATA        cell, lines of the specified SINEX block
bool_1 = contains(MDATA, ['+' block_id]);
bool_2 = contains(MDATA, ['-' block_id]);
idx_1 = find(bool_1, 1, 'first');
idx_2 = find(bool_2, 1, 'first');
DATA = MDATA(idx_1:idx_2);

function yeardoy = convertTimeStamp(str)
% This function converts the timestampt into year and (fractional) doy
% str ... timestamp (e.g., 1991:012:43200)
% yeardoy ... (1) year and (2) doy
yeardoy(1) = str2double(str(01:04));
yeardoy(2) = str2double(str(06:07)) + str2double(str(10:14))/86400;

function descr = block2descr(block)
% This function finds the description to a specific satellite block
switch block
    case 'GPS-I'
        descr = 'GPS test satellite';
    case 'GPS-II'
        descr = 'operational GPS satellite';
    case 'GPS-IIA'
        descr = 'modified Block II satellites';
    case 'GPS-IIR-A'
        descr = 'replenishment GPS satellite with legacy antenna panel';
    case 'GPS-IIR-B'
        descr = 'replenishment GPS satellite with new antenna panel';
    case 'GPS-IIR-M'
        descr = 'modernized GPS-IIR satellite';
    case 'GPS-II-F'
        descr = 'follow-on GPS satellite';
    case 'GPS-IIF'
        descr = 'follow-on GPS satellite';        
    case 'GPS-III'
        descr = '3rd generation GPS satellite';
    case 'GPS-IIIF'
        descr = '3rd generation follow-on GPS satellite';
    case 'GLO'
        descr = '1st generation GLONASS satellite';
    case 'GLO-M'
        descr = 'modernized GLONASS satellite';
    case 'GLO-M+'
        descr = 'GLONASS-M with L3 CDMA capability';
    case 'GLO-K1A'
        descr = '1st generation GLONASS-K with two antenna panels';
    case 'GLO-K1B'
        descr = '1st generation GLONASS-K with single antenna panel';
    case 'GLO-K1+'
        descr = '1st generation GLONASS-K with L2 CDMA capability';
    case 'GLO-K2'
        descr = '2nd generation GLONASS-K';
    case 'GAL-0A'
        descr = 'GIOVE-A';
    case 'GAL-0B'
        descr = 'GIOVE-B';
    case 'GAL-1'
        descr = 'Galileo IOV';
    case 'GAL-2'
        descr = 'Galileo FOC';
    case 'BDS-2G'
        descr = 'BeiDou-2 GEO';
    case 'BDS-2I'
        descr = 'BeiDou-2 IGSO';
    case 'BDS-2M'
        descr = 'BeiDou-2 MEO';
    case 'BDS-3SI-CAST'
        descr = 'BeiDou-3S IGSO by CAST';
    case 'BDS-3SI-SECM'
        descr = 'BeiDou-3S IGSO by SECM';
    case 'BDS-3SM-CAST'
        descr = 'BeiDou-3S MEO by CAST';
    case 'BDS-3SM-SECM'
        descr = 'BeiDou-3S MEO by SECM';
    case 'BDS-3G'
        descr = 'BeiDou-3 GEO';
    case 'BDS-3I'
        descr = 'BeiDou-3 IGSO';
    case 'BDS-3M-CAST'
        descr = 'BeiDou-3 MEO by CAST';
    case 'BDS-3M-SECM-A'
        descr = 'BeiDou-3 MEO by SECM';
    case 'BDS-3M-SECM-B'
        descr = 'BeiDou-3 MEO by SECM, modified bus';
    case 'QZS-1'
        descr = '1st generation QZSS IGSO';
    case 'QZS-2I'
        descr = '2nd generation QZSS IGSO';
    case 'QZS-2G'
        descr = '2nd generation QZSS GEO';
    case 'QZS-2A'
        descr = 'QZSS Block IIA IGSO';
    case 'QZS-3I'
        descr = '3rd generation QZSS IGSO';
    case 'QZS-3G'
        descr = '3rd generation QZSS GEO';
    case 'IRS-1G'
        descr = '1st generation IRNSS GEO';
    case 'IRS-1I'
        descr = '1st generation IRNSS IGSO';
    case 'IRS-2G'
        descr = '2nd generation IRNSS GEO';
    otherwise
        descr = '';
end

function descr = plane2descr(plane)
% This function finds the description to a specific satellite plane
switch plane
    case {'1', '2', '3', '4', '5', '6'}
        descr = plane;          % regular planes 
    case 'X'
        descr = 'irregular';    % irregular plane, e.g., E201/2 
    case 'I'
        descr = 'IGSO';         % Inclined Geosynchronous Orbit, longitude given in slot
    case 'G'
        descr = 'GEO';          % Geostationary Earth Orbit, longitude given in slot     
    case 'Q'
        descr = 'Q-GEO';        % Quasi-Geostationary Orbit, longitude given in slot
    otherwise
        descr = ''; 
end

