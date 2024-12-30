%% LAMBDA 4.0 | Decorrelate ambiguities by an admissible Z-transformation
% This function decorrelates the ambiguities by reduction and ordering of 
% conditional variances. The Z-transformation matrix (unimodular) is then
% obtained conventionally here as inv(Z').
%
% -------------------------------------------------------------------------
%_INPUTS:
%   L_mat       Old LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       Old LtDL-decomposition matrix D (diagonal elements)
%   iZt_mat     Old inverse transpose Z-transformation matrix (unimodular)
%
%_OUTPUTS:
%   L_mat       New LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       New LtDL-decomposition matrix D (diagonal elements)
%   iZt_mat     New inverse transpose Z-transformation matrix (unimodular)
%
%_DEPENDENCIES:
%   computeIGT_row.m
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
%       Implementation for LAMBDA 4.0 toolbox, based on LAMBDA 3.0
%
% Modified by
%   dd/mm/yyyy  - Name Surname author - email address
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [L_mat,d_vec,iZt_mat] = transformZ(L_mat,d_vec,iZt_mat)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(d_vec);

% Check # of inputs
if nargin < 2
    error('ATTENTION: number of inputs is insufficient!')

elseif nargin < 3
    % Case without any a priori Z-transformation matrix
    iZt_mat = eye(nn,nn);

end
% NOTE: we use iZt = inv(Z'), assuming a transformation z_hat = Z' * a_hat

%% ALGORITHM: matrix reduction with conditional variances ordering

% Iterative loop for swapping & decorrelate adjacent components
kk = nn - 1;
while kk > 0
    kp1 = kk + 1;
    %----------------------------------------------------------------------
    % Check current pairs {k,k+1} and a correlation-like term L_mat(kp1,kk)
    CORR = L_mat(kp1,kk);
    mu = round( CORR );
    if mu ~= 0
        CORR = CORR - mu;
    end
    %----------------------------------------------------------------------
    % Condition for swapping adjacent ambiguities
    delta = d_vec(kk) + CORR^2 * d_vec(kp1);
    if delta < d_vec(kp1)
        %------------------------------------------------------------------
        % Check if decorrelation for L_mat(kk+1,kk) was needed 
        if mu ~=0
            L_mat(kp1:nn,kk) = L_mat(kp1:nn,kk) - mu * L_mat(kp1:nn,kp1);
            iZt_mat(:,kp1)   = iZt_mat(:,kp1)   + mu * iZt_mat(:,kk);
            
            % Reduce entire column L_mat(kk+1:nn,kk) -> better stability
            for ii = kk+2:nn
                mu = round( L_mat(ii,kk) );
                if mu ~= 0 
                    L_mat(ii:nn,kk) = L_mat(ii:nn,kk) - mu * L_mat(ii:nn,ii);
                    iZt_mat(:,ii)   = iZt_mat(:,ii)   + mu * iZt_mat(:,kk);
                end
            end            
        end
        %------------------------------------------------------------------
        % Compute auxiliary variables for performing the adjacent swapping
        lambda = L_mat(kp1,kk) * d_vec(kp1) / delta;    % Auxiliary #1
        eta    =                 d_vec(kk ) / delta;    % Auxiliary #2

        % STEP I: adjacent swapping operation
        swapMatrix = [ -L_mat(kp1,kk)     1   ; 
                              eta      lambda];
        L_mat([kk kp1],1:kk-1) = swapMatrix * L_mat([kk kp1],1:kk-1);
          
        % STEP II: update decomposition in the specific swapped block
        L_mat(kp1,kk) = lambda;
        d_vec(kk)     = eta * d_vec(kp1);
        d_vec(kp1)    = delta;
        
        % STEP III: update decomposition in the other conditioned block
        L_mat(kk+2:nn,[kk kp1]) = L_mat(kk+2:nn,[kp1 kk]);
        iZt_mat(:,[kk kp1])     = iZt_mat(:,[kp1 kk]);
        %------------------------------------------------------------------
        % If a swap took place at lower levels, we move up
        if kk < nn - 1
            kk = kk + 1;
        end
    else
        % No swap took place, so we move one level down
        kk = kk - 1;
    end
    %----------------------------------------------------------------------
end

% Assure that all the ambiguity components are ultimately decorrelated
[L_mat,iZt_mat] = computeIGT_row(L_mat,iZt_mat);
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END