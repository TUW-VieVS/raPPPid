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
    [files, folderpath] = uigetfile({'*.*'}, 'Select files to copy.', startfolder, 'MultiSelect', 'on');
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

n = numel(FILEPATHS);
for i = 1:n
    curr_path = FILEPATHS{i};
    curr_path_ = curr_path;
    if strcmp(curr_path(end-3:end), '.mat')
        curr_path_ = curr_path(1:end-4);
    end
    [~, file, ext] = fileparts(curr_path_);    % disassemble filepath
    ext = lower(ext(2:end));           % convert to lowercase and remove '.'
    if ~(numel(ext) == 3 || numel(ext) == 5)
        fprintf(2, [file '.' ext ' is not copied (unknown data type).\n'])
        continue
        % ||| print message
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
        case 'ssc'
            tfolder = 'COORDS';
        case 'inx'
            tfolder = 'IONO';
        case 'rnx'
            tfolder = 'OBS';
            if strcmp(file(end-1:end), 'MN')
                tfolder = 'BROADCAST';
            end
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
    [subf_1, subf_2] = AnalyzeFileName(file, ext);
    % create full path of target folder
    target = [datafolder tfolder '/' subf_1 '/' subf_2];
    % copy file
    mkdir(target);
    [success, mess, messID] = copyfile(curr_path, target);
    % check if moving was successful
    if success
        fprintf([file '.' ext ' copied to ' [tfolder '/' subf_1 '/' subf_2]  '\n'])
    else
        fprintf(2, [file '.' ext ' could not copied.\n'])
        fprintf([mess '\n'])
    end
end

msgbox('Data was copied successfully!', 'Achievement', 'help')




function [subf_1, subf_2] = AnalyzeFileName(file, ext)
% This function tries to extract the year and the day of year belonging to
% a GNSS related data file (e.g. RINEX, orbit,...)
subf_1 = ''; subf_2 = '';
n = numel(file);
if strcmp(ext, 'atx')       % no subfolders needed
    return
end

if n == 34 && strcmp(ext, 'rnx') 	% Rinex 3 observatiom file
    idx = strfind(file, '_');
    idx_1 = idx(2) + 1;
    idx_2 = idx_1  + 3;
    idx_3 = idx_2  + 1;
    idx_4 = idx_3  + 2;
    subf_1 = file(idx_1:idx_2);
    subf_2 = file(idx_3:idx_4);
elseif strcmp(ext, 'fcb')           % SGG FCB, gps week and dow in file name
    gpsweek = str2double(file(4:7));
    dow = str2double(file(8));
    jd = gps2jd_GT(gpsweek,dow*24*3600);
    [doy, yyyy] = jd2doy_GT(jd);
    yyyy   = sprintf('%04d',yyyy);
    doy    = sprintf('%03d',doy);
    subf_1 = yyyy;
    subf_2 = doy;
elseif n == 34                      % Rinex 3 long filename
    idx = strfind(file, '_');
    idx_1 = idx(1) + 1;
    idx_2 = idx_1  + 3;
    idx_3 = idx_2  + 1;
    idx_4 = idx_3  + 2;
    subf_1 = file(idx_1:idx_2);
    subf_2 = file(idx_3:idx_4);
elseif n == 8                   	% Rinex short filename
    subf_1 = ['20' ext(1:2)];
    if str2double(ext(1:2)) > 70
        subf_1 = ['19' ext(1:2)];
    end
    subf_2 = file(5:7);
else
    fprintf([file ': date could not be extracted!\n']);
end


