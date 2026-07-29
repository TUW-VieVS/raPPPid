function [settings] = DownloadERP(settings, gpsweek, dow, yyyy, mm, doy)
% This function dowloads the *.erp-file from an IGS or Analysis Center 
% server. If the file contains data for multiple days (e.g., 07D) raPPPid 
% stores the *.erp file into ERP/yyyy/. Daily *.erp files are stored into 
%  ERP/yyyy/doy/.
%
% INPUT:
%	settings        struct, settings from GUI
%   gpsweek         string, GPS Week
%   dow             string, 1-digit, day of week
%   yyyy            string, 4-digit, year
%   mm              string, 2-digit, month
%   doy             string, 3-digit, day of yearbool_archive
% OUTPUT:
%	settings        updated
%
% Revision:
%   2024/12/10, MFWG: decompressed file name from function unzip_and_delete
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
% define target folders
target = {[Path.DATA, 'ERP/', yyyy]};       % for 7 day long files

URL_host = 'igs.ign.fr:21';                 % default ftp-server                                     
URL_host_2 = 'https://cddis.nasa.gov';      % option 2: CDDIS
URL_folders_2 = '';  files_2 = ''; 

download = true;        % boolean variable if products need still to be downloaded
bool_archive = true;  	% true, if archives are downloaded

% determine year/doy for the first day of the current gps week
jd = gps2jd_GT(str2double(gpsweek), 1);
[doy_0, yyyy_0] = jd2doy_GT(jd);
yyyy_0    = sprintf('%04d',yyyy_0);
doy_0 	= sprintf('%03d', floor(doy_0));

% initialize output
settings.ORBCLK.file_erp = '';  decompressed = {''};


