function [] = writeTropo(storeData, obs, settings)
% This function writes the estimated tropospheric delays into a textfile.
% Details about the 'Tropo SINEX' format can be found here:
% https://www.igs.org/formats-and-standards/
% 
% INPUT:
%	storeData       struct, contains data of processing
%   obs             struct, observable specific data
%   settings        struct, processing settings
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Open output file and get variables
% get troposphere variables
zhd_model = storeData.zhd;
zwd_model = storeData.zwd;
zwd_est   = storeData.param(:,4);
ztd = zhd_model + zwd_model + zwd_est;
ztd = ztd * 1000;       % convert from [m] to [mm]
% get information about station
stat = obs.stationname;
ant  = obs.antenna_type;
% get time variables
date = obs.startdate;
yyyy  = sprintf('%04d',date(1));        % 4-digit year
yy  = yyyy(3:4);                        % 2-digit year
doy = sprintf('%03d',obs.doy);          % day of year
hh = sprintf('%02.0f', obs.startdate(5));   % start hour
mm = sprintf('%02.0f', obs.startdate(6));   % start minute
sec = mod(storeData.gpstime, 86400);    % seconds of day, ||| check this!
n = numel(sec);
% create filename
% filename = ['TUW1PPP_' yyyy doy hh mm '_xxH_xxS_' stat '_TRO.TRO'];
filename = ['TUW1PPP_' yyyy doy hh mm '_' stat '_TRO.TRO'];     % freestyle
zpd_filepath = [settings.PROC.output_dir '/' filename];
% open file
fid = fopen(zpd_filepath, 'w+');

%% Header
% top line
topline = '%=TRO X.XX';
agency = 'TUW';
stadate = sprintf('%s:%s:%05.0f', yy, doy, sec(1));
enddate = sprintf('%s:%s:%05.0f', yy, doy, sec(n));
fprintf(fid,'%s %s %s %s %s %s %s %s \n', ...
    topline, agency, 'aa:bbb:cccccc', agency, stadate, enddate, 'P', stat);  
fprintf(fid,'\n');
% ||| add version, creation

% FILE/REFERENCE
str{1} = '+FILE/REFERENCE';
str{2} = ' DESCRIPTION          ZTD estimation from PPP';
str{3} = ' OUTPUT               Total Troposphere Zenith Path Delay product';
str{4} = ' CONTACT              marcus.glaner@geo.tuwien.ac.at';
str{5} = ' SOFTWARE             raPPPid (VieVS PPP)';
str{6} = ' INPUT                XXXXX, RINEX file';
str{7} = '-FILE/REFERENCE';

% INPUT/ACKNOWLEDGMENTS
str{ 8} = '+INPUT/ACKNOWLEDGMENTS';
str{ 9} = ' XXXXX e.g. IGS';
str{10} = '-INPUT/ACKNOWLEDGMENTS';

% TROP/DESCRIPTION
str{11} = '+TROP/DESCRIPTION';
str{12} = '*_________KEYWORD_____________ __VALUE(S)______________________';
str{13} = [' SAMPLING INTERVAL             ' sprintf('%d', obs.interval)];
str{14} = [' SAMPLING TROP                 ' sprintf('%d', obs.interval)];
str{15} = [' ELEVATION CUTOFF ANGLE        ' sprintf('%d', settings.PROC.elev_mask)];
str{16} =  ' TROP MAPPING FUNCTION         XXXXXXXXXX';
str{17} =  ' SOLUTION_FIELDS_1             TROTOT';
str{18} =  '-TROP/DESCRIPTION';

% +TROP/STA_COORDINATES
str{19} = '+TROP/STA_COORDINATES';
str{20} = '*SITE PT SOLN T __STA_X_____ __STA_Y_____ __STA_Z_____ SYSTEM REMRK';
str{21} = [stat '  X     X xxxxxxx.xxx  xxxxxxx.xxx  xxxxxxx.xxx  XXXXX  XXX'];
str{22} = '-TROP/STA_COORDINATES';

% write header
linebreak = [7, 10, 18, 22];        % add a \n after these lines
for i = 1:numel(str)
    fprintf(fid,'%s\n', str{i});    % writes lines
    if any(i == linebreak)
        fprintf(fid,'\n');          % writes line breaks
    end
end


%% Troposphere estimation
% write beginning of troposphere estimation
fprintf(fid,'%s\n', '+TROP/SOLUTION');
fprintf(fid,'%s\n', ' *SITE ____EPOCH___ TROTOT');
% print data with loop over epochs
for i = 1:n
    fprintf(fid,' %s %s:%s:%05.0f %06.1f\n', ...
        stat, yy, doy, sec(i), ztd(i));
end
% write lines indicating end of file
fprintf(fid,'%s\n', '-TROP/SOLUTION');
fprintf(fid,'%s\n', '%=ENDTRO');

% close file
fclose(fid);        


