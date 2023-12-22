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
%   ...
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
settings.ORBCLK.file_erp = '';


%% switch source of orbits/clocks
switch settings.ORBCLK.prec_prod
    
    case 'IGS'
        % http://www.igs.org/products
        URL_folders = {['/pub/igs/products/', gpsweek, '/']};
        URL_folders_2 = {['/archive/gnss/products/' gpsweek]};
        
        switch settings.ORBCLK.prec_prod_type
            case 'Final'
                if str2double(gpsweek) >= 2238
                    file = {['IGS0OPSFIN_' yyyy_0 doy_0 '0000_07D_01D_ERP.ERP.gz']};
                else
                    file = {['igs' yyyy(3:4) 'P' gpsweek '.erp.Z']};    % IGS erp file
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
        if settings.ORBCLK.MGEX
            if str2double(gpsweek) >= 2238
                file_erp = ['ESA0MGNFIN_' yyyy_0 doy_0 '0000_07D_01D_ERP.ERP.gz'];
            else
                file_erp = ['esm', gpsweek, dow, '.erp.gz'];
            end
            file = {file_erp};
            % remove the zip file extension
            [~,file{1},~] = fileparts(file{1});
            if ~isfile([target{1}, '/', file{1}])
                [~, ~] = mkdir(target{1});
                websave([target{1}, '/', file_erp] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_erp]);
            end
            % decompress and delete archive
            unzip_and_delete({file_erp}, target(1));
            download = false;   % orbit download is finished
            
        else
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    if str2double(gpsweek) >= 2238
                        file_erp = ['ESA0OPSFIN_' yyyy_0 doy_0 '0000_07D_01D_ERP.ERP.gz'];
                    else
                        file_erp = ['esa', gpsweek, dow, '.erp.Z'];
                    end
                    file = {file_erp};
                    % remove the zip file extension
                    [~,file{1},~] = fileparts(file{1});
                    if ~isfile([target{1}, '/', file{1}])
                        [~, ~] = mkdir(target{1});
                        websave([target{1}, '/', file_erp] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_erp]);
                    end
                    % decompress and delete archive
                    unzip_and_delete({file_erp}, target(1));
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
                        websave([target{1}, '/', file_erp] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_erp]);
                    end
                    % decompress and delete archive
                    unzip_and_delete({file_erp}, target(1));
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
        URL_host = 'ftp.aiub.unibe.ch:21';
        target = {[Path.DATA, 'ERP/', yyyy, '/', doy]};
        if settings.ORBCLK.MGEX
            URL_folders = {['/CODE_MGEX/CODE/' yyyy, '/']};
            if str2double(gpsweek) >= 2238
                file = {['COD0MGXFIN_' yyyy doy '0000_01D_12H_ERP.ERP.gz']};   
            else
                file = {['COM', gpsweek, dow, '.ERP.Z']};
            end
        else
            URL_folders = {['/CODE/' yyyy, '/']};
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    if str2double(gpsweek) >= 2238
                        file = {['COD0OPSFIN_' yyyy doy '0000_01D_01D_ERP.ERP.gz']};
                    else
                        file = {['COD', gpsweek, dow, '.ERP.Z']};
                    end
                    
                case 'Rapid'
                    URL_folders = {'/CODE/'};
                    file = {['COD0OPSRAP_' yyyy doy '0000_01D_01D_ERP.ERP']};
                    bool_archive = false;
                    
                case 'Ultra-Rapid'
                    URL_folders = {'/CODE/'};
                    file = {['COD0OPSULT_' yyyy doy '0000_01D_01D_ERP.ERP']};
                    bool_archive = false;
                    
                otherwise
                    return
            end
        end
        
        
    case 'GFZ'
        % https://www.gfz-potsdam.de/en/section/space-geodetic-techniques/topics/gnss-igs-analysis-center/
        URL_host = 'ftp.gfz-potsdam.de:21';     % very different structure and naming to cddis 
        if settings.ORBCLK.MGEX
            switch settings.ORBCLK.prec_prod_type
                case 'Final'

                    URL_folders = {['/pub/GNSS/products/mgex/' gpsweek, '/']};
                    file = {['gbm', gpsweek, dow, '.erp.Z']};
                    
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
                    % last time checked, GFZ did not change to long
                    % filenames (10 Jan 2023)
                    URL_folders = {['/pub/GNSS/products/final/w' gpsweek, '/']};
                    file = {['gfz', gpsweek, dow, '.erp.Z']};
                    
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
            % takes forever...
            URL_host = 'igs.gnsswhu.cn:21';
            URL_folders{1} = ['/pub/whu/phasebias/' yyyy, '/orbit/'];
            if str2double(gpsweek) > 2230
                URL_folders_2 = {['/archive/gnss/products/' gpsweek]};
            else
                URL_folders_2 = {['/archive/gnss/products/mgex/' gpsweek]};
            end
            file{1}    = ['WUM0MGXRAP_' yyyy doy '0000_01D_01D_ERP.ERP.gz'];
            files_2{1} = ['WUM0MGXFIN_' yyyy doy '0000_01D_01D_ERP.ERP.gz'];
            
        else
            fprintf(2, 'WUM ERP file is not implemented!')
            return
        end
        
    otherwise
       return
        
end



%% download and unzip files, if necessary
i = 1;
if isempty(files_2); files_2 = file; end
while download   &&   i <= length(file)
    file_status = 0;
    % create target folder
    [~, ~] = mkdir(target{i});
    try     %#ok<TRYNC>                             % try to download from igs.ign.fr
        [file_status] = ftp_download(URL_host, URL_folders{i}, file{i}, target{i}, true);
        if ~bool_archive       % pretend archive, otherwise the following code does not work 
            file{i} = [file{i} '.gz'];
        end
    end
    if bool_archive   &&   (file_status == 1 || file_status == 2)
        unzip_and_delete(file(i), target(i));
    end
    if file_status == 0 && ~isempty(URL_folders_2) 	% try to download from CDDIS
        file = files_2{i};    target = target{i};
        file_status = get_cddis_data(URL_host_2, URL_folders_2, {file}, {target}, true);
        if bool_archive   &&   (file_status == 1   ||   file_status == 2)
            unzip_and_delete(files_2(i), target(i));
        end
    end
    % other download sources can be added here
    if file_status == 0
        errordlg({['Downloading ' settings.ORBCLK.prec_prod ' ERP file failed.']}, 'Error');
        return
    end
    [~,file{i},~] = fileparts(file{i});   % remove the zip file extension
    i = i + 1;
end


%% save file-path into settings
settings.ORBCLK.file_erp = [target{1} '/' file{1}];       % save path to EOPs (erp)

