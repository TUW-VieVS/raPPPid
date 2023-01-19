function out_dir_new = createResultsFolder(obs_file_path, proc_name)
% Creates the folder where processing is stored. Starting from the results 
% directory an optional folder is created, then a folder with name of the 
% and then folder with the name of processing and timestamp. The results will be 
% saved there after the processing.
%
% INPUT:
%   obs_file_path       string, path to RINEX observation file
%   proc_name           string, name of processing
% OUTPUT:
%   out_dir_new         string, path to new created results folder
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if isempty(proc_name)
    proc_name = DEF.proc_name;
end

% 1) check for subfolder in results folder
sub_dir = '';

if contains(proc_name, '/')
    idx_slash = strfind(proc_name, '/');
    sub_dir = proc_name(1:idx_slash(end));
    proc_name(1:idx_slash(end)) = '';
end    

% 2) get name of Rinex-File 
[~, obs_filename, ~] = fileparts(obs_file_path);

% 3) get current date+time  
str = datestr(now);    
% convert date+time into nicer format
Folder_date = [str(1:11), '_', str(13:14), 'h', str(16:17), 'm', str(19:20), 's'];
newFolder = [proc_name, '_', Folder_date];

out_dir_new = [Path.RESULTS sub_dir obs_filename '/' newFolder];	% folder for results of processing

end






































