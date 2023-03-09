function settings = downloadInputFiles(settings, obs_startdate, glo_channels)
% This function checks if the Input Files which are selected in the GUI
% exist in particular folder of DATA. If this products if missing this
% function downloads this file. Additionally some changes in the struct 
% settings are made for the further processing (e.g. stream Archive has to
% be handled like processing with precise products). After this function 
% all filepaths and booleans are (correctly) set in the struct settings.
% 
% INPUT:
%   settings        struct, settings from GUI
%   obs_startdate   vector, [year month day hour minute second]
% 
% OUTPUT:
%   settings        struct, updated with paths to the needed input files
%   glo_channels    boolean, true if Glonass could not be extracted from
%                       Rinex header
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| if download failed, try another ftp server

% IGS data centers [https://kb.igs.org/hc/en-us/articles/115003935351-Access-to-Products]:
% CDDIS:  ftp://cddis.gsfc.nasa.gov/gnss/products/
% IGN:    ftp://igs.ign.fr/pub/igs/products/
% ESA:    ftp://gssc.esa.int/gnss/products/
%   ...



% ------ Convert date and create strings ------


% give a command window output that files are downloaded
if ~settings.INPUT.bool_parfor
    fprintf('\nDownloading required data, this can take some seconds...\n')
end

% date conversion to julian date
dd = obs_startdate(3);
mm = obs_startdate(2);
yyyy = obs_startdate(1);
jd = cal2jd_GT(yyyy,mm,dd);
% convert from julian date into other formats
% [~, mm, dd] = jd2cal_GT(jd);
[doy, yyyy] = jd2doy_GT(jd);
[gpsweek, sow, ~] = jd2gps_GT(jd);
dow = floor(sow/3600/24);
% create strings
gpsweek = sprintf('%04d',gpsweek);
dow     = sprintf('%01d',dow);
yyyy    = sprintf('%04d',yyyy);
doy 	= sprintf('%03d',doy);
mm      = sprintf('%02d',mm);
% dd      = sprintf('%02d',dd);



%% --- orbits and clocks
if settings.ORBCLK.bool_sp3 && settings.ORBCLK.bool_clk && ~strcmp(settings.ORBCLK.prec_prod, 'manually')
    settings = DownloadOrbitClock(settings, gpsweek, dow, yyyy, mm, doy);
    if settings.ORBCLK.bool_obx
        settings = DownloadORBEX(settings, gpsweek, dow, yyyy, mm, doy);
    end
end


%% --- Correction stream
% before Multi-GNSS broadcast message as this not needed if a sp3 and 
% clk file from a stream archive are processed (except Glonass channels)
if settings.ORBCLK.bool_brdc && (strcmp(settings.ORBCLK.CorrectionStream, 'CNES Archive') || strcmp(settings.ORBCLK.CorrectionStream, 'IGC01 Archive'))
    settings = DownloadStreamArchive(settings, gpsweek, dow, yyyy, mm, doy);
end



%% --- Multi-GNSS broadcast message
if settings.ORBCLK.bool_brdc && settings.ORBCLK.bool_nav_multi && ~strcmp(settings.ORBCLK.multi_nav, 'manually')
    if str2double(yyyy) < 2015
        error('There are no Multi-GNSS broadcast messages before 2015! Please choose Single-GNSS Navigation Files instead!')
    end    
    target_nav = {[Path.DATA, 'BROADCAST/', yyyy, '/', doy]};
    mkdir(target_nav{1});
    switch settings.ORBCLK.multi_nav
        case 'IGS'  
            URL_host    = 'igs.ign.fr:21';
            URL_folder = {['/pub/igs/data/' yyyy '/' doy '/']};
            file = {['BRDC00IGS_R_', yyyy, doy, '0000', '_01D_MN.rnx.gz']};
            URL_host_2 = 'gssc.esa.int:21';
            URL_folder_2 = {['/gnss/data/daily/', yyyy, '/', doy, '/']};
        case 'IGN'
            URL_host    = 'igs.ign.fr:21';
            URL_folder = {['/pub/igs/data/' yyyy '/' doy '/']};
            URL_host_2 = '';
            URL_folder_2 = {''};
            file = {['BRDC00IGN_R_', yyyy, doy, '0000', '_01D_MN.rnx.gz']};
        case 'BKG'      % ||| removed from GUI
            % broadcast archive of BKG ||| check the download code
            file_decompr = {['BRDC00WRD_R_' yyyy doy '0000_01D_MN.rnx']};
            file         = {['BRDC00WRD_R_' yyyy doy '0000_01D_MN.rnx.gz']};
            URL_host_2 = '';
            URL_folder_2 = {''};
            if ~isfile([target_nav{1} '/' file_decompr{1}])  	% check if already existing
                websave([target_nav{1} '/' file{1}], ['https://igs.bkg.bund.de/root_ftp/IGS/BRDC/' yyyy '/' doy '/' file{1}]);
                if isfile([target_nav{1} '/' file{1}])          % check if download worked
                    unzip_and_delete(file, target_nav);
                else
                    % ||| download failed :(
                end
            end
    end
    file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target_nav{1}, false);
    if file_status == 0
        file_status = ftp_download(URL_host_2, URL_folder_2{1}, file{1}, target_nav{1}, true);
    end
    if file_status == 1   ||   file_status == 2
        unzip_and_delete(file, target_nav);
    elseif file_status == 0
        errordlg(['No Multi-GNSS broadcast message from ' settings.ORBCLK.multi_nav ' found on server. Please specify different source!'], 'Error');
    end
    [~,file,~] = fileparts(file{1});   % remove the zip file extension
    settings.ORBCLK.file_nav_multi = [target_nav{1} '/' file];

elseif glo_channels
    % Glonass channel numbers could not be extracted from the Rinex header
    % so a brodcast navigation message is needed
    if str2double(yyyy) < 2015
        error('There are no Multi-GNSS broadcast messages before 2015! Please choose Single-GNSS Navigation Files instead!')
    end
    settings.ORBCLK.file_nav_multi = DownloadBrdcNavMess(yyyy, doy);
end



%% --- Ionosphere

% Check if coefficients from broadcast navigation message are needed for
% ionospheric correction (e.g. Klobuchar, NeQuick)
bool_nav_iono = ~strcmp(settings.ORBCLK.multi_nav, 'manually') && ...
    (strcmp(settings.IONO.source, 'Klobuchar model') || strcmp(settings.IONO.source, 'NeQuick model'));
if bool_nav_iono
    % No Multi-GNSS broadcast messages before 2015 which is ignored here!
    target_nav = {[Path.DATA, 'BROADCAST/', yyyy, '/', doy]};
    mkdir(target_nav{1});
    URL_host    = 'igs.ign.fr:21';
    URL_folder = {['/pub/igs/data/' yyyy '/' doy '/']};
    file = {['BRDC00IGN_R_', yyyy, doy, '0000', '_01D_MN.rnx.gz']};
    file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target_nav{1}, true);
    if file_status == 1   ||   file_status == 2
        unzip_and_delete(file, target_nav);
    elseif file_status == 0
        errordlg(['No Multi-GNSS broadcast message from ' settings.ORBCLK.multi_nav ' found on server. Please specify different source!'], 'Error');
    end
    [~,file,~] = fileparts(file{1});   % remove the zip file extension
    settings.ORBCLK.file_nav_multi = [target_nav{1} '/' file];
