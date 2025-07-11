function [] = CopyData2Folders()
% This function lets the users select some files which are then copied to
% the folder structure of raPPPid in the correct folder and subfolder (e.g.
% day and day of year)
% 
% INPUT:
%	[]        
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| not all special cases are covered
% ||| option to delete copied files


if ~contains(pwd, 'WORK')   % check if in WORK folder
    errordlg('Change current folder to .../WORK', 'Error');
    return
end

datafolder = GetFullPath([pwd '/' Path.DATA]);     % start folder of raPPPid data structure
FILEPATHS = {};

startfolder = datafolder;
while true      % loop to allow to add multiple times
    [files, folderpath] = uigetfile({'*.*'}, 'Select files to copy.', GetFullPath(startfolder), 'MultiSelect', 'on');
    if isempty(files) || isnumeric(files)
        break       % no files selected, stopp adding files in table
    end   
    files = cellstr(files);     % necessary if only one file was selected
    files = strcat(folderpath, files);      % put full path together
    FILEPATHS = [FILEPATHS, files];  % save filepaths
    startfolder = folderpath;   % to start the selection in the same folder
end

if isempty(FILEPATHS)       % no files to copy
    return
end

% remove twice entries
FILEPATHS = unique(FILEPATHS);

n = numel(FILEPATHS);       % number of files

for i = 1:n
    curr_path = FILEPATHS{i};
    curr_path_ = curr_path;
    
    if strcmp(curr_path(end-3:end), '.mat')
        curr_path_ = curr_path(1:end-4);
    end
    [~, file, ext] = fileparts(curr_path_);    % disassemble filepath
    
    % check for compressed files
    if strcmp(ext, '.gz') || strcmp(ext, '.zip')
        % create absolute (! necessary !) path to 7zip.exe
        path_info = what([pwd, '/../CODE/7ZIP/']);      % canonical path of 7-zip is needed
        path_7zip = [path_info.path, '/7za.exe'];
        curr_path = unzip_7zip(path_7zip, curr_path_);  
        [~, file, ext] = fileparts(curr_path);    % disassemble filepath
    end
    
    % check for *.crx files
    if strcmp(ext, '.crx')
        [curr_path, ext] = crx2rnx(curr_path, ext);
    end
    
    ext = lower(ext(2:end));           % convert to lowercase and remove '.'
    if ~(numel(ext) == 3 || numel(ext) == 5)
        fprintf(2, [file '.' ext ' is not copied (unknown data type).\n'])
        continue
    end
    % switch extension to find target folder
    switch ext                  
        case {'sp3', 'obx'}
            tfolder = 'ORBIT';
        case 'clk'
            tfolder = 'CLOCK';
        case {'bia', 'fcb'}
            tfolder = 'BIASES';
        case 'dcb'
            tfolder = 'BIASES';
            % || monthly files
        case 'atx'
            tfolder = 'ANTEX';
        case {'ssc', 'pos', 'snx'}
            tfolder = 'COORDS';
        case 'inx'
            tfolder = 'IONO';
        case {'rnx', 'obs'}
            tfolder = 'OBS';
            if strcmp(file(end-1:end), 'MN')
                tfolder = 'BROADCAST';
            end
        case 'ssr'
            tfolder = 'STREAM';              
        case 'txt'
            tfolder = 'OBS';  
        case 'erp'
            tfolder = 'ERP'; 
        case 'tro'
            tfolder = 'TROPO'; 
        otherwise
            switch ext(3)
                case 'o'
                    tfolder = 'OBS';
                case 'i'
                    tfolder = 'IONO';
                case 'c'
                    tfolder = 'STREAM';
                case {'n', 'g', 'l'}
                    tfolder = 'BROADCAST';
                case 'z'
                    if strcmp(ext(3:5), 'zpd')
                        tfolder = 'TROPO';
                    end
            end
            % not implemented:
            %     targetfolder = 'TROPO';
            %     targetfolder = 'SIM';
            %     targetfolder = 'V3GR';
            %     targetfolder = 'VMF3';

    end
    % analyze file-name to get the year and day of year
    [subf_1, subf_2] = AnalyzeFileName(file, ext, curr_path);
    % create full path of target folder
    target = [datafolder tfolder '/' subf_1 '/' subf_2];
    % copy file
    [~, ~] = mkdir(target);
    [success, mess, messID] = copyfile(curr_path, target);
    % check if moving was successful
    if success
        fprintf([file '.' ext ' copied to ' [tfolder '/' subf_1 '/' subf_2]  '\n'])
    else
        fprintf(2, [file '.' ext ' could not copied.\n'])
        fprintf([mess '\n'])
    end
end

msgbox('CopyData2Folders has finished.', 'Achievement', 'help')




function [subf_1, subf_2] = AnalyzeFileName(file, ext, fpath)
% This function tries to extract the year and the day of year belonging to
% a GNSS related data file (e.g. RINEX, orbit,...)
subf_1 = '';    % string with 4-digit year
subf_2 = '';    % string with doy, 3-digit
n = numel(file);
if strcmp(ext, 'atx')       % no subfolders needed
    return
