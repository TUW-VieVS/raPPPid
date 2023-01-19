function gnss_number = char2gnss_number(char)
% Function to convert the letter of a GNSS to its hundred number
% e.g. G -> 0 or Glonass -> 100
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

switch char
    case {'G', 'g'}
        gnss_number = 0;
    case {'R', 'r'}
        gnss_number = 100;
    case {'E', 'e'}
        gnss_number = 200;
    case {'C', 'c'}
        gnss_number = 300;
    otherwise 
        gnss_number = NaN;
end
