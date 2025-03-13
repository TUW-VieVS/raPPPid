function input = get_V3GR(obs, input, settings)
% Defines and reads all VMF3+GRAD information, collected under the term V3GR.
% 
% INPUT:
%   obs         struct, observation-specific information
%   input       struct, holding input data
%   settings    struct, processing settings from GUI
% OUTPUT:
%	input       struct, updated with input.TROPO.V3GR.data
% 
% Coded:
%   01 Feb 2019 by D. Landskron
%
% Revision:
%   July 23 by MFG      slight improvments (e.g., comments)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



% define which jd's are needed
V3GR_data_all = [];
jd_all = (floor(obs.startdate_jd-0.5)+0.5-1 : floor(obs.startdate_jd-0.5)+0.5+1);   % get the 3 jd's: previous day, current day and subsequent day (a bit complicated because a julian day starts at *.5)



% start the loop over all necessary daily files
for i_jd = 1:length(jd_all)
    
    % first determine all date variables
    % mjd = jd_all(i_jd) - 2400000.5;
    [year, ~, ~] = jd2cal_GT(jd_all(i_jd));
    year_str = num2str(year);
    doy = jd2doy_GT(jd_all(i_jd));
    doy_str = num2str(doy,'%03d');
    
    % define the subdirectory
    if year < 2008
        NWM_source = 'EI';
    elseif strcmp(settings.TROPO.vmf_version, 'operational')
        NWM_source = 'OP';
    elseif strcmp(settings.TROPO.vmf_version, 'forecast')
        NWM_source = 'FC';
    end
    
    % define the paths for V3GR
    dir_V3GR_sitewise = ['../DATA/V3GR/sitewise/V3GR_' NWM_source '/'];
    url_V3GR_sitewise = ['https://vmf.geo.tuwien.ac.at/trop_products/GNSS/V3GR/V3GR_' NWM_source '/daily/'];
    dir_V3GR_gridwise = ['../DATA/V3GR/gridwise/V3GR_' NWM_source '/'];
    gridsize = [sprintf('%d', DEF.VMF3_grid_resolution) 'x' sprintf('%d', DEF.VMF3_grid_resolution)];
    url_V3GR_gridwise = ['https://vmf.geo.tuwien.ac.at/trop_products/GRID/' gridsize '/V3GR/V3GR_' NWM_source '/'];

    file_V3GR = [year_str doy_str '.v3gr_g'];
    
    % check if the respective V3GR yearly file(s) is locally available. If not, then download. Also update an outdated existing yearly file.
    if ~exist([dir_V3GR_sitewise '/' year_str '/' file_V3GR],'file')   % if file does not exists, download in any case
        [~, ~] = mkdir([dir_V3GR_sitewise '/' year_str '/']);
        try
            websave([dir_V3GR_sitewise '/' year_str '/' file_V3GR], [url_V3GR_sitewise '/' year_str '/' file_V3GR]);
        catch
            fprintf(2, ['Download failed: ' url_V3GR_sitewise '/' year_str '/' file_V3GR '\n'])
            errordlg({'VMF3 is not available!', 'Change troposphere model to GPT3.'}, 'Error');
            continue
        end
        if ~settings.INPUT.bool_parfor
            fprintf('  %s%s%s%s\n' , file_V3GR,' successfully downloaded into ',dir_V3GR_sitewise,'.');
        end
    end

    % open the V3GR file
    fid = fopen([dir_V3GR_sitewise '/' year_str '/' file_V3GR]);
    V3GR_data = textscan(fid,'%s%f%f%f%f%f%f%f%f%f%f%f%f','CommentStyle','#');
    fclose(fid);
    
    % concatenate the files, if necessary
    V3GR_data_all = [V3GR_data_all; V3GR_data];
    
end


% concatenate data
clear V3GR_data
for i_col = 1:size(V3GR_data_all,2)
    V3GR_data{i_col} = cat(1, V3GR_data_all{:,i_col});
end

% check if VMF3 stationlist contains processed station (e.g., IGS station)
ind = ismember(V3GR_data{1,1}, strtrim(obs.stationname));
if sum(ind)~=0          % station is part of stationlist
    
    % use sitewise V3GR
    input.TROPO.V3GR.version = 'sitewise';
    for i_col = 1:length(V3GR_data)     % get data for this station
        input.TROPO.V3GR.data{i_col} = V3GR_data{i_col}(ind);
    end
    
else                    % station is not part of VMF3 stationlist
    
    % use gridwise V3GR
    input.TROPO.V3GR.version = 'gridwise';
    % determine all necessary mjd's
    input.TROPO.V3GR.data{2} = unique(V3GR_data{2});
    % get the correct VMF3 and/or GRAD coefficients
    V3GR_grid_file = [];
    approx_pos_WGS84 = cart2geo(settings.INPUT.pos_approx);
    for i_jd = 1:length(input.TROPO.V3GR.data{2})
        % determine mapping functions + zenith delays from gridded V3GR files
        input.TROPO.V3GR.data{1}{i_jd} = upper(obs.stationname);
        [...
            input.TROPO.V3GR.data{3}(i_jd,1), input.TROPO.V3GR.data{4}(i_jd,1), ...
            input.TROPO.V3GR.data{5}(i_jd,1), input.TROPO.V3GR.data{6}(i_jd,1), ...
            input.TROPO.V3GR.data{10}(i_jd,1), input.TROPO.V3GR.data{11}(i_jd,1), ...
            input.TROPO.V3GR.data{12}(i_jd,1), input.TROPO.V3GR.data{13}(i_jd,1), V3GR_grid_file ] = ...
            v3gr_grid_adapted ( dir_V3GR_gridwise, url_V3GR_gridwise, V3GR_grid_file, input.TROPO.V3GR.data{2}(i_jd), ...
            approx_pos_WGS84.lat, approx_pos_WGS84.lon, approx_pos_WGS84.h, DEF.VMF3_grid_resolution);
    end

end

% Column description V3GR data (input.TROPO.V3GR.data):
% (1)	station name
% (2)	modified Julian date
% (3)	hydrostatic "a" coefficient
% (4)	wet "a" coefficient
% (5)	zenith hydrostatic delay [m]
% (6)	zenith wet delay [m]
% (7)	pressure at the site [hPa], empty for gridwise
% (8)	temperature at the site [°C], empty for gridwise
% (9)	water vapor pressure at the site [hPa], empty for gridwise
% (10)	hydrostatic north gradient Gn_h [mm]
% (11)	hydrostatic east gradient Ge_h [mm]
% (12)	wet north gradient Gn_w [mm]
% (13)	wet east gradient Ge_w [mm]
