function [M_norm] = vecnorm2(M)
% implemented from MATLAB R2017b onwards, but not in older 
% MATLAB versions calculates the norm of each column in M
%
% INPUT:
%   M           Matrix with several columns
% OUTPUT:
%   M_norm      vector, with norm of each column of M
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

n = size(M,2);
M_norm = NaN(1,n);
for i = 1:n
    M_norm(i) = norm(M(:,i));    
end

end