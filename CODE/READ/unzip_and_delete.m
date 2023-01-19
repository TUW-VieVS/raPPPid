function unzipped = unzip_and_delete(files, targets)
% Unzips and deletes all files from a host
% 
% INPUT:
%	files       cell, name of the files
%   targets     cell, folder-path
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

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