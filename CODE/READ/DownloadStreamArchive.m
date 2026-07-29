function [settings] = DownloadStreamArchive(settings, gpsweek, dow, yyyy, mm, doy)
% This function downloads the selected archived stream and manipulates
% settings in a way that the processing works with the file-formats.
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
[~, ~] = mkdir(target);

% files are not small and servers are slow -> increase timeout
woptions = weboptions;
woptions.Timeout = 60;      % use 60s (usually 5s is the default value)

switch settings.ORBCLK.CorrectionStream

    case 'CNES Archive'
        file_sp3 = ['cnt' gpsweek dow '.sp3'];
        file_clk = ['cnt' gpsweek dow '.clk'];
        file_bia = ['cnt' gpsweek dow '.bia'];
        file_obx = ['cnt' gpsweek dow '.obx'];      % since 2054/2
        % backup file names (downloaded first, before falling back to regular file)
        file_sp3_backup = ['cnt' gpsweek dow '_backup.sp3'];
        file_clk_backup = ['cnt' gpsweek dow '_backup.clk'];
        file_bia_backup = ['cnt' gpsweek dow '_backup.bia'];
        file_obx_backup = ['cnt' gpsweek dow '_backup.obx'];

        % type, regular file name, backup file name - same handling for all 4 files
        file_types   = {'sp3', 'clk', 'bia', 'obx'};
        file_names   = {file_sp3,        file_clk,        file_bia,        file_obx};
        file_backups = {file_sp3_backup, file_clk_backup, file_bia_backup, file_obx_backup};

        files   = {};       % archives that still need to be downloaded and unzipped
        targets = {};
        avail_file = struct();     % path to the available (decompressed) file for each type

        for i = 1:numel(file_names)
            type        = file_types{i};
            file        = file_names{i};
            file_backup = file_backups{i};
            avail_regular = exist([target file],'file') || exist([target file '.mat'],'file');
            avail_backup  = exist([target file_backup],'file') || exist([target file_backup '.mat'],'file');
            if avail_regular
                avail_file.(type) = [target file];
            elseif avail_backup
                avail_file.(type) = [target file_backup];
            else        % neither regular nor backup file available -> download
                try         % try backup source first
                    websave([target file_backup '.gz'] , ['http://www.ppp-wizard.net/products/REAL_TIME/' file_backup '.gz']);
                    downloaded = file_backup;
                catch
                    try     % fallback: regular source
                        websave([target file '.gz'] , ['http://www.ppp-wizard.net/products/REAL_TIME/' file '.gz']);
                        downloaded = file;
                    catch
                        error('%s%s%s\n','Correction stream file ',file,' not found!');
                    end
                end
                files{end+1,1}     = [downloaded '.gz'];   %#ok<AGROW>
                targets{end+1,1}   = target;               %#ok<AGROW>
                avail_file.(type)  = [target downloaded];
            end
        end

        unzip_and_delete(files, targets);     % much faster than gunzip
        % orbit and clock handling like with "Precise Products" (sp3 and clk-file)
        settings.ORBCLK.file_sp3 = avail_file.sp3;
        settings.ORBCLK.file_clk = avail_file.clk;
        settings.ORBCLK.file_obx = avail_file.obx;
        % use .bia-file
        settings.BIASES.code_file  = avail_file.bia;
        settings.BIASES.phase_file = avail_file.bia;

    case 'IGC01 Archive'
        % only available until GPS week 2279 (as of July 20, 2026)
        targets = {target; target};
        host = 'https://cddis.nasa.gov';
        folders = repmat({['/archive/gnss/products/rtpp/' gpsweek]},2,1);
        files = {['igc' gpsweek dow '.sp3.Z'];
            ['igc' gpsweek dow '.clk.Z']};
        filestatus = get_cddis_data(host, folders, files, targets, true);
        if any(filestatus==0)
            errordlg(['No correction stream from ' settings.ORBCLK.CorrectionStream ' found on server. Please specify different source!'], 'Error');
            return
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

    case 'CAS Archive'
        % from the data center of the Chinese Academy of Sciences (CAS)
        % CAS changed their AC/product code from "CAS0MGXRTS" to
        % "CAS1IGSRTS" at the start of 2026; new naming is tried first,
        % old naming kept as a fallback for older dates.
        httpserver = ['https://data.bdsmart.cn/pub/product/rts/rtpp/' yyyy];
        dcmpr_clk_new = ['CAS1IGSRTS_' yyyy doy '0000_01D_30S_CLK.CLK'];
        dcmpr_bia_new = ['CAS1IGSRTS_' yyyy doy '0000_01D_01D_OSB.BIA'];
        dcmpr_sp3_new = ['CAS1IGSRTS_' yyyy doy '0000_01D_01M_ORB.SP3'];
        dcmpr_clk_old = ['CAS0MGXRTS_' yyyy doy '0000_01D_30S_CLK.CLK'];
        dcmpr_bia_old = ['CAS0MGXRTS_' yyyy doy '0000_01D_01D_OSB.BIA'];
        dcmpr_sp3_old = ['CAS0MGXRTS_' yyyy doy '0000_01D_01M_ORB.SP3'];

        % orbit: try new naming/01M interval first, old naming next, 05M
        % (even older interval convention) as final fallback
        [file_sp3, dcmpr_sp3] = get_cas_archive(target, httpserver, {dcmpr_sp3_new, dcmpr_sp3_old}, woptions);
        if isempty(file_sp3) && ~isfile([target dcmpr_sp3]) && ~isfile([target dcmpr_sp3 '.mat'])
            dcmpr_sp3_05m = ['CAS0MGXRTS_' yyyy doy '0000_01D_05M_ORB.SP3'];
            [file_sp3, dcmpr_sp3] = get_cas_archive(target, httpserver, {dcmpr_sp3_05m}, woptions);
        end
        [file_clk, dcmpr_clk] = get_cas_archive(target, httpserver, {dcmpr_clk_new, dcmpr_clk_old}, woptions);
        [file_bia, dcmpr_bia] = get_cas_archive(target, httpserver, {dcmpr_bia_new, dcmpr_bia_old}, woptions);
        % fallback names in case nothing could be found/downloaded, so that
        % the existence checks below can still produce their error dialogs
        if isempty(file_sp3); file_sp3 = [dcmpr_sp3 '.gz']; end
        if isempty(file_clk); file_clk = [dcmpr_clk '.gz']; end
        if isempty(file_bia); file_bia = [dcmpr_bia '.gz']; end
        % unzip if download was successful
        sp3_file_path = unzip_and_delete({file_sp3}, {target});
        clk_file_path = unzip_and_delete({file_clk}, {target});
        bia_file_path = unzip_and_delete({file_bia}, {target});
        % check existence
        if ~isfile(sp3_file_path)
            errordlg({'No CAS real-time orbits found in archive.', 'Please do not use!'}, 'Error');
        end
        if ~isfile(clk_file_path) && ~isfile([clk_file_path{1} '.mat'])
            errordlg({'No CAS real-time clocks found in archive.', 'Please do not use!'}, 'Error');
        end
        if ~isfile(bia_file_path) && ~isfile([bia_file_path{1} '.mat'])
            errordlg({'No CAS real-time biases found in archive.', 'Please do not use!'}, 'Error');
        end
        % orbit and clock handling like with "Precise Products" (sp3 and clk-file)
        settings.ORBCLK.file_sp3 = sp3_file_path{1};
        settings.ORBCLK.file_clk = clk_file_path{1};
        % use .bia-file
        settings.BIASES.code_file  = [target dcmpr_bia];
        settings.BIASES.phase_file = [target dcmpr_bia];

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



