function [settings] = DownloadIonex(settings, gpsweek, dow, yyyy, mm, doy)
% Download the selected IONEX File.
%
% INPUT:
%	settings        struct, settings from GUI
%   gpsweek         string, GPS Week
%   dow             string, 1-digit, day of week
%   yyyy            string, 4-digit, year
%   mm              string, 2-digit, month
%   doy             string, 3-digit, day of year
% OUTPUT:
%	settings        updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% create folder and prepare the download
target = {[Path.DATA, 'IONO/', yyyy, '/', doy '/']};
[~, ~] = mkdir(target{1});
switch settings.IONO.file_source
    case 'IGS'
        URL_host = 'gssc.esa.int:21';
        URL_folder = {['/gnss/products/ionex/', yyyy, '/', doy, '/']};
        URL_host_2 = 'igs.ign.fr:21';
        URL_folder_2 = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file = {['igsg', doy, '0.', yyyy(3:4), 'i.Z']};
            case 'rapid'
                file = {['igrg', doy, '0.', yyyy(3:4), 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['igsg', doy, '0.', yyyy(3:4), 'i.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0     % download from GSSC ESA failed, try IGS IGN
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
            if file_status == 1   ||   file_status == 2
                unzip_and_delete(file, target);
            elseif file_status == 0
                errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
            end
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        
    case 'CODE'
        switch settings.IONO.type_ionex
            case 'final'
                URL_host = 'ftp.aiub.unibe.ch:21';
                URL_folder = {['/CODE/' yyyy, '/']};
                if str2double(gpsweek) >= 2238
                    file = {['COD0OPSFIN_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
                else
                    file = {['CODG' doy '0.' yyyy(3:4) 'I.Z']};
                end
            case 'rapid'
                URL_host = 'igs.ign.fr:21';
                URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
                file = {['corg' doy '0.' yyyy(3:4) 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['CODG' doy '0.' yyyy(3:4) 'i.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        
    case 'ESA'
        switch settings.IONO.type_ionex
            case 'final'
                file = {['ESA0OPSFIN_' yyyy doy '0000_01D_02H_ION.IOX.gz']};
                file_dec = ['ESA0OPSFIN_' yyyy doy '0000_01D_02H_ION.IOX'];
            case 'rapid'
                file = {['ESA0OPSRAP_' yyyy doy '0000_01D_01H_ION.IOX.gz']};
                file_dec = {['ESA0OPSRAP_' yyyy doy '0000_01D_01H_ION.IOX']};
            case 'rapid high-rate'
                % file = {['ehrg', doy, '0.' yyyy(3:4) 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['esag', doy, '0.' yyyy(3:4) 'i.Z']};
        end
        if ~isfile([target{1} file_dec])
            websave([target{1}, '/', file{1}] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file{1}]);
            % decompress and delete archive
            unzip_and_delete(file(1), target(1));
        end
        % remove the zip file extension
        [~,file{1},~] = fileparts(file{1});
        
    case 'GFZ'
        URL_host = 'isdcftp.gfz-potsdam.de:21';
        URL_folder = {['/gnss/products/iono/w' gpsweek '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file = {['GFZ0OPSFIN_' yyyy doy '0000_01D_02H_ION.IOX.gz']};
            case 'rapid'
                file = {['GFZ0OPSRAP_' yyyy doy '0000_01D_02H_ION.IOX.gz']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['GFZ0OPSFIN_' yyyy doy '0000_01D_02H_ION.IOX.gz']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension

    case 'Regiomontan'              % Ionosphere Model Janina
        file = {['REGR' doy '0.' yyyy(3:4) 'I']};
        folder = Path.TUW_IONO;
        if ~isfile([target{1}, file{1}])
            subfolder = [yyyy '/' gpsweek '/'];
            success = copyfile([folder subfolder  file{1}], [target{1}]);
            if ~success
                errordlg([settings.IONO.file_source ': File could not be copied.'], 'Error');
            end
        end
        
    case 'GIOMO'                    % Ionosphere Model Nina
        file = {['MLMG' doy '0.' yyyy(3:4) 'I']};
        folder = Path.TUW_IONO;
        if ~isfile([target{1}, file{1}])
            subfolder = [yyyy '/' gpsweek '/'];
            success = copyfile([folder subfolder  file{1}], [target{1}]);
            if ~success
                errordlg([settings.IONO.file_source ': File could not be copied.'], 'Error');
            end
        end
        
    case 'GIOMO predicted'          % predicted Ionosphere Model Nina
        file = {['MLMP' doy '0.' yyyy(3:4) 'I']};
        folder = Path.TUW_IONO;
        if ~isfile([target{1}, file{1}])
            subfolder = [yyyy '/' gpsweek '/'];
            success = copyfile([folder subfolder  file{1}], [target{1}]);
            if ~success
                errordlg([settings.IONO.file_source ': File could not be copied.'], 'Error');
            end
        end
        
    case 'CAS'
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
        URL_host_2 = 'gssc.esa.int:21';
        URL_folder_2 = {['/gnss/products/ionex/', yyyy, '/', doy, '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file = {['casg', doy, '0.', yyyy(3:4), 'i.Z']};
            case 'rapid'
                file = {['carg', doy, '0.', yyyy(3:4), 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['casg', doy, '0.', yyyy(3:4), 'i.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        
    case 'JPL'
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
        URL_host_2 = 'gssc.esa.int:21';
        URL_folder_2 = {['/gnss/products/ionex/', yyyy, '/', doy, '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file = {['jplg', doy, '0.', yyyy(3:4), 'i.Z']};
            case 'rapid'
                file = {['jprg', doy, '0.', yyyy(3:4), 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['jplg', doy, '0.', yyyy(3:4), 'i.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        
    case 'NRCAN'
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
        URL_host_2 = 'gssc.esa.int:21';
        URL_folder_2 = {['/gnss/products/ionex/', yyyy, '/', doy, '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file = {['emrg', doy, '0.', yyyy(3:4), 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['jplg', doy, '0.', yyyy(3:4), 'i.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        
    case 'UPC'
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
        URL_host_2 = 'gssc.esa.int:21';
        URL_folder_2 = {['/gnss/products/ionex/', yyyy, '/', doy, '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file = {['upcg', doy, '0.', yyyy(3:4), 'i.Z']};
            case 'rapid'
                file = {['uprg', doy, '0.', yyyy(3:4), 'i.Z']};
            case 'rapid high-rate'
                file = {['uhrg', doy, '0.', yyyy(3:4), 'i.Z']};
%             case 'high-rate 15min'
%                 file = {['uqrg', doy, '0.', yyyy(3:4), 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['upcg', doy, '0.', yyyy(3:4), 'i.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        
    case 'WHU'
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
        URL_host_2 = 'gssc.esa.int:21';
        URL_folder_2 = {['/gnss/products/ionex/', yyyy, '/', doy, '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file = {['whug', doy, '0.', yyyy(3:4), 'i.Z']};
            case 'rapid'
                file = {['whrg', doy, '0.', yyyy(3:4), 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = {['whug', doy, '0.', yyyy(3:4), 'i.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        
    case 'IGS RT GIM'
        file =  {['irtg' doy '0.' yyyy(3:4) 'i']};
        if ~isfile([target{1} file{1}])
            try     % try download only if file is not yet existing
                file_zip = {[file{1} '.Z']};
                webfolder = ['http://chapman.upc.es/irtg/archive/' yyyy '/' doy '/global_vtec_movie_since_last_midnight/ionex_file/'];
                websave([target{1} '/' file_zip{1}] , [webfolder file_zip{1}]);
                unzip_and_delete(file_zip, target);
            catch
                errordlg('Download of IGS Real-Time GIM failed.', 'Error');
            end
        end
    otherwise
        errordlg(['Ionex Source ' settings.IONO.file_source ' not implemented!'], 'Error');
        
end

% check if decompressed file is really existing
if ~isfile([target{1} '/' file{1}])
    errordlg({'Please select IONEX file manually!', 'Compressed file has not the archive´s name.'}, 'Error');
end

% save downloaded file into settings
settings.IONO.file_ionex = [target{1} '/' file{1}];


