function [mfh, mfw] = vmf3_ht_eval(ah, aw, bh, bw, ch, cw, h_ell, el)

% vmf3_ht_eval.m
%
%     !!! This is the version with height correction !!!
%     !!! It has to be used with the grid !!!
%
% Evaluates the VMF3 hydrostatic and wet mapping functions (including the
% height correction of the hydrostatic part) from the bh/bw/ch/cw
% coefficients (see vmf3_coeff.m) and the satellite elevation. This is
% the satellite-specific part of vmf3_ht.m and has to be computed once per
% satellite.
%
% INPUT:
%        o ah, aw: hydrostatic/wet mf coefficient a (http://vmf.geo.tuwien.ac.at/trop_products/)
%        o bh, bw, ch, cw: VMF3 coefficients from vmf3_coeff.m
%        o h_ell: ellipsoidal height (m)
%        o el: elevation (radians)
%
% OUTPUT:
%        o mfh: hydrostatic mapping factor
%        o mfw: wet mapping factor
%
%--------------------------------------------------------------------------
% History:
%
% 2026-09-22: function created (split off from vmf3_ht.m)
%
%--------------------------------------------------------------------------


if el == 0      % elevation is zero (e.g., satellite has no orbit data)
    mfh = 0; mfw = 0;
    return      % to avoid modeling absurdly big tropospheric delay values
end

% calculating the hydrostatic and wet mapping factors
mfh = (1+(ah/(1+bh/(1+ch))))   /   (sin(el)+(ah/(sin(el)+bh/(sin(el)+ch))));
mfw = (1+(aw/(1+bw/(1+cw))))   /   (sin(el)+(aw/(sin(el)+bw/(sin(el)+cw))));

% height correction for the hydrostatic part [Niell, 1996]
a_ht = 2.53d-5;
b_ht = 5.49d-3;
c_ht = 1.14d-3;
h_ell_km     = h_ell/1000;   % convert height to km
ht_corr_coef = 1/sin(el)   -   (1+(a_ht/(1+b_ht/(1+c_ht))))  /  (sin(el)+(a_ht/(sin(el)+b_ht/(sin(el)+c_ht))));
ht_corr      = ht_corr_coef * h_ell_km;
mfh          = mfh + ht_corr;
