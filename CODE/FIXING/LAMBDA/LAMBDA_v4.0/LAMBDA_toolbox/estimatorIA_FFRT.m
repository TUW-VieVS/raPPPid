%% LAMBDA 4.0 | Integer Aperture (IA) using Fixed Failure-rate Ratio Test
% This function compute the 'fixed' or 'float' solution based on Integer
% Aperture (IA-)estimator, thus adopting a Fixed Failure-rate Ratio Test 
% (FFRT, [RD01]) based on lookup tables newly defined in [RD02], where 
% the maximum failure-rate treshold should be in the range [0.05-1%].
%
% -------------------------------------------------------------------------
%_INPUTS:
%   a_hat       Ambiguity float vector (column)
%   L_mat       Decomposition L matrix (lower unitriangular)
%   d_vec       Decomposition D matrix (vector of diagonal components)
%	maxFR       Maximum failure-rate treshold, in the range [0.05-1%]
%   mu_RATIO    Ratio value used for an arbitrary ratio test    [OPTIONAL]
%
%_OUTPUTS:
%	a_fix 	    IA solution based on FFRT (or an arbitrary ratio test)
%   a_sqnorm    Squared-norm for the fixed solution
%   nFixed      Number of fixed ambiguity components
%
%_DEPENDENCIES:
%   estimatorILS.m
%   computeSR_IBexact.m
%   computeFFRTcoeff.m
%
%_REFERENCES:
%   [RD01] Verhagen, S., Teunissen, P.J.G. The ratio test for future GNSS 
%       ambiguity resolution. GPS Solut 17, 535–548 (2013). 
%       DOI: 10.1007/s10291-012-0299-z
%
%   [RD02] Hou, Yanqing, Sandra Verhagen, and Jie Wu. 2016. "An Efficient 
%       Implementation of Fixed Failure-Rate Ratio Test for GNSS Ambiguity 
%       Resolution" Sensors 16, no. 7: 945
%       DOI: 10.3390/s16070945
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
function [a_fix,sqnorm,nFixed] = estimatorIA_FFRT(a_hat,L_mat,d_vec,maxFR,mu_RATIO)
%--------------------------------------------------------------------------
% Problem dimensionality
nn = size(a_hat,1);

% Check # of input arguments
if nargin < 3
    error('ATTENTION: number of inputs is insufficient!')

elseif nargin < 4
    maxFR = 0.1/100;        % Defaul maximum Fixed Failure Rate is 0.1%
    
end
                 
% Instead of a maximum failure-rate criterion, we can consider an arbitrary 
% ratio test based on the input "mu_RATIO", while setting "maxFR" to zero.
if nargin > 4
    maxFR = 0;              % Assure FR >= maxFR for arbitrary ratio tests
end

% Compute two best solutions used for the Fixed Failure-rate Ratio Test
[a_fix_temp,sqnorm_temp] = estimatorILS(a_hat,L_mat,d_vec,2);

% Compute Success Rate (SR) and Failure Rate (FR)
SR = computeSR_IBexact(d_vec);
FR = 1 - SR;

% Check the Failure Rate (FR) with respect to current maximum FR treshold
if FR < maxFR

    % FR is below the treshold, so we return the ILS solution
    a_fix = a_fix_temp(:,1);
    sqnorm = sqnorm_temp(1);
    nFixed = nn;
    
else

    % FR is over the treshold, so we compute the mu-value for IA
    if nargin > 4
        mu_value = mu_RATIO;                        % Arbitrary ratio test
    else
        mu_value = computeFFRTcoeff(maxFR,FR,nn);   % Fixed-FR ratio test
    end
            
    % Perform the Ratio Test based on the mu-value
    if sqnorm_temp(1) / sqnorm_temp(2) > mu_value
        a_fix = a_hat;
        sqnorm = 0;
        nFixed = 0;
    else
        a_fix = a_fix_temp(:,1);
        sqnorm = sqnorm_temp(1);
        nFixed = nn;
    end

end
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END