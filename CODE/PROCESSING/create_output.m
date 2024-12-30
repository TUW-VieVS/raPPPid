function [storeData] = create_output(storeData, obs, settings, q_end)
% create_output.m is run after PPP_main.m when the epoch-wise processing is 
% finished. Results get exported to files in the result-folder. Furthermore, 
% some results are printed to the command window and saved into storeData 
% 
% INPUT:
%   storeData       struct, collected data from all epochs
%   obs             struct, observation corresponding data
%   settings        struct, settings from GUI
%   q_end           number of processed epochs, Epoch.q
% OUTPUT:
%   storeData       struct, updated, collected data from all epochs
%  
% Revision:
%   2024/12/17, MFWG: slight improvements, writing output for DCM
%   2024/01/18, MFWG: comments, improve trafos, output to command 
%   2023/10/09, MFWG: improving layout of results_float/fixed.txt
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations

obs_int = obs.interval;
epochs = settings.PROC.epochs(1):settings.PROC.epochs(2)+1;   % processed epochs of the rinex observation file

if isempty(epochs)
    % no epochs processed -> can not write any output
    return
end

% --- Get estimated parameters from storeData ---
posFloat = storeData.param(:,1:3);      % estimated float position (x, y, z)

if settings.AMBFIX.bool_AMBFIX
    posFixed = storeData.xyz_fix(:,1:3);                      % estimated fixed position
    sigma_posFixed = sqrt(storeData.param_var_fix(:,1:3));      % fixed coordinates variances
end

if obs_int >= 1
    % round observation interval to full second
    timeCalculated = round(storeData.gpstime);
else
    % round observation interval to 2 decimal places
    timeCalculated = round(100*storeData.gpstime)/100;
end

% initialize
n = size(posFloat,1);
posFloat_geo = NaN(n,3);
posFloat_utm = NaN(n,3);
posFixed_geo = NaN(n,3);
posFixed_utm = NaN(n,3);




%% Output-Data transformations

for i = 1:n         % loop over all epochs to transform coordinates
    % float coordinate solution
    temp_geo = cart2geo(posFloat(i,1:3));                       % ellipsoidal coordinates
    [North, East] = ell2utm_GT(temp_geo.lat, temp_geo.lon);     % UTM coordinates
    % save UTM and ellipsoidal coordinates from current epoch (float)
    posFloat_geo(i,:) = [temp_geo.lat, temp_geo.lon, temp_geo.h];
    posFloat_utm(i,:) = [North,  East,  temp_geo.h];
    if settings.AMBFIX.bool_AMBFIX
        % fixed coordinate solution
        temp_geo = cart2geo(posFixed(i,1:3));                 	% ellipsoidal coordinates
        [North, East] = ell2utm_GT(temp_geo.lat, temp_geo.lon);	% UTM coordinates
        % save UTM and ellipsoidal coordinates from current epoch (fixed)
        posFixed_geo(i,:) = [temp_geo.lat, temp_geo.lon, temp_geo.h];
        posFixed_utm(i,:) = [North,  East,  temp_geo.h];
    end
end

% save coordinates in differents formats in storeData
storeData.posFloat_geo = posFloat_geo;
storeData.posFloat_utm = posFloat_utm;
if settings.AMBFIX.bool_AMBFIX
    storeData.posFixed_geo = posFixed_geo;
    storeData.posFixed_utm = posFixed_utm;
end



%% Write the two main textfiles

% ----- (1) results_float.txt -----
if settings.EXP.results_float
    % open file to write
    fid = fopen([settings.PROC.output_dir,'/results_float.txt'],'w+');
    % create string with epochs, where result of the solution was performed
    line_2nd = '# ';
    if settings.PROC.reset_float
        line_2nd = ['# Reset of float solution in the following epochs: ' num2str(storeData.float_reset_epochs)];
    end   
    % write file depending on PPP model
    if strcmp(settings.IONO.model, 'Estimate, decoupled clock')
        % Decoupled Clock Model
        writeFloatResults_DCM(settings, storeData, line_2nd, fid, q_end, epochs, obs, timeCalculated)
    else
        writeFloatResults(settings, storeData, line_2nd, fid, q_end, epochs, obs, timeCalculated)
    end
    fclose(fid);
end


