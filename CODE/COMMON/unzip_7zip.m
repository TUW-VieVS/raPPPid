function file_unzipped = unzip_7zip(path_7zip, path_file)
% Function to decompress a *.Z-file with 7zip under windows
% 7-Zip standalone version 16.04 is used (18.06 does not work!)
%
% INPUT:
%   path_7zip       string, absolute path to exe of 7zip
%   path_file       string, absolute path of file to decompress
% OUTPUT:
%   file_unzipped   string, path to decompressed file
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

[dir_file, name_file, ~] = fileparts(path_file);
file_unzipped = [dir_file, '/', name_file];

% check if decompressed file already exists as file or *.mat-file
if exist(file_unzipped, 'file') || exist([file_unzipped '.mat'], 'file')
    return;
end

% preparing for command line
dir_file = ['"' dir_file '"'];
path_file = ['"' path_file '"'];
path_7zip = ['"' path_7zip '"'];

% building string for command line
str = [path_7zip,  ' x -o', dir_file, ' ', path_file];

% writing command to command line to unzip
[status, cmdout] = system(str);      % status = 0 = OK

if status ~= 0          % check if unzipping worked
    fprintf(2, 'Unzipping failed: %s                 \n', path_file);
end
