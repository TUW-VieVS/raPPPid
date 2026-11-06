function [] = CopyInputs2Folders()
% This function lets the user select a settings.mat file of raPPPid (for
% example from another raPPPid installation). All file-paths stored in the 
% struct "settings" are then checked and the corresponding input files are 
% copied into the DATA folder structure of the current raPPPid installation, 
% keeping the same subfolder structure (e.g. type, year, and day of year).
% Only files which do not already exist in the current raPPPid installation
% are copied, existing files are left untouched.
%
% A source file is searched for at the path stored in settings, in the DATA
% folder of the selected settings.mat, and in the folder of the selected
% settings.mat itself (the parsed '<file>.mat' variant is accepted, too).
%
% The selected settings.mat is additionally copied into RESULTS as
% 'settings_copied.mat' (an existing settings_copied.mat is replaced).
%
% INPUT:
%	[]
% OUTPUT:
%	[]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% check if current folder is the WORK folder (needed to resolve the
% raPPPid folder structure via the class Path)
if ~contains(pwd, 'WORK')
    errordlg('Change current folder to .../WORK', 'Error');
    return
end

% absolute paths of the folder structure of the current raPPPid installation
curr_DATA    = tidyPath(GetFullPath([pwd '/' Path.DATA]));
curr_RESULTS = tidyPath(GetFullPath([pwd '/' Path.RESULTS]));

% let the user select a settings.mat file (e.g. from another raPPPid installation)
[file, folder] = uigetfile('*.mat', ...
    'Select a raPPPid settings.mat file', GetFullPath([pwd '/' Path.RESULTS]));
if isnumeric(file)
    return          % selection aborted
end
settingspath = [folder file];

% try to locate the DATA folder of the raPPPid installation the selected
% settings.mat belongs to (needed to resolve relative file-paths and paths
% pointing to another installation)
other_DATA = findInstallationDATA(folder);

% load the struct 'settings' from the selected file
try
    S = load(settingspath, 'settings');
    settings = S.settings;
catch
    errordlg('Struct ''settings'' could not be loaded from the selected file.', 'Error');
    return
end
if ~isstruct(settings)
    errordlg('Selected *.mat file does not contain the struct ''settings''.', 'Error');
    return
end

% collect all char / string leaves of the struct 'settings'
allstrings = collectStrings(settings);
allstrings = unique(allstrings, 'stable');

% lists for the final report
list_copied  = {};      % files which were copied into the current DATA folder
list_exist   = {};      % files which already exist in the current DATA folder
list_skipped = {};      % files which exist but are located outside the DATA tree
list_failed  = {};      % files which could not be copied (source missing, copy error, ...)

for i = 1:numel(allstrings)
    src = tidyPath(allstrings{i});

    % consider only strings which look like a path to a file
    if ~contains(src, '/')
        continue
    end

    % a whole folder is referenced (e.g. IONEX folder)?
    srcdir = resolveFolder(src, relInsideDATA(src), other_DATA);
    if ~isempty(srcdir)
        [c, e, f] = copyFolderMissing(srcdir, curr_DATA);
        list_copied = [list_copied, c];
        list_exist  = [list_exist,  e];
        list_failed = [list_failed, f];
        continue
    end

    [~, ~, xt] = fileparts(src);
    if isempty(xt)              % no extension -> obviously not a file
        continue
    end

    % sub-path below the DATA folder; '' if not located inside a DATA folder
    rel = relInsideDATA(src);
    if isempty(rel)
        % file is referenced in settings but sits outside the DATA tree, so
        % there is no defined target subfolder -> report it if it exists
        src_out = resolveSource(src, '', '', folder);
        if ~isempty(src_out)
            list_skipped{end+1} = src_out; %#ok<AGROW>
        end
        continue
    end

    % find the source file: try the stored path and the DATA folder of the
    % selected settings.mat; raPPPid stores read-in files as '<file>.mat' and
    % deletes the original, so also accept the parsed '.mat' variant
    src_real = resolveSource(src, rel, other_DATA, folder);
    if isempty(src_real)
        list_failed{end+1} = [src '   (source file not found)']; %#ok<AGROW>
        continue
    end

    % target path inside the DATA folder structure of the current raPPPid
    target = tidyPath([curr_DATA '/' rel]);
    if endsWith(src_real, '.mat') && ~endsWith(src, '.mat')
        target = [target '.mat'];      % source only exists as parsed *.mat file
    end

    % copy only if the file does not already exist in the current raPPPid
    if exist(target, 'file') == 2
        list_exist{end+1} = target; %#ok<AGROW>
        continue
    end

    % create target (sub)folder and copy the file
    tdir = fileparts(target);
    [~, ~] = mkdir(tdir);
    [ok, msg] = copyfile(src_real, target);
    if ok
        list_copied{end+1} = target; %#ok<AGROW>
    else
        list_failed{end+1} = [src_real '   (' strtrim(msg) ')']; %#ok<AGROW>
    end