function [archive, dcmpr_matched] = get_cas_archive(target, httpserver, dcmpr_names, woptions)
% Makes sure the compressed CAS real-time archive for one of dcmpr_names
% (candidate decompressed file names without their archive extension,
% e.g. an .sp3/.clk/.bia file under both the new and old AC/product code)
% is available in target, downloading it if necessary. Candidates are
% tried in order. CAS has used both '.gz' and '.GZ' as the archive
% extension over time (switched to lowercase around end of 2025), so
% '.gz' is tried first, '.GZ' as fallback, for each candidate name.
% Returns the name of the (still compressed) archive file that is
% available (archive = '' if the decompressed file is already there or
% nothing could be found/downloaded), and which candidate name matched
% (dcmpr_matched = the first/primary candidate if none worked, so callers
% can still build a sensible path for their own error messages).
if ischar(dcmpr_names); dcmpr_names = {dcmpr_names}; end
archive = '';
for n = 1:numel(dcmpr_names)
    dcmpr_name = dcmpr_names{n};
    dcmpr_matched = dcmpr_name;
    if isfile([target dcmpr_name]) || isfile([target dcmpr_name '.mat'])
        return      % decompressed file already available, no archive needed
    end
    for ext = {'.gz', '.GZ'}
        candidate = [dcmpr_name ext{1}];
        if isfile([target candidate])
            archive = candidate;
            return
        end
        try
            websave([target candidate], [httpserver '/' candidate], woptions);
            archive = candidate;
            return
        catch
        end
    end
end
dcmpr_matched = dcmpr_names{1};