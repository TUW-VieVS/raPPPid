function [] = OpenObsFolder(varargin)
% Opens the observation data folder of raPPPid in Windows Explorer and 
% (optionally) a specific subfolder.
%
% INPUT:
%   []
% OUPUT:
%   []
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if ~contains(pwd, 'WORK')
    return
end

switch nargin
    case 0      % no input variables
        winopen([Path.DATA 'OBS'])
        
    case 1      % year as input variable
        year = varargin{1};
        yyyy = sprintf('%04d',year);
        try
            path = [Path.DATA 'OBS/' yyyy];
            winopen(path);
        catch
            fprintf(1,'This Data Folder does not exist!');
        end
        
    case 2      % year and doy as input variables
        year = varargin{1};
        yyyy = sprintf('%04d',year);
        day = varargin{2};
        doy = sprintf('%03d',day);
        try
            path = [Path.DATA 'OBS/' yyyy '/' doy];
            winopen(path);
        catch
            fprintf(1,'This Data Folder does not exist!');
        end

    otherwise
        return
        
end