% ----- (2) results_fixed.txt -----
if settings.AMBFIX.bool_AMBFIX && settings.EXP.results_fixed    % only if ambiguities are fixed and file is written
    
    fid = fopen([settings.PROC.output_dir,'/results_fixed.txt'],'w+');
    line_2nd = '# ';
    if settings.PROC.reset_fixed
        line_2nd = ['# Reset of fixed solution in the following epochs: ' num2str(storeData.float_reset_epochs)];
    end    
    
    % first print comment section
    fprintf(fid,'%s\n',['# This file contains all relevant output data of the fixed solution: ' settings.PROC.output_dir]);
    fprintf(fid,'%s\n',line_2nd);
    fprintf(fid,'%s\n','# Columns:');
    fprintf(fid,'%s\n','# (1) number of epoch');
    fprintf(fid,'%s\n','# (2) GPS week number');
    fprintf(fid,'%s\n','# (3) Seconds of GPS week');
    fprintf(fid,'%s\n','# (4) receiver position: x [m]');
    fprintf(fid,'%s\n','# (5) receiver position: y [m]');
    fprintf(fid,'%s\n','# (6) receiver position: z [m]');
    fprintf(fid,'%s\n','# (7) sigma receiver position: x [m]');
    fprintf(fid,'%s\n','# (8) sigma receiver position: y [m]');
    fprintf(fid,'%s\n','# (9) sigma receiver position: z [m]');
    fprintf(fid,'%s\n','# (10) receiver position: phi [°]');
    fprintf(fid,'%s\n','# (11) receiver position: lambda [°]');
    fprintf(fid,'%s\n','# (12) receiver position: height [m]');
    fprintf(fid,'%s\n','# (13) receiver position: x_UTM [m]');
    fprintf(fid,'%s\n','# (14) receiver position: y_UTM [m]');
    fprintf(fid,'%s\n','#************************************************** ');
    fprintf(fid,'%s\n','# (1)  (2)       (3)        (4)             (5)             (6)        (7)        (8)        (9)        (10)          (11)             (12)          (13)            (14)');
    
    % print the data with loop over epochs
    for q = 1:q_end
        fprintf(fid,'%4.0f  %4.0f  %8.1f  %14.6f  %14.6f  %14.6f  %9.6f  %9.6f  %9.6f  %12.9f  %13.10f  %9.4f  %14.6f  %14.6f   \n'   ,   ...
            epochs(q) , obs.startGPSWeek , timeCalculated(q) , ...
            posFixed(q,1) , posFixed(q,2) , posFixed(q,3) , ...
            sigma_posFixed(q,1) , sigma_posFixed(q,2) , sigma_posFixed(q,3) , ... 
            posFixed_geo(q,1)*180/pi , posFixed_geo(q,2)*180/pi , posFixed_geo(q,3) , ...
            posFixed_utm(q,1) , posFixed_utm(q,2));
    end
    fclose(fid);
    
end



%% Write additional files
posTemp = posFloat_geo;
if settings.AMBFIX.bool_AMBFIX;    posTemp = posFixed_geo;      end

% --- Export to result.nmea ---
if settings.EXP.nmea
    if 1 < settings.INPUT.use_GPS + settings.INPUT.use_GLO + settings.INPUT.use_GAL + settings.INPUT.use_BDS
        str_sol = 'GN';        % create beginn of NMEA message depending on processed GNSS
    elseif settings.INPUT.use_GPS;        str_sol = 'GP';
    elseif settings.INPUT.use_GLO;        str_sol = 'GL';
    elseif settings.INPUT.use_GAL;        str_sol = 'GA';
    elseif settings.INPUT.use_GAL;        str_sol = 'BD';  
    end
    UTC = timeCalculated - obs.leap_sec;
    nmea_path = [settings.PROC.output_dir, '/results.nmea'];
    nsats = sum(full(storeData.C1)~=0,2);   % number of satellites (fishy calculation)
    createNMEAOutput(UTC, posTemp, nmea_path, str_sol, storeData.HDOP, nsats, obs.startdate);
end

% --- Export positions to trajectory.kml (e.g., for Google Earth) ---
if settings.EXP.kml
    kml_path = [settings.PROC.output_dir, '/trajectory.kml'];
    valid = ~any(isnan(posTemp) | isinf(posTemp),2);     % check which epochs are valid
    kmlwriteline(kml_path, posTemp(valid,1)/pi*180, posTemp(valid,2)/pi*180, posTemp(valid,3), ...
        'Name', settings.PROC.name, 'Description', settings.PROC.output_dir, 'Color', 'b', 'Alpha', 1, 'LineWidth', 8)
end


% Write troposphere delay estimation into file
if settings.EXP.tropo_est
    writeTropo(storeData, obs, settings)
