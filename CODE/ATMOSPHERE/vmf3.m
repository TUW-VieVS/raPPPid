function [mfh, mfw] = vmf3(ah, aw, mjd, lat, lon, el)

% vmf3.m 
% slightly modified!
% 
% (c) Department of Geodesy and Geoinformation, Vienna University of
% Technology, 2016
%
% This subroutine determines the VMF3 hydrostatic and wet mapping factors.
% The a coefficients have to be inserted from discrete data, while the b
% and c coefficients are of empirical nature containing a geographical 
% and temporal dependence, represented in spherical harmonics. The 
% spherical harmonics coefficients are developed to degree and order 12 and 
% are based on a 5°x5° grid containing ray-tracing data from 2001-2010.
% All input quantities have to be scalars!
%
% INPUT: 
%        o ah: hydrostatic mf coefficient a (http://vmf.geo.tuwien.ac.at/trop_products/)
%        o aw: wet mf coefficient a (http://vmf.geo.tuwien.ac.at/trop_products/)
%        o mjd: modified julian date
%        o lat: latitude (radians)
%        o lon: longitude (radians)
%        o el: elevation (radians)
%
% OUTPUT:
%        o mfh: hydrostatic mapping factor
%        o mfw: wet mapping factor
%
%--------------------------------------------------------------------------
% 
% m-file created by Daniel Landskron
%
%--------------------------------------------------------------------------
% History:
%
% 2016-03-14: m-file created
% 2019-08-26: input change from zd to el [MFG]
% 2023-01-26: added return if el == 0
% 2026-09-22: bh/bw/ch/cw computation factored out into vmf3_coeff.m [MFWG]
%
%--------------------------------------------------------------------------


if el == 0      % elevation is zero (e.g., satellite has no orbit data)
    mfh = 0; mfw = 0;
    return      % to avoid modeling absurdly big tropospheric delay values 
end

% VMF3 coefficients are independent of the satellite elevation and only 
% depend on mjd/lat/lon
[bh, bw, ch, cw] = vmf3_coeff(mjd, lat, lon);

% calculating the hydrostatic and wet mapping factors
[mfh, mfw] = vmf3_eval(ah, aw, bh, bw, ch, cw, el);

