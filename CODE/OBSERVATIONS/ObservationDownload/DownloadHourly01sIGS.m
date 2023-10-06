function [] = DownloadHourly01sIGS(stations, hours, doys, year)
% Function to download, decompress and save highrate RINEX observation data
% with an observation interval of 1sec from IGS stations for the specific hours.
% The data is saved automatically in the right folder of raPPPid.
% The stations of which data should be downloaded can be either delivered as
% cell or entered in the IGS_r3_stations.txt (same folder as this function)
% open('../CODE/OBSERVATIONS/ObservationDownload/IGS_r3_highrate_stations.txt')
% 
% Example call: 
% DownloadHourly01sIGS('', [], 001, 2020)
% DownloadHourly01sIGS('BRUX00BEL_S_', [], 160, 2022)

% INPUT:
%   stations	cell, station names, 9-digit [4-digit name, '00', 3-digit country]
%   hours       vector, hour(s) of doy(s) for download
%   doys        vector, day(s) of year for download
%   year        number, year
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


host = 3;

% ||| Be careful: CDDIS has changed the storage of high-rate files! (IGSMAIL-8189)
% ||| Somehow the cddis download does not work inside the GEO-IT on H: and U:


switch host
    case 1
        URL_host = 'igs.ign.fr:21'; 
    case 2
        URL_host = 'https://cddis.nasa.gov';    % typically very complete
    case 3
        URL_host = 'gssc.esa.int:21';
end

% check input of variable year
if numel(year) > 1 || year < 1900
    errordlg('Check input for year!', 'Error');
    return
end

% check if in WORK folder
if ~contains(pwd, 'WORK')
    errordlg('Change current folder to .../WORK', 'Error');
    return
end

% if hours is empty download whole day
if isempty(hours)
    hours = 0:23;
end

% check if stations is a cell
if ~isempty(stations) && ~iscell(stations)
    stations = {stations};
end

% check if stations list from file
if isempty(stations)
    % open and read txt file
    fid = fopen('../CODE/OBSERVATIONS/ObservationDownload/IGS_r3_highrate_stations.txt');         
    stations = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
    stations = stations{1};
    fclose(fid);
    
    idx_del = contains(stations, '%') | cellfun(@isempty,stations);
    stations(idx_del) = '';
end

% create some variable
no_stations = numel(stations);          % number of stations
no_hours = numel(hours);                % number of days
no_days = numel(doys);                  % number of days
year = sprintf('%04.0f', year);         % convert year to string

% initialize
no_download = 4*no_hours*no_days*no_stations;
URL_folders = cell(no_download,1);
files = cell(no_download,1);
targets = cell(no_download,1);

% Prepare waitbar and print out of epochs to command window 
WBAR = waitbar(0, 'Creating list to download data.', 'Name', 'Downloading IGS Data');  

% loop over stations and doys to create the needed variables for the download
i = 1;
for d = 1:no_days
    for h = 1:no_hours
        for n = 1:no_stations
            for m = 0:15:45
                
                % create variables for current archive/file
                station = strtrim(stations{n});
                doy = sprintf('%03.0f',doys(d));
                hour = sprintf('%02.0f',hours(h));
                min = sprintf('%02.0f',m);
                switch host
                    case 1
                        URL_folder = {['/pub/igs/data/highrate/' year '/' doy '/']};  % igs.ign
                    case 2
                        URL_folder = {['/archive/gnss/data/highrate/' year '/' doy '/' year(3:4) 'd/' hour]};   % cddis
                    case 3
                        URL_folder = {['/gnss/data/highrate/' year '/' doy '/' hour]};   % gssc.esa
                end

                file = [station year doy hour min '_15M_01S_MO.crx.gz'];
                target = ['../DATA/OBS/' year '/' doy];
                
                % save
                URL_folders{i} = URL_folder;
                files{i} = file;
                targets{i} = target;
                i = i + 1;
                
                % create target folder
                [~, ~] = mkdir(target);
            end
        end
    end
end

% update waitbar
if ishandle(WBAR)
    waitbar(0, WBAR, 'Downloading data. This will take some time.')
end

% loop over files to check if RINEX file already exists
i = 1;
while i <= numel(files)
    
    % create string with path of rinex file
    rinex_file = [targets{i}, '/', files{i}];
    rinex_file = erase(rinex_file, '.gz');
    rinex_file = strrep(rinex_file, '.crx', '.rnx');
    
    % check if file exists and delete it from the download list
    if exist(rinex_file, 'file')
        URL_folders(i) = '';
        files(i) = '';
        targets(i) = '';
    else
        i = i + 1;      % otherwise files are skipped
    end

end

% download all files
if host ~= 2
    file_status = ftp_download_multi(URL_host, URL_folders, files, targets, true);
else    % download from cddis
    file_status = get_cddis_data(URL_host, URL_folders, files, targets, true);
end

