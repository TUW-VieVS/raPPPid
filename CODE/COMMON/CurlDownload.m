function file_status = CurlDownload(target, source, bool_print)
% This function downloads a specified file with curl (e.g., from
% ftps://bdspride.com). For unreliable servers the download is attempted
% with a bounded per-attempt timeout and retried a few times before giving 
% up.
%
% INPUT:
%   target          string, path to local file
%   source          string, adress of file to download
% OUTPUT:
%	file_status
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

file_status = 0;

% check if file exists already
[path, file, ~] = fileparts(target);
if isfile(target) || isfile([target '.mat']) || isfile([path '/' file]) || isfile([path '/' file '.mat'])
    file_status = 1;
    return
end

% build command string for command line
command = ['curl --ssl-reqd --user anonymous:anonymous -k --max-time 30 -o "' ...
           target '" "' source '"'];

% retry a few times for unreliable servers
n_attempts = 3;
for attempt = 1:n_attempts
    [status, cmdout] = system(command);
    if status == 0 && isfile(target) && dir(target).bytes > 0
        file_status = 1;
        return
    end
    if isfile(target); delete(target); end   % remove a failed/partial attempt
end

if bool_print
    disp(cmdout);
end