end




%% Output to command window 

% print coordinates of the last epoch
if ~settings.INPUT.bool_parfor
    % get ellipsoidal and cartesian coordinates from the last epoch
    geo_print = posFloat_geo(n,:);
    XYZ_print = posFloat(n,:);
    % print ellipsoidal coordinates
    fprintf('\nFloat coordinates of the last processed epoch\n');
    fprintf('Latitude: \t %9.5f [°]\n', geo_print(1)*(180/pi));
    fprintf('Longitude:\t %9.5f [°]\n', geo_print(2)*(180/pi));
    fprintf('Height:\t\t %9.3f [m], WGS84\n', geo_print(3));
    % print cartesian coordinates
    fprintf('X:\t%12.3f [m]\n', XYZ_print(1));
    fprintf('Y:\t%12.3f [m]\n', XYZ_print(2));
    fprintf('Z:\t%12.3f [m], %s\n\n',XYZ_print(3), obs.coordsyst);
end





function [] = writeFloatResults(settings, storeData, line_2nd, fid, q_end, epochs, obs, timeCalculated)
% settings ... struct, processing settings
% storeData ... struct, processing results
% line_2nd ... string, content of second line (e.g., resets)
% fid ... file to write
% epochs ... vector, processed epochs
% obs ... struct, observation-specific variables
% timeCalculated ... vector, GPS time of each epoch

% get some variables
posFloat         = storeData.param(:,1:3);  	% float position, x-y-z
posFloat_geo     = storeData.posFloat_geo;      % float position, lat-lon-height
posFloat_utm     = storeData.posFloat_utm;      % float position, UTM_x - UTM_y
sigma_posFloat   = sqrt(storeData.param_var(:,1:3));	% sigma estimated float position
delta_zwd        = storeData.param(:,4);        % estimated Zenith Wet Delay
% estimated receiver clock error / time offsets
rec_dt_GPS       = storeData.param(:, 5);       % estimated receiver clock error for GPS
rec_dt_GLO       = storeData.param(:, 8);       % estimated time offset / receiver clock error for Glonass
rec_dt_GAL       = storeData.param(:,11);    	% estimated time offset / receiver clock error for Galileo
rec_dt_BDS       = storeData.param(:,14);    	% time offset / estimated receiver clock error for BeiDou
% variances of time offsets / receiver clock error:
sigma_rec_dt_GPS = sqrt(storeData.param_var(:, 5));
sigma_rec_dt_GLO = sqrt(storeData.param_var(:, 8));
sigma_rec_dt_GAL = sqrt(storeData.param_var(:,11));
sigma_rec_dt_BDS = sqrt(storeData.param_var(:,14));
% estimated DCBs
rec_dcb_12_GPS = storeData.param(:, 6);        % estimated DCB between GPS frequency 1 and 2
rec_dcb_13_GPS = storeData.param(:, 7);        % estimated DCB between GPS frequency 1 and 3
rec_dcb_12_GLO = storeData.param(:, 9);        % estimated DCB between Glonass frequency 1 and 2
rec_dcb_13_GLO = storeData.param(:,10);        % estimated DCB between Glonass frequency 1 and 3
rec_dcb_12_GAL = storeData.param(:,12);        % estimated DCB between Galileo frequency 1 and 2
rec_dcb_13_GAL = storeData.param(:,13);        % estimated DCB between Galileo frequency 1 and 3
rec_dcb_12_BDS = storeData.param(:,15);        % estimated DCB between BeiDou frequency 1 and 2
rec_dcb_13_BDS = storeData.param(:,16);        % estimated DCB between BeiDou frequency 1 and 3
% read the a priori zwd and zhd, those are equal for all satellites
zwd_model = storeData.zwd;
zhd_model = storeData.zhd;

