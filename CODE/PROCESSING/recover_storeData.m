function [storeData, success] = recover_storeData(results_path)
% This function recovers/rebuilds the variable storeData from the data in
% the text files of results_float.txt and (potentially) results_fixed.txt
%
% INPUT:
%	results_path        string, path to results folder of processing
% OUTPUT:
%	storeData           struct, contains recovered fields (e.g., position)
%   success         boolean, true if loading was successful
% 
% Revision:
%   2025/08/07, MFWG: improving function (more generic)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| only the following data is read out from the text files:
%     coordinates, troposphere (estimation)

% initialize
success = false;



%% read settings_summary.txt
summary_path = results_path;
if ~isfile(summary_path);   summary_path = [summary_path '/settings_summary.txt'];   end

if isfile(summary_path)
    % open and read
    fid = fopen(summary_path);
    TXT = textscan(fid,'%s', 'delimiter','\n', 'whitespace','');
    TXT = TXT{1};
    fclose(fid);

    % detect number of estimated parameters
    bool_no_param = contains(TXT, 'Number of estimated parameters:');
    if any(bool_no_param)
        line_param = TXT{bool_no_param};
        idx = strfind(line_param, ':');
        storeData.NO_PARAM = str2double(line_param(idx+1:end));
    end
end


%% read out results of results_float/fixed.csv
[storeData_, success] = read_results_csv(results_path);
if success; storeData = storeData_; end


%% read out results of float solution from results file
floatpath_txt = [results_path '/results_float.txt'];
if ~success && isfile(floatpath_txt)
    storeData = recover_storeData_float(floatpath_txt, storeData);
end


%% read out results of fixed solution from text file
fixedpath_txt = [results_path '/results_fixed.txt'];
if ~success && isfile(fixedpath_txt)
    storeData = recover_storeData_fixed(fixedpath_txt, storeData);
end


success = true;

