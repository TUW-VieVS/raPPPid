function [settings] = DownloadBiases(settings, gpsweek, dow, yyyy, mm, doy)
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
%	settings        updated with settings.BIASES.code_file
%
% Revision:
%   2024/03/12, MFWG: download CAS biases improved according to IGSMAIL-8399
%   2024/12/02, MFWG: change to https://data.bdsmart.cn/pub/ [IGS-RTWG-359] 
%   2024/12/10, MFWG: decompressed file name from function unzip_and_delete
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| could be solved more elegant (a lot of source code is repeated)

bool_archive = true;        % true if archive is downloaded
decompressed = {''};

switch settings.BIASES.code
    case 'CAS Multi-GNSS DCBs'      % ||| implement weekly and daily
        % create folder and prepare the download
        target = [Path.DATA, 'BIASES/', yyyy, '/', doy '/'];
        [~, ~] = mkdir(target);
        httpserver = ['https://data.bdsmart.cn/pub/product/bias/' yyyy];
        % 'CAS1' considers the latest IGS antenna model in the DCB
        % determination for full compatibility with PPP models
        file_3 = ['CAS1OPSRAP_' yyyy doy '0000_01D_01D_DCB.BIA.gz'];   % tried first
        file_2 = ['CAS1MGXRAP_' yyyy doy '0000_01D_01D_DCB.BSX.gz'];
        file_1 = ['CAS0OPSRAP_' yyyy doy '0000_01D_01D_DCB.BIA.gz'];
        file_0 = ['CAS0MGXRAP_' yyyy doy '0000_01D_01D_DCB.BSX.gz'];
        % try different files until one is successfully downloaded
        file = file_3;                      % try first file
        [~, decompr, ~] = fileparts(file);  % remove the zip file extension
        if ~isfile([target file]) && ~isfile([target decompr])
            try websave([target file], [httpserver '/' file]); end      %#ok<*TRYNC>
        end
        if ~isfile([target file]) && ~isfile([target decompr])
            file = file_2;      [~, decompr, ~] = fileparts(file);
            try websave([target file], [httpserver '/' file]); end
        end
        if ~isfile([target file]) && ~isfile([target decompr])
            file = file_1;      [~, decompr, ~] = fileparts(file);
            try websave([target file], [httpserver '/' file]); end
        end
        if ~isfile([target file]) && ~isfile([target decompr])
            file = file_0;      [~, decompr, ~] = fileparts(file);
            try websave([target file], [httpserver '/' file]); end
        end    
        if ~isfile([target file]) && ~isfile([target decompr])
            file = file_0;      [~, decompr, ~] = fileparts(file);
            try websave([target file], [httpserver '/' file]); 
            catch
                % for example 2020/001 (My First PPP Processing)
                URL_host = 'igs.ign.fr:21';     
                URL_folder = {['/pub/igs/products/mgex/dcb/' yyyy '/']};
                file_status = ftp_download(URL_host, URL_folder{1}, file, target, true);
                [~, decompr, ~] = fileparts(file);
            end
        end           
        % unzip if download was successful
        decompressed = unzip_and_delete({file}, {target});
        if ~isfile([target decompr])
            errordlg('No CAS Multi-GNSS DCBs found on server. Please change source of biases!', 'Error');
        end
        % save file-path
        settings.BIASES.code_file = decompressed{1};

    case 'CAS Multi-GNSS OSBs'       
        target = [Path.DATA, 'BIASES/', yyyy, '/', doy '/'];
        [~, ~] = mkdir(target);
        httpserver = ['https://data.bdsmart.cn/pub/product/bias/' yyyy];
        file_3 = ['CAS1OPSRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz'];
        file_2 = ['CAS1MGXRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz'];
        file_1 = ['CAS0OPSRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz'];
        file_0 = ['CAS0MGXRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz'];
        % try different files until one is successfully downloaded
        file = file_3;                      % try first file
        [~, decompr, ~] = fileparts(file);  % remove the zip file extension
        if ~isfile([target file]) && ~isfile([target decompr])
            try websave([target file], [httpserver '/' file]); end
        end
        if ~isfile([target file]) && ~isfile([target decompr])
            file = file_2;      [~, decompr, ~] = fileparts(file);
            try websave([target file], [httpserver '/' file]); end
        end
        if ~isfile([target file]) && ~isfile([target decompr])
            file = file_1;      [~, decompr, ~] = fileparts(file);
            try websave([target file], [httpserver '/' file]); end
        end
        if ~isfile([target file]) && ~isfile([target decompr])
            file = file_0;      [~, decompr, ~] = fileparts(file);
            try websave([target file], [httpserver '/' file]); end
        end       
        % unzip if download was successful
        decompressed = unzip_and_delete({file}, {target});
        if ~isfile([target decompr])
            errordlg('No CAS Multi-GNSS DCBs found on server. Please change source of biases!', 'Error');
        end
        % save file-path
        settings.BIASES.code_file = decompressed{1};
        
    case 'DLR Multi-GNSS DCBs'
        % determine the variable "quart" (also consider leapyears)
        if str2double(doy) < 91+leapyear(str2double(yyyy))
            quart = '001';
        elseif str2double(doy) < 182+leapyear(str2double(yyyy))
            quart = num2str(91+leapyear(str2double(yyyy)),'%03d');
        elseif str2double(doy) < 274+leapyear(str2double(yyyy))
            quart = num2str(182+leapyear(str2double(yyyy)),'%03d');
        else
            quart = num2str(274+leapyear(str2double(yyyy)),'%03d');
        end
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/']};
        [~, ~] = mkdir(target{1});
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/mgex/dcb/' yyyy '/']};
        file = {['DLR0MGXFIN_' yyyy quart '0000_03L_01D_DCB.BSX.gz']};
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 0
            errordlg({'No DLR Multi-GNSS quarterly DCBs found on server. Please change source of biases!';' ';'(DLR Multi-GNSS quarterly DCBs only become available some months in retrospect; perhaps this is the problem.)'}, 'Error');
        end
        decompressed = unzip_and_delete(file, target);
        % save file-path
        settings.BIASES.code_file = decompressed{1};
        
    case 'CODE DCBs (P1P2, P1C1, P2C2)'           % "old" DCBs
        % create folder and prepare download
        targets = repmat({[Path.DATA, 'BIASES/', yyyy, '/']},3,1);
        [~, ~] = mkdir(targets{1});
        URL_host = 'ftp.aiub.unibe.ch:21';
        URL_folder = repmat({['/CODE/' yyyy '/']},3,1);
        files = {['P1P2' yyyy(3:4) mm '_ALL.DCB.Z'];...
            ['P1C1' yyyy(3:4) mm '_RINEX.DCB.Z'];...
            ['P2C2' yyyy(3:4) mm '_RINEX.DCB.Z'];};
        % download, unzip, save file-path
        for i = 1:length(files)
            file_status = ftp_download(URL_host, URL_folder{i}, files{i}, targets{i}, true);
            if file_status == 0
                errordlg('No CODE DCBs found on server. Please change source of biases!', 'Error');
            end
            decompressed{i} = unzip_and_delete(files(i), targets(i));
            settings.BIASES.code_file{i} = decompressed{i};
        end

    case 'WUM MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        [~, ~] = mkdir(target{1});
        URL_host = 'igs.gnsswhu.cn:21';
        URL_folder = {['/pub/whu/phasebias/' yyyy, '/bias/']};
        URL_host_2 = 'igs.ign.fr:21';
        URL_folder_2 = {['/pub/igs/products/mgex/' gpsweek, '/']};
        file   = {['WUM0MGXRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        file_2 = {['WUM0MGXRAP_' yyyy doy '0000_01D_01D_ABS.BIA.gz']};
        % download
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, false);
        end
        if file_status == 0
            file = file_2;
            file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        end
        if file_status == 0
            errordlg('No WUM MGEX Biases found on server. Please specify different source!', 'Error');
        end
        % unzip 
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file(1), target(1));
        end
        % save file-path
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file{1}];
        
    case 'CNES MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        [~, ~] = mkdir(target{1});
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/mgex/' gpsweek, '/']};
        file = {['GRG0MGXFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true); 
        if file_status == 0
            errordlg('No CNES MGEX Biases found on server. Please change source of biases!', 'Error');
        end
        decompressed = unzip_and_delete(file(1), target(1));
        % save file-path
        settings.BIASES.code_file = decompressed{1};

    case 'GFZ MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        [~, ~] = mkdir(target{1});
        URL_host = 'ftp.gfz-potsdam.de:21';
        if str2double(gpsweek) > 2245
            URL_folder = {['/pub/GNSS/products/mgex/' gpsweek '_IGS20' '/']};
        else
            URL_folder = {['/pub/GNSS/products/mgex/' gpsweek '/']};
        end
        file = {['GBM0MGXRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true); 
        if file_status == 0
            errordlg('No GFZ MGEX Biases found on server. Please change source of biases!', 'Error');
        end
        decompressed = unzip_and_delete(file(1), target(1));
        settings.BIASES.code_file = decompressed{1};
        
    case 'CODE OSBs'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        [~, ~] = mkdir(target{1});
        URL_host = 'ftp.aiub.unibe.ch:21';
        switch settings.ORBCLK.prec_prod_type
            case 'Final'
                URL_folder = {['/CODE/' yyyy '/']};
                if str2double(gpsweek) >= 2238
                    file = {['COD0OPSFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
                else
                    file = {['COD', gpsweek, dow, '.BIA.Z']};
                end
            case 'Rapid'
                URL_folder = {'/CODE/'};
                file = {['COD0OPSRAP_' yyyy doy '0000_01D_01D_OSB.BIA']};
                bool_archive = false;
            otherwise
                errordlg([settings.ORBCLK.prec_prod_type ' CODE OSBs are not implemented!'], 'Error');
        end

        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if ~bool_archive        % pretend archive, otherwise code does not work
            file{1} = [file{1} '.gz'];
        end
        decompressed = unzip_and_delete(file(1), target(1));
        % save file-path
        settings.BIASES.code_file = decompressed{1};

    case 'CNES OSBs'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        [~, ~] = mkdir(target{1});
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/' gpsweek, '/']};
        file = {['GRG0OPSFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 0
            errordlg('No CNES OSBs Biases found on server. Please change source of biases!', 'Error');
        end
        decompressed = unzip_and_delete(file(1), target(1));
        % save file-path
        settings.BIASES.code_file = decompressed{1};

    case 'CODE MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        [~, ~] = mkdir(target{1});
        URL_host = 'ftp.aiub.unibe.ch:21';
        URL_folder = {['/CODE_MGEX/CODE/' yyyy '/']};
        if str2double(gpsweek) >= 2238
            file = {['COD0MGXFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        else
            file = {['COM', gpsweek, dow, '.BIA.Z']};
        end
        % download and unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 0
            errordlg('No CODE MGEX Biases found on server. Please change source of biases!', 'Error');
        end
        decompressed = unzip_and_delete(file(1), target(1));
        % save file-path
        settings.BIASES.code_file = decompressed{1};
        
    case 'CNES postprocessed'
        % create folder and prepare download
        target = [Path.DATA, 'BIASES/', yyyy, '/' doy '/'];
        [~, ~] = mkdir(target);
        if str2double(yyyy) == 2019 && str2double(doy) >= 27
            file_bia = ['GFZ0MGXRAP_' yyyy doy '0000_01D_30S_ABS.BIA'];
        elseif str2double(yyyy) >= 2020
            file_bia = ['GBM0MGXRAP_' yyyy doy '0000_01D_30S_ABS.BIA'];
        else        % other filename before 2019/027
            file_bia = ['gbm' gpsweek dow '.bia'];
        end
        if ~( exist([target file_bia],'file') || exist([target file_bia '.mat'],'file') )
            file_bia = [file_bia '.gz'];
            try
                websave([target file_bia] , ['http://www.ppp-wizard.net/products/POST_PROCESSED/' file_bia]);
            catch
                error('%s%s%s\n','CNES postprocessed ',file_bia,' not found!');
            end
            decompressed = unzip_and_delete({file_bia}, {target});
            [~,file_bia,~] = decompressed{1};   % remove the zip file extension
        end
        settings.BIASES.code_file = [target file_bia];
        % CNES postprocessed also provides a bias file
        if settings.ORBCLK.bool_precise && strcmp(settings.ORBCLK.prec_prod, 'GFZ') && settings.ORBCLK.MGEX
            target = [Path.DATA, 'ORBIT/', yyyy, '/', doy '/'];
            file_obx = ['GBM0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX'];
            file_obx_gz = ['GBM0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX.gz'];
            file_obx_mat = ['GBM0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX.mat'];
            if ~( exist([target file_obx],'file') || exist([target file_obx_mat],'file') )
                try
                    websave([target file_obx_gz] , ['http://www.ppp-wizard.net/products/POST_PROCESSED/' file_obx_gz]);
                catch
                    error('%s%s%s\n','CNES postprocessed ',file_obx_gz,' not found!');
                end
                decompressed = unzip_and_delete({file_obx_gz}, {target});
            end
            settings.ORBCLK.file_obx = decompressed{1};	
        end
        
    case 'HUST MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        [~, ~] = mkdir(target{1});
        URL_host = 'ggda.ac.cn:21';
        URL_folder = {['/pub/mgex/products/' yyyy '/']};
        switch settings.ORBCLK.prec_prod_type
            case 'Final'
                file = {['HUS0MGXFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
            case 'Rapid'
                file = {['HUS0MGXRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
            case 'Ultra-Rapid'
                file = {['HUS0MGXULT_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 0
            errordlg('No HUST MGEX Biases found on server. Please change source of biases!', 'Error');
        end
        decompressed = unzip_and_delete(file(1), target(1));
        % save file-path
        settings.BIASES.code_file = decompressed{1};

    case 'Correction Stream'
        % nothing to do here, biases are in correction stream file
        
    case 'manually'
        % nothing to do here
        
    case 'off'
        % nothing to do here

    case 'Broadcasted TGD'
        % nothing to do here
        
    otherwise
        errordlg('Error in choice of code biases [downloadInputFiles.m].', 'Error');
end
