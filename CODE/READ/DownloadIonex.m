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
%   2024/12/02, MFWG: CAS download, https://data.bdsmart.cn/pub/ [IGS-RTWG-359] 
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
                file   = {['IGS0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
                file_2 = {['igsg' doy '0.' yyyy(3:4) 'i.Z']};
            case 'rapid'
                file   = {['IGS0OPSRAP_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
                file_2 = {['igrg' doy '0.' yyyy(3:4) 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file   = {['IGS0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
                file_2 = {['igsg' doy '0.' yyyy(3:4) 'i.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0     % download from GSSC ESA failed, try IGS IGN
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 0     % try GSSC ESA with old filename
            file_status = ftp_download(URL_host, URL_folder{1}, file_2{1}, target{1}, false);
            if file_status ~= 0; file = file_2; end
        end
        if file_status == 0     % try IGS IGN with old filename
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file_2{1}, target{1}, true);
            if file_status ~= 0; file = file_2; end
        end
        if file_status == 0     % last resort: try CDDIS mirror
            [file_status, matched] = try_cddis_ionex(file, target, yyyy, doy, true);
            if file_status ~= 0; file = matched; end
        end
        % decompress if download was successful or file is existing
        if file_status == 1 || file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        
    case 'CODE'
        switch settings.IONO.type_ionex
            case 'final'
                host = 'http://www.aiub.unibe.ch/download/';
                URL_folder = {['/CODE/' yyyy, '/']};
                if str2double(gpsweek) >= 2238
                    file = {['COD0OPSFIN_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
                    decomp = {['COD0OPSFIN_' yyyy doy '0000_01D_01H_GIM.INX']};
                else
                    file = {['CODG' doy '0.' yyyy(3:4) 'I.Z']};
                    decomp = {['CODG' doy '0.' yyyy(3:4) 'I']};
                end
                file_cddis = {['COD0OPSFIN_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
            case 'rapid'
                URL_host = 'igs.ign.fr:21';
                URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
                file = {['corg' doy '0.' yyyy(3:4) 'i.Z']};
                decomp = {['corg' doy '0.' yyyy(3:4) 'i']};
                file_cddis = {['COD0OPSRAP_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                host = 'http://www.aiub.unibe.ch/download/';
                URL_folder = {['/CODE/' yyyy, '/']};
                file = {['CODG' doy '0.' yyyy(3:4) 'i.Z']};
                decomp = {['CODG' doy '0.' yyyy(3:4) 'i']};
                file_cddis = {['COD0OPSFIN_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
        end
        % download
        % 'rapid' is served over FTP (igs.ign.fr); 'final'/otherwise are
        % served over HTTP (aiub.unibe.ch) - websave with an undefined
        % `host` for 'rapid' used to silently fail every time
        if ~(isfile([target{1} file{1}]) || isfile(decomp{1}))
            if strcmp(settings.IONO.type_ionex, 'rapid')
                file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
            else
                try
                    websave([target{1} file{1}], [host URL_folder{1} file{1}]);
                    file_status = 1;
                catch
                    file_status = 0;
                end
            end
        else
            file_status = 1;
        end
        if file_status == 0     % last resort: try CDDIS mirror
            [file_status, matched] = try_cddis_ionex(file_cddis, target, yyyy, doy, true);
            if file_status ~= 0; file = matched; end
        end
        % unzip
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        % save file-path
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension

    case 'ESA'
        % ESA has changed the file name. file_2 is the older naming, tried 
        % as a fallback if the current naming fails.
        switch settings.IONO.type_ionex
            case 'final'
                file   = {['ESA0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
                file_2 = {['ESA0OPSFIN_' yyyy doy '0000_01D_02H_ION.INX.gz']};
            case 'rapid'
                file   = {['ESA0OPSRAP_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
                file_2 = {['ESA0OPSRAP_' yyyy doy '0000_01D_01H_ION.INX.gz']};
            case 'rapid high-rate'
                % ||| implement, no known filename convention for this product
                errordlg('Ionex-Type "rapid high-rate" is not implemented for ESA!', 'Error');
                return
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file   = {['esag', doy, '0.' yyyy(3:4) 'i.Z']};
                file_2 = file;
        end
        [~, file_dec, ~]   = fileparts(file{1});
        [~, file_2_dec, ~] = fileparts(file_2{1});
        if isfile([target{1} file_2_dec]) && ~isfile([target{1} file_dec])
            file = file_2;      % already downloaded under the older naming
        elseif ~isfile([target{1} file_dec])
            try
                % current naming
                websave([target{1}, '/', file{1}] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file{1}]);
                % decompress and delete archive
                unzip_and_delete(file(1), target(1));
            catch
                try
                    % older naming, used around GPS week 2238 (Nov 2022)
                    websave([target{1}, '/', file_2{1}] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_2{1}]);
                    unzip_and_delete(file_2(1), target(1));
                    file = file_2;
                catch
                    % last resort: try CDDIS mirror
                    [file_status, matched] = try_cddis_ionex([file, file_2], target, yyyy, doy, true);
                    if file_status == 1 || file_status == 2
                        unzip_and_delete(matched, target);
                        file = matched;
                    else
                        errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
                        return
                    end
                end
            end
        end
        % remove the zip file extension
        [~,file{1},~] = fileparts(file{1});
        
    case 'GFZ'
        host = 'https://isdc-data.gfz.de/gnss/products/iono/';
        URL_folder = {['w' gpsweek '/']};
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
        % GFZ's archive can contain the file under a different (underscore-
        % prefixed) name than the archive itself, so both names are checked
        [~, file_dec, ~] = fileparts(file{1});
        file_dec_alt = ['_' file_dec];
        if isfile([target{1} file_dec])
            file{1} = file_dec;
        elseif isfile([target{1} file_dec_alt])
            file{1} = file_dec_alt;
        else
            try
                websave([target{1} file{1}], [host URL_folder{1} file{1}]);
                decompressed = unzip_and_delete(file, target);
                [~, fname, fext] = fileparts(decompressed{1});
                file{1} = [fname fext];
            catch
                % last resort: try CDDIS mirror
                [file_status, matched] = try_cddis_ionex(file, target, yyyy, doy, true);
                if file_status == 1 || file_status == 2
                    decompressed = unzip_and_delete(matched, target);
                    [~, fname, fext] = fileparts(decompressed{1});
                    file{1} = [fname fext];
                else
                    errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
                    file{1} = file_dec;
                end
            end
        end

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
        targeti = target{1};
        % download server according to [IGS-RTWG-359]
        httpserver = ['https://data.bdsmart.cn/pub/product/iono/ionex/' yyyy '/' doy '/'];  
        % IONEX file depending on chosen product type
        switch settings.IONO.type_ionex
            case 'final'
                file = ['CAS0OPSFIN_' yyyy doy, '0000_01D_30M_GIM.INX.gz'];
            case 'rapid'
                file = ['CAS0OPSRAP_' yyyy doy, '0000_01D_30M_GIM.INX.gz'];
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file = ['CAS0OPSFIN_' yyyy doy, '0000_01D_30M_GIM.INX.gz'];
        end
        [~, decompr, ~] = fileparts(file);      % name of decompressed file
        % try to download
        if ~isfile([targeti file]) && ~isfile([targeti decompr])
            try websave([targeti file], [httpserver '/' file]); end
        end
        % unzip if download was successful
        if isfile([targeti file])
            unzip_and_delete({file}, {targeti});
        elseif ~isfile([targeti decompr])
            % last resort: try CDDIS mirror (same filename as CAS's own server)
            [file_status, matched] = try_cddis_ionex({file}, {targeti}, yyyy, doy, true);
            if file_status == 1 || file_status == 2
                unzip_and_delete(matched, {targeti});
            else
                errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
            end
        end
        % save filename as cell
        file = {decompr};
        
    case 'JPL'
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
        URL_host_2 = 'gssc.esa.int:21';
        URL_folder_2 = {['/gnss/products/ionex/', yyyy, '/', doy, '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file   = {['jplg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['JPL0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
            case 'rapid'
                file   = {['jprg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['JPL0OPSRAP_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file   = {['jplg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['JPL0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 0
            file_status = ftp_download(URL_host, URL_folder{1}, file_2{1}, target{1}, false);
            if file_status ~= 0; file = file_2; end
        end
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file_2{1}, target{1}, true);
            if file_status ~= 0; file = file_2; end
        end
        if file_status == 0     % last resort: try CDDIS mirror
            [file_status, matched] = try_cddis_ionex(file_2, target, yyyy, doy, true);
            if file_status ~= 0; file = matched; end
        end
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg(['No Ionex file from ' settings.IONO.file_source ' found on server. Please specify different source!'], 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension

    case 'NRCAN'
        % NRCAN's AC code in the long filename convention is "EMR"
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/ionosphere/', yyyy, '/', doy, '/']};
        URL_host_2 = 'gssc.esa.int:21';
        URL_folder_2 = {['/gnss/products/ionex/', yyyy, '/', doy, '/']};
        switch settings.IONO.type_ionex
            case 'final'
                file   = {['emrg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['EMR0OPSFIN_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file   = {['emrg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['EMR0OPSFIN_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 0
            file_status = ftp_download(URL_host, URL_folder{1}, file_2{1}, target{1}, false);
            if file_status ~= 0; file = file_2; end
        end
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file_2{1}, target{1}, true);
            if file_status ~= 0; file = file_2; end
        end
        if file_status == 0     % last resort: try CDDIS mirror
            [file_status, matched] = try_cddis_ionex(file_2, target, yyyy, doy, true);
            if file_status ~= 0; file = matched; end
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
                file   = {['upcg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['UPC0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
            case 'rapid'
                file   = {['uprg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['UPC0OPSRAP_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
            case 'rapid high-rate'
                file   = {['uhrg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['UPC0OPSRAP_' yyyy doy '0000_01D_01H_GIM.INX.gz']};
%             case 'high-rate 15min'
%                 file = {['uqrg', doy, '0.', yyyy(3:4), 'i.Z']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file   = {['upcg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['UPC0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 0     % last resort: try CDDIS mirror
            [file_status, matched] = try_cddis_ionex(file_2, target, yyyy, doy, true);
            if file_status ~= 0; file = matched; end
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
                file   = {['whug', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['WHU0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
            case 'rapid'
                file   = {['whrg', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['WHU0OPSRAP_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
            otherwise
                errordlg(['Selected Ionex-Type: "' settings.IONO.type_ionex '" not found! "Final" is tried.'], 'Error');
                file   = {['whug', doy, '0.', yyyy(3:4), 'i.Z']};
                file_2 = {['WHU0OPSFIN_' yyyy doy '0000_01D_02H_GIM.INX.gz']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 0     % last resort: try CDDIS mirror
            [file_status, matched] = try_cddis_ionex(file_2, target, yyyy, doy, true);
            if file_status ~= 0; file = matched; end
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
        return

end

% check if decompressed file is really existing
if ~isfile([target{1} '/' file{1}])
    errordlg({'Please select IONEX file manually!', 'Compressed file has not the archive´s name.'}, 'Error');
end

% save downloaded file into settings
settings.IONO.file_ionex = [target{1} '/' file{1}];


function [file_status, matched] = try_cddis_ionex(candidates, target, yyyy, doy, bool_print)
% Last-resort fallback for all IONEX sources: CDDIS mirrors GNSS ionosphere
% products under two different archive paths depending on product/date,
% using the same filenames as the sources' own servers.
host = 'https://cddis.nasa.gov';
folders = {['/archive/gnss/products/ionex/' yyyy '/' doy '/'], ...
           ['/archive/gnss/products/ionosphere/' yyyy '/' doy '/']};
file_status = 0;
matched = {};
for c = 1:numel(candidates)
    for f = 1:numel(folders)
        fs = get_cddis_data(host, folders(f), candidates(c), target, bool_print);
        if fs(1) == 1 || fs(1) == 2
            file_status = fs(1);
            matched = candidates(c);
            return
        end
    end
end


