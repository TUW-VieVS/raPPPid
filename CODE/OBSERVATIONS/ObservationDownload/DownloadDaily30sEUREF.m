function [] = DownloadDaily30sEUREF(stations, doys, year)
% Function to download, decompress and save RINEX observation files from
% EUREF stations with 30s interval and for the whole day in the correct folder
% of raPPPid
% The station of which data should be downloaded can be either delivered as
% cell or entered in the EUREF_r3_stations.txt (same folder as this function)
% open('..\CODE\OBSERVATIONS\ObservationDownload\EUREF_r3_stations.txt')
% Example call: 
% DownloadDaily30sEUREF({'BAIA00ROU', 'BOGO00POL', 'CAEN00FRA'}, 001, 2020)
% DownloadDaily30sEUREF('BAIA00ROU', 032, 2020)
% DownloadDaily30sEUREF('', 012, 2019)
% 
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


URL_host = 'gnss.bev.gv.at:21';

% check input of variable year
if numel(year) > 1
    errordlg('Check input for year!', 'Error');
    return
end

% check if in WORK folder
if ~contains(pwd, 'WORK')
    errordlg('Change current folder to .../WORK', 'Error');
    return
end

% check if stations list from file
if isempty(stations)
    % open and read txt file
    fid = fopen('..\CODE\OBSERVATIONS\ObservationDownload\EUREF_r3_stations.txt');         
    stations = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
    stations = stations{1};
    fclose(fid);
    % remove commented stations
    idx_del = contains(stations, '%') | cellfun(@isempty,stations);
    stations(idx_del) = '';
elseif ~iscell(stations)
    stations = {stations};      % for single station input make sure that cell
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
WBAR = waitbar(0, 'Creating list do download data.', 'Name', 'Downloading EUREF Data');  

% loop over stations and doys to create the needed variables for the download
for d = 1:no_days
    for n = 1:no_stations
        
        % create variables for current archive/file
        station = strtrim(stations{n});
        doy = sprintf('%03.0f',doys(d));
        URL_folder = {['/pub/obs/' year '/' doy '/']};
        file = [station '_R_' year doy '0000_01D_30S_MO.crx.gz'];
        target = ['../DATA/OBS/' year '/' doy];
        
        % save
        URL_folders{d,n} = URL_folder;
        files{d,n} = file;
        targets{d,n} = target;
        
        % create target folder
        mkdir(target);
        
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
file_status = ftp_download_multi(URL_host, URL_folders, files, targets, true);

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



