function [] = DownloadDaily30sIGS(stations, doys, year)
% Function to download, decompress and save daily RINEX observation files 
% for IGS stations with 30s interval. They are saved in the correct folder
% of raPPPid.
% The stations of which data should be downloaded can be either delivered as
% cell or entered in the IGS_r3_stations.txt (same folder as this function)
% For a (uncomplete) list of IGS MGEX station check IGS_r3_stations.txt
% open('../CODE/OBSERVATIONS/ObservationDownload/IGS_r3_stations.txt')
% 
% Example call: 
% DownloadDaily30sIGS({'GRAZ00AUT', 'MIZU00JPN', 'FALK00FLK'}, 001, 2020)
% DownloadDaily30sIGS('GRAZ00AUT', 032, 2020)
% DownloadDaily30sIGS('', 012, 2020)
% DownloadDaily30sIGS('BRUX00BEL', 001, 2020)
% DownloadDaily30sIGS('KIRU00SWE', 360, 2020)
% 
% INPUT:
%   stations	cell, station names, 9-digit [4-digit name, '00', 3-digit country]
%   doys        vector, day of year for download
%   year        number, year
% OUTPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

host = 3;

switch host
    case 1
        URL_host = 'igs-ftp.bkg.bund.de:21';
    case 2
        URL_host = 'https://cddis.nasa.gov';    % typically very complete
    case 3
        URL_host = 'igs.ign.fr:21';
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

% check if stations is a cell
if ~isempty(stations) && ~iscell(stations)
    stations = {stations};
end

% check if stations list from file
if isempty(stations)
    % open and read txt file
    fid = fopen('../CODE/OBSERVATIONS/ObservationDownload/IGS_r3_stations.txt');         
    stations = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
    stations = stations{1};
    fclose(fid);
    idx_del = contains(stations, '%') | cellfun(@isempty,stations);
    stations(idx_del) = '';
end

% create some variable
no_stations = numel(stations);          % number of stations
no_days = numel(doys);                  % number of days
year = sprintf('%04.0f', year);         % convert year to string

% initialize
URL_folders = cell(no_days, no_stations);
files = cell(no_days, no_stations);
targets = cell(no_days, no_stations);

% Prepare waitbar and print out of epochs to command window 
WBAR = waitbar(0, 'Creating list to download data.', 'Name', 'Downloading IGS Data');  

% loop over stations and doys to create the needed variables for the download
for d = 1:no_days
    for n = 1:no_stations
        
        % create variables for current archive/file
        station = strtrim(stations{n});
        doy = sprintf('%03.0f',doys(d));
        switch host
            case 1
                URL_folder = {['/IGS/obs/' year '/' doy '/']};            % igs.bkg.bund.de
            case 2
                URL_folder = {['/archive/gnss/data/daily/' year '/' doy '/' year(3:4) 'd']};    % cddis.gsfc.nasa.gov
            case 3
                URL_folder = {['/pub/igs/data/' year '/' doy '/']};       % igs.ign.fr
        end 
        file = [station '_R_' year doy '0000_01D_30S_MO.crx.gz'];
        target = ['../DATA/OBS/' year '/' doy];
        
        % save
        URL_folders{d,n} = URL_folder;
        files{d,n} = file;
        targets{d,n} = target;
        
        % create target folder
        [~, ~] = mkdir(target);
        
    end
end

% update waitbar
if ishandle(WBAR)
    waitbar(0, WBAR, 'Downloading data. This will take some time.')
end

% convert to list where same folders are subsequent
URL_folders = URL_folders';
URL_folders = URL_folders(:);
files = files';
files = files(:);
targets = targets';
targets = targets(:);

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