% update waitbar
if ishandle(WBAR)
    waitbar(0, WBAR, 'Download finished. Decompressing.')
end

% unzip all files and delete archives
unzipped = unzip_and_delete(files, targets);

% update waitbar
if ishandle(WBAR)
    waitbar(0, WBAR, 'Decompressing finished. Convert *.crx to *.rnx')
end

% change path to folder where crx2rnx.exe is stored
work_path = pwd;
cd('../CODE/OBSERVATIONS/ObservationDownload/RNXCMP_4.1.0_Windows_mingw_64bit/bin')

n = numel(files);
for i = 1:n
    
    % create absolute path
    file = unzipped{i};
    full_file_path = [erase(work_path, 'WORK'), file(4:end)];
    
    % prepare string for command window
    str = ['CRX2RNX "' full_file_path '"'];
    
    % writing command to command line to decompress with crx2rnx.exe
    [status, cmdout] = system(str);      % status = 0 = OK
    
    % delete *crx
    delete(full_file_path);    
    

    % update waitbar
    if ishandle(WBAR)
        progress = i/n;
        waitbar(progress, WBAR, 'Converting *.crx to *.rnx')
    end
end



% go back to WORK folder
cd(work_path)

% close waitbar
if ishandle(WBAR)
    close(WBAR)
end



function unzipped = unzip_and_delete(files, targets)
% unzips and deletes all files from a host
num_files = numel(files);
unzipped = cell(num_files, 1);
path_info = what([pwd, '/../CODE/7ZIP/']);      % canonical path of 7-zip is needed
path_7zip = [path_info.path, '/7za.exe'];
for i = 1:num_files
    curr_archive = [targets{i}, '/', files{i}];
    file_unzipped = unzip_7zip(path_7zip, curr_archive);
    unzipped{i} = file_unzipped;
    delete(curr_archive);
end



% AGGO00ARG_S_
% AIRA00JPN_R_
% ALBH00CAN_R_
% ALGO00CAN_R_
% AREG00PER_R_
% ASCG00SHN_R_
% BAIE00CAN_R_
% BAKE00CAN_R_
% BRST00FRA_S_
% BRUX00BEL_S_
% CCJ200JPN_R_
% CEBR00ESP_R_
% CHOF00JPN_S_
% CHPG00BRA_R_
% CHUR00CAN_R_
% CIBG00IDN_R_
% CPVG00CPV_R_
% CUT000AUS_S_
% DAEJ00KOR_R_
% DJIG00DJI_R_
% DLF100NLD_R_
% DRAO00CAN_R_
% DUBO00CAN_R_
% DYNG00GRC_R_
% EBRE00ESP_R_
% FAA100PYF_R_
% FLIN00CAN_R_
% FRDN00CAN_R_
% FTNA00WLF_R_
% GAMB00PYF_R_
% GAMG00KOR_R_
% GMSD00JPN_R_
% GOP600CZE_R_
% GOP700CZE_R_
% GOPE00CZE_R_
% GRAC00FRA_S_
% HARB00ZAF_R_
% HARB00ZAF_S_
% HLFX00CAN_R_
% HRAG00ZAF_S_
% IQAL00CAN_R_
% ISHI00JPN_R_
% JFNG00CHN_R_
% KERG00ATF_R_
% KIRU00SWE_R_
% KITG00UZB_R_
% KOKV00USA_R_
% KOUG00GUF_R_
% KOUR00GUF_R_
% KRGG00ATF_R_
% KZN200RUS_S_
% LLAG00ESP_S_
% LMMF00MTQ_S_
% M0SE00ITA_S_
% MAL200KEN_R_
% MAS100ESP_R_
% MAYG00MYT_R_
% METG00FIN_R_
% MGUE00ARG_R_
% NKLG00GAB_R_
% NNOR00AUS_R_
% NRC100CAN_R_
% NTUS00SGP_R_
% OWMG00NZL_R_
% PRDS00CAN_R_
% PTGG00PHL_R_
% REDU00BEL_R_
% REUN00REU_S_
% RGDG00ARG_R_
% ROAG00ESP_R_
% SASK00CAN_R_
% SCH200CAN_R_
% SCRZ00BOL_S_
% SEYG00SYC_R_
% SIN100SGP_S_
% STFU00USA_S_
% STJ300CAN_R_
% STJO00CAN_R_
% STK200JPN_R_
% THTG00PYF_R_
% TLSE00FRA_R_
% TLSG00FRA_R_
% TSK200JPN_R_
% UNB300CAN_S_
% UNBD00CAN_S_
% VALD00CAN_R_
% VILL00ESP_R_
% WHIT00CAN_R_
% WROC00POL_R_
% WSRT00NLD_R_
% WTZ200DEU_S_
% WTZ300DEU_S_
% WTZZ00DEU_S_
% YEL200CAN_R_
% YELL00CAN_R_
% ZIM300CHE_S_