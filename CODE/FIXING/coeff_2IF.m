function [k1, k2] = coeff_2IF(f1, f2)
% This function calculates the coefficients of the 2-frequency
% ionosphere-free linear combination: IF = k1*C1 + k2*C2
%
% INPUT:
%   f1, f2      frequencies of 1st and 2nd frequency of the IF LC [Hz]
% OUTPUT:
%   k1, k2      coefficients of the 2-frequency IF LC
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% coefficients of 2-Frequency-IF-LC
k1 =  f1.^2 ./ (f1.^2 - f2.^2);
k2 = -f2.^2 ./ (f1.^2 - f2.^2);
