function [Qzhat,Z,L,D,zhat,iZt] = decorrel (Qahat,ahat)
%DECORREL: Decorrelate a (co)variance matrix of ambiguities
%
%     [Qzhat,Z,L,D,zhat] = decorrel (Qahat,ahat)
%
% This routine creates a decorrelated Q-matrix, by finding the
% Z-matrix and performing the corresponding transformation.
%
% The method is described in:
% The routine is based on Fortran routines written by Paul de Jonge (TUD)
% and on Matlab-routines written by Kai Borre.
% The resulting Z-matrix can be used as follows:
% zhat = Zt * ahat; \hat(z) = Z' * \hat(a);
% Q_\hat(z) = Z' * Q_\hat(a) * Z
%
% Input arguments:
%   Qahat: Variance-covariance matrix of ambiguities (original)
%   ahat:  Original ambiguities (optional)
%
% Output arguments:
%   Qzhat: Variance-covariance matrix of decorrelated ambiguities
%   Z:     Z-transformation matrix
%   L:     L matrix (from LtDL-decomposition of Qzhat)
%   D:     D matrix (from LtDL-decomposition of Qzhat)
%   zhat:  Transformed ambiguities (optional)
%   iZt:   inv(Z')-transformation matrix
%
% ----------------------------------------------------------------------
% Function.: decorrel
% Date.....: 19-MAY-1999 / modified 12-APRIL-2012
% Author...: Peter Joosten / Sandra Verhagen
%            Mathematical Geodesy and Positioning
%            Delft University of Technology
% ----------------------------------------------------------------------

%Tests on Inputs ahat and Qahat                           

%Is the Q-matrix symmetric?
if ~isequal(Qahat-Qahat'<1E-6,ones(size(Qahat)));
  error ('Variance-covariance matrix is not symmetric!');
end;

%Is the Q-matrix positive-definite?
if sum(eig(Qahat)>0) ~= size(Qahat,1);
  error ('Variance-covariance matrix is not positive definite!');
end;

% -----------------------
% --- Initialisations ---
% -----------------------

n    = size(Qahat,1);
iZt  = eye(n);
i1   = n - 1;
sw   = 1;

% --------------------------
% --- LtDL decomposition ---
% --------------------------

[L,D] = ldldecom (Qahat);

% ------------------------------------------
% --- The actual decorrelation procedure ---
% ------------------------------------------

while sw;

   i  = n;   %loop for column from n to 1
   sw = 0;

   while ( ~sw ) && (i > 1)

      i = i - 1;  %the ith column
      if (i <= i1); 
      
         for j = i+1:n
            mu = round(L(j,i));
            if mu % if mu not equal to 0
               L(j:n,i) = L(j:n,i) - mu * L(j:n,j);
               iZt(:,j) = iZt(:,j) + mu * iZt(:,i);  %iZt is inv(Zt) matrix 
            end
         end

      end;

      delta = D(i) + L(i+1,i)^2 * D(i+1);
      if (delta < D(i+1))

         lambda       = D(i+1) * L(i+1,i) / delta;
         eta          = D(i) / delta;
         D(i)         = eta * D(i+1);
         D(i+1)       = delta;

         L(i:i+1,1:i-1) = [ -L(i+1,i) 1 ; eta lambda ] * L(i:i+1,1:i-1);
         L(i+1,i)     = lambda;

         % swap rows i and i+1
         L(i+2:n,i:i+1) = L(i+2:n,i+1:-1:i);
         iZt(:,i:i+1) = iZt(:,i+1:-1:i);

         i1           = i;
         sw           = 1;

      end;

   end;

end;

% ---------------------------------------------------------------------
% --- Return the transformed Q-matrix and the transformation-matrix ---
% --- Return the decorrelated ambiguities, if they were supplied    ---
% ---------------------------------------------------------------------

Z = round(inv(iZt'));
Qzhat = Z' * Qahat * Z;

if nargin == 2 && nargout >= 5;
  zhat = Z' * ahat;
end;

return;

% ----------------------------------------------------------------------
% End of routine: decorrel
% ----------------------------------------------------------------------
