function [file_status] = ftp_download_multi(host, folders, files, targets, bool_print)

% Function to download multiple archives/files from a ftp host.
% Checks before download if file (as archive or decompressed) already exists.
% Example call: ftp_download_multi(host, folder, file, target, true)
% 
% INPUT:
%   host        	string, e.g. 'cddis.gsfc.nasa.gov:21'
%   folder          cell, strings of folders of files to download
%   file            cell, strings with filenames of files to download
%   target          cell, paths where downloaded files should be placed
%   bool_print      boolean, true -> print message if download failed 
% 
% OUTPUT:
%   file_status     vector with numbers:
%                       0... could not be downloaded
%                       1....successfully downloaded
%                       2....already existing, but zipped
%                       3....already existing and unzipped
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


n = numel(files);           % number of files to download
file_status = ones(n,1);

% Open ftp connection
f = ftp(host);
folder_old = 'empty';
% Enter passive mode
h = struct(f);
h.jobject.enterLocalPassiveMode()


for i = 1:n
    
    % prepare download
    folder = folders{i};
    file = files{i};
    target = targets{i};
    file_status(i) = 0;
    
    [~, name_file, ~] = fileparts(['A:/', file ]);
    
    % check if file already in target folder (check for the normal file name, the zipped file name and the .mat file name
    if exist([target, '/', file], 'file')
        file_status(i) = 2;
        continue;   % if file is already existing, then do nothing
    elseif exist([target, '/', name_file], 'file')   % ||   exist([target, '/', name_file '.mat'], 'file')
        file_status(i) = 3;
        continue;   % if file is already existing, then do nothing
    end
    
    
    % change folder if necessary
    if ~strcmp(folder, folder_old)
        % change to folder
        try
            cd(f, folder);
            % ascii(f);
            folder_old = folder;
        catch
            if bool_print
            fprintf(2, ['Folder does not exist: ftp://', host(1:end-3), folder{1}, '\n'])
            end
            file_status(i) = 0;
        end
    end
    
    % download file
    try
        mget(f, file, target);
        file_status(i) = 1;
    catch
        if bool_print
        fprintf(2, ['Download failed: ftp://', host(1:end-3), folder{1} , '/', file, '\n'])
        end
        file_status(i) = 0;
    end
    
    
    
end

% Close connection
close(f);

end