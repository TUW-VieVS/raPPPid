function [settings] = DownloadOrbitClock(settings, gpsweek, dow, yyyy, mm, doy)
% This function dowloads the selected orbit and clock files (*.sp3 and
% *.clk) from an IGS or Analysis Center server.
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


%% Preparations
targets = {...
    [Path.DATA, 'ORBIT/', yyyy, '/', doy]
    [Path.DATA, 'CLOCK/', yyyy, '/', doy]};
mkdir(targets{1});
mkdir(targets{2});
URL_host = 'igs.ign.fr:21';                                 % default ftp-server
URL_host_2 = 'https://cddis.nasa.gov'; URL_folders_2 = '';  files_2 = ''; % option 2
download = true;    % boolean variable if products need still to be downloaded
multiple = false;   % is set to true if multiple sp3-files are needed (e.g. ???)



%% switch source of orbits/clocks
switch settings.ORBCLK.prec_prod
    
    case 'IGS'
        % http://www.igs.org/products
        switch settings.ORBCLK.prec_prod_type
            case 'Final'
                URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},2,1);
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                if settings.INPUT.use_GPS && settings.INPUT.use_GLO
                    % ||| implement
                    errordlg('ERROR: IGS final products for GPS+GLO are not implemented!', 'Error');
                elseif settings.INPUT.use_GPS
                    if str2double(gpsweek) >= 2238
                        files = {...
                            ['IGS0OPSFIN_' yyyy doy '0000_01D_15M_ORB.SP3.gz']   
                            ['IGS0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};
                    else
                        files = {...
                            ['igs', gpsweek, dow, '.', 'sp3',     '.Z']     	% IGS precise orbits (gps only)
                            ['igs', gpsweek, dow, '.', 'clk_30s', '.Z']};     	% IGS 30sec clock (gps only)
                    end
                    
                elseif settings.INPUT.use_GLO
                    % ||| check this! somehow not working
                    errordlg('ERROR: IGS final products for GLO are not implemented!', 'Error');
%                     URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},2,1);
%                     % no separate clock file
%                     settings.ORBCLK.bool_clk = false;
%                     files = {['igl', gpsweek, dow, '.', 'sp3',     '.Z']     	% IGS precise orbits+clocks (glo only)
%                         ''};
                end
                
            case 'Rapid'
                URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},2,1);
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                if settings.INPUT.use_GPS && settings.INPUT.use_GLO
                    % ||| implement
                    errordlg('ERROR: IGS Products for GPS+GLO are not implemented!', 'Error');
                elseif settings.INPUT.use_GPS
                    if str2double(gpsweek) >= 2238
                        files = {...
                            ['IGS0OPSRAP_' yyyy doy '0000_01D_15M_ORB.SP3.gz']   
                            ['IGS0OPSRAP_' yyyy doy '0000_01D_05M_CLK.CLK.gz']};
                    else
                        files = {...
                            ['igr', gpsweek, dow, '.', 'sp3', '.Z']     	% IGS rapit orbits (gps only)
                            ['igr', gpsweek, dow, '.', 'clk', '.Z']};     	% IGS rapid clock (gps only)
                    end
                elseif  settings.INPUT.use_GLO
                    % ||| implement
                    errordlg('ERROR: IGS Products for GLONASS are not implemented!', 'Error');
                end
                
            case 'Ultra-Rapid'
                if settings.INPUT.use_GPS
                    if str2double(gpsweek) >= 2238
                        URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},1,1);
                        URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                        files = {['IGS0OPSULT_' yyyy doy '0000_02D_15M_ORB.SP3.gz']};
                    else
                        [gpsweek, dow] = NextDay(gpsweek, dow);
                        targets = targets(1);       % no clk file
                        URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},1,1);
                        URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                        files = {['igu', gpsweek, dow, '_00.', 'sp3',     '.Z']};
                    end
                    
                elseif settings.INPUT.use_GLO
                    % ||| implement, igv
                    errordlg('ERROR: IGS ultra-rapid products for GLONASS are not implemented!', 'Error');
                end
                
            otherwise
                errordlg(['Precise Product Type: ' settings.ORBCLK.prec_prod_type ' is not implemented.'], 'Error');
        end
        
        
    case 'ESA'
        % http://navigation-office.esa.int/GNSS_based_products.html
        if settings.ORBCLK.MGEX
            if str2double(gpsweek) >= 2238
                file_sp3 = ['ESA0MGNFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
                file_clk = ['ESA0MGNFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
            else
                file_sp3 = ['esm', gpsweek, dow, '.sp3.gz'];
                file_clk = ['esm', gpsweek, dow, '.clk.gz'];
            end
            files = {file_sp3, file_clk};
            % remove the zip file extension
            [~,files{1},~] = fileparts(files{1});
            [~,files{2},~] = fileparts(files{2});
            if ~isfile([targets{1}, '/', files{1}])
                websave([targets{1}, '/', file_sp3] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_sp3]);
            end
            if ~isfile([targets{2}, '/', files{2}])
                websave([targets{2}, '/', file_clk] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_clk]);
            end
            % decompress and delete archive
            unzip_and_delete({file_sp3}, targets(1));
            unzip_and_delete({file_clk}, targets(2));
            download = false;   % orbit download is finished
            
        else
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    if str2double(gpsweek) >= 2238
                        file_sp3 = ['ESA0OPSFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
                        file_clk = ['ESA0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
                    else
                        file_sp3 = ['esa', gpsweek, dow, '.sp3.Z'];
                        file_clk = ['esa', gpsweek, dow, '.clk.Z'];
                    end
                    files = {file_sp3, file_clk};
                    % remove the zip file extension
                    [~,files{1},~] = fileparts(files{1});
                    [~,files{2},~] = fileparts(files{2});
                    if ~isfile([targets{1}, '/', files{1}])
                        websave([targets{1}, '/', file_sp3] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_sp3]);
                    end
                    if ~isfile([targets{2}, '/', files{2}])
                        websave([targets{2}, '/', file_clk] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_clk]);
                    end
                    % decompress and delete archive
                    unzip_and_delete({file_sp3}, targets(1));
                    unzip_and_delete({file_clk}, targets(2));
                    download = false;   % orbit download is finished
                    
                case 'Rapid'
                    if str2double(gpsweek) >= 2238
                        file_sp3 = ['ESA0OPSRAP_' yyyy doy '0000_01D_15M_ORB.SP3.gz'];
                        file_clk = ['ESA0OPSRAP_' yyyy doy '0000_01D_05M_CLK.CLK.gz'];
                    else
                        file_sp3 = ['esr', gpsweek, dow, '.sp3.Z'];
                        file_clk = ['esr', gpsweek, dow, '.clk.Z'];
                    end
                    files = {file_sp3, file_clk};
                    % remove the zip file extension
                    [~,files{1},~] = fileparts(files{1});
                    [~,files{2},~] = fileparts(files{2});
                    if ~isfile([targets{1}, '/', files{1}])
                        websave([targets{1}, '/', file_sp3] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_sp3]);
                    end
                    if ~isfile([targets{2}, '/', files{2}])
                        websave([targets{2}, '/', file_clk] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_clk]);
                    end
                    % decompress and delete archive
                    unzip_and_delete({file_sp3}, targets(1));
                    unzip_and_delete({file_clk}, targets(2));
                    download = false;   % orbit download is finished
                    
                case 'Ultra-Rapid'
                    if str2double(gpsweek) >= 2238
                        file_sp3 = ['ESA0OPSULT_' yyyy doy '0000_02D_15M_ORB.SP3.gz'];
                    else
                        [gpsweek, dow] = NextDay(gpsweek, dow);
                        targets = targets(1);       % no clk file
                        file_sp3 = ['esu', gpsweek, dow, '_00.sp3.Z'];
                    end
                    % remove the zip file extension
                    [~,files{1},~] = fileparts(file_sp3);
                    if ~isfile([targets{1}, '/', files{1}])
                        websave([targets{1}, '/', file_sp3] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_sp3]);
                    end
                    % decompress and delete archive
                    unzip_and_delete({file_sp3}, targets(1));
                    download = false;   % orbit download is finished
                    
                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
            end
        end    
        
        
    case 'CNES'
        % https://igsac-cnes.cls.fr/html/products.html
        if settings.ORBCLK.MGEX
            URL_folders = repmat({['/pub/igs/products/mgex/' gpsweek, '/']},2,1);
            if str2double(gpsweek) > 2230 
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
            else
                URL_folders_2 = repmat({['/archive/gnss/products/mgex/' gpsweek]},2,1);
            end
            if str2double(gpsweek) > 2141       % orbit interval changed after week 2141
                files = {...
                    ['GRG0MGXFIN_', yyyy, doy, '0000', '_01D_05M_ORB.SP3.gz']
                    ['GRG0MGXFIN_', yyyy, doy, '0000', '_01D_30S_CLK.CLK.gz']};
            elseif str2double(gpsweek) > 2024 	% naming changed after week 2025
                files = {...
                    ['GRG0MGXFIN_', yyyy, doy, '0000', '_01D_15M_ORB.SP3.gz']
                    ['GRG0MGXFIN_', yyyy, doy, '0000', '_01D_30S_CLK.CLK.gz']};
            else
                files = {...
                    ['grm', gpsweek, dow, '.sp3.Z']            % CNES multi-gnss precise orbits
                    ['grm', gpsweek, dow, '.clk.Z']};          % CNES multi-gnss precise orbits clock
            end
        else
            URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},2,1);
            URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    if str2double(gpsweek) >= 2238
                        files = {...
                            ['GRG0OPSFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz']
                            ['GRG0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};
                    else
                        files = {...
                            ['grg', gpsweek, dow, '.sp3.Z']
                            ['grg', gpsweek, dow, '.clk.Z']};
                    end
                    
                case 'Rapid'
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                
                case 'Ultra-Rapid'
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    
                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
            end
        end
        % Some satellites stay unfixed and have no integer clock therefore:
        % ftp://ftpsedr.cls.fr/pub/igsac/readme_ELIMSAT.txt
        if ~exist([Path.DATA 'CLOCK/' 'GRG_ELIMSAT_all.dat'], 'file')
            ftp_download('ftpsedr.cls.fr:21', '/pub/igsac/', 'GRG_ELIMSAT_all.dat', [Path.DATA 'CLOCK/'], true);
        end
        
    case 'CODE'
        % no nice overview and no storage for (ultra) rapid products
        URL_host = 'ftp.aiub.unibe.ch:21';
       
        if settings.ORBCLK.MGEX
            URL_folders = repmat({['/CODE_MGEX/CODE/' yyyy, '/']},2,1);
            if str2double(gpsweek) >= 2238
                files = {...
                    ['COD0MGXFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz']  
                    ['COD0MGXFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};   
            else
                files = {...
                    ['COM', gpsweek, dow, '.EPH.Z']         % CODE MGEX precise orbits
                    ['COM', gpsweek, dow, '.CLK.Z']};    	% CODE MGEX precise clocks
            end
        else
            URL_folders = repmat({['/CODE/' yyyy, '/']},2,1);
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    if str2double(gpsweek) >= 2238
                        files = {...
                            ['COD0OPSFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz']
                            ['COD0OPSFIN_' yyyy doy '0000_01D_05S_CLK.CLK.gz']};
                    else
                        files = {...
                            ['COD', gpsweek, dow, '.EPH.Z']
                            ['COD', gpsweek, dow, '.CLK.Z']};
                    end
                    
                case 'Rapid'
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                
                case 'Ultra-Rapid'
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    
                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
            end
            
            
        end
        
        
    case 'GFZ'
        % https://www.gfz-potsdam.de/en/section/space-geodetic-techniques/topics/gnss-igs-analysis-center/
        URL_host = 'ftp.gfz-potsdam.de:21';     % very different structure and naming to cddis 
        if settings.ORBCLK.MGEX
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    
                    % ||| check this!!!!!
                    URL_folders = repmat({['/pub/GNSS/products/mgex/' gpsweek, '/']},2,1);
                    files = {...
                        ['gbm', gpsweek, dow, '.sp3.Z']
                        ['gbm', gpsweek, dow, '.clk.Z']};
                    
                case 'Rapid'
                    % ftp adress without 'pub' does only work in the browser
                    URL_folders = repmat({['/pub/GNSS/products/mgex/' gpsweek, '/']},2,1);
                    if str2double(gpsweek) > 2230
                        URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                    else
                        URL_folders_2 = repmat({['/archive/gnss/products/mgex/' gpsweek]},2,1);
                    end
                    if str2double(gpsweek) > 2081
                        files = {...    % follows http://mgex.igs.org/IGS_MGEX_Metadata.php
                            ['GBM0MGXRAP_', yyyy, doy, '0000_01D_05M_ORB.SP3.gz']       % GFZ Multi-GNSS precise orbits
                            ['GBM0MGXRAP_', yyyy, doy, '0000_01D_30S_CLK.CLK.gz']}; 	% GFZ Multi-GNSS precise clocks
                        files_2 = {...    % follows http://mgex.igs.org/IGS_MGEX_Metadata.php
                            ['GFZ0MGXRAP_', yyyy, doy, '0000_01D_05M_ORB.SP3.gz']       % GFZ Multi-GNSS precise orbits
                            ['GFZ0MGXRAP_', yyyy, doy, '0000_01D_30S_CLK.CLK.gz']}; 	% GFZ Multi-GNSS precise clocks
                    elseif str2double(gpsweek) > 1782 
                        files = {...
                            ['gbm', gpsweek, dow, '.sp3.Z']
                            ['gbm', gpsweek, dow, '.clk.Z']};
                    else
                        files = {...
                            ['gfm', gpsweek, dow, '.sp3.Z']
                            ['gfm', gpsweek, dow, '.clk.Z']};
                    end
                    
                case 'Ultra-Rapid'
                    % ||| check this!!!!!
                    % ftp adress without 'pub' does only work in the browser
                    URL_host = 'ftp.gfz-potsdam.de:21';
                    [gpsweek, dow] = NextDay(gpsweek, dow);
                    targets = targets(1);       % no clk file
                    URL_folders = repmat({['/pub/GNSS/products/mgex/' gpsweek, '/']},1,1);
                    files = {['gbu', gpsweek, dow, '_00.', 'sp3', '.Z']};
                    
                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
            end
            
        else
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    % last time checked, GFZ did not change to long
                    % filenames (10 Jan 2023)
                    URL_folders = repmat({['/pub/GNSS/products/final/w' gpsweek, '/']},2,1);
                    files = {...
                        ['gfz', gpsweek, dow, '.sp3.Z']
                        ['gfz', gpsweek, dow, '.clk.Z']};
                    
                case 'Rapid'
                    URL_folders = repmat({['/pub/GNSS/products/rapid/w' gpsweek, '/']},2,1);
                    % ||| same filename as final? therefore not implemented
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                
                case 'Ultra-Rapid'
                    [gpsweek, dow] = NextDay(gpsweek, dow);
                    targets = targets(1);       % no clk file
                    URL_folders = repmat({['/pub/GNSS/products/ultra/w' gpsweek, '/']},1,1);
                    files = {['gfu', gpsweek, dow, '_00.', 'sp3',     '.Z']};
                    
                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
            end
        end


    case 'JAXA'
        if settings.ORBCLK.MGEX
            % MGEX-Products website says that JAXA changed filenaming after
            % gpsweek 1938 but I could not find any orbit products before
            % gpsweek 1946 on the server
            if str2double(gpsweek) < 1946
                errordlg('Precise products from JAXA only available starting from GPS week 1947 (2017-04-23). Please specify different source!', 'Error');
                return
            end
            URL_folders = repmat({['/pub/ips/products/mgex/' gpsweek, '/']},2,1);
            if str2double(gpsweek) > 2230
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
            else
                URL_folders_2 = repmat({['/archive/gnss/products/mgex/' gpsweek]},2,1);
            end
            files = {...
                ['JAX0MGXFIN_', yyyy, doy, '0000_01D_05M_ORB.SP3.gz']
                ['JAX0MGXFIN_', yyyy, doy, '0000_01D_30S_CLK.CLK.gz']};
        else
            errordlg(['Precise Product Type: ' settings.ORBCLK.prec_prod_type ' is not implemented.'], 'Error');
        end
        
    case 'SHAO'
        if settings.ORBCLK.MGEX
            if str2double(gpsweek) < 1959
                errordlg('Precise products from SHAO only available starting from GPS week 1959 (2017-07-23). Please specify different source!', 'Error');
                return
            end
            URL_folders = repmat({['/pub/ips/products/mgex/' gpsweek, '/']},2,1);
            if str2double(gpsweek) > 2230
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
            else
                URL_folders_2 = repmat({['/archive/gnss/products/mgex/' gpsweek]},2,1);
            end
            files = {...
                ['SHA0MGXRAP_', yyyy, doy, '0000', '_01D_15M_ORB.SP3.gz'] 	% orbits
                ['SHA0MGXRAP_', yyyy, doy, '0000', '_01D_05M_CLK.CLK.gz']};   	% clocks
        else
            errordlg(['Precise Product Type: ' settings.ORBCLK.prec_prod_type ' is not implemented.'], 'Error');
        end
        
    case 'TUM'
        if settings.ORBCLK.MGEX
            % tum has no clk-file, only sp3 (?!)
            URL_folders = repmat({['/pub/igs/products/mgex/' gpsweek, '/']},1,1);
            if str2double(gpsweek) > 2230
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
            else
                URL_folders_2 = repmat({['/archive/gnss/products/mgex/' gpsweek]},2,1);
            end
            files = {['SHA0MGXRAP_', yyyy, doy, '0000', '_01D_15M_ORB.SP3.gz']}; 	% orbits
        else
            errordlg(['Precise Product Type: ' settings.ORBCLK.prec_prod_type ' is not implemented.'], 'Error');
        end
        
    case 'WUM'
        if settings.ORBCLK.MGEX
            % takes forever...
            URL_host = 'igs.gnsswhu.cn:21';
            URL_folders{1} = ['/pub/whu/phasebias/' yyyy, '/orbit/'];
            URL_folders{2} = ['/pub/whu/phasebias/' yyyy, '/clock/'];
            if str2double(gpsweek) > 2230
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
            else
                URL_folders_2 = repmat({['/archive/gnss/products/mgex/' gpsweek]},2,1);
            end
            files{1} = ['WUM0MGXRAP_' yyyy doy '0000_01D_01M_ORB.SP3.gz'];
            files{2} = ['WUM0MGXRAP_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
            files_2{1} = ['WUM0MGXFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
            files_2{2} = ['WUM0MGXFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
%             URL_folders = repmat({['/pub/igs/products/mgex/' gpsweek, '/']},2,1);
%             if str2double(gpsweek) > 1961 	% naming of products changed after week 1961
%                 files = {...
%                     ['WUM0MGXFIN_', yyyy, doy, '0000', '_01D_15M_ORB.SP3.gz']       % Wuhan Multi-GNSS precise orbits
%                     ['WUM0MGXFIN_', yyyy, doy, '0000', '_01D_30S_CLK.CLK.gz']}; 	% Wuhan Multi-GNSS precise clocks
%             else
%                 files = {['wum', gpsweek, dow, '.sp3.Z']        % Wuhan Multi-GNSS precise orbits
%                     ['wum', gpsweek, dow, '.clk.Z']};           % Wuhan Multi-GNSS precise clocks
%             end
        else
            errordlg(['Precise Product Type: ' settings.ORBCLK.prec_prod_type ' is not implemented.'], 'Error');
        end
        
    otherwise
        errordlg(['Precise products from ' settings.ORBCLK.prec_prod ' are not implemented. Please specify different source!'], 'Error');
        
end



%% download and unzip files, if necessary
i = 1;
if isempty(files_2); files_2 = files; end
while download   &&   i <= length(files)
    file_status = 0;
    try     %#ok<TRYNC>                             % try to download from igs.ign.fr
        [file_status] = ftp_download(URL_host, URL_folders{i}, files{i}, targets{i}, true);
    end
    if file_status == 1   ||   file_status == 2
        unzip_and_delete(files(i), targets(i));
    end
    if file_status == 0 && ~isempty(URL_folders_2) 	% try to download from CDDIS
        file = files_2{i};    target = targets{i};
        file_status = get_cddis_data(URL_host_2, URL_folders_2, {file}, {target}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(files_2(i), targets(i));
        end
    end
    % other download sources can be added here
    if file_status == 0
        errordlg({['Downloading ' settings.ORBCLK.prec_prod ' satellite orbits+clocks failed.']; 'Please try different source!'}, 'Error');
        return
    end
    [~,files{i},~] = fileparts(files{i});   % remove the zip file extension
    i = i + 1;
end


%% combine multiple sp3-files to one
if multiple     % put downloaded files to one file for the whole day together
    % ||| check if this necessary at some point
    curr_dir = pwd;
    cd(targets{1})
    % create name for new file
    [~, fil, ext]  = fileparts(files{1});
    newfile = [fil(1:8) ext];
    % put files together
    command_str = 'copy ';
    for i = 1:numel(files)
        command_str = [command_str files{i} '+']; 
    end
    command_str(end) = '';      % remove last "+"
    command_str = [command_str ' ' newfile];
    system(command_str);
    system(['copy ' files{1} '+' files{2} '+' files{3} '+' files{4} newfile])
    cd(curr_dir)
    % ||| needs further implementation (e.g. multiple headers in new file,
    % possible "EOF"s, read-in of sp3)
end


%% save file-path into settings
settings.ORBCLK.file_sp3 = [targets{1} '/' files{1}];
if numel(files) > 1
    settings.ORBCLK.file_clk = [targets{2} '/' files{2}];
else
    settings.ORBCLK.file_clk = '';
    settings.ORBCLK.bool_clk = false;
end





function [gpsweek, dow] = NextDay(gpsweek, dow)
% Ultra-rapid files contain 48 hours of data. Therefore take ultra-rapid 
% file of next day at 0h (no predicted orbit are processed). BUT his file 
% is saved into the day-folder of the Rinex file (although the file name of 
% the next day!)
ur_week = sscanf(gpsweek, '%f');
ur_dow = sscanf(dow, '%f');
ur_dow = ur_dow + 1;
if ur_dow == 7      % check week roll over
    ur_dow = 0;
    ur_week = ur_week + 1;
end
gpsweek = sprintf('%04d',ur_week);
dow     = sprintf('%01d',ur_dow);