%% switch source of orbits/clocks
switch settings.ORBCLK.prec_prod

    case 'IGS'
        % http://www.igs.org/products
        URL_folders = {['/pub/igs/products/', gpsweek, '/']};
        URL_folders_2 = {['/archive/gnss/products/' gpsweek]};

        switch settings.ORBCLK.prec_prod_type
            case 'Final'
                if ~settings.ORBCLK.MGEX
                    if str2double(gpsweek) >= 2238
                        file = {['IGS0OPSFIN_' yyyy_0 doy_0 '0000_07D_01D_ERP.ERP.gz']};
                    else
                        file = {['igs' yyyy(3:4) 'P' gpsweek '.erp.Z']};    % IGS erp file
                    end
                else
                    % ||| not implemented yet
                    % % not available yet?! CHANGE FILENAME!
                    % file = {['IGS0DEMFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
                    %
                    % URL_host = 'https://cddis.nasa.gov';
                    % URL_folder = {['/archive/gnss/products/' gpsweek '/']};
                    % % create folder and prepare the download
                    % target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
                    % [~, ~] = mkdir(target);
                    % % download
                    % file_status = get_cddis_data(URL_host, URL_folder, file, {target}, false);
                    % if file_status == 0
                    %     errordlg('No IGS MGEX ERPs found on server.', 'Error');
                    % end
                    % % decompress
                    % decompressed = unzip_and_delete(file, {target});
                    % % save path to EOPs (erp)
                    % settings.ORBCLK.file_erp = decompressed{1};
                    % return
                    errordlg('IGS Final MGEX ERP file is not implemented!', 'Error');
                    return
                end

            case 'Rapid'
                if str2double(gpsweek) >= 2238
                    file = {['IGS0OPSRAP_' yyyy doy '0000_01D_01D_ERP.ERP.gz']};
                else
                    file = {['igr', gpsweek, dow, '.', 'erp', '.Z']};     	% IGS rapid erp
                end
                target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
                
            case 'Ultra-Rapid'
                % ||| implement at some point
                fprintf(2, 'IGS ultra-rapid ERP file is not implemented!')
                return
                
            otherwise
                return
        end
        
        
    case 'ESA'
        % http://navigation-office.esa.int/GNSS_based_products.html
        % unlike IGS, ESA publishes a daily (not 7-day) ERP file
        if settings.ORBCLK.MGEX
            target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
            if str2double(gpsweek) >= 2238
                file_erp = ['ESA0MGNFIN_' yyyy doy '0000_01D_01D_ERP.ERP.gz'];
            else
                file_erp = ['esm', gpsweek, dow, '.erp.gz'];
            end
            file = {file_erp};
            % remove the zip file extension
            [~,file{1},~] = fileparts(file{1});
            if ~isfile([target{1}, '/', file{1}])
                [~, ~] = mkdir(target{1});
                try
                    websave([target{1}, '/', file_erp] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_erp]);
                catch
                    errordlg({'Download of ESA MGEX ERP file failed:', file_erp}, 'Error');
                    return
                end
            end
            % decompress and delete archive
            decompressed = unzip_and_delete({file_erp}, target(1));
            download = false;   % orbit download is finished

        else
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
                    if str2double(gpsweek) >= 2238
                        file_erp = ['ESA0OPSFIN_' yyyy doy '0000_01D_01D_ERP.ERP.gz'];
                    else
                        file_erp = ['esa', gpsweek, dow, '.erp.Z'];
                    end
                    file = {file_erp};
                    % remove the zip file extension
                    [~,file{1},~] = fileparts(file{1});
                    if ~isfile([target{1}, '/', file{1}])
                        [~, ~] = mkdir(target{1});
                        try
                            websave([target{1}, '/', file_erp] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_erp]);
                        catch
                            errordlg({'Download of ESA ERP file failed:', file_erp}, 'Error');
                            return
                        end
                    end
                    % decompress and delete archive
                    decompressed = unzip_and_delete({file_erp}, target(1));
                    download = false;   % orbit download is finished

                case 'Rapid'
                    target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
                    if str2double(gpsweek) >= 2238
                        file_erp = ['ESA0OPSRAP_' yyyy doy '0000_01D_01D_ERP.ERP.gz'];
                    else
                        file_erp = ['esr', gpsweek, dow, '.erp.Z'];
                    end
                    file = {file_erp};
                    % remove the zip file extension
                    [~,file{1},~] = fileparts(file{1});
                    if ~isfile([target{1}, '/', file{1}])
                        [~, ~] = mkdir(target{1});
                        try
                            websave([target{1}, '/', file_erp] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_erp]);
                        catch
                            errordlg({'Download of ESA ERP file failed:', file_erp}, 'Error');
                            return
                        end
                    end
                    % decompress and delete archive
                    decompressed = unzip_and_delete({file_erp}, target(1));
                    download = false;   % orbit download is finished

                case 'Ultra-Rapid'
                    % ||| implement at some point
                    fprintf(2, 'ESA ultra-rapid ERP file is not implemented!')
                    return
                    
                otherwise
                    return
            end
        end    
        
        
    case 'CNES'
        % https://igsac-cnes.cls.fr/html/products.html
        if settings.ORBCLK.MGEX
            URL_folders = {['/pub/igs/products/mgex/' gpsweek, '/']};
            if str2double(gpsweek) > 2230 
                URL_folders_2 = {['/archive/gnss/products/' gpsweek]};
            else
                URL_folders_2 = {['/archive/gnss/products/mgex/' gpsweek]};
            end
            if str2double(gpsweek) > 2141       % orbit interval changed after week 2141
                file = {['GRG0MGXFIN_', yyyy_0, doy_0, '0000', '_07D_01D_ERP.ERP.gz']};
            elseif str2double(gpsweek) > 2024 	% naming changed after week 2025
                file = {['GRG0MGXFIN_', yyyy_0, doy_0, '0000', '_07D_01D_ERP.ERP.gz']};
            else
                file = {['grm', gpsweek, dow, '.erp.Z']};
            end
        else
            URL_folders = {['/pub/igs/products/', gpsweek, '/']};
            URL_folders_2 = {['/archive/gnss/products/' gpsweek]};
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    if str2double(gpsweek) >= 2238
                        file = {['GRG0OPSFIN_' yyyy_0 doy_0 '0000_07D_01D_ERP.ERP.gz']};
                    else
                        file = {['grg', gpsweek, dow, '.erp.Z']};
                    end
                    
                case 'Rapid'
                    % ||| implement at some point
                    fprintf(2, 'CNES rapid ERP file is not implemented!')
                    return
                    
                case 'Ultra-Rapid'
                    % ||| implement at some point
                    fprintf(2, 'CNES ultra-rapid ERP file is not implemented!')
                    return
                    
                otherwise
                    return
            end
        end
        
    case 'CODE'
        % no nice overview and no storage for (ultra) rapid products
        host = 'http://www.aiub.unibe.ch/download/';
        target = {[Path.DATA, 'ERP/', yyyy, '/', doy '/']};
        [~, ~] = mkdir(target{1});
        if settings.ORBCLK.MGEX
            URL_folders = {['/CODE_MGEX/CODE/' yyyy, '/']};
            if str2double(gpsweek) >= 2238
                file = {['COD0MGXFIN_' yyyy doy '0000_01D_12H_ERP.ERP.gz']};   
                decomp = {['COD0MGXFIN_' yyyy doy '0000_01D_12H_ERP.ERP']};   
            else
                file = {['COM', gpsweek, dow, '.ERP.Z']};
                decomp = {['COM', gpsweek, dow, '.ERP']};
            end
        else
            URL_folders = {['/CODE/' yyyy, '/']};
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    if str2double(gpsweek) >= 2238
                        file = {['COD0OPSFIN_' yyyy doy '0000_01D_01D_ERP.ERP.gz']};
                        decomp = {['COD0OPSFIN_' yyyy doy '0000_01D_01D_ERP.ERP']};
                    else
                        file = {['COD', gpsweek, dow, '.ERP.Z']};
                        decomp = {['COD', gpsweek, dow, '.ERP']};
                    end
                    
                case 'Rapid'
                    URL_folders = {'/CODE/'};
                    file = {['COD0OPSRAP_' yyyy doy '0000_01D_01D_ERP.ERP']};
                    decomp = {['COD0OPSRAP_' yyyy doy '0000_01D_01D_ERP.ERP']};
                    bool_archive = false;
                    % additional source: CDDIS mirrors this (gzipped) even
                    % when CODE's own site doesn't have it anymore
                    file_cddis = {['COD0OPSRAP_' yyyy doy '0000_01D_01D_ERP.ERP.gz']};

                case 'Ultra-Rapid'
                    URL_folders = {'/CODE/'};
                    file = {['COD0OPSULT_' yyyy doy '0000_01D_01D_ERP.ERP']};
                    decomp = {['COD0OPSULT_' yyyy doy '0000_01D_01D_ERP.ERP']};
                    bool_archive = false;
                    % additional source: CDDIS mirrors this (gzipped, "02D"
                    % span - unlike CODE's own "01D"-labelled file) even
                    % when CODE's own site doesn't have it anymore
                    file_cddis = {['COD0OPSULT_' yyyy doy '0000_02D_01D_ERP.ERP.gz']};

                otherwise
                    return
            end
        end

        % download
        decompressed_cddis = {};
        if ~(isfile([target{1} file{1}]) || isfile(decomp{1}))
            downloaded = false;
            try
                websave([target{1} file{1}], [host URL_folders{1} file{1}]);
                downloaded = true;
            catch
                % websave can leave a 0-byte file behind even on failure;
                % delete it so it doesn't fool the CDDIS fallback's
                % already-exists check below
                if isfile([target{1} file{1}]); delete([target{1} file{1}]); end
            end
            if ~downloaded && exist('file_cddis', 'var')
                fs = get_cddis_data('https://cddis.nasa.gov', {['/archive/gnss/products/' gpsweek '/']}, file_cddis, target, true);
                if fs(1) == 1 || fs(1) == 2
                    % already decompressed here - do not run unzip_and_delete
                    % again below on what is now a plain (non-archive) file
                    decompressed_cddis = unzip_and_delete(file_cddis, target);
                    downloaded = true;
                end
            end
            if ~downloaded
                errordlg('No CODE ERPs found on server!', 'Error');
            end
        end
        download = false;
        % decompress
        if isempty(decompressed_cddis)
            decompressed = unzip_and_delete(file(1), target(1));
        else
            decompressed = decompressed_cddis;
        end
        
    case 'GFZ'
        % https://www.gfz-potsdam.de/en/section/space-geodetic-techniques/topics/gnss-igs-analysis-center/
        URL_host = 'ftp.gfz-potsdam.de:21';     % very different structure and naming to cddis 
        if settings.ORBCLK.MGEX
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    % GFZ does not provide a final MGEX product (only
                    % rapid); /pub/GNSS/products/mgex/w<week> no longer
                    % exists on the server
                    errordlg('GFZ does not provide a final MGEX ERP product. Please use Rapid instead!', 'Error');
                    return

                case 'Rapid'
                    % ftp adress without 'pub' does only work in the browser
                    if str2double(gpsweek) > 2245
                        URL_folders = {['/pub/GNSS/products/mgex/' gpsweek '_IGS20' '/']};
                    else
                        URL_folders = {['/pub/GNSS/products/mgex/' gpsweek '/']};
                    end
                    if str2double(gpsweek) > 2230
                        URL_folders_2 = {['/archive/gnss/products/' gpsweek]};
                    else
                        URL_folders_2 = {['/archive/gnss/products/mgex/' gpsweek]};
                    end
                    if str2double(gpsweek) > 2081
                        file = {...    % follows http://mgex.igs.org/IGS_MGEX_Metadata.php
                            ['GBM0MGXRAP_', yyyy, doy, '0000_01D_01D_ERP.ERP.gz']}; 	
                        files_2 = {...    % follows http://mgex.igs.org/IGS_MGEX_Metadata.php
                            ['GFZ0MGXRAP_', yyyy, doy, '0000_01D_01D_ERP.ERP.gz']}; 
                    elseif str2double(gpsweek) > 1782 
                        file = {['gbm', gpsweek, dow, '.erp.Z']};
                    else
                        file = {['gfm', gpsweek, dow, '.erp.Z']};
                    end
                    target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
                    
                case 'Ultra-Rapid'
                    % ||| implement at some point
                    fprintf(2, 'GFZ ultra-rapid ERP file is not implemented!')
                    return
                    
                otherwise
                    return
            end
            
        else
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    URL_folders = {['/pub/GNSS/products/final/w' gpsweek, '/']};
                    file = {['GFZ0OPSFIN_' yyyy doy '0000_07D_01D_ERP.ERP.gz']};
                    target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};

                case 'Rapid'
                    fprintf(2, 'GFZ rapid ERP file is not implemented!')
                    return
                
                case 'Ultra-Rapid'
                    fprintf(2, 'GFZ ultra-rapid ERP file is not implemented!')
                    return
                    
                otherwise
                    return
            end
        end
        
    case 'JGX'
        URL_folders = {['/pub/igs/products/', gpsweek, '/']};
        URL_folders_2 = {['/archive/gnss/products/' gpsweek]};
        switch settings.ORBCLK.prec_prod_type
            case 'Final'
                file = {['JGX0OPSFIN_' yyyy_0 doy_0 '0000_07D_01D_CLK.CLK.gz']};
                
            case 'Rapid'
                target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
                file = {['JGX0OPSRAP_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};
                
            otherwise
                return
        end
        
    case 'WUM'
        if settings.ORBCLK.MGEX
            switch settings.ORBCLK.prec_prod_type
                case 'Rapid'
                    URL_host = 'igs.gnsswhu.cn:21'; % takes forever...
                    URL_folders = {['/pub/whu/phasebias/' yyyy, '/orbit/']};
                    file{1}    = ['WUM0MGXRAP_' yyyy doy '0000_01D_01D_ERP.ERP.gz'];
                case 'Final'
                    URL_folders = {['/pub/igs/products/mgex/', gpsweek, '/']};
                    file{1} = ['WUM0MGXFIN_' yyyy doy '0000_01D_01D_ERP.ERP.gz'];

                otherwise
                    fprintf(2, 'WUM ERP file is not implemented for this product type!')
                    return
            end
            if str2double(gpsweek) > 2230
                URL_folders_2 = {['/archive/gnss/products/' gpsweek]};
            else
                URL_folders_2 = {['/archive/gnss/products/mgex/' gpsweek]};
            end
            % try ftps://bdspride.com
            target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
            [~, ~] = mkdir(target{1});
            URL_host_1 = 'ftps://bdspride.com/';
            URL_folders_1 = ['wum/' gpsweek '/'];
            file_status = CurlDownload([target{1} '/' file{1}], [URL_host_1 URL_folders_1 file{1}], false);
            if file_status
                decompressed = unzip_and_delete(file(1), target(1));
                download = false;
            end
        else
            fprintf(2, 'WUM ERP file is not implemented!')
            return
        end
        
    case 'HUST'
        if settings.ORBCLK.MGEX
            URL_host = 'ggda.ac.cn:21';
            URL_folders = {['/pub/mgex/products/' yyyy '/']};
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    file    = {['HUS0MGXFIN_' yyyy doy '0000_01D_01D_ERP.ERP.gz']};
                case 'Rapid'
                    file    = {['HUS0MGXRAP_' yyyy doy '0000_01D_01D_ERP.ERP.gz']};
                case 'Ultra-Rapid'
                    file    = {['HUS0MGXULT_' yyyy doy '0000_01D_01D_ERP.ERP.gz']};
            end
        else
            fprintf(2, 'HUST ERP file is not implemented!')
            return
        end


    case 'WCC'
        URL_host_1 = 'ftps://bdspride.com/';
        URL_folders_1 = ['wcc/' gpsweek '/'];
        file{1} = ['WCC0OPSFIN_' yyyy doy '0000_01D_01D_ERP.ERP.gz'];
        % download
        target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
        [~, ~] = mkdir(target{1});
        file_status = CurlDownload([target{1} '/' file{1}], [URL_host_1 URL_folders_1 file{1}], true);
        % decompress
        if file_status
            decompressed = unzip_and_delete(file(1), target(1));
        end
        % check if file exists 
        if ~isfile(decompressed{1})
            errordlg({['Downloading ' settings.ORBCLK.prec_prod ' ERP file failed.'] 'Polar Tides correction is not applied.'}, 'Error');
        end
        % save filepath for read-in
        settings.ORBCLK.file_erp = decompressed{1};
        return
        
    otherwise
       return
        
end



%% download and unzip files, if necessary
if isempty(files_2); files_2 = file; end
if download
    file_status = 0;
    % create target folder
    [~, ~] = mkdir(target{1});
    try     %#ok<TRYNC>                             % try to download (e.g., igs.ign.fr)
        [file_status] = ftp_download(URL_host, URL_folders{1}, file{1}, target{1}, true);
        if ~bool_archive       % pretend archive, otherwise the following code does not work 
            file{1} = [file{1} '.gz'];
        end
    end
    if file_status == 0 && ~isempty(URL_folders_2) 	% try alternative download (e.g., CDDIS)
        file_status = get_cddis_data(URL_host_2, URL_folders_2, files_2(1), target(1), true);
        if file_status == 1 || file_status == 2
            file = files_2;
        end
    end
    % other download sources can be added here
    if file_status == 0
        errordlg({['Downloading ' settings.ORBCLK.prec_prod ' ERP file failed.'] 'Polar Tides correction is not applied.'}, 'Error');
        settings.ORBCLK.file_erp = '';
        return
    end
    if bool_archive
        decompressed = unzip_and_delete(file(1), target(1));
    end
end


%% save file-path into settings
settings.ORBCLK.file_erp = decompressed{1};       % save path to EOPs (erp)