end


% copy the selected settings.mat into RESULTS as 'settings_copied.mat'
% (replacing an existing settings_copied.mat)
settings_copy = tidyPath([curr_RESULTS '/settings_copied.mat']);
[ok_sc, msg_sc] = copyfile(settingspath, settings_copy, 'f');
if ok_sc
    fprintf('\nselected settings.mat copied to %s\n', settings_copy);
else
    fprintf(2, '\nselected settings.mat could not be copied to RESULTS (%s)\n', strtrim(msg_sc));
end


%% print summary and success message

fprintf('\n*** CopyInputs2Folders summary ***\n');

fprintf('\n%d file(s) COPIED into the current DATA folder:\n', numel(list_copied));
for i = 1:numel(list_copied)
    fprintf('  %s\n', list_copied{i});
end

fprintf('\n%d file(s) ALREADY EXISTING (kept, not copied):\n', numel(list_exist));
for i = 1:numel(list_exist)
    fprintf('  %s\n', list_exist{i});
end

% print the "SKIPPED" part in red only if there actually are such files
fid_skipped = 1;                    % black (standard output)
if ~isempty(list_skipped)
    fid_skipped = 2;                % red (error output)
end
fprintf(fid_skipped, '\n%d file(s) SKIPPED (located outside the DATA tree, not copied):\n', numel(list_skipped));
for i = 1:numel(list_skipped)
    fprintf(2, '  %s\n', list_skipped{i});
end

% print the "NOT COPIED" header in red only if there actually are such files
fid_failed = 1;                     % black (standard output)
if ~isempty(list_failed)
    fid_failed = 2;                 % red (error output)
end
fprintf(fid_failed, '\n%d file(s) NOT COPIED:\n', numel(list_failed));
for i = 1:numel(list_failed)
    fprintf(2, '  %s\n', list_failed{i});
end
fprintf('\n');

msgbox('CopyInputs2Folders has finished.', 'Achievement', 'help')




function rel = relInsideDATA(src)
% Return the sub-path below the DATA folder (e.g. 'ORBIT/2025/301/xyz.SP3').
% The last path segment which is exactly 'DATA' marks the root of the
% raPPPid folder structure. Returns '' if the path is not inside a DATA folder.
rel = '';
parts = strsplit(tidyPath(src), '/');
idxD = find(strcmp(parts, 'DATA'), 1, 'last');
if ~isempty(idxD) && idxD < numel(parts)
    rel = strjoin(parts(idxD+1:end), '/');
end


function real = resolveSource(src, rel, other_DATA, settingsfolder)
% Find the source file which belongs to the stored path 'src' (with sub-path
% 'rel' below the DATA folder). Candidates, in order: the stored path itself,
% the DATA folder of the selected settings.mat, the folder of the selected
% settings.mat, and for all of them the parsed '<file>.mat' variant (raPPPid
% replaces read-in files with a *.mat file). Returns '' if no candidate exists.
cand = {src};
if ~isempty(rel) && ~isempty(other_DATA)
    cand{end+1} = tidyPath([other_DATA '/' rel]);
