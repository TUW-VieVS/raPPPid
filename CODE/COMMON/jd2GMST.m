function GMST = jd2GMST(jd)
% Calculate the approximate Greenwich mean sidereal time from a specific 
% julian date.
% 
% adapted from: 
% Darin Koblick (2023). Julian Date to Greenwich Mean Sidereal Time 
% (https://www.mathworks.com/matlabcentral/fileexchange/28176-julian-date-to-greenwich-mean-sidereal-time), 
% MATLAB Central File Exchange. Retrieved July 26, 2023.
% 
% INPUT:
%   jd          julian date
% OUTPUT:
%	GMST        Greenwich mean sidereal time, [rad]
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% find the Julian Date of the previous midnight, jd0
jd_min = floor(jd) - 0.5;
jd_max = floor(jd) + 0.5;
jd0(jd > jd_min) = jd_min(jd > jd_min);
jd0(jd > jd_max) = jd_max(jd > jd_max);

H = (jd - jd0) * 24;            % time since previous midnight, [h]
D  = jd - 2451545.0;            % number of days since J2000 (current jd)
D0 = jd0 - 2451545.0;           % number of days since J2000 (previous midnight)
T = D / 36525;                  % number of centuries since J2000 (current jd)

% calculate GMST in hours (0h to 24h) and convert to radians
GMST = mod(6.697374558 + 0.06570982441908.*D0  + 1.00273790935.*H + ...
    0.000026.*(T.^2),24); 	% [h]
GMST = GMST / 12 * pi;      % convert to [rad]