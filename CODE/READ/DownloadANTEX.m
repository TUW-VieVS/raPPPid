function path_antex = DownloadANTEX(settings, obs_startdate)
% Determines and downloads the correct ANTEX file
%
% INPUT:
%   settings    struct, processing settings from GUI
%   obs_startdate   vector, [year month day hour minute second]
% OUTPUT:
%	path_antex  string, path to (hopefully) correct ANTEX file
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Determine coordinate system of satellite orbits
path_sp3 = settings.ORBCLK.file_sp3;
if contains(path_sp3, '$')
    [fname, fpath] = ConvertStringDate(path_sp3, obs_startdate(1:3));
    path_sp3 = ['../DATA/ORBIT' fpath fname];
end
coordsyst = GetCoordSystemFromSP3(path_sp3);


% Determine correct ANTEX file
switch coordsyst
    case {'IGb14', 'IGS14'}
        file_atx = 'igs14.atx';
    case {'IGS20'}
        file_atx = 'igs20.atx';
    case {'IGS08'}
        file_atx = 'igs08.atx';
    case {'IGS05'}
        file_atx = 'igs05.atx';
    case 'brdc'
        % Broadcast products are used, determine reference frame with date
        jd = cal2jd_GT(obs_startdate(1),obs_startdate(2),obs_startdate(3));
        [gpsweek, ~, ~] = jd2gps_GT(jd);
        if gpsweek >= 2238; file_atx = 'igs20.atx';
        else;               file_atx = 'igs14.atx';        end
        % ||| consider older dates
    otherwise
        file_atx = 'igs20.atx';
        msgbox({'DownloadANTEX struggled to determine', 'the correct ANTEX file: igs20.atx is used.'}, 'Attention')
end

% path to antex file
target_atx = [Path.DATA, 'ANTEX/'];
path_antex = [target_atx file_atx];

% Check if file is existing and download
download = false;
if strcmp(settings.OTHER.antex, 'Use existing igsXX.atx') && ~exist(path_antex, 'file')
    download = true;    % existing antex file is not existing -> download
end
if strcmp(settings.OTHER.antex, 'Download current igsXX.atx') || download
        delete([target_atx, file_atx]);  	% delete old igsXX.atx file to enable download of new file
        % atx-files are not small and server is slow -> increase timeout
        woptions = weboptions;
        woptions.Timeout = 60;      % use 60s (usually 5s is the default value)
        websave([target_atx file_atx] , ['https://files.igs.org/pub/station/general/' file_atx], woptions);
end

