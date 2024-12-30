%% LAMBDA 4.0 | Integer Least-Squares (ILS) estimator by search-and-shrink
% This function computes a 'fixed' solution based on Integer Least-Squares
% (ILS-)estimator using the search-and-shrink approach. The latter adopts 
% the algorithm proposed by Ghasemmehdi and Agrell (2011, [RD01]).
%
% -------------------------------------------------------------------------
%_INPUTS
%   a_hat       Ambiguity float vector (column)
%   L_mat       LtDL-decomposition matrix L (lower unitriangular)
%   d_vec       LtDL-decomposition matrix D (diagonal elements)
%	nCands      Number of best integer solutions [DEFAULT = 1]
%
%_OUTPUTS
%	a_fix 	    Ambiguity fixed vector (column) - Best ILS solution(s)
%   a_sqnorm    Squared norm for each ILS solution
%
%_DEPENDENCIES:
%   none
%
% REFERENCES
%   [RD01] A. Ghasemmehdi and E. Agrell, "Faster Recursions in Sphere 
%       Decoding" in IEEE Transactions on Information Theory, vol. 57, 
%       no. 6, pp. 3530-3536, June 2011. 
%       DOI: 10.1109/TIT.2011.2143830.
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
function [a_fix,sqnorm] = estimatorILS(a_hat,L_mat,d_vec,nCands)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = length(a_hat);

% Check # of input arguments
if nargin < 3
    error('ATTENTION: number of inputs is insufficient!')
    
elseif nargin < 4
    nCands = 1;      % Compute only the best ILS solution

end

%--------------------------------------------------------------------------
% Determine which level to move to after z_cond(1) is chosen at level 1.
if nCands == 1 && nn > 1           
    k0 = 2;     % Cannot find a better candidate, so directly try level 2
else
    k0 = 1;     % Try to further improve candidates at level 1
end

% Initialization output variables 
a_fix = zeros(nn,nCands);    % Store p best candidate solutions
sqnorm = zeros(1,nCands);    % Store squared norm of each p best candidate 

% Initial number of candidate solutions
int_count = 0;       
int_max = nCands;

% Start from an ellipsoid with infinite radius
maxChi2 = inf;

% Initialization variables used
a_cond = zeros(nn,1);
z_cond = zeros(nn,1);
left  = zeros(nn,1);
step  = zeros(nn,1);

% Initialization at the n-th level
a_cond(nn) = a_hat(nn);
z_cond(nn) = round( a_cond(nn) );
left(nn) = a_cond(nn) - z_cond(nn);
step(nn) = sign( left(nn) );
%--------------------------------------------------------------------------
% NOTE: very rarely, we need a positive step to avoid stall in the case an
% exact integer value is provided for "a_hat(nn)".
if step(nn) == 0
    step(nn) = 1;
end
%--------------------------------------------------------------------------
% Used to compute conditional ambiguities
S = zeros(nn,nn);

% Initializing the variable "dist(k) = sum_{j=k+1}^{n} (a_j-acond_j)^2/d_j"
dist = zeros(nn+1,1);

% Additional variables needed for keeping track of the conditional update
path = nn * ones(nn,1);     % path(k) used for updating S(k,k:path(k)-1) 

%% Algorithm GHAH (Ghasemmehdi and Agrell, 2011; [RD01])
kk = nn;        % Start main search-loop from the last ambiguity component

% Iterative search
endSearch = false;
while ~endSearch

    % Current (partial) distance of a candidate solution
    newDist = dist(kk) + left(kk)^2 / d_vec(kk);
    
    % Keep moving down if current (partial) distance is smaller than radius
    while newDist < maxChi2
        if kk ~= 1  
            % Move down to level "k-1"
            kk = kk - 1;
            dist(kk) = newDist;

            % Conditionally update recalling previous updates by "path"
            for jj = path(kk):-1:kk+1
                S(jj-1,kk) = S(jj,kk) - left(jj) * L_mat(jj,kk);
            end

            a_cond(kk) = a_hat(kk) + S(kk,kk);
            z_cond(kk) = round( a_cond(kk) );
            left(kk)  = a_cond(kk) - z_cond(kk);
            step(kk)  = sign( left(kk) );
            %--------------------------------------------------------------
            % NOTE: very rarely, we need a positive step to avoid stall in 
            % the case an exact integer value is found for "a_cond(kk)".
            if step(kk) == 0
                step(kk) = 1;
            end
            %--------------------------------------------------------------
        else
            
            % Store the candidate found and try next valid integer
            if int_count < nCands - 1     
                int_count = int_count + 1;
                a_fix(:, int_count) = z_cond;   % Store first p-1 candidates
                sqnorm(int_count) = newDist;    % Store f(z)
            else
                a_fix(:, int_max) = z_cond;
                sqnorm(int_max) = newDist;
                [maxChi2, int_max] = max(sqnorm);
            end

            % Next valid integer (kk+1 level)
            kk = k0;
            z_cond(kk)  =  z_cond(kk) + step(kk);
            left(kk)    =  a_cond(kk) - z_cond(kk);
            step(kk)    = -step(kk) - sign( step(kk) );
        end
        newDist = dist(kk) + left(kk)^2 / d_vec(kk);
    end
    iLevel = kk;

    % Exit or move up
    while newDist >= maxChi2
        if kk == nn
            endSearch = true;
            break;
        end
        kk          = kk + 1;                   % Move up to level "kk+1"
        z_cond(kk)  =  z_cond(kk) + step(kk);   % Next valid integer
        left(kk)    =  a_cond(kk) - z_cond(kk);
        step(kk)    = -step(kk) - sign( step(kk) );
        newDist     =  dist(kk) + left(kk)^2 / d_vec(kk);
    end

    % Define "path" for the successive conditional update
    path(iLevel:kk-1) = kk;
    for jj = iLevel-1:-1:1
        if path(jj) < kk 
            path(jj) = kk;
        else
            break   % Exit from this for-cycle
        end
    end

end

% Sort the solutions by their corresponding residuals' squared norm
[sqnorm,nCands] = sort(sqnorm);
a_fix = a_fix(:,nCands);
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END