%% LAMBDA 4.0 | Compute Integer Gauss Transformations over matrix rows
% This function computes the Integer Gauss Transformations over a range of 
% rows, specified by the user or over all rows. In the latter case, all 
% entries of matrix L becomes bounded between -0.5 and 0.5, so it provides
% a complete (still not perfect) decorrelation. Operating on rows seems to
% be faster in MATLAB, but the same can be achieved operating on columns.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   L_mat       Old LtDL-decomposition matrix L (lower unitriangular)
%   iZt_mat     Old inverse transpose of Z-transformation matrix
%   ii_min      Minimum index of rows to be processed
%   ii_max      Maximum index of rows to be processed
%
%_OUTPUTS:
%   L_mat       New LtDL-decomposition matrix L (lower unitriangular)
%   iZt_mat     New inverse transpose of Z-transformation matrix
%
%_DEPENDENCIES:
%   none
%
%_REFERENCES:
%   none
%
% -------------------------------------------------------------------------
% Copyright: Geoscience & Remote Sensing department @ TUDelft | 01/06/2024
% Contact email:    LAMBDAtoolbox-CITG-GRS@tudelft.nl
% -------------------------------------------------------------------------
% Created by
%   01/06/2024  - Lotfi Massarweh
%       Implementation for LAMBDA 4.0 toolbox
%
% Modified by
%   dd/mm/yyyy  - Name Surname author - email address
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [L_mat,iZt_mat] = computeIGT_row(L_mat,iZt_mat,ii_min,ii_max)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(L_mat,2);

% Check # of input arguments
if nargin < 2
    % Assumes no previous Z-transformation was performed
    iZt_mat = eye(nn,nn);
    ii_min = 2;
    ii_max = nn;

elseif nargin < 3
    % Operate over the full range of rows
    ii_min = 2;
    ii_max = nn;

elseif nargin < 4
    % Operate till the last row
    ii_max = nn;

else
    % Check that input "ii_min" and "ii_max" are correct
    if ii_min > ii_max || ii_min < 2 || ii_max > nn
        error('ATTENTION: something is wrong with "ii_min" and "ii_max"!')
    end

end

%% Iterate over each row from "ii_min" till "ii_max" ( up -> down )
for ii = ii_min:ii_max
    
    % Round elements of current row "ii"
    mu_vect = round( L_mat(ii,1:ii-1) );
    index_mu = find( mu_vect );    
    
    % At the ii-th row, process columns defined in "index_mu"
    for jj = index_mu
        L_mat(ii:nn,jj) = L_mat(ii:nn,jj) - mu_vect(jj) * L_mat(ii:nn,ii);
        iZt_mat(:,ii)   = iZt_mat(:,ii)   + mu_vect(jj) * iZt_mat(:,jj);
    end

end
%--------------------------------------------------------------------------
end