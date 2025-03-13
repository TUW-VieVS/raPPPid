function iono = stec2iono(stec, f1, f2, f3)
% Convert the slant total electron content to the the ionospheric delay on 
% three frequencies (specified by f1, f2, f3)
% 
% INPUT:
%   stec        slant total electront content [TECU]
%   f1, f2, f3 	signal frequencies [Hz]      
% OUTPUT:
%	iono        (1x3), ionospheric delay on the three frequencies
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

iono(1) = 40.3e16/f1^2 * stec;
iono(2) = 40.3e16/f2^2 * stec;
iono(3) = 40.3e16/f3^2 * stec;