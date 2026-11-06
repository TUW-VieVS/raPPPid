function [mfh, mfw] = vmf3_eval(ah, aw, bh, bw, ch, cw, el)

% vmf3_eval.m
%
% Evaluates the VMF3 hydrostatic and wet mapping functions from the
% bh/bw/ch/cw coefficients from vmf3_coeff.m and the satellite elevation.
% This is satellite-specific part of vmf3.m and has to be called once per
% satellite.
%
% INPUT:
%        o ah, aw: hydrostatic/wet mf coefficient a (http://vmf.geo.tuwien.ac.at/trop_products/)
%        o bh, bw, ch, cw: VMF3 coefficients from vmf3_coeff.m
%        o el: elevation (radians)
%
% OUTPUT:
%        o mfh: hydrostatic mapping factor
%        o mfw: wet mapping factor
%
%--------------------------------------------------------------------------
% History:
%
% 2026-09-22: function created (split off from vmf3.m)
%
%--------------------------------------------------------------------------


if el == 0      % elevation is zero (e.g., satellite has no orbit data)
    mfh = 0; mfw = 0;
    return      % to avoid modeling absurdly big tropospheric delay values
end

% calculating the hydrostatic and wet mapping factors
mfh = (1+(ah/(1+bh/(1+ch))))   /   (sin(el)+(ah/(sin(el)+bh/(sin(el)+ch))));
mfw = (1+(aw/(1+bw/(1+cw))))   /   (sin(el)+(aw/(sin(el)+bw/(sin(el)+cw))));
