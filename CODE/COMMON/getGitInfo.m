function info = getGitInfo()

% Retrieves git version information of the raPPPid repository so that the
% exact code state used for a processing run can be recovered later. Works
% independently of MATLAB's current working directory, which is why it also
% works during batch processing (the previous approach called git relative
% to pwd and therefore failed for batch runs).
%
% Two strategies are used:
%   1) the git executable, queried with "git -C <repo>" so it always looks
%      at the raPPPid repository regardless of pwd. This also yields the
%      branch, the commit date and whether the working tree is dirty
%      (uncommitted changes -> results not exactly reproducible).
%   2) if the git executable is not available (e.g. git not installed, or
%      raPPPid downloaded as a zip with a .git folder but no git), the .git
%      folder is read directly from disk as a fallback.
%
% INPUT:
%   none
% OUTPUT:
%   info    struct with fields:
%             .hash     [string] full commit hash ('' if unknown)
%             .short    [string] abbreviated commit hash
%             .branch   [string] branch name ('' if unknown)
%             .date     [string] commit date ('' if unknown)
%             .dirty    [logical] true if uncommitted changes exist, [] if
%                                 this could not be determined
%             .summary  [string] one-line human readable description
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

info = struct('hash', '', 'short', '', 'branch', '', 'date', '', ...
    'dirty', [], 'summary', '');

% repo root = three levels up from this file: CODE/COMMON/getGitInfo.m
repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));

% --- strategy 1: the git executable (most information) -------------------
gitcmd = sprintf('git -C "%s" ', repo_root);
[status, hash] = system([gitcmd 'rev-parse HEAD']);
if status == 0 && ~isempty(strtrim(hash))
    info.hash = strtrim(hash);
    [~, br]   = system([gitcmd 'rev-parse --abbrev-ref HEAD']);
    info.branch = strtrim(br);
    [~, dt]   = system([gitcmd 'show -s --format=%ci HEAD']);
    info.date = strtrim(dt);
    [~, st]   = system([gitcmd 'status --porcelain --untracked-files=no']);
    info.dirty = ~isempty(strtrim(st));
else
    % --- strategy 2: read the .git folder directly ----------------------
    info = readGitFromDisk(repo_root, info);
end

if ~isempty(info.hash)
    info.short = info.hash(1:min(7, numel(info.hash)));
end
info.summary = buildSummary(info);
end



function info = readGitFromDisk(repo_root, info)
% Fallback that parses the .git folder without the git executable.
gitdir = fullfile(repo_root, '.git');
headfile = fullfile(gitdir, 'HEAD');
if exist(headfile, 'file') ~= 2
    return      % no git information available (e.g. plain zip download)
end
head = strtrim(fileread(headfile));

if startsWith(head, 'ref:')
    ref = strtrim(head(5:end));                         % e.g. refs/heads/master
    info.branch = regexprep(ref, '^refs/heads/', '');
    reffile = fullfile(gitdir, ref);
    if exist(reffile, 'file') == 2
        info.hash = strtrim(fileread(reffile));
    else
        % ref not stored loose -> look it up in packed-refs
        packed = fullfile(gitdir, 'packed-refs');
        if exist(packed, 'file') == 2
            lines = strsplit(fileread(packed), newline);
            for i = 1:numel(lines)
                parts = strsplit(strtrim(lines{i}));
                if numel(parts) == 2 && strcmp(parts{2}, ref)
                    info.hash = parts{1};
                    break
                end
            end
        end
    end
else
    info.hash = head;               % detached HEAD stores the hash directly
    info.branch = 'detached HEAD';
end
end



function str = buildSummary(info)
% Builds a compact one-line description from the collected fields.
if isempty(info.hash)
    str = 'git commit unknown';
    return
end
str = info.hash;
if ~isempty(info.branch)
    str = sprintf('%s (branch %s)', str, info.branch);
end
if islogical(info.dirty) && info.dirty
    str = [str ' + uncommitted changes'];
end
end
