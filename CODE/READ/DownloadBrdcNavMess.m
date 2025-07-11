function brdc_file_path = DownloadBrdcNavMess(yyyy, doy, option, bool_print)
% Download broadcast navigation message. Due to regularly changing
% filenames and ftp servers in this regard, multiple options are considered
%
% INPUT:
%   yyyy                string, 4-digit year
%   doy                 string, day of year
%   option              string, defines source for download
%   bool_print          boolean, true to print download information
% OUTPUT:
%	brdc_file_path      string, full relative filepath
%
% Revision:
%   2025/06/02, MFWG    change of CDDIS source
%   2023/03/15, MFG     download all brdc nav message from here
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


brdc_file_path = '';

% define target for download
target_nav = {[Path.DATA 'BROADCAST/' yyyy '/' doy '/']};
[~, ~] = mkdir(target_nav{1});

% define FTP host and folder
FTP_h_ign = 'igs.ign.fr:21';
FTP_f_ign = {['/pub/igs/data/' yyyy '/' doy '/']};
% define alternative FTP host and folder
FTP_h_esa = 'gssc.esa.int:21';
FTP_f_esa = {['/gnss/data/daily/', yyyy, '/brdc/']};
% define alternative FTP host and folder
URL_cddis = 'https://cddis.nasa.gov'; 
folder_cddis = ['/archive/gnss/data/daily/' yyyy '/' doy '/' yyyy(3:4) 'p'];  

% booleans for sources
bool_ign = true; bool_esa = true; bool_cddis = true;
file_status = 0;

switch option
    case 'IGS'
        file = {['BRDC00IGS_R_' yyyy doy '0000_01D_MN.rnx.gz']};
        
    case 'IGN'
        file = {['BRDC00IGN_R_' yyyy doy '0000_01D_MN.rnx.gz']};
        bool_esa = false; bool_cddis = false;
        
    case 'DLR, BRD4'
        file = {['BRD400DLR_S_' yyyy doy '0000_01D_MN.rnx.gz']};
        bool_ign = false;
        
    case 'DLR, BRDM'
        file = {['BRDM00DLR_S_' yyyy doy '0000_01D_MN.rnx.gz']};
        bool_ign = false;
        
    case 'CAS, BDRM'        
        % from the data center of the Chinese Academy of Sciences (CAS)
        httpserver = ['https://data.bdsmart.cn/pub/product/rts/brdc/' yyyy];
        file  = ['BRDM00CAS_S_' yyyy doy '0000_01D_MN.rnx.gz'];
        dcmpr = ['BRDM00CAS_S_' yyyy doy '0000_01D_MN.rnx'];
        % try to download
        if ~isfile([target_nav{1} file]) && ~isfile([target_nav{1} dcmpr])
            try websave([target_nav{1} file], [httpserver '/' file]); end      %#ok<*TRYNC>
        end
        % unzip if download was successful
        brdc_file_path = unzip_and_delete({file}, target_nav);
        if ~isfile(brdc_file_path)
            errordlg({'No CAS Multi-GNSS Navigation File found on server.', ' Please specify different source!'}, 'Error');
        end
        return
        
    otherwise
        errordlg({'DownloadBrdcNavMess.m failed. Please', 'specify a different navigation file!'}, 'Error');
end

% try to download from igs.ign.fr
if bool_ign && file_status == 0
    file_status = ftp_download(FTP_h_ign, FTP_f_ign{1}, file{1}, target_nav{1}, false);
end
% try to download from gssc.esa.int
if bool_esa && file_status == 0
    file_status = ftp_download(FTP_h_esa, FTP_f_esa{1}, file{1}, target_nav{1}, ~bool_cddis&&bool_print);
end
% try to download from CDDIS 
if bool_cddis && file_status == 0
   file_status = get_cddis_data(URL_cddis, {folder_cddis}, file(1), target_nav, bool_print);
end
if bool_cddis && file_status == 0
   file = {['BRDM00DLR_R_' yyyy doy '0000_01D_MN.rnx.gz']};   % seems to be reliable
   file_status = get_cddis_data(URL_cddis, {folder_cddis}, file, target_nav, bool_print);
end

% unzip downloaded file
if file_status == 1 || file_status == 2
    unzip_and_delete(file, target_nav);
end

% check if file is existing and save path
[~,file,~] = fileparts(file{1});   % remove the zip file extension
if isfile([target_nav{1} '/' file])
    brdc_file_path = [target_nav{1} '/' file];
elseif bool_print
    errordlg(['No Multi-GNSS broadcast message from ' option ' available. Please try different source!'], 'Error');
end