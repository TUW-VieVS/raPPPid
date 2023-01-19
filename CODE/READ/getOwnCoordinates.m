function XYZ = getOwnCoordinates(stations, dates, XYZ)
% This function extracts the coordinates for stations from the simple
% Coords.txt-file (5 columns: 4-digit-station-name, mjd, X, Y, Z).
% Useful for example for station without IGS coordinate estimation
% The nearest coordinates (date) from Coords.txt are taken.
% It is possible to insert a coordinate bias in Coords.txt ( < 1e4 )
% open([Path.DATA 'COORDS/Coords.txt'])
% 
% INPUT:
%   stations        [cell], with 4-digit station names
%   dates           [vector], year - month - day for each station
%   XYZ             [vector], coordinates for each station
% OUTPUT:
%   XYZ             [vector], coordinates for each station
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% necessary for single input
if ~iscell(stations)
    stations = {stations};      % convert stations from char-array to cell
end

% initialize
n = numel(stations);

% check which stations have coordinates already
xyz_found = ~(any(XYZ == 0,2) | any(isnan(XYZ),2));

% load file with own coordinates into MATLAB
fid = fopen([Path.DATA 'COORDS/Coords.txt']);
DATA = textscan(fid,'%s %f %f %f %f');
fclose(fid);
STAT = DATA{:,1};
MJD = DATA{:,2};
X = DATA{:,3};
Y = DATA{:,4};
Z = DATA{:,5};


% loop over all stations
for i = 1:n
    if all(xyz_found)       % check if all true coordinates are already found
        return
    end
    if xyz_found(i)         % check if true coordinates for current station are already found
        continue
    end
    % get current station and date
    station = stations{i};
    date = dates(i,:);
    % look for true coordinates
    idx_1 = strcmpi(stations, station);  	% same stations are handled at once
    idx_2 = strcmpi(STAT, station);       	% check where station is in Coords.txt
    if sum(idx_2) == 1          % station is found once in Coords.txt
        XYZ(idx_1,1) = X(idx_2);
        XYZ(idx_1,2) = Y(idx_2);
        XYZ(idx_1,3) = Z(idx_2);
        xyz_found(idx_1) = true;
    elseif sum(idx_2) > 1       % station is found multiple times in Coords.txt
        % find correct entry depending on date for the current line
        mjds = MJD(idx_2);      % all mjds of current station
        X_curr = X(idx_2);      % all coordinates of current station
        Y_curr = Y(idx_2);
        Z_curr = Z(idx_2);
        jd = cal2jd_GT(date(1), date(2), date(3)+.5);   % add half a day because date is 0h and coordinates typically at 12h
        mjd = jd2mjd_GT(jd);    % mjd of current station
        diff = abs(mjds-mjd);   % difference between current mjd and all mjd
        idx_3 = diff == min(diff);
        X_new = X_curr(idx_3);  % coordinates for current mjd
        Y_new = Y_curr(idx_3);
        Z_new = Z_curr(idx_3);
        % in case of multiple matches take first
        X_new = X_new(1); Y_new = Y_new(1); Z_new = Z_new(1);
        % save correct coordinates for current station and all same dates
        idx_4 = all(dates(i,:) == dates, 2) & idx_1';           % same date AND station
        XYZ(idx_4,1) = X_new;
        XYZ(idx_4,2) = Y_new;
        XYZ(idx_4,3) = Z_new;
        xyz_found(i) = true;
    end
end


% print which stations where found in Coords.txt (to avoid unintended matches)
stations_found = stations(xyz_found);
n = numel(stations_found);
if n > 0
    fprintf('The following station were found in Coords.txt:\n');
    for i = 1:n
        fprintf('%s ', stations_found{i});
        if mod(i,10)==0; fprintf('\n'); end
    end
    fprintf('\n');
end