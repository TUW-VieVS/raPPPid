function [] = downloadAntexFromCODE()
% This function downloads M14.atx, M20.atx, and I20.atx from the FTP server
% of CODE (Center of Orbit Determination Europe)
%
% INPUT:
%   ...
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************

% define origin of files
host = 'ftp.aiub.unibe.ch:21';
folders = repmat({'/CODE_MGEX/CODE/'}, 3, 1);

% define files and targets to download
files = {'M14.ATX'; 'M20.ATX'; 'I20.ATX'};
targets = repmat({[Path.DATA, 'ANTEX/']}, 3, 1);


% download
for i = 1:3
    fprintf('Download %s ... \n', files{i})
    status = ftp_download(host, folders{i}, files{i}, targets{i}, true);
end
fprintf('Download finished. \n')