function IMUDATA = readIMUcsv(filepath)
% Reads IMU data from a CSV file into a struct.
%
% INPUT:
%   filepath        string, file path to CSV file
% OUTPUT:
%	IMUDATA         ...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% Create import options from the file header (fast and flexible)
opts = detectImportOptions(filepath, 'NumHeaderLines', 0);

% Read numeric data (readmatrix uses opts when passed)
try
    numericData = readmatrix(filepath, opts);
catch
    % Fall back to readtable if readmatrix+opts not available on this MATLAB
    T = readtable(filepath, opts);
    tmpStruct = table2struct(T, 'ToScalar', true);
    IMUDATA = selectAndRenameFields(tmpStruct);
    return
end

% Get variable names from options
varNames = opts.VariableNames;

% If readmatrix returns a vector for single-column case, ensure it's a column
if isvector(numericData) && isscalar(varNames)
    numericData = numericData(:);
end

% If numericData has fewer columns than varNames (some nonnumeric columns),
% fall back to readtable to preserve nonnumeric columns.
if size(numericData,2) < numel(varNames)
    T = readtable(filepath, opts);
    tmpStruct = table2struct(T, 'ToScalar', true);
    IMUDATA = selectAndRenameFields(tmpStruct);
    return
end

% Desired fields (lowercase)
desired = {'pitch','roll','yaw','timestamp'};

% Create scalar struct and assign only desired fields (use the header names)
IMUDATA = struct();
for k = 1:numel(varNames)
    % Clean field name to be valid MATLAB identifier
    fname = matlab.lang.makeValidName(varNames{k});
    % Remove any leading prefix up to the first underscore (if present)
    % e.g. 'riegl_pof_latitude' -> 'latitude'
    unders = regexp(fname, '_');
    if ~isempty(unders)
        fname = fname(unders(end)+1:end);
    end
    % Use lowercase comparison to match desired list
    fnameKey = lower(fname);
    if any(strcmp(fnameKey, desired))
        IMUDATA.(fnameKey) = numericData(:, k);
    end
end

end




% Local helper to rename/select fields when starting from a struct (table fallback)
function out = selectAndRenameFields(in)
    desired = {'pitch','roll','yaw','timestamp'};
    out = struct();
    fnames = fieldnames(in);
    for i = 1:numel(fnames)
        fname = matlab.lang.makeValidName(fnames{i});
        % remove any leading prefix up to first underscore
        unders = regexp(fname, '_', 'once');
        if ~isempty(unders)
            fname = fname(unders+1:end);
        end
        key = lower(fname);
        if any(strcmp(key, desired))
            out.(key) = in.(fnames{i});
        end
    end
end