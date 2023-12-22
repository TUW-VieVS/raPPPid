function char = gnss2char(string_gnss)
% Function to convert between the GNSS name into the letter of this GNSS
% e.g. GPS -> G or Glonass -> R
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

switch string_gnss
    case 'GPS'
        char = 'G';
    case 'GLO'
        char = 'R';
    case 'Glonass'
        char = 'R';
    case 'GAL'
        char = 'E';
    case 'Galileo'
        char = 'E';
    case 'BDS'
        char = 'C';
    case 'BeiDou'
        char = 'C';
    case 'QZSS'
        char = 'J';      
    otherwise 
        char = [];
        errordlg('ERROR: gnss2char.m', 'Error');
end

end