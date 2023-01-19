function Epoch = multipath_articifial(Epoch, use_column)
% function to create an artificial Cycle-Slip in a specific epoch and for a
% specific satellite
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% ||| not up-to-date!!!!! 


mp_on = false;

if mp_on
    mp_start = 200;             	% [epoch]
    mp_lgth = 10;                 	% [epochs]
    mp_ende = mp_start + mp_lgth;	% [epoch]
    mp_size = 2;                 	% [m]
    cs_sat_i  = 01;                 % epoch satellite index of affected satellite
    if Epoch.q >= mp_start && Epoch.q <= mp_ende
        Epoch.C1(cs_sat_i,1) = Epoch.C1(cs_sat_i,1) + mp_size;
    end
end


