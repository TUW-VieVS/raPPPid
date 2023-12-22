function gnss_string3 = char2gnss3(char)
% Function to convert between the letter of a GNSS into the name of this
% GNSS
% e.g. GPS -> G or Glonass -> R
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

switch char
    case 'G'
        gnss_string3 = 'GPS';
    case 'R'
        gnss_string3 = 'GLO';
    case 'E'
        gnss_string3 = 'GAL';
    case 'C'
        gnss_string3 = 'BDS';
    case 'J'
        gnss_string3 = 'QZSS';        
    otherwise 
        gnss_string3 = [];
        errordlg('ERROR: char2gnss3.m', 'Error');
end
