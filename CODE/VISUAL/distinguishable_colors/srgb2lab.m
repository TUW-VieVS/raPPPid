function lab = srgb2lab(rgb)
% Converts sRGB color triples into the CIE L*a*b* color space. This is a
% toolbox-free replacement for the Image Processing Toolbox calls
%   C = makecform('srgb2lab'); lab = applycform(rgb, C);
% and can be handed over to distinguishable_colors.m as 3rd input argument.
% Like the ICC profile connection space (and therefore applycform) the D50
% white point is used, so the resulting colors are identical to the ones
% created with the Image Processing Toolbox (differences < 0.05 in L*a*b*).
%
% INPUT:
%   rgb         [n x 3], sRGB triples, values in the range [0, 1]
% OUTPUT:
%	lab         [n x 3], corresponding CIE L*a*b* values
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

% remove the gamma encoding (sRGB -> linear RGB, IEC 61966-2-1)
lin = rgb;
bool = (lin <= 0.04045);
lin( bool) = lin( bool) / 12.92;
lin(~bool) = ((lin(~bool) + 0.055) / 1.055).^2.4;

% linear RGB -> CIE XYZ (sRGB primaries, Bradford-adapted to D50)
M = [0.4360747, 0.3850649, 0.1430804; ...
     0.2225045, 0.7168786, 0.0606169; ...
     0.0139322, 0.0971045, 0.7141733];
xyz = lin * M';

% normalize with the D50 white point
white = [0.9642957, 1, 0.8251046];
xyz = xyz ./ white;

% nonlinear compression, CIE 15:2004
e = 216/24389;      % = (6/29)^3
k = 24389/27;       % = (29/3)^3
f = xyz;
bool = (f > e);
f( bool) = nthroot(f(bool), 3);
f(~bool) = (k * f(~bool) + 16) / 116;

% CIE XYZ -> CIE L*a*b*
lab = [116*f(:,2) - 16, 500*(f(:,1) - f(:,2)), 200*(f(:,2) - f(:,3))];
