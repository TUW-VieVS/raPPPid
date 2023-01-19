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
mkdir(target{1});
URL_host = 'igs.ign.fr:21';            % default ftp-server


%% switch source of orbits/clocks
if settings.ORBCLK.MGEX
    % http://www.igs.org/products
    URL_folders = {['/pub/igs/products/mgex/', gpsweek, '/']};
    switch settings.ORBCLK.prec_prod
        case 'CODE'
            URL_host = 'ftp.aiub.unibe.ch:21';
            URL_folders = {['/CODE_MGEX/CODE/' yyyy, '/']};
            file = {['COD0MGXFIN_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            
        case 'CNES'
            file = {['GRG0MGXFIN_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            
        case 'WUM'
            URL_host = 'igs.gnsswhu.cn:21';
            URL_folders = {['/pub/whu/phasebias/' yyyy, '/orbit/']};
            file = {['WUM0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
                        
        case 'GFZ'
            file = {['GFZ0MGXRAP_' yyyy doy '0000_01D_30S_ATT.OBX.gz']};
            
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

[file_status] = ftp_download(URL_host, URL_folders{1}, file{1}, target{1}, true);
% ||| if download failed, try another ftp server
if file_status == 1   ||   file_status == 2
    unzip_and_delete(file(1), target(1));
elseif file_status == 0
    errordlg(['No ORBEX file from ' settings.ORBCLK.prec_prod ' found on server. Disable ORBEX file!'], 'Error');
    return
end
[~,file,~] = fileparts(file{1});   % remove the zip file extension

%% save file-path into settings
settings.ORBCLK.file_obx = [target{1} '/' file];	


