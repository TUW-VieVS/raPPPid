function [settings] = DownloadORBEX(settings, gpsweek, dow, yyyy, mm, doy)
% This function dowloads the ORBEX file from IGS or Analysis Center server.
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
target = {[Path.DATA, 'ORBIT/', yyyy, '/', doy]};
[~, ~] = mkdir(target{1});
URL_host = 'igs.ign.fr:21';            % default ftp-server
decompressed = {''};
URL_host_2 = ''; URL_folder_2 = ''; file_2 = '';

%% switch source of orbits/clocks
if settings.ORBCLK.MGEX
    % http://www.igs.org/products
    URL_folder = {['/pub/igs/products/mgex/', gpsweek, '/']};
    switch settings.ORBCLK.prec_prod
        case 'CODE'
            URL_host = 'ftp.aiub.unibe.ch:21';
            URL_folder = {['/CODE_MGEX/CODE/' yyyy, '/']};
            file = {['COD0MGXFIN_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            
        case 'CNES'
            file = {['GRG0MGXFIN_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            
        case 'WUM'
            switch settings.ORBCLK.prec_prod_type
                case 'Rapid'
                    URL_host = 'igs.gnsswhu.cn:21';
                    URL_folder = {['/pub/whu/phasebias/' yyyy, '/orbit/']};
                    file = {['WUM0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
                case 'Final'
                    URL_folder = {['/pub/igs/products/mgex/', gpsweek, '/']};
                    file = {['WUM0MGXFIN_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            end

            
        case 'GFZ'
            file = {['GBM0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            URL_host = 'ftp.gfz-potsdam.de:21';
            if str2double(gpsweek) > 2245
                URL_folder = {['/pub/GNSS/products/mgex/' gpsweek '_IGS20' '/']};
            else
                URL_folder = {['/pub/GNSS/products/mgex/' gpsweek '/']};
            end
            % alternative
            URL_host_2   = 'igs.ign.fr:21';
            URL_folder_2 = {['/pub/igs/products/mgex/', gpsweek, '/']};
            file_2   = {['GFZ0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            
        case 'HUST'
            URL_host = 'ggda.ac.cn:21';
            URL_folder = {['/pub/mgex/products/' yyyy '/']};
            switch settings.ORBCLK.prec_prod_type
                case 'Final'
                    file = {['HUS0MGXFIN_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
                case 'Rapid'
                    file = {['HUS0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
                case 'Ultra-Rapid'
                    file = {['HUS0MGXULT_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            end
            
        otherwise
            errordlg('No ORBEX file for this institution', 'ORBEX Error');
            return
            
    end
    
else
            errordlg('ORBEX file for non-MGEX products are not implemented!', 'ORBEX Error');
            return
end

% ||| add more


%% download and unzip files, if necessary

file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
if file_status == 0 && ~isempty(URL_host_2)
    % download failed, try another ftp server
    file_status = ftp_download(URL_host_2, URL_folder_2{1}, file_2{1}, target{1}, true);
end
decompressed = unzip_and_delete(file(1), target(1));
if file_status == 0
    errordlg(['No ORBEX file from ' settings.ORBCLK.prec_prod ' found on server. Disable ORBEX file!'], 'Error');
    return
end

%% save file-path into settings
settings.ORBCLK.file_obx = decompressed{1};	


