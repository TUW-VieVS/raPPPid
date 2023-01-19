function delta_windup = PhaseWindUp(prn, Epoch, model, SatOr_ECEF, los0)
% Calculates Phase Wind-Up correction for a specific satellite and epoch
% The wind-up paper: [08], check also: [00]: p.26 or [03]
% 
% INPUT:
%   prn                 Satellite number
%   Epoch           struct, epoch-specific data
%   model               struct, values for modelled error sources
%   SatOr_ECEF          Axes from satellite in ECEF
%   los0                unit vector of line of sight from receiver to satellite
% OUTPUT:
%   delta_windup        Phase Wind-Up correction in [cycles]
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% get windup correction from last epoch
delta_windup_old = 0;
if ~isempty(Epoch.old.sats)                     % not 1st epoch (afer reset)
    i_windup = find(Epoch.old.sats == prn);
    if ~isnan(i_windup)     % get windup correction from last epoch for current satellite
        delta_windup_old = Epoch.old.delta_windup(i_windup);    % [cycles]
    end
end

% Unit vectors sat system in ECEF
a_sat = SatOr_ECEF(:,1);
b_sat = SatOr_ECEF(:,2);
% Unit vectors Local Level Frame
a_rec =  model.R_LL2ECEF(:,1);     % North
b_rec = -model.R_LL2ECEF(:,2);     % West
% Unit vectors of antennas, [00]: (2.32) and (2.33)
D_rec = a_rec - los0*dot2(los0,a_rec) + cross2(los0,b_rec);
D_sat = a_sat - los0*dot2(los0,a_sat) - cross2(los0,b_sat);
% Windup of this epoch in [rad]
cosphi = dot2(D_sat,D_rec) / (norm(D_sat)*norm(D_rec));
if cosphi > 1
    cosphi = 1;         % occured in PALM1/021/2020, Epoch 2359, prn 221
end
y = dot2(los0,cross2(D_sat,D_rec));
dphi = sign(y)*acos(cosphi);
DPhi_prev = delta_windup_old*2*pi;
N = round((DPhi_prev - dphi)/(2*pi));       % to avoid jumps
if DPhi_prev == 0; N = 0; end
DPhi = dphi + N*2*pi;
delta_windup = DPhi/(2*pi);

end