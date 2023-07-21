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
%	settings        updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| could be solved more elegant


switch settings.BIASES.code
    case 'CAS Multi-GNSS DCBs'      % ||| implement weekly and daily
        % create folder and prepare the download
        % ||| alternative: ftp://ftp.gipp.org.cn/product/dcb/mgex/yyyy/
        target = {[Path.DATA, 'BIASES/', yyyy, '/', doy '/']};
        mkdir(target{1});
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/mgex/dcb/' yyyy '/']};
        file = {['CAS0MGXRAP_' yyyy doy '0000_01D_01D_DCB.BSX.gz']};
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            URL_host = 'ftp.gipp.org.cn:21';
            URL_folder = {['/product/dcb/mgex/' yyyy '/']};
            file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
            if file_status == 1   ||   file_status == 2
                unzip_and_delete(file, target);
            elseif file_status == 0
                errordlg('No CAS Multi-GNSS DCBs found on server. Please specify different source!', 'Error');
            end
        end
        [~,file,~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file];

    case 'CAS Multi-GNSS OSBs'       
        target = {[Path.DATA, 'BIASES/', yyyy, '/', doy '/']};
        mkdir(target{1});
        URL_host = 'ftp.gipp.org.cn:21';
        URL_folder = {['/product/dcb/mgex/' yyyy '/']};
        file = {['CAS0MGXRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg('No CAS Multi-GNSS OSBs found on server. Please specify different source!', 'Error');
        end
        [~,file,~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file];
        
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
        mkdir(target{1});
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/mgex/dcb/' yyyy '/']};
        file = {['DLR0MGXFIN_' yyyy quart '0000_03L_01D_DCB.BSX.gz']};
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file, target);
        elseif file_status == 0
            errordlg({'No DLR Multi-GNSS quarterly DCBs found on server. Please specify different source!';' ';'(DLR Multi-GNSS quarterly DCBs only become available some months in retrospect; perhaps this is the problem.)'}, 'Error');
        end
        [~,file,~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file];
        
    case 'CODE DCBs (P1P2, P1C1, P2C2)'           % "old" DCBs
        % create folder and prepare download
        targets = repmat({[Path.DATA, 'BIASES/', yyyy, '/']},3,1);
        mkdir(targets{1});
        URL_host = 'ftp.aiub.unibe.ch:21';
        URL_folder = repmat({['/CODE/' yyyy '/']},3,1);
        files = {['P1P2' yyyy(3:4) mm '_ALL.DCB.Z'];...
            ['P1C1' yyyy(3:4) mm '_RINEX.DCB.Z'];...
            ['P2C2' yyyy(3:4) mm '_RINEX.DCB.Z'];};
        % download, unzip, save file-path
        for i = 1:length(files)
            file_status = ftp_download(URL_host, URL_folder{i}, files{i}, targets{i}, true);
            if file_status == 1   ||   file_status == 2
                unzip_and_delete(files(i), targets(i));
            elseif file_status == 0
                errordlg('No CODE DCBs found on server. Please specify different source!', 'Error');
            end
            [~,files{i},~] = fileparts(files{i});   % remove the zip file extension
            settings.BIASES.code_file{i} = [targets{i} '/' files{i}];
        end

    case 'WUM MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        mkdir(target{1});
        URL_host = 'igs.gnsswhu.cn:21';
        URL_folder = {['/pub/whu/phasebias/' yyyy, '/bias/']};
        file = {['WUM0MGXRAP_' yyyy doy '0000_01D_01D_ABS.BIA.gz']};
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file(1), target(1));
        elseif file_status == 0
            URL_host = 'igs.ign.fr:21';
            URL_folder = {['/pub/igs/products/mgex/' gpsweek, '/']};
            file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
            if file_status == 0
                errordlg('No WUM MGEX Biases found on server. Please specify different source!', 'Error');
            end
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file{1}];
        
    case 'CNES MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        mkdir(target{1});
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/mgex/' gpsweek, '/']};
        file = {['GRG0MGXFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file(1), target(1));
        elseif file_status == 0
            errordlg('No CNES MGEX Biases found on server. Please specify different source!', 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file{1}];

    case 'GFZ MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        mkdir(target{1});
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/mgex/' gpsweek, '/']};
        file = {['GFZ0MGXRAP_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, false);
        if file_status == 0
            URL_host_2 = 'ftp.gfz-potsdam.de:21';
            if str2double(gpsweek) > 2245
                URL_folder_2 = {['/pub/GNSS/products/mgex/' gpsweek '_IGS20' '/']};
            else
                URL_folder_2 = {['/pub/GNSS/products/mgex/' gpsweek '/']};
            end
            file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target{1}, true);
        end
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file(1), target(1));
        elseif file_status == 0
            errordlg('No GFZ MGEX Biases found on server. Please specify different source!', 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file{1}];
        
    case 'CODE OSBs'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        mkdir(target{1});
        URL_host = 'ftp.aiub.unibe.ch:21';
        URL_folder = {['/CODE/' yyyy '/']};
        if str2double(gpsweek) >= 2238
            file = {['COD0OPSFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};  
        else
            file = {['COD', gpsweek, dow, '.BIA.Z']};
        end
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file(1), target(1));

        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file{1}];

    case 'CNES OSBs'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        mkdir(target{1});
        URL_host = 'igs.ign.fr:21';
        URL_folder = {['/pub/igs/products/' gpsweek, '/']};
        file = {['GRG0OPSFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        % download, unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file(1), target(1));
        elseif file_status == 0
            errordlg('No CNES OSBs Biases found on server. Please specify different source!', 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file{1}];

    case 'CODE MGEX'
        % create folder and prepare download
        target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
        mkdir(target{1});
        URL_host = 'ftp.aiub.unibe.ch:21';
        URL_folder = {['/CODE_MGEX/CODE/' yyyy '/']};
        if str2double(gpsweek) >= 2238
            file = {['COD0MGXFIN_' yyyy doy '0000_01D_01D_OSB.BIA.gz']};
        else
            file = {['COM', gpsweek, dow, '.BIA.Z']};
        end
        % download and unzip, save file-path
        file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(file(1), target(1));
        elseif file_status == 0
            errordlg('No CODE MGEX Biases found on server. Please specify different source!', 'Error');
        end
        [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
        settings.BIASES.code_file = [target{1} '/' file{1}];

    case 'CNES postprocessed'
        % create folder and prepare download
        target = [Path.DATA, 'BIASES/', yyyy, '/' doy '/'];
        mkdir(target);
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
            unzip_and_delete({file_bia}, {target});
            [~,file_bia,~] = fileparts(file_bia);   % remove the zip file extension
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
                unzip_and_delete({file_obx_gz}, {target});
            end
            settings.ORBCLK.file_obx = [target file_obx];	
        end

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
