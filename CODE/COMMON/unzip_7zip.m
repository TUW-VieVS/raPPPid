function file_decompr = unzip_7zip(path_7zip, archive)
% Function to decompress a *.Z-file with 7zip under windows
% 7-Zip standalone version 16.04 is used (18.06 does not work!).
% This function should be used only for archives containing a single
% compressed file.
%
% INPUT:
%   path_7zip       string, absolute path to exe of 7zip
%   archive         string, absolute path of archive to decompress
% OUTPUT:
%   file_unzipped   string, path to decompressed file
%
%
% Revision:
%   2024/01/11, MFWG: adding file/archive name check
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


[dir_file, name_file, ~] = fileparts(archive);
file_decompr = [dir_file '/' name_file];

% preparing some strings for command line
dir_file_ = ['"' dir_file '"'];
path_file_ = ['"' archive '"'];
path_7zip_ = ['"' path_7zip '"'];

% prepare file/archive name check
checkcontent = [path_7zip,  ' l ', archive];    % building string for command line
[status, cmdout] = system(checkcontent);       	% status = 0 = OK

% check if the file compressed in the archive has the same name as the archive
if status == 0
    compressed_file = findFilenameInConsoleOutput(cmdout);
    if ~strcmpi(compressed_file, name_file)
        % the name of the compressed file does not match the name of the archive
        file_decompr = [dir_file '/' compressed_file];
    end
end


% check if decompressed file already exists as file or *.mat-file
if exist(file_decompr, 'file') || exist([file_decompr '.mat'], 'file')
    return;
end

% building decompress string for command line
decompress = [path_7zip_,  ' x -o', dir_file_, ' ', path_file_];

% writing decompress command to command line to unzip
[status, cmdout] = system(decompress);      % status = 0 = OK

if status ~= 0          % check if unzipping worked
    fprintf(2, 'Unzipping failed: %s                 \n', path_file_);
end





function compressed_file = findFilenameInConsoleOutput(cmdout)
% find the name of the decompressed file in the output of the console
% ||| includes hardcoding
pos = strfind(cmdout, '------------------------');
idx_approx = sum(pos)/2;                        % approximate position of filename
idx_newline = strfind(cmdout, newline);         % indices of newline characters
idx_1 = idx_newline(idx_newline < idx_approx);  % indices of newline characters before filename
idx_1 = idx_1(end)  + 54;       % index beginning filename
idx_2 = idx_newline(idx_newline > idx_approx);
idx_2 = idx_2(1);               % index end filename
compressed_file = strtrim(cmdout(idx_1:idx_2)); % indices of newline characters after filename