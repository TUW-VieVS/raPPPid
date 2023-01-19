function M = zero2nan(M)
% Simple function to 'de-sparse' a matrix and replace all zeros with NaN.
% 
% INPUT:
%   M       matrix or vector
% OUTPUT:
%	M       matrix or vector
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

M = full(M);
M(M==0) = NaN;