function [L,D] = ldldecom(Qahat)
%LDLDECOM: Find LtDL-decompostion of Qahat-matrix
%
%           [L,D] = ldldecom(Qahat)
%
% This routine finds the LtDL decomposition of a given variance/
% covariance matrix.
%
% Input arguments:
%    Qahat: Symmetric n by n matrix to be factored
%
% Output arguments:
%    L:     n by n factor matrix (strict lower triangular)
%    D:     Diagonal n-vector

% ----------------------------------------------------------------------
% File.....: ldldecom
% Date.....: 19-MAY-1999
% Author...: Peter Joosten
%            Mathematical Geodesy and Positioning
%            Delft University of Technology
% ----------------------------------------------------------------------

n = size (Qahat,1);

for i = n:-1:1;

   D(i) = Qahat(i,i);
   L(i,1:i) = Qahat(i,1:i)/sqrt(Qahat(i,i));
   
   for j = 1:i-1
      Qahat(j,1:j) = Qahat(j,1:j)-L(i,1:j)*L(i,j);
   end
   
   L(i,1:i) = L(i,1:i)/L(i,i);

end;

if (sum(D < 1E-10));

  error ('Matrix on input is not positive definite!');

end;

% ----------------------------------------------------------------------
% End of routine: ldldecom
% ----------------------------------------------------------------------
