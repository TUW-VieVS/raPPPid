function brdc_file_path = DownloadBrdcNavMess(yyyy, doy)
% Download broadcast navigation message. Due to regularly changing
% filenames and ftp servers in this regard, multiple options are considered
% 
% INPUT:
%   yyyy                string, 4-digit year
%   doy                 string, day of year
% OUTPUT:
%	brdc_file_path      string, full relative filepath
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


target_nav = {[Path.DATA, 'BROADCAST/', yyyy, '/', doy]};
mkdir(target_nav{1});

% possible mGNSS navigation message files
file_1 = ['BRDC00IGN_S_', yyyy, doy, '0000', '_01D_MN.rnx'];
file_2 = ['BRDC00IGS_R_', yyyy, doy, '0000', '_01D_MN.rnx'];
file_3 = ['BRDM00DLR_S_' yyyy doy '0000_01D_MN.rnx'];


% check if any already downloaded
if isfile([ Path.DATA 'BROADCAST/' yyyy, '/' doy '/' file_1 ])
    brdc_file_path = [Path.DATA 'BROADCAST/' yyyy, '/' doy '/' file_1];
    return
end
if isfile([ Path.DATA 'BROADCAST/' yyyy, '/' doy '/' file_2 ])
    brdc_file_path = [Path.DATA 'BROADCAST/' yyyy, '/' doy '/' file_2];
    return
end
if isfile([ Path.DATA 'BROADCAST/' yyyy, '/' doy '/' file_3 ])
    brdc_file_path = [Path.DATA 'BROADCAST/' yyyy, '/' doy '/' file_3];
    return
end


% otherwise, try to download 
% IGS IGN: ||| not working... then working....
URL_host    = 'igs.ign.fr:21';
URL_folder = {['/pub/igs/data/' yyyy '/' doy '/']};
% file = {['BRDC00IGN_R_', yyyy, doy, '0000', '_01D_MN.rnx.gz']};
file = {['BRDC00IGN_S_', yyyy, doy, '0000', '_01D_MN.rnx.gz']};
file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target_nav{1}, false);
if file_status == 1   ||   file_status == 2
    unzip_and_delete(file, target_nav);

elseif file_status == 0
    % GSSC ESA -> but also: ||| not working... then working....
    URL_host = 'gssc.esa.int:21';
    URL_folder = {['/gnss/data/daily/' yyyy '/brdc/']};
    file = {['BRDC00IGS_R_', yyyy, doy, '0000', '_01D_MN.rnx.gz']};
    file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target_nav{1}, false);
    if file_status == 1   ||   file_status == 2
        unzip_and_delete(file, target_nav);

    elseif file_status == 0     
        % broadcast archive of BKG
        %             % does not contain GLONASS (why?
        %             file_decompr = {['BRDC00WRD_R_' yyyy doy '0000_01D_MN.rnx']};
        %             file         = {['BRDC00WRD_R_' yyyy doy '0000_01D_MN.rnx.gz']};
        file_decompr = {['BRDM00DLR_S_' yyyy doy '0000_01D_MN.rnx']};
        file         = {['BRDM00DLR_S_' yyyy doy '0000_01D_MN.rnx.gz']};
        if ~isfile([target_nav{1} '/' file_decompr{1}])  	% check if already existing
            websave([target_nav{1} '/' file{1}], ['https://igs.bkg.bund.de/root_ftp/IGS/BRDC/' yyyy '/' doy '/' file{1}]);
            if isfile([target_nav{1} '/' file{1}])          % check if download worked
                unzip_and_delete(file, target_nav);
            elseif file_status == 0
                errordlg('No Multi-GNSS broadcast message from IGS found on server for Glonass channels.', 'Error');
            end
        end
    end
    
end


% create filepath
[~,file,~] = fileparts(file{1});   % remove the zip file extension
brdc_file_path = [target_nav{1} '/' file];