% This function prints the changes of the satellite constellation into the
% command window
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

[FileName, PathName] = uigetfile({'*.mat'}, 'Select data4plot.mat', GetFullPath([Path.RESULTS]));
path_mat = [PathName FileName];

if ~ischar(FileName) || ~ischar(PathName)
    return
end

load(path_mat, 'satellites');

bool_obs = logical(full(satellites.obs));

n = size(bool_obs,1);
all_sats = 1:size(bool_obs,2);

% print satellites of first epoch
fprintf('\nEpoch %d:\n', 1)
fprintf('%g ',all_sats(bool_obs(1,:)))
fprintf('\n')


% loop over epochs
for i = 2:n
    % get satellite prns of last epoch
    last = bool_obs(i-1,:);
    prns_last = all_sats(last);
    % get satellite prns of current epoch
    now = bool_obs(i,:);
    prns_now = all_sats(now);
    
    
    % check if geometry has changed compare
    if ~isequal(prns_last, prns_now)
        new_sats  = setdiff(prns_now, prns_last);
        lost_sats = setdiff(prns_last, prns_now);

        % print
        if ~isempty(new_sats) || ~isempty(lost_sats)
            fprintf('\nEpoch %d:\n', i)
            if ~isempty(lost_sats)
                fprintf('(-): ')
                fprintf('%g ',lost_sats)
                fprintf('\n')
            end
            if ~isempty(new_sats)
                fprintf('(+): ')
                fprintf('%g ',new_sats)
                fprintf('\n')
            end
            
            
        end
    end
end