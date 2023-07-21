function formatSpec = createRawFormat(raw_variables)
% This function determines the data format for textscan when reading the
% raw GNSS data from Android smartphones
% 
% INPUT:
%   ...
% OUTPUT:
%	...
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


m = numel(raw_variables);   % number of variables

formatSpec='';      % initialize

% loop over all variables to determine the data format for textscan
for i = 1:m
    switch raw_variables{i}
        
        case {'TimeNanos', 'FullBiasNanos', 'ReceivedSvTimeNanos', 'ReceivedSvTimeUncertaintyNanos', ...
                'CarrierCycles', 'allRxMillis', 'BiasNanos', 'TimeOffsetNanos'}
            % big number -> int64
            formatSpec = sprintf('%s %%d64', formatSpec);
            
        case {'Raw', 'CodeType'}
            % string
            formatSpec = strcat(formatSpec, ' %s');
            
        otherwise
            % everything else as double
            formatSpec = sprintf('%s %%f', formatSpec);
            
    end
end