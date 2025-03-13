function input = get_VMF1(obs, input, settings)
% Defines and reads all VMF1 information.
% 
% INPUT:
%   obs         struct, observation-specific information
%   input       struct, holding input data
%   settings    struct, processing settings from GUI
% OUTPUT:
%	input       struct, updated with input.TROPO.VMF1.data
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


product = 'VMF1';

if strcmp(settings.TROPO.vmf_version, 'operational')
    type = 'VMF1_OP';
elseif strcmp(settings.TROPO.vmf_version, 'forecast')
    type = 'VMF1_FC';
end

% get the 3 jd's: previous day, current day and subsequent day (a bit 
% complicated because a julian day starts at *.5)
VMF1_data_all = [];
% define which jd's are needed
jd_all = (floor(obs.startdate_jd-0.5)+0.5-1 : floor(obs.startdate_jd-0.5)+0.5+1);   

% loop over all necessary daily files to check, download, and open
for i_jd = 1:length(jd_all)
    
    % first determine all date variables
    [year, ~, ~] = jd2cal_GT(jd_all(i_jd));
    year_str = num2str(year);
    doy = jd2doy_GT(jd_all(i_jd));
    doy_str = num2str(doy,'%03d');
       
    % define the paths for VMF1
    dir_VMF1_sitewise = ['../DATA/VMF1/sitewise/' type '/'];
    url_VMF1_sitewise = ['https://vmf.geo.tuwien.ac.at/trop_products/GNSS/VMF1/' type '/daily/'];
    dir_VMF1_gridwise = ['../DATA/VMF1/gridwise/' type '/'];
    url_VMF1_gridwise = ['https://vmf.geo.tuwien.ac.at/trop_products/GRID/2.5x2/VMF1/' type '/'];
                        
    % VMF1 file for this day
    file_VMF1 = [year_str doy_str '.vmf1_g'];
    
    % check if the VMF1 file is locally available 
    if ~exist([dir_VMF1_sitewise '/' year_str '/' file_VMF1],'file')   
        % if file does not exists, download it
        [~, ~] = mkdir([dir_VMF1_sitewise '/' year_str '/']);
        try
            websave([dir_VMF1_sitewise '/' year_str '/' file_VMF1], [url_VMF1_sitewise '/' year_str '/' file_VMF1]);
        catch
            fprintf(2, ['Download failed: ' url_VMF1_sitewise '/' year_str '/' file_VMF1 '\n'])
            errordlg({'VMF1 is not available!', 'Change troposphere model to GPT3.'}, 'Error');
            continue
        end
        if ~settings.INPUT.bool_parfor
            fprintf('  %s%s%s%s\n' , file_VMF1,' successfully downloaded into ', dir_VMF1_sitewise,'.');
        end
    end
    
    % open the VMF1 file
    fid = fopen([dir_VMF1_sitewise '/' year_str '/' file_VMF1]);
    VMF1_data = textscan(fid,'%s%f%f%f%f%f%f%f%f%f%f','CommentStyle','#');
    fclose(fid);
    
    % concatenate the files, if necessary
    VMF1_data_all = [VMF1_data_all; VMF1_data];
    
end


% concatenate data
clear VMF1_data
for i_col = 1:size(VMF1_data_all,2)
    VMF1_data{i_col} = cat(1, VMF1_data_all{:,i_col});
end

% check if VMF1 stationlist contains processed station (e.g., IGS station)
ind = ismember(upper(VMF1_data{1,1}), strtrim(obs.stationname));
if any(ind)         % station is part of stationlist
    
    % use sitewise VMF1
    input.TROPO.VMF1.version = 'sitewise';
    % get data for this station
    for i_col = 1:length(VMF1_data)
        input.TROPO.VMF1.data{i_col} = VMF1_data{i_col}(ind);
    end

else
    
    % use gridwise VMF1
    input.TROPO.VMF1.version = 'gridwise';
    
    % determine all necessary mjd's
    input.TROPO.VMF1.data{2} = unique(VMF1_data{2});
    
    % get the correct VMF1 coefficients
    VMF1_grid_file = []; 
    approx_pos_WGS84 = cart2geo(settings.INPUT.pos_approx);     % approximate position
    
    for i_jd = 1:length(input.TROPO.VMF1.data{2})
        dir_orography = '../CODE/ATMOSPHERE';
        input.TROPO.VMF1.data{1}{i_jd} = upper(obs.stationname);
        [...
            input.TROPO.VMF1.data{ 3}(i_jd,1), input.TROPO.VMF1.data{ 4}(i_jd,1), ...
            input.TROPO.VMF1.data{ 5}(i_jd,1), input.TROPO.VMF1.data{ 6}(i_jd,1), VMF1_grid_file ] = ...
            vmf1_grid_adapted(dir_VMF1_gridwise, dir_orography, url_VMF1_gridwise, VMF1_grid_file, ...
            input.TROPO.VMF1.data{2}(i_jd), approx_pos_WGS84.lat, approx_pos_WGS84.lon, approx_pos_WGS84.h);
        
    end

end


% Column description of input.TROPO.VMF1.data:
% (1)	station name
% (2)	modified Julian date
% (3)	hydrostatic "a" coefficient
% (4)	wet "a" coefficient
% (5)	hydrostatic zenith delay [m]
% (6)	wet zenith delay [m]
% (7)	mean temperature of the atmosphere at the Earth surface corresponding to orography_ell [K]
% (8)	pressure at the site [hPa], empty for gridwise
% (9)	temperature at the site [°C], empty for gridwise
% (10)	water vapor pressure at the site [hPa], empty for gridwise
% (11)	orthometric height of the station [m] (using geoid EGM96), empty for gridwise