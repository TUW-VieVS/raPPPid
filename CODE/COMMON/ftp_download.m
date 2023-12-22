function [file_status] = ftp_download(host, folder, file, target, bool_print)

% Function to download one archive/file from a ftp host.
% Checks before download if file (as archive or decompressed) already exists.
% Example call: ftp_download(host, folder, file, target, true)
% 
% INPUT:
%   host.......   string, e.g. 'cddis.gsfc.nasa.gov:21'
%   folder....    string with string of folder of file to download
%   file......    string with string with filename of file to download 
%   target....    string with path where downloaded file should be placed
%   bool_print    boolean, true -> print message if download failed 
% 
% OUTPUT: 
%   file_status.. status of download:
%                   0... could not be downloaded
%                   1....successfully downloaded
%                   2....already existing, but zipped
%                   3....already existing and unzipped
%                   NOTE:   distinction between 2 and 3 works only for 
%                           archives as input
%  
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



%% Check if files have to be downloaded at all

file_status = 0;
[~, name_file, ~] = fileparts(['A:/', file ]);

% check if file already in target folder (check for the normal file name, the zipped file name and the .mat file name
if exist([target, '/', file], 'file')    ||   exist([target, '/', file '.mat'], 'file')
    file_status = 2;   
    return;   % if file is already existing, then do nothing
elseif exist([target, '/', name_file], 'file')    ||   exist([target, '/', name_file '.mat'], 'file')
    file_status = 3;
    return;   % if file is already existing, then do nothing
end


%% Download file

% Open ftp connection
try
    f = ftp(host);
catch
    if bool_print
        fprintf(2, ['Could not open a connection to: ', host(1:end-3), '\n'])
        file_status = 0;
    end
    return
end

% change to folder
try
    cd(f, folder);
    % ascii(f);
catch
    if bool_print
        fprintf(2, ['Folder does not exist: ftp://', host(1:end-3), folder, '\n'])
    end
    file_status = 0;
end

% Enter passive mode
h=struct(f);
try
    h.jobject.enterLocalPassiveMode();
catch       % on some PC the line above does not work (for whatever reason)
    h.LocalDataConnectionMethod();
end

% download file
try
    mget(f, file, target);
    file_status = 1;
catch
    if bool_print
        fprintf(2, ['Download failed: ftp://', host(1:end-3), folder, file, '\n'])
    end
    file_status = 0;
end
    
    
% Close connection
close(f);

end