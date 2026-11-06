function delta_windup = PhaseWindUp(delta_windup_old, R_LL2ECEF, SatOr_ECEF, los0)
% Calculates Phase Wind-Up correction for a specific satellite and epoch.
% The wind-up paper: [08], check also: [00]: p.26 or [03] or
% Galileo High Accuracy Service Reference User Algorithm - Technical Note
%
% INPUT:
%   delta_windup_old    windup correction from last epoch for this satellite [cycles]
%   R_LL2ECEF           3x3, rotation Matrix from Local Level to ECEF
%   SatOr_ECEF          3x3, axes from satellite in ECEF
%   los0                3x1, unit vector of line of sight from satellite to receiver
% OUTPUT:
%   delta_windup        Phase Wind-Up correction in [cycles]
%
% Revision:
%   2026/09/21, MFWG: flipping sign of los0 (incorrect before!)
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Unit vectors sat system in ECEF
a_sat = SatOr_ECEF(:,1);            % x-axis, along solar panels
b_sat = SatOr_ECEF(:,2);            % y-axis
% Unit vectors Local Level Frame
a_rec =  R_LL2ECEF(:,1);            % North (static case)
b_rec = -R_LL2ECEF(:,2);            % West (static case)

% Unit vectors of antennas, [00]: (2.32) and (2.33)
D_rec = a_rec - los0*dot2(los0,a_rec) + cross2(los0,b_rec);
D_sat = a_sat - los0*dot2(los0,a_sat) - cross2(los0,b_sat);

% Windup of this epoch in [rad]
cosphi = dot2(D_sat,D_rec) / (norm(D_sat)*norm(D_rec));     % [08]: (14), term of cos^-1
if abs(cosphi) > 1
    % documented occurence: 2x in my PPP life (e.g., PALM1/021/2020, Epoch 2359, prn 221)
    cosphi = sign(cosphi); 
end   

y = dot2(los0, cross2(D_sat, D_rec));       % [08]: (15)
% y tells how much los0 points out of the plane defined by D_sat and D_rec
% if y = 0, los0 is coplanar to D_sat and D_rec (lies in the same plane)
% the sign of y tells on which side los0 points of the plane(D_sat, D_rec)

dphi = sign(y)*acos(cosphi);                % [08]: (14), 3rd part (1st and 2nd are added in the following)
DPhi_prev = delta_windup_old*2*pi;
N = round((DPhi_prev - dphi)/(2*pi));       % to avoid jumps
if DPhi_prev == 0; N = 0; end
DPhi = dphi + N*2*pi;
delta_windup = DPhi/(2*pi);
end