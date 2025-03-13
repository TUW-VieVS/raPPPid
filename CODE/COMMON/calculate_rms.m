function rms_calc = calculate_rms(vec)
% Calculate root mean square. This implementation avoids Toolbox
% Dependencies
% 
% INPUT:
%   vec         vector 
% OUTPUT:
%	rms_calc    rms of vec
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

vec = vec(vec~=0 & ~isnan(vec));        % ignore zeros and NaNs
rms_calc = sqrt(mean(vec.*vec));
