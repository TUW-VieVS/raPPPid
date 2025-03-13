function [] = OpenDataFolder(varargin)
% Opens the data folder of raPPPid in Windows Explorer and (optionally) a
% specific subfolder.
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
        OpenFolder(Path.DATA);
        
    case 1      % data-folder as input variable
        folder = varargin{1};
        try
            OpenFolder([Path.DATA '/' folder]);
        catch
            fprintf(1,'This Data Folder does not exist!');
        end
        
    case 2      % data-folder and year as input variables
        folder = varargin{1};
        year = varargin{2};
        yyyy = sprintf('%04d',year);
        try
            OpenFolder([Path.DATA '/' folder '/' yyyy]);
        catch
            fprintf(1,'This Data Folder does not exist!');
        end
        
    case 3      % data-folder, year and doy as input variables
        folder = varargin{1};
        year = varargin{2};
        doy  = varargin{3};
        yyyy = sprintf('%04d',year);
        ddd  = sprintf('%03d',doy);
        try
            OpenFolder([Path.DATA '/' folder '/' yyyy '/' ddd]);
        catch
            fprintf('This Data Folder does not exist!\n');
        end
    otherwise
        return
        
end

