function [] = printSatelliteStatus(Epoch)
% Prints the status of all current satellites to the command window to
% easily understand the current satellite constellation.
%
% INPUT:
%   Epoch       struct, containing epoch-specific data
% OUTPUT:
%	...         output is printed to the command window
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



sats = Epoch.sats;      % prn numbers of satellites
n = numel(sats);        % number of satellites in current epoch
frq = size(Epoch.sat_status,2);   % number of frequencies

% print current epoch
fprintf(['Epoch ' '%d' '\n'], Epoch.q);

% loop over satellites to print to command window
for i = 1:n
    
    string_status = '';
    
    for j = 1:frq
        % get status and prn of current satellite
        status = Epoch.sat_status(i,j);
        prn = sats(i);
        
        % determine status of current satellite
        switch status
            case 0
                str_add = 'not observed';
            case 1
                str_add = 'healthy';
            case 2
                str_add = 'below cutoff angle';
            case 3
                str_add = 'cycle slip detected';
            case 4
                str_add = 'multipath detected';
            case 5
                str_add = 'no satellite clock';
            case 6
                str_add = 'no satellite orbit';
            case 7
                str_add = 'below C/N0 threshold';
            case 8
                str_add = 'SSR digit too low';
            case 9
                str_add = '';
            case 10
                str_add = 'not fixable';
            case 11
                str_add = 'omc check positive';
            case 12
                str_add = 'excluded in GUI';
            case 13
                str_add = 'eclipsing';
            case 14
                str_add = 'on multipath cooldown';
            case 15
                str_add = 'no BRDC ephemeris';
            case 16
                str_add = 'faulty code observations';                
            otherwise
                str_add = '';
        end
        
        string_status = [string_status str_add ' | '];
        
    end
    % get char of gnss from prn number
    if prn < 100
        gnsschar = 'G';
    elseif prn < 200
        gnsschar = 'R';
    elseif prn < 300
        gnsschar = 'E';
    elseif prn < 400
        gnsschar = 'C';
    elseif prn < 500
        gnsschar = 'J';
    end
    
    % print info to command window
    fprintf( [gnsschar '%02d' ': '], mod(prn, 100));
    fprintf([string_status '\n']);
    
end

fprintf('\n');