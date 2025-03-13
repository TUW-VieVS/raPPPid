function [POLY] = legendre_Pnm(N,M,y)
% Calculates the normalized Legendre functions which are used to calculate 
% the VTEC from the broadcast correction stream for the ionospheric
% correction. The used recursive formulas and the recursion process can be 
% found in
% 
% Zhixi Nie et al.; Quality assessment of CNES real-time ionospheric products; 
% GPS Solutions (2019) 23:11; https://doi.org/10.1007/s10291-018-0802-2; 2018 
% 
% Holmes, S., Featherstone, W. A unified approach to the Clenshaw summation 
% and the recursive computation of very high degree and order normalised 
% associated Legendre functions. Journal of Geodesy 76, 279–299 (2002). 
% https://doi.org/10.1007/s00190-002-0216-2
%
% INPUT:   
%   N           degree of spherical harmonics
%   M           order of spherical harmonics
%   y           latitude of IPP, [rad]
% OUTPUT:
%   POLY        matrix with values of normalized Legendre functions
%
% Revision:
%   2025/02/06, MFWG: corrected sign in (9) (error in Zhixi Nie et al.)
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% initialize matrix and insert starting values
POLY = zeros(N,M);      % be careful: P_00 = POLY(1,1), P_32 = P(4,3),...
POLY(1,1) = 1;
POLY(2,2) = sqrt(3)*cos(y);

% loop over matrix to calculate the P_nm recursive with the correct formula
% as P_32 = P(4,3),... everytime accessing the matrix POLY one has to be
% added to n and m
for n = 0:N-1
    for m = 0:M-1
        if m > n || POLY(n+1,m+1)~=0 
            continue
        elseif n == m           % diagonal entries
            POLY(n+1,m+1) = sqrt((2*n+1)/(2*n)) * cos(y) * POLY(n,m);    	% (7)
        elseif n == m+1         % the entries under (or left of) the diagonal
            POLY(n+1,m+1) = sqrt(2*n+1)*sin(y)*POLY(n,n);                   % (8)
        else                    % all other entries     
            a_nm = calc_a(n, m);
            b_nm = calc_b(n, m);
            POLY(n+1,m+1) = a_nm*sin(y)*POLY(n,m+1) - b_nm*POLY(n-1,m+1);  	% (9), sign error in publication!
        end
    end
end
end


function a = calc_a(n, m)       % calculate a_nm (10)
a = sqrt( ((2*n-1)*(2*n+1)) / ((n-m)*(n+m)) );
end

function b = calc_b(n, m)       % calculate b_nm (11)
b = sqrt( ((2*n+1)*(n+m-1)*(n-m-1)) / ((n-m)*(n+m)*(2*n-3)) );
end