end



% IONEX file
bool_downl_ionex = strcmp(settings.IONO.source,'IONEX File') && ( strcmpi(settings.IONO.model,'Estimate with ... as constraint') || strcmpi(settings.IONO.model,'Correct with ...') );
if bool_downl_ionex
   [settings] = DownloadIonex(settings, gpsweek, dow, yyyy, mm, doy);    
end

% .ion file
if strcmpi(settings.IONO.source,'CODE Spherical Harmonics')
    % create folder and prepare the download
    target = {[Path.DATA, 'IONO/', yyyy, '/', doy '/']};
    mkdir(target{1});
    URL_host = 'ftp.aiub.unibe.ch:21';
    URL_folder = {['/CODE/' yyyy '/']};
    if str2double(gpsweek) >= 2238
        file = {['COD0OPSFIN_' yyyy doy '0000_01D_01H_GIM.ION.gz']};
    else
        file = {['COD' gpsweek dow '.ION.Z']};
    end
    % download, unzip, save file-path
    file_status = ftp_download(URL_host, URL_folder{1}, file{1}, target{1}, true);
    if file_status == 1   ||   file_status == 2
        unzip_and_delete(file, target);
    elseif file_status == 0
        errordlg('No CODE Spherical Harmonics found on server. Please specify different source!', 'Error');
    end
    [~,file{1},~] = fileparts(file{1});   % remove the zip file extension
    settings.IONO.file_ion = [target{1} '/' file{1}];
end



%% --- Code Biases
settings = DownloadBiases(settings, gpsweek, dow, yyyy, mm, doy);



