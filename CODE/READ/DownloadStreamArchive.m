function [settings] = DownloadStreamArchive(settings, gpsweek, dow, yyyy, mm, doy)
% This function dowloads the selected archived stream and manipulates
% settings that the processings works with the file-formats
%
% INPUT:
%	settings        struct, settings from GUI
%   gpsweek         string, GPS Week
%   dow             string, 1-digit, day of week
%   yyyy            string, 4-digit, year
%   mm              string, 2-digit, month
%   doy             string, 3-digit, day of year
% OUTPUT:
%	settings        updated and manipulated for correct processing
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



target = [Path.DATA, 'STREAM/', yyyy, '/', doy '/'];
mkdir(target);

switch settings.ORBCLK.CorrectionStream
    
    case 'CNES Archive'
        file_sp3 = ['cnt' gpsweek dow '.sp3'];
        file_clk = ['cnt' gpsweek dow '.clk'];
        file_bia = ['cnt' gpsweek dow '.bia'];
        file_obx = ['cnt' gpsweek dow '.obx'];      % since 2054/2
        targets = repmat({target},4,1);
        if ~( exist([target file_sp3],'file') || exist([target file_sp3 '.mat'],'file') )
            try
                websave([target file_sp3 '.gz'] , ['http://www.ppp-wizard.net/products/REAL_TIME/' file_sp3 '.gz']);
            catch
                error('%s%s%s\n','Correction stream file ',file_sp3,' not found!');
            end
        end
        if ~( exist([target file_clk],'file') || exist([target file_clk '.mat'],'file') )
            try
                websave([target file_clk '.gz'] , ['http://www.ppp-wizard.net/products/REAL_TIME/' file_clk '.gz']);
            catch
                error('%s%s%s\n','Correction stream file ',file_clk,' not found!');
            end
        end
        if ~( exist([target file_bia],'file') || exist([target file_bia '.mat'],'file') )
            try
                websave([target file_bia '.gz'] , ['http://www.ppp-wizard.net/products/REAL_TIME/' file_bia '.gz']);
            catch
                error('%s%s%s\n','Correction stream file ',file_bia,' not found!');
            end
        end
        if ~( exist([target file_obx],'file'))
            try
                websave([target file_obx '.gz'] , ['http://www.ppp-wizard.net/products/REAL_TIME/' file_obx '.gz']);
            catch
                error('%s%s%s\n','Correction stream file ',file_obx,' not found!');
            end
        end
        files = {[file_sp3 '.gz']
            [file_clk '.gz']
            [file_bia '.gz']
            [file_obx '.gz']};
        unzip_and_delete(files, targets);     % much faster than gunzip
        % orbit and clock handling like with "Precise Products" (sp3 and clk-file)
        settings.ORBCLK.file_sp3 = [target file_sp3];
        settings.ORBCLK.file_clk = [target file_clk];
        settings.ORBCLK.file_obx = [target file_obx];
        % use .bia-file
        settings.BIASES.code_file  = [target file_bia];
        settings.BIASES.phase_file = [target file_bia];
        
    case 'IGC01 Archive'
        targets = {target; target};
        host = 'https://cddis.nasa.gov';
        folders = repmat({['/archive/gnss/products/rtpp/' gpsweek]},2,1);
        files = {['igc' gpsweek dow '.sp3.Z'];
            ['igc' gpsweek dow '.clk.Z']};
        filestatus = get_cddis_data(host, folders, files, targets, true);
        if any(filestatus==0)
            errordlg(['No correction stream from ' settings.ORBCLK.CorrectionStream ' found on server. Please specify different source!'], 'Error');
        end
        % decompress
        for i = 1:2
            if filestatus(i) == 1   ||   filestatus(i) == 2
                unzip_and_delete(files(i), targets(i));
            end
            [~,files{i},~] = fileparts(files{i});   % remove the zip file extension
        end 
        % orbit and clock handling like with "Precise Products" (sp3 and clk-file)
        settings.ORBCLK.file_sp3 = [targets{1} '/' files{1}];
        settings.ORBCLK.file_clk = [targets{2} '/' files{2}];
        
end

% orbit and clock handling like with "Precise Products": sp3, clk
% (in case of CNES Archive the obx file is used depending on
% handles.checkbox_obx.Value)
settings.ORBCLK.bool_sp3 = true;
settings.ORBCLK.bool_clk = true;
settings.ORBCLK.bool_brdc = false;
settings.ORBCLK.bool_nav_multi = false;
settings.ORBCLK.bool_nav_single = false;
settings.ORBCLK.corr2brdc_clk = false;
settings.ORBCLK.corr2brdc_orb = false;
settings.ORBCLK.file_corr2brdc = [];
% information for user that no navigation message is used
if ~settings.INPUT.bool_parfor
    fprintf('\nCorrection stream archive (*.sp3, *.clk,...): No broadcast navigation message is used\n');
end