% ABMF00GLP
% ABPO00MDG
% AGGO00ARG
% AIRA00JPN
% AJAC00FRA
% ALBH00CAN
% ALG200CAN
% ALG300CAN
% ALGO00CAN
% ALIC00AUS
% AMC400USA
% ANKR00TUR
% ANMG00MYS
% AREG00PER
% AREQ00PER
% ARUC00ARM
% ASCG00SHN
% ATRU00KAZ
% AUCK00NZL
% BAIE00CAN
% BAKE00CAN
% BAKO00IDN
% BELE00BRA
% BIK000KGZ
% BOAV00BRA
% BOGT00COL
% BOR100POL
% BRAZ00BRA
% BREW00USA
% BRST00FRA
% BRUX00BEL
% BSHM00ISR
% CAS100ATA
% CCJ200JPN
% CEBR00ESP
% CEDU00AUS
% CHOF00JPN
% CHPG00BRA
% CHPI00BRA
% CHTI00NZL
% CHU200CAN
% CHUR00CAN
% CKSV00TWN
% COCO00AUS
% CORD00ARG
% CPNM00THA
% CPVG00CPV
% CRO100VIR
% CUSV00THA
% CUT000AUS
% CUUT00THA
% DAE200KOR
% DAEJ00KOR
% DARW00AUS
% DAV100ATA
% DGAR00GBR
% DJIG00DJI
% DLF100NLD
% DRA300CAN
% DRA400CAN
% DRAO00CAN
% DUBO00CAN
% DUND00NZL
% DYNG00GRC
% EBRE00ESP
% ELBA00ITA
% EUR200CAN
% FAA100PYF
% FAIR00USA
% FALK00FLK
% FFMJ00DEU
% FLIN00CAN
% FRDN00CAN
% FTNA00WLF
% GAMB00PYF
% GAMG00KOR
% GANP00SVK
% GCGO00USA
% GENO00ITA
% GLPS00ECU
% GMSD00JPN
% GODE00USA
% GODN00USA
% GODS00USA
% GOP600CZE
% GOP700CZE
% GOPE00CZE
% GRAC00FRA
% GRAZ00AUT
% GUAM00GUM
% HAL100USA
% HARB00ZAF
% HERS00GBR
% HKSL00HKG
% HKWS00HKG
% HLFX00CAN
% HOB200AUS
% HOFN00ISL
% HRAG00ZAF
% HRAO00ZAF
% HUEG00DEU
% IISC00IND
% IQAL00CAN
% ISHI00JPN
% ISTA00TUR
% JCTW00ZAF
% JFNG00CHN
% JOG200IDN
% JOZE00POL
% JPLM00USA
% JPRE00ZAF
% KARR00AUS
% KAT100AUS
% KERG00ATF
% KIR800SWE
% KIRU00SWE
% KIT300UZB
% KITG00UZB
% KMNM00TWN
% KOKV00USA
% KOS100NLD
% KOUC00NCL
% KOUG00GUF
% KOUR00GUF
% KRGG00ATF
% KUUJ00CAN
% KZN200RUS
% LAMP00ITA
% LAUT00FJI
% LEIJ00DEU
% LHAZ00CHN
% LLAG00ESP
% LMMF00MTQ
% LPGS00ARG
% LPIL00NCL
% M0SE00ITA
% MADR00ESP
% MAJU00MHL
% MAR700SWE
% MARS00FRA
% MAS100ESP
% MAT100ITA
% MATE00ITA
% MATG00ITA
% MATZ00ITA
% MAW100ATA
% MAYG00MYT
% MCHL00AUS
% MCM400ATA
% MDO100USA
% MEDI00ITA
% MELI00ESP
% MET300FIN
% METG00FIN
% MGO200USA
% MGUE00ARG
% MIKL00UKR
% MIZU00JPN
% MKEA00USA
% MOBS00AUS
% MQZG00NZL
% MRC100USA
% MRO100AUS
% MYVA00ISL
% NAUR00NRU
% NCKU00TWN
% NICO00CYP
% NIUM00NIU
% NKLG00GAB
% NLIB00USA
% NMEA00NCL
% NNOR00AUS
% NOT100ITA
% NRC100CAN
% NRMD00NCL
% NRMG00NCL
% NTUS00SGP
% NYA100NOR
% NYA200NOR
% OBE400DEU
% OHI200ATA
% OHI300ATA
% ONS100SWE
% OP7100FRA
% OUS200NZL
% OWMG00NZL
% PADO00ITA
% PALM00ATA
% PARK00AUS
% PERT00AUS
% PFRR00USA
% PICL00CAN
% PIE100USA
% PIMO00PHL
% PNGM00PNG
% POAL00BRA
% POHN00FSM
% POL200KGZ
% POLV00UKR
% POTS00DEU
% POVE00BRA
% PRD200CAN
% PRD300CAN
% PRDS00CAN
% PTAG00PHL
% PTGG00PHL
% QUIN00USA
% RAEG00PRT
% RDSD00DOM
% REDU00BEL
% REUN00REU
% REYK00ISL
% RGDG00ARG
% RIGA00LVA
% RIO200ARG
% ROAG00ESP
% SALU00BRA
% SAMO00WSM
% SANT00CHL
% SASK00CAN
% SAVO00BRA
% SCH200CAN
% SCRZ00BOL
% SCTB00ATA
% SCUB00CUB
% SEY200SYC
% SEYG00SYC
% SGOC00LKA
% SIN100SGP
% SOD300FIN
% SOLO00SLB
% SPTU00BRA
% STFU00USA
% STHL00GBR
% STJ200CAN
% STJ300CAN
% STJO00CAN
% STK200JPN
% STR100AUS
% STR200AUS
% SUTH00ZAF
% SUTM00ZAF
% SYDN00AUS
% TASH00UZB
% THTG00PYF
% TID100AUS
% TIDV00AUS
% TIT200DEU
% TLSE00FRA
% TLSG00FRA
% TONG00TON
% TOPL00BRA
% TOW200AUS
% TRO100NOR
% TSK200JPN
% TUVA00TUV
% TWTF00TWN
% UCAG00ITA
% UCAL00CAN
% UFPR00BRA
% ULAB00MNG
% UNB300CAN
% UNBD00CAN
% UNSA00ARG
% URAL00RUS
% URUM00CHN
% USAL00ITA
% USN700USA
% USN800USA
% USN900USA
% VACS00MUS
% VALD00CAN
% VEN100ITA
% VILL00ESP
% VOIM00MDG
% WAB200CHE
% WARK00NZL
% WARN00DEU
% WGTN00NZL
% WHIT00CAN
% WIND00NAM
% WROC00POL
% WSRT00NLD
% WTZ200DEU
% WTZR00DEU
% WTZS00DEU
% WTZZ00DEU
% WUH200CHN
% XMIS00AUS
% YAR200AUS
% YAR300AUS
% YARR00AUS
% YEBE00ESP
% YEL200CAN
% YEL300CAN
% YELL00CAN
% YKRO00CIV
% ZIM200CHE
% ZIMJ00CHE
% ZIMM00CHE