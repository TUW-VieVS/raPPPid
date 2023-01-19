function mu = ratioinv(Pf_FIX,PfILS,n)
%          mu = ratioinv(Pf,PfILS,n)
%
%   Determine appropriate threshold value MU for Ratio Test with Fixed
%   Failure rate Pf.
%   Use tabulated values of MU depending on the ILS failure rate and 
%   the number of float ambiguities
%
% INPUT:
%
%   Pf_FIX:  Fixed failure rate (maximum tolerable failure rate)
%            Possible values are 0.01 and 0.001
%   PfILS :  ILS failure rate
%   n     :  number of float ambiguities
%
%   The routine loads (once) tables for different values of PF from the mat
%   file RATIOTAB.MAT, which must be in a directory in the Matlab path.
%
%
%   Copyright 2007-2012, TU Delft

%   Created:    20 April 2007 by Sandra Verhagen
%   Modified:   20 January 2010 by Hans van der Marel
%                - merged tables into RATIOTAB.MAT
%                - load tables only once (persistent variables)
%                - added tests on the input arguments
%                - use interp1q for interpolation 
%                - added description and comments
%

% Load the tables from ratiotab.mat (once)

persistent ratiotab;

if isempty(ratiotab) 
   ratiotab=load('ratiotab.mat');
end

% Select the right table for the given fixed failure rate

kPf=round(Pf_FIX*1000);
if ( kPf == 1 || kPf == 10 )
  table=ratiotab.(sprintf('table%d',kPf));
else
  error('Incorrect value for Pf');
end

% Make sure n is within range of table
 
if  n < 1
  error('n must be larger than 0.');
end
if  n >  size(table,2)-1
  n=size(table,2)-1;
end

% % Check the range of PfILS
% 
% if ( any(PfILS < 0) || any(PfILS > 1 ) )
%   disp('Warning RATIOINV: PfILS must be between 0 and 1.');
%   PfILS(PfILS < 0)=0;
%   PfILS(PfILS > 1)=1;
% end

% Use linear interpolation to find the treshhold value for the given PfILS

mu = interp1q(table(:,1),table(:,n+1),PfILS);

return