% ACOR00ESP
% ADAR00GBR
% AJAC00FRA
% ALAC00ESP
% ALBA00ESP
% ALME00ESP
% ANKR00TUR
% AQUI00ITA
% ARGI00FRO
% ARIS00GBR
% ARJ600SWE
% AUBG00DEU
% AUT100GRC
% AUTN00FRA
% AXPV00FRA
% BACA00ROU
% BADH00DEU
% BAIA00ROU
% BAUT00DEU
% BBYS00SVK
% BCLN00ESP
% BELL00ESP
% BISK00CZE
% BOGE00POL
% BOGI00POL
% BOGO00POL
% BOLG00ITA
% BOR100POL
% BORJ00DEU
% BORR00ESP
% BPDL00POL
% BRMF00FRA
% BRST00FRA
% BRUX00BEL
% BSCN00FRA
% BUCU00ROU
% BUDP00DNK
% BUTE00HUN
% BYDG00POL
% BZRG00ITA
% CACE00ESP
% CAEN00FRA
% CAG100ITA
% CAKO00HRV
% CANT00ESP
% CARG00ESP
% CASC00PRT
% CASE00ESP
% CEBR00ESP
% CEU100ESP
% CFRM00CZE
% CHIO00GBR
% CHIZ00FRA
% CLIB00CZE
% CNIV00UKR
% COBA00ESP
% COMO00ITA
% COST00ROU
% CPAR00CZE
% CRAK00CZE
% CREU00ESP
% CTAB00CZE
% DARE00GBR
% DELF00NLD
% DENT00BEL
% DEVA00ROU
% DGOR00MNE
% DIEP00DEU
% DILL00DEU
% DLF100NLD
% DNMU00UKR
% DOUR00BEL
% DRAG00ISR
% DUB200HRV
% DUTH00GRC
% DYNG00GRC
% EBRE00ESP
% EDIN00GBR
% EGLT00FRA
% EIJS00NLD
% ELBA00ITA
% ENIS00GBR
% ENTZ00FRA
% ESCO00ESP
% EUSK00DEU
% FFMJ00DEU
% FINS00FIN
% FLRS00PRT
% FOYL00GBR
% FUNC00PRT
% GAIA00PRT
% GANP00SVK
% GARI00ITA
% GDRS00UKR
% GELL00DEU
% GENO00ITA
% GLSV00UKR
% GOP600CZE
% GOPE00CZE
% GOR200DEU
% GRAC00FRA
% GRAS00FRA
% GRAZ00AUT
% GSR100SVN
% GUIP00FRA
% GWWL00POL
% HAS600SWE
% HEL200DEU
% HELG00DEU
% HERS00GBR
% HERT00GBR
% HETT00FIN
% HOBU00DEU
% HOFJ00DEU
% HOFN00ISL
% HUEL00ESP
% IBIZ00ESP
% IENG00ITA
% IGEO00MDA
% IGM200ITA
% IGMI00ITA
% IJMU00NLD
% ILDX00FRA
% INVR00GBR
% IRBE00LVA
% ISTA00TUR
% IZAN00ESP
% IZMI00TUR
% IZRS00UKR
% JOE200FIN
% JOEN00FIN
% JON600SWE
% JOZ200POL
% JOZE00POL
% KAD600SWE
% KARL00DEU
% KATO00POL
% KEV200FIN
% KHAR00UKR
% KILP00FIN
% KIR000SWE
% KIR800SWE
% KIRU00SWE
% KIV200FIN
% KLOP00DEU
% KNJA00SRB
% KOS100NLD
% KRA100POL
% KRAW00POL
% KRRS00UKR
% KRS100TUR
% KTVL00UKR
% KUNZ00CZE
% KURE00EST
% KUU200FIN
% LAGO00PRT
% LAMA00POL
% LAMP00ITA
% LARM00GRC
% LDB200DEU
% LEIJ00DEU
% LEK600SWE
% LEON00ESP
% LERI00GBR
% LIL200FRA
% LINZ00AUT
% LLIV00ESP
% LODZ00POL
% LOV600SWE
% LPAL00ESP
% LROC00FRA
% M0SE00ITA
% MALA00ESP
% MALL00ESP
% MAN200FRA
% MAR600SWE
% MAR700SWE
% MARP00UKR
% MARS00FRA
% MAS100ESP
% MAT100ITA
% MATE00ITA
% MATG00ITA
% MDVJ00RUS
% MEDI00ITA
% MELI00ESP
% MERS00TUR
% MET300FIN
% METG00FIN
% METS00FIN
% MIK300FIN
% MIKL00UKR
% MKRS00UKR
% MLVL00FRA
% MOP200SVK
% MOPI00SVK
% MOPS00ITA
% MORP00GBR
% MSEL00ITA
% NEWL00GBR
% NICO00CYP
% NOA100GRC
% NOR700SWE
% NOT100ITA
% NPAZ00SRB
% NYA100NOR
% NYA200NOR
% OBE400DEU
% OLK200FIN
% ONS100SWE
% ONSA00SWE
% ORID00MKD
% ORIV00FIN
% OROS00HUN
% OSK600SWE
% OSLS00NOR
% OST600SWE
% OUL200FIN
% OVE600SWE
% PADO00ITA
% PASA00ESP
% PAT000GRC
% PDEL00PRT
% PENC00HUN
% PFA200AUT
% PFA300AUT
% PMTH00GBR
% POLV00UKR
% PORE00HRV
% POTS00DEU
% POUS00CZE
% POZE00HRV
% PRAT00ITA
% PRYL00UKR
% PTBB00DEU
% PULK00RUS
% PUYV00FRA
% PYHA00FIN
% QAQ100GRL
% RABT00MAR
% RAEG00PRT
% RAMO00ISR
% RANT00DEU
% REDU00BEL
% REDZ00POL
% REYK00ISL
% RIGA00LVA
% RIO100ESP
% ROM200FIN
% ROVE00ITA
% SABA00SRB
% SALA00ESP
% SAS200DEU
% SAVU00FIN
% SBG200AUT
% SCIL00GBR
% SCOA00FRA
% SCOR00GRL
% SFER00ESP
% SHOE00GBR
% SJDV00FRA
% SKE000SWE
% SKE800SWE
% SMID00DNK
% SMLA00UKR
% SMNE00FRA
% SNEO00GBR
% SOD300FIN
% SODA00FIN
% SOFI00BGR
% SONS00ESP
% SPRN00HUN
% SPT000SWE
% SRJV00BIH
% STAS00NOR
% SULD00DNK
% SULP00UKR
% SUN600SWE
% SUR400EST
% SVE600SWE
% SVTL00RUS
% SWAS00GBR
% SWKI00POL
% TAR000ESP
% TERC00PRT
% TERS00NLD
% TERU00ESP
% TIT200DEU
% TLL100IRL
% TLMF00FRA
% TLSE00FRA
% TOIL00EST
% TOR100ESP
% TOR200EST
% TORI00ITA
% TORN00FIN
% TRDS00NOR
% TRF200AUT
% TRO100NOR
% TUBI00TUR
% TUBO00CZE
% TUC200GRC
% TUO200FIN
% UCAG00ITA
% UME600SWE
% UNPG00ITA
% UNTR00ITA
% USAL00ITA
% USDL00POL
% UZHL00UKR
% VAA200FIN
% VAAS00FIN
% VACO00CZE
% VAE600SWE
% VALA00ESP
% VALE00ESP
% VARS00NOR
% VEN100ITA
% VFCH00FRA
% VIGO00ESP
% VIL000SWE
% VIL600SWE
% VILL00ESP
% VIR200FIN
% VIS000SWE
% VIS600SWE
% VLIS00NLD
% VLN100IRL
% VLNS00LTU
% VNRS00UKR
% WARE00BEL
% WARN00DEU
% WRLG00DEU
% WROC00POL
% WSRT00NLD
% WTZA00DEU
% WTZR00DEU
% WTZS00DEU
% WTZZ00DEU
% YEBE00ESP
% ZADA00HRV
% ZARA00ESP
% ZECK00RUS
% ZIM200CHE
% ZIMM00CHE
% ZOUF00ITA
% ZPRS00UKR
% ZYWI00POL