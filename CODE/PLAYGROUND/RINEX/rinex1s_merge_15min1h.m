function [] = rinex1s_merge_15min1h()
% merge multiple (e.g. hourly) RINEX in one file. the header of the
% first RINEX file of the hour is kept and the other files (without header) are
% attached. 
% the name of the outputfile is created automatically.



% Select RINEX input-files
[files_in, path_in] = uigetfile('*.*', 'Select RINEX-Files to merge', pwd, 'MultiSelect', 'on');
path_out = path_in;

no_input_files = numel(files_in);        % number of input files

if mod(no_input_files,4) ~= 0
    errordlg('ERROR: Number of input files!', 'Error');
    return
end

% loop over files, take 4 files from an hour and merge them 
for i = 1:4:no_input_files
    file_in = files_in(i:i+3);
    file_out = file_in{1};
    file_out = strrep(file_out, '15M', '01H');
    rinex_merge(file_in, path_in, file_out, path_out)
end

% loop over files to delete input files
for i = 1:no_input_files
    delete([path_in files_in{i}])
end