end

if n == 34 && strcmp(ext, 'rnx') || ...         % Rinex 3 observatiom file
        n == 30 && strcmp(ext, 'rnx') || ...	% Rinex navigation file
        n == 23 && ext(end) == 'o'              % e.g. RINEX logged with rinex ON
    idx = strfind(file, '_');
    idx_1 = idx(2) + 1;
    idx_2 = idx_1  + 3;
    idx_3 = idx_2  + 1;
    idx_4 = idx_3  + 2;
    subf_1 = file(idx_1:idx_2);
    subf_2 = file(idx_3:idx_4);
    
elseif strcmp(ext, 'fcb')               % SGG FCB, gps week and dow in file name
    [subf_1, subf_2] = gps2calendar(file(4:7), file(8));
    
elseif n == 34                          % Rinex 3 long filename
    idx = strfind(file, '_');
    idx_1 = idx(1) + 1;
    idx_2 = idx_1  + 3;
    idx_3 = idx_2  + 1;
    idx_4 = idx_3  + 2;
    subf_1 = file(idx_1:idx_2);
    subf_2 = file(idx_3:idx_4);
    
elseif n == 8                           % Rinex short filename
    subf_1 = ['20' ext(1:2)];
    if str2double(ext(1:2)) > 70
        subf_1 = ['19' ext(1:2)];
    end
    subf_2 = file(5:7);
    
elseif n == 14                          % e.g. correction stream recorded with BNC
    subf_1 = ['20' ext(1:2)];
    subf_2 = file(11:13);
    
elseif n == 11 && strcmp(ext, 'ssc')    % daily IGS coordinate solution (old short filename)
    [subf_1, subf_2] = gps2calendar(file(7:10), file(11));  
    
elseif n == 9 && ext(end) == 'c'        % e.g. correction stream recorded with BNC
    subf_2 = file(6:8);
    subf_1 = ['20' ext(1:2)];
    
elseif n == 44 && strcmp(ext, 'tro')    % IGS troposphere file, long filename
    subf_1 = file(12:15);
    subf_2 = file(16:18);
    
elseif ext(3) == 'o'                    % RINEX observation file
    % RINEX file and year+doy could not be extracted from filename
    rheader = anheader_GUI(fpath);      % analyze header of RINEX file
    jd = cal2jd_GT(rheader.first_obs(1), rheader.first_obs(2), rheader.first_obs(3));
    [doy, yyyy] = jd2doy_GT(jd);
    subf_1    = sprintf('%04d',yyyy);
    subf_2 	= sprintf('%03d',doy); 
    
elseif strcmp(ext, 'ssr') && n == 31    % e.g. correction stream recorded with BNC
    subf_1 = file(14:17);
    subf_2 = file(18:20);
    
elseif strcmp(ext, 'txt') && contains(file, 'gnss_log')     % Android raw sensor data
    subf_1 = file(10:13);       % year
    year  = str2double(subf_1);
    month = str2double(file(15:16));
    day   = str2double(file(18:19));
    jd = cal2jd_GT(year, month, day);
    [doy, ~] = jd2doy_GT(jd);
    subf_2 	= sprintf('%03d',doy);  
    
else
    fprintf([file ': date could not be extracted!\n']);
end


function [yyyy, doy] = gps2calendar(gpsweek, dow)
% convert GPS week and day of week to year and day of year
% all input and output variables are strings
gpsweek = str2double(gpsweek);
dow = str2double(dow);
jd = gps2jd_GT(gpsweek,dow*24*3600);
[doy, yyyy] = jd2doy_GT(jd);
yyyy   = sprintf('%04d',yyyy);
doy    = sprintf('%03d',doy);


function [curr_path, ext] = crx2rnx(curr_path, ext)
% Convert file from crx to rnx format
work_path = pwd;
if ispc
    cd('../CODE/OBSERVATIONS/ObservationDownload/RNXCMP_4.1.0_Windows_mingw_64bit/bin')
elseif isunix
    cd('../CODE/OBSERVATIONS/ObservationDownload/RNXCMP_4.1.0_Linux_x86_64bit/bin')
else
    st = dbstack;
    errordlg([st.name ' is not compatible with your operating system!'], 'Error');
    return
end

% prepare string for command window
if ispc         % Windows
    str = strcat('CRX2RNX "',curr_path,'"');
elseif isunix 	% Linux
    % To run the RNXCMP bash script, make them executable
    system('chmod u+x ./*');
    str = strcat('./CRX2RNX "',full_file_path,'"');
end

% writing command to command line to decompress with crx2rnx.exe
[status, cmdout] = system(str);     % status = 0 = OK
% delete *crx
delete(curr_path);
% change extension
ext = '.rnx';
curr_path = strrep(curr_path, '.crx', ext);
% go back to WORK folder
cd(work_path)
