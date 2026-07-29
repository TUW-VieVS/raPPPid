function settings = BatchProcessingPreparation(settings, ROW)
% This function prepares the use of PPP_main.m for the one row of batch
% processing.
%
% INPUT:
%	settings    struct, settings for processing from GUI
%   ROW       	cell, current row of batch processing table
% OUTPUT:
%	settings    struct, updated for current row of batch processing
%
% Revision:
%   2023/11/15, MFWG: considering QZSS (not implemented for batch processing)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% QZSS is not implemented for batch processing: hardcode some settings because 
settings.INPUT.use_QZSS = false;
settings.INPUT.qzss_freq = {'OFF'; 'OFF'; 'OFF'};
settings.INPUT.qzss_freq_idx = [5; 5; 5];
settings.INPUT.qzss_ranking = DEF.RANKING_QZSS;


% check which GNSS are enabled
bool_GPS = ROW{ 3};
bool_GLO = ROW{ 6};
bool_GAL = ROW{ 9};
bool_BDS = ROW{12};

% check frequency setting of each GNSS for current row
for i = 4:3:13
    % replace "," with ";" because otherwise processing fails
    ROW{i} = strrep(ROW{i}, ',', ';');
    % make sure that last char of frequency string is a ';' otherwise it is
    % possible that the algorithm fails
    if ~isempty(ROW{i}) && ~strcmp(ROW{i}(end), ';')
        ROW{i}(end+1) = ';';
    end
end

% convert frequencies from strings into numbers
gps_freq = split(ROW{ 4}, ';');     % split frequencies with ';'
glo_freq = split(ROW{ 7}, ';');
gal_freq = split(ROW{10}, ';');
bds_freq = split(ROW{13}, ';');
% make sure that gnss_freq contains 3 elements after split
if length(gps_freq) > 3
    gps_freq = gps_freq(1:3);       % first three frequencies are taken
elseif length(gps_freq) == 2
    gps_freq{3} = '';
end
if length(glo_freq) > 3
    glo_freq = glo_freq(1:3);
elseif length(glo_freq) == 2
    glo_freq{3} = '';
end
if length(gal_freq) > 3
    gal_freq = gal_freq(1:3);
elseif length(gal_freq) == 2
    gal_freq{3} = '';
end
if length(bds_freq) > 3
    bds_freq = bds_freq(1:3);
elseif length(bds_freq) == 2
    bds_freq{3} = '';
end

% set all empty frequencies to 'OFF'
ind = cellfun(@isempty,gps_freq);
if bool_GPS && length(ind) == 3
    gps_freq(ind) = {'OFF'};
else
    gps_freq = {'OFF';'OFF';'OFF'};
end
ind = cellfun(@isempty,glo_freq);
if bool_GLO && length(ind) == 3
    glo_freq(ind) = {'OFF'};
else
    glo_freq = {'OFF';'OFF';'OFF'};
end
ind = cellfun(@isempty,gal_freq);
if bool_GAL && length(ind) == 3
    gal_freq(ind) = {'OFF'};
else
    gal_freq = {'OFF';'OFF';'OFF'};
end
ind = cellfun(@isempty,bds_freq);
if bool_BDS && length(ind) == 3
    bds_freq(ind) = {'OFF'};
else
    bds_freq = {'OFF';'OFF';'OFF'};
end

% manipulate settings for current row
settings.INPUT.file_obs     = [ROW{1}, ROW{2}];
settings.INPUT.use_GPS      =  bool_GPS;
settings.INPUT.use_GLO      =  bool_GLO;
settings.INPUT.use_GAL      =  bool_GAL;
settings.INPUT.use_BDS      =  bool_BDS;
settings.INPUT.gps_freq     =  gps_freq;
settings.INPUT.glo_freq     =  glo_freq;
settings.INPUT.gal_freq     =  gal_freq;
settings.INPUT.bds_freq     =  bds_freq;
[~, settings.INPUT.gps_freq_idx] = ismember(settings.INPUT.gps_freq, DEF.freq_GPS_names);
[~, settings.INPUT.glo_freq_idx] = ismember(settings.INPUT.glo_freq, DEF.freq_GLO_names);
[~, settings.INPUT.gal_freq_idx] = ismember(settings.INPUT.gal_freq, DEF.freq_GAL_names);
[~, settings.INPUT.bds_freq_idx] = ismember(settings.INPUT.bds_freq, DEF.freq_BDS_names);
settings.INPUT.gps_ranking  =  ROW{ 5};
settings.INPUT.glo_ranking  =  ROW{ 8};
settings.INPUT.gal_ranking  =  ROW{11};
settings.INPUT.bds_ranking  =  ROW{14};
settings.PROC.timeFrame     = [ROW{15}, ROW{16}];
settings.PROC.timeSpan_format_epochs = true;
settings.PROC.timeSpan_format_SOD = false;
settings.PROC.timeSpan_format_HOD = false;
settings.PROC.name = replacePseudoCode(settings, settings.PROC.name_GUI, true);