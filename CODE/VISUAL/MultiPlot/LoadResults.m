function [storeData, obs, success] = LoadResults(folderpath, n, label)
% This function tries to read (at least partly) the variables storeData and
% obs from the result folder of a raPPPid processing.
%
% INPUT:
%   folderpath      string, path to folder containing processing results
%   n               number of file
%   label           string, label of Multi-Plot
% OUTPUT:
%	storeData       struct, results of processing
%   obs             struct, observation-specific information
%   success         boolean, true if loading was successful
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


success = false;        % initialize


% rebuild obs from settings_summary.txt
obs = recover_obs(folderpath);


% load storeData from text files
[storeData, success] = recover_storeData(folderpath);   % e.g., no data4plot.mat file


if ~success
    try
        % load from data4plot.mat (very complete, but slow)
        fpath_data4plot = GetFullPath([folderpath 'data4plot.mat']);
        load(fpath_data4plot, 'storeData', 'obs');      %  variables not used: 'satellites', 'settings', 'model_save'
        if isempty(storeData); storeData = recover_storeData(folderpath); end
        if isempty(obs); obs = recover_obs(folderpath); end
    catch
        success = false;
        errordlg({['Loading File #' sprintf('%d',n) ' of label ' ], [label ' failed!']}, 'Error')
    end
end