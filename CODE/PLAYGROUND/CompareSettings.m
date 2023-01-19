function [] = CompareSettings()
% This function compares the settings of one processing with the settings 
% of one or multiple other processings. Differences in the settings are 
% printed in the Command window. Requires no input as the *.mat-files are 
% selected manually.
% 
% INPUT:
%	[]              
% OUTPUT:
%	...
%
% Revision:
%   ...
%
%*************************************************************************


% ||| comparison is not complete!!! check before using


startfolder = Path.RESULTS;
[FileName, PathName] = uigetfile('*.mat','Select the settings.mat for comparison', startfolder);
if ~FileName            % uigetfile cancelled
    return;
end
load([PathName, FileName], 'settings');
CompSetts = settings;
fprintf(relativepath(PathName)); fprintf( '\n\n');

% loop to compare multiple settings
while true      
    PathName = uigetdir(startfolder, 'Select folder(s) to compare settings');
    if PathName == 0
        return       % no files selected, stopp adding files in table
    end
    [startfolder,~,~] = fileparts(PathName);    % to start next selection in the same folder
    % search all settings.mat
    AllFiles = dir([PathName '\**\settings.mat']);     % get all data4plot.files in folder and subfolders
    n = length(AllFiles);
    for i = 1:n         % loop over all detected data4plot.mat-files to load date and stationname
        % load in current file
        path_folder = AllFiles(i).folder;
        path_data4plot = [path_folder '/settings.mat'];
        load(path_data4plot, 'settings')
    end
    % compare settings
    CompSetts = compare(CompSetts, settings, relativepath(path_folder));
end



function CompSetts = compare(CompSetts, setts, proc_path)
% Compare all variables

% print processing which is compared
fprintf(proc_path); fprintf( '\n');

% INPUT
if strcmp(setts.INPUT.file_obs, CompSetts.INPUT.file_obs)
    fprintf('Different observation file.\n');
end
% ||| continue
% setts.INPUT.use_GPS, setts.INPUT.use_GLO, setts.INPUT.use_GAL, setts.INPUT.use_BDS
% setts.INPUT.gps_ranking, setts.INPUT.glo_ranking, setts.INPUT.gal_ranking, setts.INPUT.bds_ranking
% setts.INPUT.gps_freq_idx, setts.INPUT.glo_freq_idx, setts.INPUT.gal_freq_idx, setts.INPUT.bds_freq_idx

% ORBCLK

% BIASES


% TROPO


% IONO


% OTHER



% AMBFIX



% ADJ



% PROC


% PLOT



asdf