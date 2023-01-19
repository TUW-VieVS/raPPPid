function DATA = readTropoFile(tropofile, station)
% Reads a troposphere file (*.*zpd) for a specific station
%
% INPUT:
%   tropofile   string, path to troposphere file
%   station     string, 4-digit station name
% OUTPUT:
%   data        troposphere data for station in internal format,
%               [n x 6] - matrix:
%               [year | doy | seconds of day | ZTD | stdev of ZTD]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| only ZTD is considered


%% HEADER
fid = fopen(tropofile); l = 0;
% Loop over header
while 1
    line = fgetl(fid); l = l + 1;
    if contains(line, '+TROP/SOLUTION')
        break;
    end
    
    if contains(line, 'SOLUTION_FIELDS_1')
        datafields = line(32:end);      % get only relevant part of line
        datafields = split(datafields);
        % zenith total delay (ztd)
        idx_ztd     = find(contains(datafields, 'TROTOT'));
        % check for stdev of ztd
        idx_std_ztd = [];
        if idx_ztd < numel(datafields) && strcmp(datafields{idx_ztd+1}, 'STDDEV')
            idx_std_ztd = idx_ztd + 1;
        end            
        % ||| look for other entries here e.g. gradients
    end
end



%% DATA
% Get station data
DATA = zeros(1,5); d = 1;
while 1
    line = fgetl(fid); l = l + 1;
    
    if contains(line, station)
        % get and save date
        date = sscanf(line(1:18),' %*s %2f:%3f:%5f')';      % year, doy, seconds of day
        DATA(d, 1:3) = date;        
        
        % get and save ZTD and stdev of ZTD
        linedata = sscanf(line(19:end), '%f')';             % data records
        DATA(d, 4) = linedata(idx_ztd);
        if ~isempty(idx_std_ztd)
            DATA(d, 5) = linedata(idx_std_ztd);
        end
        d = d + 1;

    end
    
    % check for end of file
    if feof(fid) || contains(line, '-TROP/SOLUTION') || contains(line, '%=ENDTRO')
        break;
    end
end
fclose(fid);

DATA(:,4) = DATA(:,4) / 1000;   % convert ZTD to [m]
