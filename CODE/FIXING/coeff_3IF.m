function [e1, e2, e3] = coeff_3IF(f1, f2, f3)
% This function calculates the coefficients of the 3-frequency
% ionosphere-free linear combination with minimum noise (check [14]).
%
% INPUT:
%   f1, f2, f3      frequencies of 1st, 2nd, 3rd processed frequency [Hz]
% OUTPUT:
%   e1, e2, e3      coefficients of the 3-frequency IF LC
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% coefficients of 3-Frequency-IF-LC, reference [14]
y2 = f1.^2 ./ f2.^2;
y3 = f1.^2 ./ f3.^2;
e1 = (y2.^2 +y3.^2  -y2-y3) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
e2 = (y3.^2 -y2.*y3 -y2 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
e3 = (y2.^2 -y2.*y3 -y3 +1) ./ (2.*(y2.^2 +y3.^2 -y2.*y3 -y2-y3+1));
