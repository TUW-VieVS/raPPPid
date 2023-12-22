function [M] = RemoveMeanPerSatelliteArc(M)
% This function runs over the columns of a matrix and removes for each
% satellite arc the mean value. For example, this is useful to remove the 
% constant part of the MP LC before plotting
%
% INPUT:
%   M       matrix, epochs x satellites, e.g. MP LC
% OUTPUT:
%	M      	mean from each satellite arc removed
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************


% ||| jumps (e.g., due cycle slips) during a satellite arc are not detected


M(isnan(M)) = 0;        % replace zeros with NaN
n = size(M,2);          % number of columns

for i = 1:n             % loop over columns
    vec = M(:,i);           % value (e.g., MP LC) for current satellite
    if any(~isnan(vec) & vec~=0)
        mask = logical(vec');                       % force logical vector
        starts = strfind([false, mask], [0 1]);     % data begins
        stops = strfind([mask, false], [1 0]);      % data ends
        n = numel(starts);
        for ii = 1:n            % loop over data series of current satellite
            s1 = starts(ii);
            s2 = stops(ii);
            if s1 == s2
                % satellite is only observed for one epoch
                vec(s1) = 0;    % set value to zero
                continue        % skip removing the mean 
            end
            % ||| check for jumps during the satellite arc here
            vec(s1:s2) = vec(s1:s2) - mean(vec(s1:s2));     % remove mean for current data series
        end
        M(:,i) = vec;       % save values (e.g., MP LC) after mean was removed
    end
    
end