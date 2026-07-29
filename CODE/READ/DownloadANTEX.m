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




%% Determine ANTEX file 
% Determine coordinate system and ANTEX file of satellite orbits
path_sp3 = settings.ORBCLK.file_sp3;
if contains(path_sp3, '$')
    [fname, fpath] = ConvertStringDate(path_sp3, obs_startdate(1:3));
    path_sp3 = ['../DATA/ORBIT' fpath fname];
end
[coordsyst, atx] = GetCoordAntexFromSP3(path_sp3);

% ANTEX file according to sp3 file (alternative: input.BIASES.sinex.Header.APC_MODEL)
file_atx_wwww = lower([atx '.atx']);

% Determine (backup) ANTEX file
switch coordsyst
    case {'IGb14', 'IGS14'}
        file_atx_XX = 'igs14.atx';
    case {'IGc20', 'IGb20', 'IGS20'}
        file_atx_XX = 'igs20.atx';
    case {'IGS08'}
        file_atx_XX = 'igs08.atx';
    case {'IGS05'}
        file_atx_XX = 'igs05.atx';
    case 'brdc'
        % Broadcast products are used, determine reference frame with date
        jd = cal2jd_GT(obs_startdate(1),obs_startdate(2),obs_startdate(3));
        [gpsweek, ~, ~] = jd2gps_GT(jd);
        if gpsweek >= 2238; file_atx_XX = 'igs20.atx';
        else;               file_atx_XX = 'igs14.atx';        end
        % ||| consider older dates
    otherwise
        file_atx_XX = 'igs20.atx';
        msgbox({'DownloadANTEX struggled to determine', 'the correct ANTEX file: igs20.atx is used.'}, 'Attention')
end

% path to antex file
target_atx = [Path.DATA, 'ANTEX/'];
path_antex_wwww = [target_atx file_atx_wwww];
path_antex_XX = [target_atx file_atx_XX];




%% Download latest ANTEX file

% atx-files are not small and server is slow -> increase timeout
woptions = weboptions;
woptions.Timeout = 60;      % use 60s (usually 5s is the default value)


% download and use latest version of, for example, igs20.atx
if strcmp(settings.OTHER.antex, 'Download current igsXX.atx')
    % websave overwrites the target file in place on success, so the
    % previous local file is only replaced once the download succeeded
    try
        websaveChecked(path_antex_XX, ['https://files.igs.org/pub/station/general/' file_atx_XX], woptions);
    catch
        fprintf(2, 'Download of %s failed! Keeping previous local file.\n', file_atx_XX);
    end
    path_antex = path_antex_XX;
    return
end


% download and use ANTEX file specified in SP3 file
if strcmp(settings.OTHER.antex, 'igsXX_wwww.atx autodetection')
    path_antex = path_antex_wwww;

    % no ANTEX version could be autodetected from the SP3 file (atx is empty
    % -> file_atx_wwww is just '.atx'): skip the pointless archive download
    % and fall back directly to igsXX.atx
    if isempty(atx)
        if ~isfile(path_antex_XX)
            try
                websaveChecked(path_antex_XX, ['https://files.igs.org/pub/station/general/' file_atx_XX], woptions);
            catch
                errordlg({'Download of ANTEX file failed:', file_atx_XX}, 'Error');
            end
        end
        path_antex = path_antex_XX;
        return
    end

    if ~isfile(path_antex_wwww)
        % download autodetected ANTEX file
        try
            try
                % download compressed ANTEX file
                websaveChecked([path_antex_wwww '.gz'], ['https://files.igs.org/pub/station/general/pcv_archive/' file_atx_wwww '.gz'], woptions);
                [~] = unzip_and_delete({[file_atx_wwww '.gz']}, {target_atx});
            catch
                % download ANTEX file
                websaveChecked(path_antex_wwww, ['https://files.igs.org/pub/station/general/pcv_archive/' file_atx_wwww], woptions);
            end
        catch
            % use igsXX.atx as fallback
            if ~isfile(path_antex_XX)
                try
                    websaveChecked(path_antex_XX, ['https://files.igs.org/pub/station/general/' file_atx_XX], woptions);
                catch
                    errordlg({'Download of ANTEX file failed:', file_atx_XX}, 'Error');
                end
            end
            path_antex = path_antex_XX;
        end

    end
end

