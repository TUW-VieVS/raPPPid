function unzipped = unzip_and_delete(files, targets)
% Unzips and deletes all files from a host
% 
% INPUT:
%	files       cell, name of the files
%   targets     cell, folder-path
% OUTPUT:
%	unzipped    cell, paths to decompressed files
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

num_files = numel(files);       % number of files to decompress
unzipped = cell(num_files, 1);  % initialize

% create absolute (! necessary !) path to 7zip.exe
path_info = what([pwd, '/../CODE/7ZIP/']);      % canonical path of 7-zip is needed
path_7zip = [path_info.path, '/7za.exe'];

% loop over files to decompress
for i = 1:num_files
    curr_archive = [targets{i}, '/', files{i}];     % path to current archive
    
    % decompress
    decompressed = unzip_7zip(path_7zip, curr_archive);   
    unzipped{i} = decompressed;
    
    % delete archive only if the name of decompressed file matches the name
    % of the archive to avoid repeated downloads
    [~, file_dec, ext_dec] = fileparts(decompressed);
    file_dec_ = [file_dec, ext_dec];             % filename of decompressed file
    [~, file_com, ~] = fileparts(curr_archive); % expected filename from archive
    if strcmpi(file_dec_, file_com)      
        delete(curr_archive);
    end
end