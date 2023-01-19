%This tool is part of Ps-LAMBDA software used to predict the probability 
%of successful ambiguity resolution, i.e., to compute the success rate of 
%integer estimator or/and its probabilistic bounds. 
%
%This graphical user interface allows to evaluate the success rate for 
%3 integer estimation methods:
%integer least squares (ILS), integer bootstrapping (IB), integer rounding (IR) 
%
%For each integer estimator different bounds and approximations are
%available, as specified below. More information on the bounds and
%approximations can be found in the manual that comes with this software.
%
%The user may select which integer estimators and bounds / approximations
%to consider (any combination is possible).
%
%    UB = upper bound
%    LB = lower bound
%    AP = approximation
%
%INPUT FILE
%
%    This must be a .mat file to be selected by the user. The file should
%    contain the variance (vc-) matrix of the float ambiguities, called Q
%
%    Examples are provided with this software
%
%METHODS AND OPTIONS
%
%    Integer least-squares
%         AP: simulation-based  
%         AP: ADOP-based
%         LB: bootstrapping [DEFAULT]
%         LB: bounding region
%         LB: bounding vc-matrix
%         UB: ADOP-based
%         UB: bounding region
%         UB: bounding vc-matrix
%
%     Integer bootstrapping
%         EXACT success rate [DEFAULT]
%         UB: ADOP-based
%
%     Integer rounding
%         AP: simulation-based
%         LB: diagonal vc-matrix
%         UB: bootstrapping [DEFAULT]
%
%DECORRELATION
%     For rounding and bootstrapping the user must specify whether or not
%     the success rates should be evaluated based on decorrelated
%     ambiguities. It is recommended to apply decorrelation (choose YES),
%     since this will result in (much) higher success rates.
%
%NUMBER OF SAMPLES FOR SIMULATIONS 
%     For the simulation-based approximation (available for integer
%     rounding and integer least-squares), the user must specify the number
%     of samples used. From experience it is known that with 100,000
%     samples the approximation becomes very close to the actual success
%     rate; it is not recommended to use less samples. More samples will
%     give more accurate results, but may take long computation times. 
%
%OUTPUT
%     The output is shown in the boxes for each integer estimation method
%     separately
%
%--------------------------------------------------------------------------
% DATE    : July-2012                                             
% Author  : Bofeng LI and Sandra VERHAGEN                                           
%           GNSS Research Center, Curtin University 
%           MGP, Delft University of Technology                               
%--------------------------------------------------------------------------
%
% REFERENCES: 
%
%  1. Teunissen P(1998) On the integer normal distribution of the GPS 
%     ambiguities. Artificial Satellites 33(2):49–64
%  2. Teunissen P(1998) Success probability of integer GPS ambiguity rounding 
%     and bootstrapping. 72: 606-612
%  3. Teunissen P(2000) The success rate and precision of GPS ambiguities.
%     J Geod 74: 321-326
%  4. Teunissen P(2000) ADOP based upperbounds for bootstrapped and the least
%     squares ambiguity success rates. Artificial satellites, 35(4):171-179 
%  5. Teunissen P(2001) Integer estimation in the presence of biases. J 
%     Geod 75:399-407
%  6. Verhagen S (2005) On the reliability of integer ambiguity resolution.
%     Journal of The Institute of Navigation, 52(2):99-110

%%============================BEGIN PROGRAM==============================%%
