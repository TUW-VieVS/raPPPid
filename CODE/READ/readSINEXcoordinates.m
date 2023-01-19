function [STATIONS_all, XYZ_all] = readSINEXcoordinates(FilePath)
% reads (true) XYZ coordinates from SINEX file, saves it as *.mat-file and
% deletes the SINEX file.
% station names are all in uppercase
%
% INPUT:
%   FilePath        string, path to IGS coordinate dayly file
% OUTPUT:
%   STATIONS_all    4-digit station identifiers
%   XYZ_all         corresponding true XYZ coordinates
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| time-stamp of coordinates in SINEX file is ignored, the last
% coordinates are taken


% open and read in file
fid = fopen(FilePath);
FILE = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
FILE = FILE{1};
fclose(fid);


%% Find out stations which have true coordinates in current file
bool_sites_1 = contains(FILE, '+SITE/ID');
bool_sites_2 = contains(FILE, '-SITE/ID');
idx_1 = find(bool_sites_1, 1, 'first');  	% find beginning and end
idx_2 = find(bool_sites_2, 1, 'last');
bool_sites = bool_sites_1;
bool_sites(idx_1:idx_2) = 1;
bool_sites(idx_1) = 0;
bool_sites(idx_1+1) = 0;
bool_sites(idx_2) = 0;
SITES = FILE(bool_sites);               % cut out part containing 4-digit station names
s1 = cellfun( @(a) a(1,2), SITES);
s2 = cellfun( @(a) a(1,3), SITES);
s3 = cellfun( @(a) a(1,4), SITES);
s4 = cellfun( @(a) a(1,5), SITES);
STATIONS_file = strcat(s1,s2,s3,s4); 	% put station names together
STATIONS_all = upper(STATIONS_file);   	% 4-digit station names should be uppercase



%% Get true coordinates for each station
bool_sol = contains(FILE, 'SOLUTION/ESTIMATE');
idx_1 = find(bool_sol, 1, 'first');
idx_2 = find(bool_sol, 1, 'last');
bool_sol(idx_1:idx_2) = 1;
COORDS = FILE(bool_sol);                % cut out part with XYZ coordinates

n = length(STATIONS_all);
XYZ_all = zeros(n,3);
for i = 1:n         % loop over all stations to find XYZ coordinates
    stat = STATIONS_file(i,:);       	% current 4-digit station
    bool_xyz = contains(COORDS, stat);	% lines where station occurs
    if all(bool_xyz == 0)               % no true coordinates for current station
        XYZ_all = [0, 0, 0];
        continue
    end
    
    % get lines with coordinates of station
    lines_coords = COORDS(bool_xyz);
    x_line = cell2mat(lines_coords(contains(lines_coords, 'STAX')));
    y_line = cell2mat(lines_coords(contains(lines_coords, 'STAY')));
    z_line = cell2mat(lines_coords(contains(lines_coords, 'STAZ')));
    
    % in case of multiple matches, take last and most (time-stamp is ignored!)
    x_line = x_line(end,:);
    y_line = y_line(end,:);
    z_line = z_line(end,:);
    
    % get and convert coordinates from string to double
    XYZ_all(i,1) = str2double(x_line(47:69));
    XYZ_all(i,2) = str2double(y_line(47:69));
    XYZ_all(i,3) = str2double(z_line(47:69));
end


%% Save results and delete file
delete(FilePath)
SaveFilePath = [FilePath '.mat'];
save(SaveFilePath, 'STATIONS_all', 'XYZ_all')

end