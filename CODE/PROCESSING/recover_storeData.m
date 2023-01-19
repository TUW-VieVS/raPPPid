function storeData = recover_storeData(folderstring)
% This function recovers/rebuilds the variable storeData from the data in
% the text files of results_float.txt and (potentially) results_fixed.txt
%
% INPUT:
%	folderstring        string, path to results folder of processing
% OUTPUT:
%	storeData           struct, contains recoverable fields
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| only the following data is read out from the textfiles:
%       coordinates,

storeData = struct;
storeData.float_reset_epochs = 1;

%% read out results of float solution from textfile
floatpath = [folderstring '\results_float.txt'];
if isfile(floatpath)

    % --- read header ---
    fid = fopen(floatpath,'rt');     	% open observation-file
    header = true;
    l = 0;
    while header
        line = fgetl(fid);              % get next line
        l = l + 1;
        
        % reset epochs
        if contains(line, '# Reset of float solution in the following epochs:')
            resets = line(51:end);
            storeData.float_reset_epochs = str2num(resets);     % only str2num works
        end
        
        % end of header
        if strcmp(line, '#************************************************** ')
            header = false;
        end
        
    end
    fclose(fid);
    
    % --- read out all data
    fid = fopen(floatpath);
    D = textscan(fid,'%f','HeaderLines', l+1);  D = D{1};
    fclose(fid);
    
    % --- extract data
    % create indizes
    n = numel(D);
    idx_t = 3:33:n;                 % GPS time
    idx_x = 4:33:n;                 % estimated xyz coordinates
    idx_y = 5:33:n;
    idx_z = 6:33:n;
    idx_utm_x = 13:33:n;
    idx_utm_y = 14:33:n;
    idx_geo_h = 12:33:n;
    % ||| continue at some point
    
    % save GPS time
    storeData.gpstime = D(idx_t);
    % save estimated xyz coordinates
    storeData.param = [D(idx_x), D(idx_y), D(idx_z)];
    % save estimated UTM coordinates
    storeData.posFloat_utm = [D(idx_utm_x), D(idx_utm_y), D(idx_geo_h)];
    % recalculate time to last reset
    time_resets = storeData.gpstime(storeData.float_reset_epochs);
    dt_ = storeData.gpstime;
    r = numel(storeData.float_reset_epochs);            % number of resets
    for i = r: -1 : 1
        dt_(dt_ >= time_resets(i)) = dt_(dt_ >= time_resets(i)) - time_resets(i);
    end
    storeData.dt_last_reset = dt_;
end



%% read out results of fixed solution from textfile
fixedpath = [folderstring '\results_fixed.txt'];
if isfile(fixedpath)
    storeData.fixed_reset_epochs = 1;
    
    % --- read header ---
    fid = fopen(fixedpath,'rt');      	% open observation-file
    header = true;
    l = 0;
    while header
        line = fgetl(fid);              % get next line
        l = l + 1;
        
        % reset epochs
        if contains(line, '# Reset of fixed solution in the following epochs:')
            resets = line(51:end);
            storeData.fixed_reset_epochs = str2num(resets);     % only str2num works
        end
        
        % end of header
        if strcmp(line, '#************************************************** ')
            header = false;
        end
        
    end
    fclose(fid);
    
    % --- read out all data
    fid = fopen(fixedpath);
    D = textscan(fid,'%f','HeaderLines', l+1);  D = D{1};
    fclose(fid);
    
    % --- extract data
    % create indizes
    n = numel(D);
    idx_t = 3:14:n;                 % GPS time
    idx_x = 4:14:n;                 % estimated xyz coordinates
    idx_y = 5:14:n;
    idx_z = 6:14:n;
    idx_utm_x = 13:14:n;
    idx_utm_y = 14:14:n;
    idx_geo_h = 12:14:n;
    % ||| continue at some point
    
    % save estimated xyz coordinates
    storeData.xyz_fix = [D(idx_x), D(idx_y), D(idx_z)];
    % save estimated UTM coordinates
    storeData.posFixed_utm = [D(idx_utm_x), D(idx_utm_y), D(idx_geo_h)];
    % create storeData.fixed
    storeData.fixed = all(~isnan(storeData.param), 2) & all(storeData.param ~= 0, 2);
end



