function TABLE_use = GetTableData(TABLE, c1, c2, c3, c4)
% This function gets the data from the Multi-Plot-Table and prepares it for
% plotting.
% 
% INPUT:
%	TABLE           cell, table from GUI   
%   c1              column which is used to check for empty rows
%   c2              column which indicates which rows should be used
%   c3              column which is used to check for identical rows
%   c4              column of file-paths, checked if valid
% OUTPUT:
%	TABLE_use       cell, prepared for plotting
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% remove empty rows
if ~isempty(c1)
    bool_empty = cellfun('isempty', TABLE(:,c1));
    TABLE_use = TABLE(~bool_empty, :);          % remove empty rows
end


% remove rows which should not be used
if ~isempty(c2)
    bool_use = cell2mat(TABLE_use(:,c2));   	% logical vector which rows should be used for plotting
    bool_use = any(bool_use, 2);                % if multiple columns are checked
    TABLE_use(~bool_use,:) = [];
end


% remove identical rows
if ~isempty(c3)
    switch numel(c3)
        case 1
            paths = TABLE_use(:,c3);
            [~, keep, ~] = unique(paths, 'stable');     % do not change order
            TABLE_use = TABLE_use(keep,:);              % keep only unique rows
        case 2
            paths  = TABLE_use(:,c3(1));
            labels = TABLE_use(:,c3(2));
            pathslabels = strcat(paths, labels);        % check combination of e.g. paths and labels
            [~, keep, ~] = unique(pathslabels, 'stable');     % do not change order
            TABLE_use = TABLE_use(keep,:);              % keep only unique rows
    end

end


% check if all file-paths are valid
if ~isempty(c4) 
    if numel(c4) == 1
        paths = TABLE_use(:,c4);
    elseif numel(c4) == 2
        folders = TABLE_use(:,c4(1));
        files = TABLE_use(:,c4(2));
        paths = strcat(folders, files);
    end
    keep = logical(cellfun(@exist, paths));
    TABLE_use = TABLE_use(keep,:);              % keep only rows with existing file-path
end