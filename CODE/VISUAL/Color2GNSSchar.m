function char = Color2GNSSchar(rgb)
% This functions converts the rgb value to the char of the GNSS where
% raPPPid GNSS colors are assumed (GPS = red, Glonas = cyan, Galileo =
% blue, BeiDou = magenta)
%
% INPUT:
%	rgb     rgb value
% OUTPUT:
%	char    GNSS char (e.g. 'G' or 'E')
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



if isequal(rgb, [1 0 0])            % GPS
    char = 'G';
elseif isequal(rgb, [0.5 0.0 0.5]) 	% Glonass
    char = 'R';
elseif isequal(rgb, [0 0 1])        % Galileo
    char = 'E';
elseif isequal(rgb, [0 1 1])        % BeiDou
    char = 'C';
elseif isequal(rgb, [1 .65 0])      % GPS L5
    char = 'G';
else
    char = '';
    
end
