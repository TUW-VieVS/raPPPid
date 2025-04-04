function tt = check_t(t)
% Repairs over- and underflow of GPS time
% 
% INPUT
% 	t       time in seconds of week
% OUPUT:
% 	tt      repaired time
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| check if necessary at all!

half_week = 302400;
tt = t;

if t >  half_week
    tt = t-2*half_week; 
end
if t < -half_week
    tt = t+2*half_week;
end

