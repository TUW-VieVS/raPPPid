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
% define target folders
targets = {...
    [Path.DATA, 'ORBIT/', yyyy, '/', doy '/']
    [Path.DATA, 'CLOCK/', yyyy, '/', doy '/']};

IGN_host = 'igs.ign.fr:21';                 % default ftp-server                                     
CDDIS_host = 'https://cddis.nasa.gov';      % option 2: CDDIS
URL_folders_2 = {};  files_2 = '';

download = true;        % boolean variable if products need still to be downloaded
multiple = false;       % is set to true if multiple sp3-files are needed (e.g. ???)
bool_archive = true;  	% true, if archives are downloaded


%% switch source of orbits/clocks
switch settings.ORBCLK.prec_prod
    
    case 'IGS'      % International GNSS Service (combination products)
        % http://www.igs.org/products
        switch settings.ORBCLK.prec_prod_type
            case 'Final'
                if ~settings.ORBCLK.MGEX
                    % "classic" IGS final combination (GPS only)
                    URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},2,1);
                    URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                    if str2double(gpsweek) >= 2238
                        files = {...
                            ['IGS0OPSFIN_' yyyy doy '0000_01D_15M_ORB.SP3.gz']
                            ['IGS0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};
                    else
                        files = {...
                            ['igs' gpsweek dow '.sp3.Z']                % IGS precise orbits (gps only)
                            ['igs' gpsweek dow '.clk_30s.Z']};          % IGS 30sec clock (gps only)
                    end

                elseif settings.ORBCLK.MGEX
                    % IGS combined demonstration multi-GNSS final combinations [IGSMAIL-8682]
                    IGN_host = 'https://cddis.nasa.gov';
                    URL_folders = {['/archive/gnss/products/' gpsweek] 
                        ['/archive/gnss/products/' gpsweek]};
                    files = {...
                        ['IGS0DEMFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz']
                        ['IGS0DEMFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};
                    % download
                    [~, ~] = mkdir(targets{1}); [~, ~] = mkdir(targets{2});
                    file_status = get_cddis_data(IGN_host, URL_folders, files, targets, true);
                    % check if the download was successful, otherwise the
                    % decompression below would run on non-existing archives
                    % and file_sp3/file_clk would be set to invalid paths
                    if file_status == 0
                        errordlg({'Download of the IGS MGEX final products failed:', ...
                            files{1}, files{2}}, 'Error');
                        download = false;
                        return
                    end
                    % decompress
                    unzipped = unzip_and_delete(files, targets);
                    % save file paths for read-in
                    settings.ORBCLK.file_sp3 = unzipped{1};
                    settings.ORBCLK.file_clk = unzipped{2};
                    % function is finished
                    download = false;
                    return
                end
                
            case 'Rapid'
                URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},2,1);
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                if settings.INPUT.use_GPS && settings.INPUT.use_GLO
                    % ||| implement
                    errordlg('ERROR: IGS Products for GPS+GLO are not implemented!', 'Error');
                    return
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
                    return
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
                    return
                end

            otherwise
                errordlg(['Precise Product Type: ' settings.ORBCLK.prec_prod_type ' is not implemented.'], 'Error');
                return
        end


    case 'ESA'      % European Space Agency
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
            if ~isfile([targets{1} files{1}])
                [~, ~] = mkdir(targets{1});
                try
                    websave([targets{1} file_sp3] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_sp3]);
                catch
                    errordlg({'Download of ESA MGEX orbit file failed:', file_sp3}, 'Error');
                    return
                end
            end
            if ~isfile([targets{2} files{2}])
                [~, ~] = mkdir(targets{2});
                try
                    websave([targets{2} file_clk] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_clk]);
                catch
                    errordlg({'Download of ESA MGEX clock file failed:', file_clk}, 'Error');
                    return
                end
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
                    if ~isfile([targets{1} files{1}])
                        [~, ~] = mkdir(targets{1});
                        try
                            websave([targets{1} file_sp3] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_sp3]);
                        catch
                            errordlg({'Download of ESA orbit file failed:', file_sp3}, 'Error');
                            return
                        end
                    end
                    if ~isfile([targets{2} files{2}])
                        [~, ~] = mkdir(targets{2});
                        try
                            websave([targets{2} file_clk] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_clk]);
                        catch
                            errordlg({'Download of ESA clock file failed:', file_clk}, 'Error');
                            return
                        end
                    end
                    % decompress and delete archive
                    unzip_and_delete({file_sp3}, targets(1));
                    unzip_and_delete({file_clk}, targets(2));
                    download = false;   % orbit download is finished

                case 'Rapid'
                    if str2double(gpsweek) >= 2238
                        file_sp3 = ['ESA0OPSRAP_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
                        file_clk = ['ESA0OPSRAP_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
                    else
                        file_sp3 = ['esr', gpsweek, dow, '.sp3.Z'];
                        file_clk = ['esr', gpsweek, dow, '.clk.Z'];
                    end
                    files = {file_sp3, file_clk};
                    % remove the zip file extension
                    [~,files{1},~] = fileparts(files{1});
                    [~,files{2},~] = fileparts(files{2});
                    if ~isfile([targets{1} files{1}])
                        [~, ~] = mkdir(targets{1});
                        try
                            websave([targets{1} file_sp3] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_sp3]);
                        catch
                            errordlg({'Download of ESA orbit file failed:', file_sp3}, 'Error');
                            return
                        end
                    end
                    if ~isfile([targets{2} files{2}])
                        [~, ~] = mkdir(targets{2});
                        try
                            websave([targets{2} file_clk] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_clk]);
                        catch
                            errordlg({'Download of ESA clock file failed:', file_clk}, 'Error');
                            return
                        end
                    end
                    % decompress and delete archive
                    unzip_and_delete({file_sp3}, targets(1));
                    unzip_and_delete({file_clk}, targets(2));
                    download = false;   % orbit download is finished

                case 'Ultra-Rapid'
                    if str2double(gpsweek) >= 2238
                        file_sp3 = ['ESA0OPSULT_' yyyy doy '0000_02D_05M_ORB.SP3.gz'];
                    else
                        [gpsweek, dow] = NextDay(gpsweek, dow);
                        targets = targets(1);       % no clk file
                        file_sp3 = ['esu', gpsweek, dow, '_00.sp3.Z'];
                    end
                    % remove the zip file extension
                    [~,files{1},~] = fileparts(file_sp3);
                    if ~isfile([targets{1} files{1}])
                        [~, ~] = mkdir(targets{1});
                        try
                            websave([targets{1} file_sp3] , ['http://navigation-office.esa.int/products/gnss-products/', gpsweek, '/', file_sp3]);
                        catch
                            errordlg({'Download of ESA orbit file failed:', file_sp3}, 'Error');
                            return
                        end
                    end
                    % decompress and delete archive
                    unzip_and_delete({file_sp3}, targets(1));
                    download = false;   % orbit download is finished

                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return
            end
        end


    case 'CNES'     % Centre national d'études spatiales
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
                    return

                case 'Ultra-Rapid'
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return

                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return
            end
        end
        % Some satellites stay unfixed and have no integer clock therefore:
        % ftp://ftpsedr.cls.fr/pub/igsac/readme_ELIMSAT.txt
        if ~exist([Path.DATA 'CLOCK/' 'GRG_ELIMSAT_all.dat'], 'file')
            ftp_download('ftpsedr.cls.fr:21', '/pub/igsac/', 'GRG_ELIMSAT_all.dat', [Path.DATA 'CLOCK/'], true);
        end
        
    case 'CODE'     % Center of Orbit Determination Europe
        % no nice overview and no storage for (ultra) rapid products
        host = 'http://www.aiub.unibe.ch/download/';
       
        if settings.ORBCLK.MGEX
            URL_folders = repmat({['/CODE_MGEX/CODE/' yyyy, '/']},2,1);
            if str2double(gpsweek) >= 2238
                files = {...
                    ['COD0MGXFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz']  
                    ['COD0MGXFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};   
                decomp = {...
                    ['COD0MGXFIN_' yyyy doy '0000_01D_05M_ORB.SP3']  
                    ['COD0MGXFIN_' yyyy doy '0000_01D_30S_CLK.CLK']};                   
            else
                files = {...
                    ['COM', gpsweek, dow, '.EPH.Z']         % CODE MGEX precise orbits
                    ['COM', gpsweek, dow, '.CLK.Z']};    	% CODE MGEX precise clocks
                decomp = {...
                    ['COM', gpsweek, dow, '.EPH']  
                    ['COM', gpsweek, dow, '.CLK']};             
            end
        else
            URL_folders = repmat({['/CODE/' yyyy, '/']},2,1);
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    if str2double(gpsweek) >= 2238
                        files = {...
                            ['COD0OPSFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz']
                            ['COD0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};
                        decomp = {...
                            ['COD0OPSFIN_' yyyy doy '0000_01D_05M_ORB.SP3']
                            ['COD0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK']};                        
                    else
                        files = {...
                            ['COD', gpsweek, dow, '.EPH.Z']
                            ['COD', gpsweek, dow, '.CLK.Z']};
                        decomp = {...
                            ['COD', gpsweek, dow, '.EPH']
                            ['COD', gpsweek, dow, '.CLK']};                        
                    end
                    
                case 'Rapid'
                    URL_folders = repmat({'/CODE/'},2,1);
                    files = {...
                        ['COD0OPSRAP_' yyyy doy '0000_01D_05M_ORB.SP3']
                        ['COD0OPSRAP_' yyyy doy '0000_01D_30S_CLK.CLK']};
                    decomp = {...
                        ['COD0OPSRAP_' yyyy doy '0000_01D_05M_ORB.SP3']
                        ['COD0OPSRAP_' yyyy doy '0000_01D_30S_CLK.CLK']};
                    decompressed = append(targets, decomp);
                    bool_archive = false;
                    % additional source: CDDIS
                    files_cddis = {...
                        ['COD0OPSRAP_' yyyy doy '0000_01D_05M_ORB.SP3.gz']
                        ['COD0OPSRAP_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};

                case 'Ultra-Rapid'
                    URL_folders = {'/CODE/'};
                    files = {['COD0OPSULT_' yyyy doy '0000_01D_05M_ORB.SP3']};
                    decomp = {['COD0OPSULT_' yyyy doy '0000_01D_05M_ORB.SP3']};
                    decompressed = append(targets, decomp);
                    bool_archive = false;
                    % additional source: CDDIS (gzipped, "02D" instead of "01D")
                    files_cddis = {['COD0OPSULT_' yyyy doy '0000_02D_05M_ORB.SP3.gz']};

                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return
            end
        end

        % loop over orbit and clock to download and decompress
        for i = 1:numel(files)
            if ~isfile([targets{i} files{i}]) && ~isfile([targets{i} decomp{i}]) && ~isfile([targets{i} decomp{i} '.mat'])
                [~, ~] = mkdir(targets{i});
                downloaded = false;
                try
                    websave([targets{i} files{i}], [host URL_folders{i} files{i}]);
                    downloaded = true;
                catch
                    % websave can leave a 0-byte file behind even on
                    % failure; delete it so it doesn't fool the CDDIS
                    % fallback's already-exists check below
                    if isfile([targets{i} files{i}]); delete([targets{i} files{i}]); end
                end
                if ~downloaded && exist('files_cddis', 'var') && numel(files_cddis) >= i
                    fs = get_cddis_data('https://cddis.nasa.gov', {['/archive/gnss/products/' gpsweek '/']}, files_cddis(i), targets(i), true);
                    if fs(1) == 1 || fs(1) == 2
                        dec = unzip_and_delete(files_cddis(i), targets(i));
                        [~, dname, dext] = fileparts(dec{1});
                        decomp{i} = [dname dext];
                        if ~bool_archive
                            decompressed{i} = dec{1};
                        end
                        downloaded = true;
                    end
                end
                if ~downloaded
                    errordlg({['Download failed: ' host] URL_folders{i} files{i}}, 'Error');
                end
            end
            if bool_archive
                decompressed(i) = unzip_and_delete(files(i), targets(i));
            end
        end
        % save paths and return
        settings.ORBCLK.file_sp3 = decompressed{1};
        if numel(files) > 1     % e.g. Ultra-Rapid only has a sp3 file
            settings.ORBCLK.file_clk = decompressed{2};
        else
            settings.ORBCLK.file_clk = '';
            settings.ORBCLK.bool_clk = false;
        end
        return


    case 'GFZ'      % Deutsches GeoForschungsZentrum
        % https://www.gfz-potsdam.de/en/section/space-geodetic-techniques/topics/gnss-igs-analysis-center/
        IGN_host = 'ftp.gfz-potsdam.de:21';     % very different structure and naming to cddis
        if settings.ORBCLK.MGEX
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    % GFZ does not provide a final MGEX product (only rapid)
                    errordlg('GFZ does not provide a final MGEX product. Please use Rapid instead!', 'Error');
                    return

                case 'Rapid'
                    % ftp address without 'pub' does only work in the browser
                    if str2double(gpsweek) > 2245
                        URL_folders = repmat({['/pub/GNSS/products/mgex/' gpsweek '_IGS20' '/']},2,1);
                    else
                        URL_folders = repmat({['/pub/GNSS/products/mgex/' gpsweek '/']},2,1);
                    end
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
                    % ftp address without 'pub' does only work in the browser
                    IGN_host = 'ftp.gfz-potsdam.de:21';
                    [gpsweek, dow] = NextDay(gpsweek, dow);
                    targets = targets(1);       % no clk file
                    URL_folders = repmat({['/pub/GNSS/products/mgex/' gpsweek, '/']},1,1);
                    files = {['gbu', gpsweek, dow, '_00.', 'sp3', '.Z']};
                    
                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return
            end

        else
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    URL_folders = repmat({['/pub/GNSS/products/final/w' gpsweek, '/']},2,1);
                    files = {...
                        ['GFZ0OPSFIN_' yyyy doy '0000_01D_15M_ORB.SP3.gz']
                        ['GFZ0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};

                case 'Rapid'
                    URL_folders = repmat({['/pub/GNSS/products/rapid/w' gpsweek, '/']},2,1);
                    % ||| same filename as final? therefore not implemented
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return

                case 'Ultra-Rapid'
                    [gpsweek, dow] = NextDay(gpsweek, dow);
                    targets = targets(1);       % no clk file
                    URL_folders = repmat({['/pub/GNSS/products/ultra/w' gpsweek, '/']},1,1);
                    files = {['gfu', gpsweek, dow, '_00.', 'sp3',     '.Z']};

                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return
            end
        end

    case 'JGX'
        URL_folders = repmat({['/pub/igs/products/', gpsweek, '/']},2,1);
        URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
        switch settings.ORBCLK.prec_prod_type
            case 'Final'
                files = {...
                    ['JGX0OPSFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz']
                    ['JGX0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};
                
            case 'Rapid'
                files = {...
                    ['JGX0OPSRAP_' yyyy doy '0000_01D_05M_ORB.SP3.gz']
                    ['JGX0OPSRAP_' yyyy doy '0000_01D_30S_CLK.CLK.gz']};
                
            otherwise
                errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                return
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
            URL_folders = repmat({['/pub/igs/products/mgex/' gpsweek, '/']},2,1);
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
            return
        end
        
    case 'SHAO'
        % ||| seems like SHAO orbits and clocks are not available anymore
        % (July 2026)
        if settings.ORBCLK.MGEX
            if str2double(gpsweek) < 1959
                errordlg('Precise products from SHAO only available starting from GPS week 1959 (2017-07-23). Please specify different source!', 'Error');
                return
            end
            URL_folders = repmat({['/pub/igs/products/mgex/' gpsweek, '/']},2,1);
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
            return
        end
        
    case 'TUM'      % Technische Universität München
        if settings.ORBCLK.MGEX
            % tum has no clk-file, only sp3 (?!)
            % TUM's MGEX orbit product was discontinued and is no longer
            % provided as of/around GPS week 2024 (~Nov 2018) - this case
            % is kept for old configs/backward compatibility
            URL_folders = repmat({['/pub/igs/products/mgex/' gpsweek, '/']},1,1);
            if str2double(gpsweek) > 2230
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
            else
                URL_folders_2 = repmat({['/archive/gnss/products/mgex/' gpsweek]},2,1);
            end
            files = {['TUM0MGXRAP_', yyyy, doy, '0000', '_01D_15M_ORB.SP3.gz']}; 	% orbits
        else
            errordlg(['Precise Product Type: ' settings.ORBCLK.prec_prod_type ' is not implemented.'], 'Error');
            return
        end
        
    case 'WUM'      % Wuhan University
        if settings.ORBCLK.MGEX
            % takes forever...
            if str2double(gpsweek) > 2230
                URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
            else
                URL_folders_2 = repmat({['/archive/gnss/products/mgex/' gpsweek]},2,1);
            end
            switch settings.ORBCLK.prec_prod_type
                case 'Rapid'
                    IGN_host = 'igs.gnsswhu.cn:21';
                    URL_folders{1} = ['/pub/whu/phasebias/' yyyy, '/orbit/'];
                    URL_folders{2} = ['/pub/whu/phasebias/' yyyy, '/clock/'];
                    URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                    files{1} = ['WUM0MGXRAP_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
                    files{2} = ['WUM0MGXRAP_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
                    decom{1} = ['WUM0MGXRAP_' yyyy doy '0000_01D_05M_ORB.SP3'];
                    decom{2} = ['WUM0MGXRAP_' yyyy doy '0000_01D_30S_CLK.CLK'];
                    % try ftps://bdspride.com
                    for i = 1:2
                        [~, ~] = mkdir(targets{i});
                        URL_host_1 = 'ftps://bdspride.com/';
                        URL_folders_1 = ['wum/' gpsweek '/'];
                        file_status = CurlDownload([targets{i} files{i}], [URL_host_1 URL_folders_1 files{i}], false);
                        if file_status
                            unzip_and_delete(files(i), targets(i));
                            files(i) = decom(i);
                            download = false;
                        end
                    end

                case 'Final'
                    URL_folders   = repmat({['/pub/igs/products/mgex/', gpsweek, '/']},2,1);
                    URL_folders_2 = repmat({['/archive/gnss/products/' gpsweek]},2,1);
                    files{1} = ['WUM0MGXFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
                    files{2} = ['WUM0MGXFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];

                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return
            end
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
            return
        end

    case 'HUST'      % Huazhong University of Science and Technology
        if settings.ORBCLK.MGEX
            IGN_host = 'ggda.ac.cn:21';
            URL_folders{1} = ['/pub/mgex/products/' yyyy '/'];
            URL_folders{2} = ['/pub/mgex/products/' yyyy '/'];
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    files{1} = ['HUS0MGXFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
                    files{2} = ['HUS0MGXFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
                case 'Rapid'
                    files{1} = ['HUS0MGXRAP_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
                    files{2} = ['HUS0MGXRAP_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
                case 'Ultra-Rapid'
                    files{1} = ['HUS0MGXULT_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
                    files{2} = ['HUS0MGXULT_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
                otherwise
                    errordlg(['Precise Product: "' settings.ORBCLK.prec_prod ', ' settings.ORBCLK.prec_prod_type '" is not implemented.'], 'Error');
                    return
            end
        else
            errordlg(['Precise Product Type: ' settings.ORBCLK.prec_prod_type ' is not implemented.'], 'Error');
            return
        end

    case 'WCC'
        URL_host_1 = 'ftps://bdspride.com/';
        URL_folders_1 = ['wcc/' gpsweek '/'];
        files{1} = ['WCC0OPSFIN_' yyyy doy '0000_01D_05M_ORB.SP3.gz'];
        files{2} = ['WCC0OPSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.gz'];
        unzipped = cell(2,1);
        for i = 1:2
            [~, ~] = mkdir(targets{i});
            file_status = CurlDownload([targets{i} files{i}], [URL_host_1 URL_folders_1 files{i}], true);
            if file_status
                unzipped(i) = unzip_and_delete(files(i), targets(i));
            else
                errordlg(['Download Failed: ' files{i}], 'Error');
            end
        end
        % save file paths for read-in
        settings.ORBCLK.file_sp3 = unzipped{1};
        settings.ORBCLK.file_clk = unzipped{2};
        return

    otherwise
        errordlg(['Precise products from ' settings.ORBCLK.prec_prod ' are not implemented. Please specify different source!'], 'Error');
        return

end



%% download and unzip files, if necessary
i = 1;
if isempty(files_2); files_2 = files; end
while download   &&   i <= length(files)
    file_status = 0;
    % create target folder
    [~, ~] = mkdir(targets{i});
    try     %#ok<TRYNC>                             % try to download
        [file_status] = ftp_download(IGN_host, URL_folders{i}, files{i}, targets{i}, true);
        if ~bool_archive       % pretend archive, otherwise the following code does not work
            files{i} = [files{i} '.gz'];
        end
    end
    if bool_archive   &&   (file_status == 1 || file_status == 2)
        decompressed = unzip_and_delete(files(i), targets(i));
        [~, file_dec, ext_dec] = fileparts(decompressed{1});
        files{i} = [file_dec ext_dec  '.gz'];       % save name of decompressed file (pretend its an archive)
    end
    if file_status == 0 && numel(URL_folders_2) >= i && ~isempty(URL_folders_2{i}) 	% try to download from CDDIS
        file = files_2{i};    target = targets{i};
        file_status = get_cddis_data(CDDIS_host, URL_folders_2, {file}, {target}, true);
        if bool_archive   &&   (file_status == 1   ||   file_status == 2)
            decompressed = unzip_and_delete(files_2(i), targets(i));
            [~, file_dec, ext_dec] = fileparts(decompressed{1});
            files{i} = [file_dec ext_dec  '.gz'];       % save name of decompressed file (pretend its an archive)
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
settings.ORBCLK.file_sp3 = [targets{1} files{1}];       % save path to orbits (sp3)
if numel(files) > 1                                         % save path to clocks (clk)
    settings.ORBCLK.file_clk = [targets{2} files{2}];
else        % e.g. ultra-rapid products only have a sp3 file
    settings.ORBCLK.file_clk = '';
    settings.ORBCLK.bool_clk = false;
end




function [gpsweek, dow] = NextDay(gpsweek, dow)
% Ultra-rapid files contain 48 hours of data. Therefore take ultra-rapid 
% file of next day at 0h (no predicted orbit are processed). BUT his file 
% is saved into the day-folder of the RINEX file (although the file name of 
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