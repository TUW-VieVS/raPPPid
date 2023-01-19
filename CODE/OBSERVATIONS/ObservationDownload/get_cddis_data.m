function filestatus = get_cddis_data(host, folders, files, targets, bool_print)
% Download data from cddis server
% modification from get_orbit.m from VieVS IONO (created 25.10.2017,
% Janina Boisits)
%
% INPUT:
%   host            string, webadress of CDDIS global datacenter
%   folders         cell, folders of data to download
%   files           cell, filenames of data to download
%   targets         cell, path to local disk where downloaded file is saved
%   bool_print      boolean, true -> print output to command window
% OUTPUT:
%	filestatus      boolean, true if element successfully downloaded
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

n = numel(files);          % number of files to download
filestatus = ones(n,1);    % initalize with: download successful 
netrcfile = '../CODE/OBSERVATIONS/ObservationDownload/cURL/.netrc';
pathCURL  = '../CODE/OBSERVATIONS/ObservationDownload/cURL/curl.exe';
cookie    = '../CODE/OBSERVATIONS/ObservationDownload/cookie.txt';

% check if .netrc file has login credentials
ntrc_is_valid = check_netrcfile(netrcfile);
if ~ntrc_is_valid
    % Create an EarthData Account: https://urs.earthdata.nasa.gov/
    % Go to \CODE\OBSERVATIONS\ObservationDownload\cURL
    % Rename example.netrc to .netrc
    % Windows: If you get the error message "You must type a file name",
    % rename example.netrc to .netrc.
    % Open .netrc and replace XXX with your login credentials
    errordlg({'Enter login credentials into the .netrc file!', 'Check get_cddis_data.m for details.'}, 'ERROR');
    return
end


for i = 1:n
    
    % prepare download
    folder = folders{i};
    file = files{i};
    target = targets{i};
    
    % check variable type
    if ischar(folder); folder = {folder}; end
    
    % try download
    try
        url = [host folder{1} '/' file];
        command = ['"' pathCURL '" -s -c "' cookie '" -L --netrc-file "' netrcfile '" "' url '" -o "' target '/' file '"'];
        system(command);
        
        % check if REALLY downloaded
        if ~exist([target '/' file],'file') && bool_print
            fprintf(2, ['Download failed: ', url '\n'])
            filestatus(i) = 0;
        end
        
    catch
        if bool_print
            fprintf(2, ['Download failed: ', url '\n'])
            filestatus(i) = 0;
        end
    end
    
end

% delete cookie file
delete ('../CODE/OBSERVATIONS/ObservationDownload/cookie.txt');






function ntrc_is_valid = check_netrcfile(netrcfile)
ntrc_is_valid = true;
% check if netrc file is existing
if ~isfile(netrcfile)
    ntrc_is_valid = false;
    return
end
% check if netrc file has valid login credentials
fid = fopen(netrcfile);
NETRC = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
NETRC = NETRC{1};
fclose(fid);
if contains(NETRC{2}, 'XXX') && contains(NETRC{3}, 'XXX')
    ntrc_is_valid = false;
end
    