%% --- Phase Biases
target = {[Path.DATA, 'BIASES/', yyyy, '/' doy]};
switch settings.BIASES.phase
    case 'TUW (not implemented)'
        % no ftp-server for download available
        file_WL = ['WL_UPD' doy '.txt'];
        file_NL = ['NL_UPD' doy '.txt'];
        settings.BIASES.phase_file = {[target{1} file_WL];[target{1} file_NL]};
        if ~exist([target{1} file_WL], 'file') && ~settings.INPUT.bool_parfor
            fprintf('\nTUW WL UPD: File does not exist!\n\n');
        end
        if ~exist([target{1} file_NL], 'file') && ~settings.INPUT.bool_parfor
            fprintf('\nTUW NL UPD: File does not exist!\n\n');
        end
        
    case 'WHU phase/clock biases'
        target{2} = [Path.DATA, 'CLOCK/', yyyy, '/' doy];
        URL_host = 'igs.gnsswhu.cn:21';
        URL_folder = {['/pub/whu/phasebias/' yyyy '/bias/']; };
        URL_folder{2} = ['/pub/whu/phasebias/' yyyy '/clock/'];
        files = {['WHU0IGSFIN_' yyyy doy '0000_01D_01D_ABS.BIA.Z']; };
        if obs_startdate(1) < 2019
            files{2} = ['whp' gpsweek dow '.clk.Z'];
        else        % Wuhan changed naming of *.clk-file with 2019
            files{2} = ['WHU5IGSFIN_' yyyy doy '0000_01D_30S_CLK.CLK.Z'];
        end
        % download phase biases
        file_status = ftp_download(URL_host, URL_folder{1}, files{1}, target{1}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(files(1), target(1));
        elseif file_status == 0
            errordlg('Download of WUHAN Phase Biases failed!', 'Error');
        end
        [~,files{1},~] = fileparts(files{1});   % remove the zip file extension
        % download clocks
        file_status = ftp_download(URL_host, URL_folder{2}, files{2}, target{2}, true);
        if file_status == 1   ||   file_status == 2
            unzip_and_delete(files(2), target(2));
        elseif file_status == 0
            errordlg('Download of WUHAN Clock failed!', 'Error');
        end
        [~,files{2},~] = fileparts(files{2});   % remove the zip file extension
        settings.BIASES.phase_file = [target{1} '/' files{1}];
        settings.ORBCLK.file_clk   = [target{2} '/' files{2}];
        
    case 'SGG FCBs'
        file_sgg = ['sgg' gpsweek dow];
        % MGEX products are preconditioned
        switch settings.ORBCLK.prec_prod        % choose file depending on orbit/clock product
            case 'CODE'
                % file_sgg = [file_sgg '_COD.fcb'];       % old
                file_sgg = [file_sgg '_COD0MGXFIN.fcb'];
            case 'GFZ'
                % file_sgg = [file_sgg '_gbm.fcb'];       % old 
                file_sgg = [file_sgg '_GFZ0MGXRAP.fcb'];
            case 'CNES'
                % file_sgg = [file_sgg '_GRG.fcb'];       % old
                file_sgg = [file_sgg '_GRG0MGXFIN.fcb'];
            case 'WUM'
                file_sgg = [file_sgg '_wum.fcb'];  
            case 'IGS'
                file_sgg = [file_sgg '_igs.fcb'];                
            otherwise
                errordlg({'SGG FCBs need orbit/clock data from:', 'CNES or GFZ or CNES MGEX'}, 'ERROR');
        end        
        mkdir(target{1})
        if ~exist([target{1} '/' file_sgg], 'file')
            try
                websave([target{1} '/' file_sgg] , ['https://raw.githubusercontent.com/FCB-SGG/FCB-FILES/master/FCB%20Files_GECJ/' gpsweek '/' file_sgg]);
            catch
                errordlg('Download of SGG FCB phase biases failed.', 'Error');
            end
        end
        settings.BIASES.phase_file = [target{1} '/' file_sgg];
        
    case 'NRCAN (not implemented)'
        % ||| implement
        errordlg('Download of phase biases failed.', 'Error');
        
    case {'Correction Stream', 'manually (not implemented)', 'off'}
        % nothing to do here
        
    otherwise
        errordlg('Download of phase biases failed.', 'Error');
end



%% --- Antex file
if strcmp(settings.OTHER.antex, 'Manual choice:') 
    % settings.OTHER.file_antex has already the correct string value
else
    settings.OTHER.file_antex = DownloadANTEX(settings, obs_startdate);
end


%% --- Finished
if ~settings.INPUT.bool_parfor; fprintf('Finished download of data.\n\n'); end

