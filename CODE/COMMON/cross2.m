function c = cross2(a, b)
% fast and dirty version of matlab's cross.m function
% returns cross product without any safety measures
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

c = [
    a(2)*b(3) - a(3)*b(2);
    a(3)*b(1) - a(1)*b(3);
    a(1)*b(2) - a(2)*b(1)   ];

 end
