function M = read_blq(blq_filepath, station)
% Reads in an BLQ file and gets the ocean tide matrix for the current
% station.
% OceanLoading.blq is created using:
% http://holt.oso.chalmers.se/loading/index.html
% GOT4.7 and default values
% function OUT = convertIGScoords(date) to create input
%
% INPUT:
%	blq_filepath    string, path to BLQ file
%   station         4-digit stationname of processing
% OUTPUT:
%	M               ocean loading matrix
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% open, read and close file
fid = fopen(blq_filepath);
BLQ = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
BLQ = BLQ{1};
fclose(fid);

% initialize
M = []; 

% remove comments
delete = contains(BLQ, '$$');
BLQ(delete) = '';

% look for data of station of processing
idx = find(contains(BLQ, station), 1, 'first');
if isempty(idx)
    fprintf(2,['\nStation ' station ' was not found in OceanLoading.blq\nNo Ocean Loading correction is applied\n']);
    return
end

% get data for station of processing
station_data = BLQ(idx+1:idx+6);
M = str2num(cell2mat(station_data));  	% not pretty, but works (only with str2num)