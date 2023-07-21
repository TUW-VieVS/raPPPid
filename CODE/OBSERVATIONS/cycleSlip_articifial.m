function Epoch = cycleSlip_articifial(Epoch, use_column)
% function to create an artificial Cycle-Slip in a specific epoch and for
% a specific satellite
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ATTENTION:
% if settings.INPUT.rawDataAndroid phase observations in Epoch.obs are in [m]


cs_on = false;

if cs_on
    cs_start = 5;                     % [epoch]
    cs_lgth = 5;                        % [epoch]
    cs_ende = cs_start + cs_lgth;   	% [epoch]
    cs_size = 1000000;                       % [cycles]
    prn  = 02;                     % prn of affected satellite
    
    if prn < 200
        col = use_column{1,1};
    elseif prn > 200
        col = use_column{3,1};
    end
    
    % -> insert cycle slip
    idx_sat = find(Epoch.sats == prn & (Epoch.gps | Epoch.gal));
    if Epoch.q >= cs_start && Epoch.q <= cs_ende
        Epoch.obs(idx_sat, col) = Epoch.obs(idx_sat, col) + cs_size*Const.GPS_L1;
    end
    
end


