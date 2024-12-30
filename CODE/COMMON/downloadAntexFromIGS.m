function [] = downloadAntexFromIGS()
% This function downloads igs14.atx, igs20.atx', igs08.atx, and igs05.atx
% from the International GNSS service (https://files.igs.org/pub/station/general/)
%
% INPUT:
%   ...
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************

% define ANTEX files to download
file_atx{1} = 'igs14.atx';
file_atx{2} = 'igs20.atx';
file_atx{3} = 'igs08.atx';
file_atx{4} = 'igs05.atx';

% path to antex file
target_atx = [Path.DATA, 'ANTEX/'];


% loop to download file
fprintf('Download started. \n')
for i = 1:4
    % delete old igsXX.atx file to enable download of new file
    delete([target_atx, file_atx{i}]);  	
    
    % atx-files are not small and server is slow -> increase timeout
    woptions = weboptions;
    woptions.Timeout = 60;      % use 60s (usually 5s is the default value)
    websave([target_atx file_atx{i}] , ['https://files.igs.org/pub/station/general/' file_atx{i}], woptions);

     fprintf('File %d finished, %d remaining.        \n', i, 4-i);
end

fprintf('Download finished. \n')
