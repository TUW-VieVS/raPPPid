function ion = read_ion(file_ion)
% Reads coefficients of CODE ionosphere map in spherical harmonics
%
% INPUT: 
%	file_ion        path to .ION file
% OUTPUT:
% 	ion:            struct containing ionosphere spherical harmonics coefficients
% 	... .height      	height of single layer [km]
% 	... .lat_GMP        latitude of geomagnetic pole [°]
% 	... .lon_GMP        longitude of geomagnetic pole [°]
% 	... .t              time in seconds of week
% 	... .degree         degrees n of spherical harmonics
% 	... .order          orders m of spherical harmonics
% 	... .cos_TEC        a_nm coefficients for cosine-term
% 	... .cos_RMS    	RMS of a_nm coeffs
% 	... .sin_TEC      	b_nm coefficients for sine-term
% 	... .sin_RMS    	RMS of b_nm coeffs
%
%   Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



% open file and read-in
fid = fopen(file_ion);
ION = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
ION = ION{1};
fclose(fid);

% initialize variables
no_maps = sum(contains(ION, 'IONOSPHERE MAPS FOR DAY'));        % number of maps in the file
ion.height  = NaN(no_maps,1);       % [km]
ion.lat_GMP	= NaN(no_maps,1);       % [°]
ion.lon_GMP	= NaN(no_maps,1);       % [°]
ion.t       = NaN(no_maps,1);       % [sow]
ion.degree 	= NaN(no_maps,1);
ion.order 	= NaN(no_maps,1);
ion.cos_TEC	= NaN(no_maps,1);       % [TECU]
ion.cos_RMS	= NaN(no_maps,1);       % [TECU]
ion.sin_TEC = NaN(no_maps,1);       % [TECU]
ion.sin_RMS = NaN(no_maps,1);       % [TECU]

% prepare loop
l = 1;
map_idx = 0;
while l <= numel(ION)       	% loop over lines
    line = ION{l};      l = l + 1;
    if contains(line,'IONOSPHERE MAPS FOR DAY')     % new map entry
        map_idx = map_idx + 1; 	% increase map index
    end
    if (length(line)>= 56) && contains(line,'HEIGHT OF SINGLE LAYER')
        ion.height(map_idx) = sscanf(line(1,50:56), '%f');          % [km], get height of single layer
    end
    if contains(line,'COORDINATES OF EARTH-CENTERED DIPOLE AXIS')
       	line = ION{l};      l = l + 1;
        ion.lat_GMP(map_idx) = sscanf(line(1,50:56), '%f');        % [°], latitute of north geomagnetic pole
        line = ION{l};      l = l + 1;
        ion.lon_GMP(map_idx) = sscanf(line(1,50:56), '%f');        % [°], longitude of north geomagnetic pole
    end
    if contains(line,'PERIOD OF VALIDITY')
        line = ION{l};      l = l + 1;
        line = line(1,50:68);
        date = sscanf(line,'%f');                               % format = date, is converted to sow
        jd = cal2jd_GT(date(1), date(2), date(3) + date(4)/24 + date(5)/1440 + date(6)/86400);
        [~, sow, ~] = jd2gps_GT(jd);
        ion.t(map_idx) = sow;
    end
    if contains(line,'COEFFICIENTS')            % start of coefficients
        l = l + 1;   	% skip description line
        idx = 0;        % index for coefficients
        while 1                                 % loop over lines with coefficients
            line = ION{l};      l = l + 1;
            if isempty(line)                    % break on end of dataset (=empty line)
                break;
            end
            help = sscanf(line,'%f');           % degree | oder | value [TECU] | RMS [TECU]
            if help(2) >= 0
                idx = idx + 1;
                ion.degree(map_idx,idx) = help(1);
                ion.order (map_idx,idx) = help(2);
                ion.cos_TEC(map_idx,idx) = help(3);
                ion.cos_RMS(map_idx,idx) = help(4);
                ion.sin_TEC(map_idx,idx) = 0;
                ion.sin_RMS(map_idx,idx) = 0;
            else
                ion.sin_TEC(map_idx,idx) = help(3);
                ion.sin_RMS(map_idx,idx) = help(4);
            end
        end
    end
end

