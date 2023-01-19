function number = gnss3_to_number(gnss3)
% Function to convert the name of the GNSS to the raPPPid hundred number
% e.g. GPS -> 0 or Galileo -> 200 or
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

switch gnss3
    case {'GPS', 'gps'}
        number = 0;
    case {'GLO', 'glo'}
        number = 100;
    case {'GAL', 'gal'}
        number = 200;
    case {'BDS', 'bds'}
        number = 300;
    otherwise 
        number = NaN;
        errordlg('ERROR: char2gnss3.m', 'Error');
end
