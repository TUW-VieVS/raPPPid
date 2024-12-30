%% LAMBDA 4.0 | Computes different GNSS Geometry-Free (GF) models
% This function computes a GNSS geometry-free model for "M" and "N" being 
% respectively the number of GNSS satellites and tracking receivers. Up to 
% "J" frequencies can be used for GPS or Galileo (or any other signals), 
% while assuming a total of "K" epochs. The uncertainty of code and phase 
% observations can be provided, along with the ionospheric model, i.e. 
% ionosphere-fixed, ionosphere-float or ionosphere-weighted.
%
% -------------------------------------------------------------------------
%_INPUTS:
%   stdIono     St.dev. of ionosphere [m] (0 if fixed, 999 if float)
%   Qcode       VC-matrix of code observables
%   Qphase      VC-matrix of phase observables
%   J           Number of signal frequencies
%   K           Number of epochs
%   M           Number of transmitting satellites
%   N           Number of tracking stations
%   GNSS        GNSS constellation adopted (GPS or Galileo)
%   freq_IN     Optional input vector for alternative signal frequencies
%
%_OUTPUTS:
%   Q_vc    Variance-covariance matrix of estimated parameters & ambiguities
%   Qbb     Variance matrix of estimated real-valued parameters
%   Qba     Covariance matrix of estimated parameters & ambiguities
%   Qaa     Variance matrix of estimated float ambiguities
%
% -------------------------------------------------------------------------
% Copyright: Geoscience & Remote Sensing department @ TUDelft | 01/06/2024
% Contact email:    LAMBDAtoolbox-CITG-GRS@tudelft.nl
% -------------------------------------------------------------------------
% Created by
%   01/06/2024  - Lotfi Massarweh
%       Implementation for LAMBDA 4.0, based on Niels Jonkman's version.
%
% Modified by
%   dd/mm/yyyy  - Name Surname author
%       >> Changes made in this new version
% -------------------------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% START
%% MAIN FUNCTION
function [Q_vc,Qbb,Qba,Qaa] = MODEL_GeometryFree(stdIono,Qcode,Qphase,J,K,M,N,GNSS,freq_IN)
%--------------------------------------------------------------------------
% Speed of light (in vacuum) [m]
c = 299792458;

% Check # of input arguments
if nargin < 8
    % Missing signal-frequency selection.
    error('ATTENTION: check that all required inputs are correctly given.')

elseif nargin < 9
    % Choose between GPS or Galileo constellation.
    if strcmp(GNSS,'gps')
        freq_vect = [1575.42e6 ;    % L1  signal
                     1227.60e6 ;    % L2  signal 
                     1176.45e6];    % L5  signal
    elseif strcmp(GNSS,'gal')
        freq_vect = [1575.42e6 ;    % E1  signal
                     1278.75e6 ;    % E6  signal
                     1176.45e6];    % E5a signal
    end      
    
else 
    % User-selected frequency vector & check that it has "J" frequencies.
    freq_vect = freq_IN;
    if length(freq_vect) < J
        error('ATTENTION: frequency input vector has missing signals.')
    end      

end

% Determine carrier frequencies used
freq_used = freq_vect(1:J);

% Compute carrier wavelengths "lambda" + ionospheric coefficient "mu_fact"
lambda = c ./ freq_used;
mu_fact = ( freq_used(1) ./ freq_used ).^2;

%==========================================================================
%% Construct GF-model for "single-epoch"
u_J =  ones(J,1);
o_J = zeros(J,1);
O_J = zeros(J,J);

%--------------------------------------------------- Ionosphere-fixed model
if stdIono == 0                                    
    % Functional model
    A_mat = [u_J  O_J;
   	         u_J  diag(lambda)];

    % Stochastic model
    Q_obs = [4*Qcode   O_J    ;
	           O_J   4*Qphase];
%--------------------------------------------------- Ionosphere-float model
elseif stdIono == 999
    % Functional model
    A_mat = [u_J  +mu_fact    O_J ;
             u_J  -mu_fact  diag(lambda)];
           
    % Stochastic model
    Q_obs = [4*Qcode    O_J;
	            O_J  4*Qphase];
%------------------------------------------------ Ionosphere-weighted model          
else
    % Functional model
    A_mat = [u_J  +mu_fact       O_J    ;
             u_J  -mu_fact  diag(lambda);
              0       1      zeros(1,J)];

    % Stochastic model 
    Q_obs = [4*Qcode   O_J	    o_J;
               O_J   4*Qphase	o_J;
  	           o_J'    o_J'   4*stdIono^2];
end

% Variance-covariance matrix for single-epoch
Qxx = inv( A_mat' * ( Q_obs \ A_mat ) );

% The vc-matrix for range/ionosphere & covariance block with ambiguities
if stdIono == 0
   Qbb = Qxx(1,1);
   Qba = Qxx(1,2:J+1);
else
   Qbb = Qxx(1:2,1:2);
   Qba = Qxx(1:2,3:2+J);
end

% Extract vc-matrix for ambiguity | i.e. lower (J x J) block of Qxx
Qaa = Qxx(end+1-J:end,end+1-J:end);

%==========================================================================
%% Extend GF-model to "multi-epoch"
u_K = ones(K,1);
I_k = eye(K);

% k epoch range/ionosphere vc-matrix
Qbb = kron(I_k,Qbb) + kron(1/K*ones(K)-I_k,Qba*(Qaa\Qba'));

% k epoch range/ionosphere ambiguity covariance matrix
Qba = kron(u_K,Qba) / K;

% The k-epoch vc-matrix is the time average of the 1-epoch vc-matrix
Qaa = Qaa / K;

%==========================================================================
%% Consider GF-model given "M" satellites & "N" stations

% Consider M-satellites
Dm = [-eye(M-1) ones(M-1,1)]';
Qbb = 0.5 * kron(Qbb,Dm'*Dm);
Qba = 0.5 * kron(Qba,Dm'*Dm);
Qaa = 0.5 * kron(Qaa,Dm'*Dm); 

% Consider N-stations
Dn = [-eye(N-1) ones(N-1,1)]';
Qbb = 0.5 * kron(Dn'*Dn,Qbb);
Qba = 0.5 * kron(Dn'*Dn,Qba);
Qaa = 0.5 * kron(Dn'*Dn,Qaa);
   
% Final variance-covariance matrix of estimated parameters & ambiguities
Q_vc = [Qbb  Qba; 
        Qba' Qaa];
    
%--------------------------------------------------------------------------
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END