% first print comment section
fprintf(fid,'%s\n',['# This file contains all relevant output data of the float solution: ' settings.PROC.output_dir]);
fprintf(fid,'%s\n', line_2nd);
fprintf(fid,'%s\n','# Columns:');
fprintf(fid,'%s\n','# (1) number of epoch');
fprintf(fid,'%s\n','# (2) GPS week number');
fprintf(fid,'%s\n','# (3) Seconds of GPS week');
fprintf(fid,'%s\n','# (4) receiver position: x [m]');
fprintf(fid,'%s\n','# (5) receiver position: y [m]');
fprintf(fid,'%s\n','# (6) receiver position: z [m]');
fprintf(fid,'%s\n','# (7) sigma receiver position: x [m]');
fprintf(fid,'%s\n','# (8) sigma receiver position: y [m]');
fprintf(fid,'%s\n','# (9) sigma receiver position: z [m]');
fprintf(fid,'%s\n','# (10) receiver position: latitude [°]');
fprintf(fid,'%s\n','# (11) receiver position: longitude [°]');
fprintf(fid,'%s\n','# (12) receiver position: height [m]');
fprintf(fid,'%s\n','# (13) receiver position: x_UTM [m]');
fprintf(fid,'%s\n','# (14) receiver position: y_UTM [m]');
fprintf(fid,'%s\n','# (15) receiver clock error dt_GPS [m]');
fprintf(fid,'%s\n','# (16) receiver clock error dt_GLONASS [m]');
fprintf(fid,'%s\n','# (17) receiver clock error dt_Galileo [m]');
fprintf(fid,'%s\n','# (18) receiver clock error dt_BeiDou [m]');
fprintf(fid,'%s\n','# (19) sigma receiver clock error dt_GPS [m]');
fprintf(fid,'%s\n','# (20) sigma receiver clock error dt_GLONASS [m]');
fprintf(fid,'%s\n','# (21) sigma receiver clock error dt_Galileo [m]');
fprintf(fid,'%s\n','# (22) sigma receiver clock error dt_BeiDou [m]');
fprintf(fid,'%s\n','# (23) estimated zwd [m]');
fprintf(fid,'%s\n','# (24) zwd (a priori + estimate) [m]');
fprintf(fid,'%s\n','# (25) zhd modelled [m]');
fprintf(fid,'%s\n','# (26) DCB GPS frequency 1 and 2 [m]');
fprintf(fid,'%s\n','# (27) DCB GPS frequency 1 and 3 [m]');
fprintf(fid,'%s\n','# (28) DCB Glonass frequency 1 and 2 [m]');
fprintf(fid,'%s\n','# (29) DCB Glonass frequency 1 and 3 [m]');
fprintf(fid,'%s\n','# (30) DCB Galileo frequency 1 and 2 [m]');
fprintf(fid,'%s\n','# (31) DCB Galileo frequency 1 and 3 [m]');
fprintf(fid,'%s\n','# (32) DCB BeiDou frequency 1 and 2 [m]');
fprintf(fid,'%s\n','# (33) DCB BeiDou frequency 1 and 3 [m]');
fprintf(fid,'%s\n','#************************************************** ');
fprintf(fid,'%s\n','# (1)  (2)       (3)        (4)             (5)             (6)        (7)        (8)        (9)        (10)          (11)             (12)          (13)            (14)            (15)            (16)            (17)            (18)       (19)       (20)       (21)       (22)       (23)       (24)       (25)      (26)   (27)   (28)   (29)   (30)   (31)   (32)   (33)');

% print the data with loop over epochs
for q = 1:q_end
    %              1      2      3       4       5       6        7      8      9       10       11     12       13     14         15      16     17      18     19       20     21     22     23     24     25     26     27     28     29     30     31     32      33
    fprintf(fid,'%4.0f  %4.0f  %8.1f  %14.6f  %14.6f  %14.6f  %9.6f  %9.6f  %9.6f  %12.9f  %13.10f  %9.4f  %14.6f  %14.6f  %14.6f  %14.6f  %14.6f  %14.6f  %9.6f  %9.6f  %9.6f  %9.6f  %9.6f  %9.6f  %9.6f  %2.3f  %2.3f  %2.3f  %2.3f  %2.3f  %2.3f  %2.3f  %2.3f  \n'   ,   ...
        epochs(q) , obs.startGPSWeek , timeCalculated(q) , ...  % 1, 2, 3
        posFloat(q,1) , posFloat(q,2) , posFloat(q,3) , ...     % 4, 5, 6
        sigma_posFloat(q,1) , sigma_posFloat(q,2) , sigma_posFloat(q,3) , ...
        posFloat_geo(q,1)*180/pi , posFloat_geo(q,2)*180/pi , posFloat_geo(q,3) , ...
        posFloat_utm(q,1) , posFloat_utm(q,2), ...
        rec_dt_GPS(q) , rec_dt_GLO(q) , rec_dt_GAL(q) , rec_dt_BDS(q) ,...
        sigma_rec_dt_GPS(q) , sigma_rec_dt_GLO(q) , sigma_rec_dt_GAL(q) , sigma_rec_dt_BDS(q), ...
        delta_zwd(q) , zwd_model(q)+delta_zwd(q), zhd_model(q), ...     % 23, 24, 25
        rec_dcb_12_GPS(q) , rec_dcb_13_GPS(q), ...      % 26, 27
        rec_dcb_12_GLO(q) , rec_dcb_13_GLO(q), ...      % 28, 29
        rec_dcb_12_GAL(q) , rec_dcb_13_GAL(q), ...      % 30, 31
        rec_dcb_12_BDS(q) , rec_dcb_13_BDS(q) );        % 32, 33
