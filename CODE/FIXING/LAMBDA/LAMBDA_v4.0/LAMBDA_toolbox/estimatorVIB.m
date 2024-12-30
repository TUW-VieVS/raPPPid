%% LAMBDA 4.0 | Vectorial Integer Bootstrapping (VIB) estimator
% This function computes a (full or partial) 'fixed' solution based on the 
% Vectorial Integer Bootstrapping (VIB-)estimator [RD01], with its simple
% implementation presented in Appendix A from [RD02]. Both IR or ILS could
% be used for fixing each (conditioned) subsets. When only some of subsets 
% are fixed, then a partial solution is returned. 
%
% -------------------------------------------------------------------------
%_INPUTS:
%	a_hat       Ambiguity float vector (column)
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%   dimBlocks   Dimensions' vector for each subset      [DEFAUL = 2 blocks]
%   typeEstim   Define estimator adopted in all subsets [DEFAUL = 'ILS']
%
%_OUTPUTS:
%   a_fix 	    Ambiguity fixed solution (column) - using VIB
%   nFixed      Number of integer-fixed components
%
%_DEPENDENCIES:
%   estimatorIR.m
%   estimatorILS.m
%
%_REFERENCES:
%   [RD01] Teunissen, P.J.G., Massarweh, L. & Verhagen, S. (2021) Vectorial 
%       integer bootstrapping: flexible integer estimation with application 
%       to GNSS. J Geod 95, 99. 
%       DOI: 10.1007/s00190-021-01552-2
%   [RD02] Massarweh, L., Strasser, S., & Mayer-Gürr, T. (2021). On vectorial 
%       integer bootstrapping implementations in the estimation of satellite 
%       orbits and clocks based on small global networks. Advances in Space 
%       Research, 68(11), 4303-4320.
%       DOI: 10.1016/j.asr.2021.09.023
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
function [a_fix,nFixed] = estimatorVIB(a_hat,L_mat,d_vec,typeEstim,dimBlocks)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(a_hat,1);

% Check # of input
if nargin < 3
    error('ATTENTION: number of inputs is insufficient!')

elseif nargin < 4   % If not specified, then use VIB-ILS (2 blocks)
    typeEstim = 'ILS';
    dimBlocks = [floor(nn/2) ceil(nn/2)];

elseif nargin < 5   % If not specified, then use a 2-block partitioning 
    dimBlocks = [floor(nn/2) ceil(nn/2)]; 

end

% Check size-compatibility of input partitioning ("dimBlocks")
if sum(dimBlocks) > nn
    error('ATTENTION: the partitions exceed the full set dimensionality!')
else
    nFixed = sum(dimBlocks);
end

%==========================================================================
%% Cascade Ambiguity Resolution [CascAR] implementation of VIB estimator
a_fix = NaN(nn,1);
for n_II = dimBlocks(end:-1:1)
    
    % Partitioning into two blocks, where {II} is being processed
    index_I  = 1:nn-n_II;
    index_II = nn-n_II+1:nn;
    
    % Compute fixed solution of current block {II} by a selected estimator
    switch typeEstim 
        case 'IR'       
            a_fix_II = estimatorIR(a_hat(index_II));  
            
        case 'ILS'
            a_fix_II = estimatorILS(a_hat(index_II),L_mat(index_II,index_II),d_vec(index_II));
            
        otherwise
            error('ATTENTION: selected VIB estimator is not available!')

    end
    
    % Save the new partial solution
    a_fix(index_II) = a_fix_II;
             
    % Condition float ambiguity vector of block {I} for next iteration
    a_hat(index_I) = a_hat(index_I) ...
                   - L_mat(index_II,index_I)' * ( L_mat(index_II,index_II)' \ ( a_hat(index_II) - a_fix_II ) );
    
    % Reduce size of the remaining ambiguity vector for next iteration
    nn = nn - n_II;
    
end

% Check for PAR solutions, i.e. sum(dimBlocks) < nn 
if nn > 0
    a_fix(index_I) = a_hat(index_I);
end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END