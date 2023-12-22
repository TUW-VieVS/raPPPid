function gnss_string = char2gnss(char)
% Function to convert between the letter of a GNSS into the name of this
% GNSS
% e.g. GPS -> G or Glonass -> R
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

switch char
    case 'G'
        gnss_string = 'GPS';
    case 'R'
        gnss_string = 'Glonass';
    case 'E'
        gnss_string = 'Galileo';
    case 'C'
        gnss_string = 'BeiDou';
    case 'J'
        gnss_string = 'QZSS';       
    case 'I'
        gnss_string = 'NavIC';       
    otherwise 
        gnss_string = '';
end