end
[~, nm, xt] = fileparts(src);
cand{end+1} = tidyPath([settingsfolder '/' nm xt]);
for k = 1:numel(cand)
    if exist(cand{k}, 'file') == 2
        real = cand{k};   return
    end
    if exist([cand{k} '.mat'], 'file') == 2
        real = [cand{k} '.mat'];   return
    end
end
real = '';


function d = resolveFolder(src, rel, other_DATA)
% Return an existing folder for the stored path 'src': either 'src' itself
% or - mapped via the sub-path 'rel' below DATA - the corresponding folder
% in the DATA folder of the selected settings.mat. '' if none exists.
d = '';
cand = {src};
if ~isempty(rel) && ~isempty(other_DATA)
    cand{end+1} = tidyPath([other_DATA '/' rel]);
end
for k = 1:numel(cand)
    if isfolder(cand{k})
        d = cand{k};   return
    end
end


function d = findInstallationDATA(startfolder)
% Walk upwards from 'startfolder' and return the first 'DATA' folder found
% next to one of the parent folders (i.e. the DATA folder of the raPPPid
% installation the selected settings.mat belongs to). '' if none is found.
d = '';
p = regexprep(tidyPath(startfolder), '/$', '');    % strip trailing slash
for k = 1:15
    if isfolder([p '/DATA'])
        d = tidyPath(GetFullPath([p '/DATA']));
        return
    end
    pp = fileparts(p);
    if isempty(pp) || strcmp(pp, p)
        break
    end
    p = pp;
end


function p = tidyPath(p)
% Normalize a file-path: backslashes to forward slashes and collapse
% repeated slashes (e.g. '.../301//COD...' -> '.../301/COD...').
if ~ischar(p) || isempty(p)
    p = '';
    return
end
p = strrep(p, '\', '/');
lead = '';
if strncmp(p, '//', 2)          % keep a leading '//' (UNC network path)
    lead = '//';   p = p(3:end);
end
p = regexprep(p, '/+', '/');
p = [lead p];


function [list_copied, list_exist, list_failed] = copyFolderMissing(srcdir, curr_DATA)
% Copy all files of a referenced folder (recursively) into the DATA folder
% structure of the current raPPPid installation, skipping files which already
% exist. Returns cell arrays with the target-paths for each category.
list_copied = {}; list_exist = {}; list_failed = {};
srcdir = tidyPath(srcdir);
list = dir(fullfile(srcdir, '**', '*'));
for j = 1:numel(list)
    if list(j).isdir
        continue
    end
    s = tidyPath(fullfile(list(j).folder, list(j).name));
    rel = relInsideDATA(s);
    if isempty(rel)
        continue        % file not located inside a DATA folder -> skip
    end
    t = tidyPath([curr_DATA '/' rel]);
    if exist(t, 'file') == 2 || exist([t '.mat'], 'file') == 2
        list_exist{end+1} = t; %#ok<AGROW>
        continue
    end
    tdir = fileparts(t);
    [~, ~] = mkdir(tdir);
    [ok, msg] = copyfile(s, t);
    if ok
        list_copied{end+1} = t; %#ok<AGROW>
    else
        list_failed{end+1} = [s '   (' strtrim(msg) ')']; %#ok<AGROW>
    end
end


function out = collectStrings(x)
% Recursively collect all non-empty char / string values contained in a
% variable (struct, cell, char, string) into a cell array of char.
out = {};
if ischar(x)
    if ~isempty(x)
        out = {x};
    end
elseif isstring(x)
    x = x(~ismissing(x));
    out = cellstr(x(:)');
elseif iscell(x)
    for k = 1:numel(x)
        out = [out, collectStrings(x{k})];
    end
elseif isstruct(x)
    f = fieldnames(x);
    for m = 1:numel(x)
        for k = 1:numel(f)
            out = [out, collectStrings(x(m).(f{k}))];
        end
    end
end