end



function [] = writeFloatResults_DCM(settings, storeData, line_2nd, fid, q_end, epochs, obs, timeCalculated)
% settings ... struct, processing settings
% storeData ... struct, processing results
% line_2nd ... string, content of second line (e.g., resets)
% fid ... file to write
% epochs ... vector, processed epochs
% obs ... struct, observation-specific variables
% timeCalculated ... vector, GPS time of each epoch

% get variables
posFloat         = storeData.param(:,1:3);  	% float position, x-y-z
posFloat_geo     = storeData.posFloat_geo;      % float position, lat-lon-height
posFloat_utm     = storeData.posFloat_utm;      % float position, UTM_x - UTM_y
sigma_posFloat   = sqrt(storeData.param_var(:,1:3));	% sigma estimated float position
delta_zwd        = storeData.param(:,4);        % estimated Zenith Wet Delay

% read the a priori zwd and zhd, those are equal for all satellites
zwd_model = storeData.zwd;
zhd_model = storeData.zhd;

% first print comment section
fprintf(fid,'%s\n',['# This file contains all relevant output data of the float solution: ' settings.PROC.output_dir]);
fprintf(fid,'%s\n', line_2nd);
fprintf(fid,'%s\n','# Columns:');
fprintf(fid,'%s\n','# (1) number of epoch');
fprintf(fid,'%s\n','# (2) GPS week number');
fprintf(fid,'%s\n','# (3) Seconds of GPS week');
% position
fprintf(fid,'%s\n','# (4) receiver position: x [m]');
fprintf(fid,'%s\n','# (5) receiver position: y [m]');
fprintf(fid,'%s\n','# (6) receiver position: z [m]');
fprintf(fid,'%s\n','# (7) sigma receiver position: x [m]');
fprintf(fid,'%s\n','# (8) sigma receiver position: y [m]');
fprintf(fid,'%s\n','# (9) sigma receiver position: z [m]');
fprintf(fid,'%s\n','# (10) receiver position: latitude [°]');
fprintf(fid,'%s\n','# (11) receiver position: longitude [°]');
fprintf(fid,'%s\n','# (12) receiver position: height [m]');
fprintf(fid,'%s\n','# (13) receiver position: x_UTM [m]');
fprintf(fid,'%s\n','# (14) receiver position: y_UTM [m]');
% troposphere
fprintf(fid,'%s\n','# (15) estimated zwd [m]');
fprintf(fid,'%s\n','# (16) zwd (a priori + estimate) [m]');
fprintf(fid,'%s\n','# (17) zhd modelled [m]');
fprintf(fid,'%s\n','#************************************************** ');
fprintf(fid,'%s\n','# (1)  (2)       (3)        (4)              (5)             (6)        (7)        (8)        (9)        (10)           (11)             (12)          (13)            (14)       (15)       (16)      (17)');

% print the data with loop over epochs
for q = 1:q_end
    %              1      2      3       4       5       6      7      8      9      10      11      12      13      14      15    16     17     
    fprintf(fid,'%4.0f  %4.0f  %8.1f  %14.6f  %14.6f  %14.6f  %9.6f  %9.6f  %9.6f  %12.9f  %13.10f  %9.4f  %14.6f  %14.6f  %9.6f  %9.6f  %2.3f  \n'   ,   ...
        epochs(q) , obs.startGPSWeek , timeCalculated(q) , ...  % 1, 2, 3
        posFloat(q,1) , posFloat(q,2) , posFloat(q,3) , ...     % 4, 5, 6
        sigma_posFloat(q,1) , sigma_posFloat(q,2) , sigma_posFloat(q,3) , ...
        posFloat_geo(q,1)*180/pi , posFloat_geo(q,2)*180/pi , posFloat_geo(q,3) , ...
        posFloat_utm(q,1) , posFloat_utm(q,2), ...
        delta_zwd(q) , zwd_model(q)+delta_zwd(q), zhd_model(q) );      
end