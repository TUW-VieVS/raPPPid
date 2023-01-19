function scalar = dot2(vec1,vec2)
% calculates dot-product, faster than the dot.m-function of Matlab
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

scalar = vec1(:)'*vec2(:);