function [RINEX, epochheader] = readRINEX(obsfile_path, r_version)
% Reads all content of a RINEX file. Saves the observation data and
% epochheaders as new variables. Only used for post-processing
% 
% INPUT:
%   obsfile_path        filepath to RINEX-observation-file
%   r_version           RINEX-version
% OUTPUT:
%   RINEX               cell, content of RINEX-observation-file without header
%   epochheader         vector, number of lines where header occurs
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Load and read RINEX file
% load RINEX observation file into MATLAB
fid = fopen(obsfile_path);
RINEX = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
RINEX = RINEX{1};
fclose(fid);

% look for end of header
bool_eoh = find(contains(RINEX, 'END OF HEADER'));
RINEX = RINEX((bool_eoh+1):end);                    % remove header

% look for lines of the epoch headers 
if r_version >= 3           % Rinex version 3 onwards
    bool_epochheader = contains(RINEX, '> ');
elseif r_version == 2       % Rinex version 2
    headerdate = RINEX{1};  
    headerdate = headerdate(1:9);
    bool_epochheader = contains(RINEX, headerdate);
end
% convert logical vector to number of lines
epochheader = find(bool_epochheader);


%% Perform some checks of RINEX file
% check for identical epoch headers
headers = RINEX(epochheader);
header_unique = unique(RINEX(epochheader));
if numel(headers) ~= numel(header_unique)
    errordlg({'Multiple identical epoch headers found in:', obsfile_path}, 'Be very careful')
end

    