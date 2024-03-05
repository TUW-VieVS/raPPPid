function init_ambi = DetectReceiverClockJump(Epoch, use_column, init_ambi, bool_print)
% This function checks for receiver clock jumps based on the approach
% introduced in 
%   Guo, F., & Zhang, X. (2014). Real-time clock jump compensation for 
%   precise point positioning. GPS Solutions.
%   https://link.springer.com/article/10.1007/s10291-012-0307-3
% Instead of checking for cycle slips, receiver clock jumps are only
% detected if more than half of the satellites are flagged in the first
% step. So this algorithm might fail in the case of many cycle slips.
% 
% INPUT:
%   Epoch           struct, containing epoch-specific data
%   use_column      cell, indicating observation are taken
%   init_ambi       3x410, contains the shift of the phase observations
%   bool_print      boolean, true to print messages to command window
% OUTPUT:
%	init_ambi       containing (new) shift of phase observations
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Wareyka-Glaner
% *************************************************************************


% ||| only observations of first frequency are used
% ||| source code not checked for mGNSS processings


% threshold for detecting receiver clock jump
k1 = 1e-3 * Const.C - 15;           % [m], equation (4), with sigma = 5

% threshold for determining size of receiver clock jump
k2 = 1e-4;                          % or 10-^5, [ms]



%% get observations as they are in the RINEX file

% --- current epoch:
% - code observation on 1st frequency
C1_G = Epoch.obs(Epoch.gps,  use_column{1,4});
C1_R = Epoch.obs(Epoch.glo,  use_column{2,4});
C1_E = Epoch.obs(Epoch.gal,  use_column{3,4});
C1_C = Epoch.obs(Epoch.bds,  use_column{4,4});
C1_J = Epoch.obs(Epoch.qzss, use_column{5,4});
C1 = [C1_G; C1_R; C1_E; C1_C; C1_J];
% - phase observation on 1st frequency
L1_G = Epoch.obs(Epoch.gps,  use_column{1,1});
L1_R = Epoch.obs(Epoch.glo,  use_column{2,1});
L1_E = Epoch.obs(Epoch.gal,  use_column{3,1});
L1_C = Epoch.obs(Epoch.bds,  use_column{4,1});
L1_J = Epoch.obs(Epoch.qzss, use_column{5,1});
L1 = [L1_G; L1_R; L1_E; L1_C; L1_J] .* Epoch.l1;

% --- last epoch:
% - code observation on 1st frequency
C1_G_ = Epoch.old.obs(Epoch.old.gps,  use_column{1,4});
C1_R_ = Epoch.old.obs(Epoch.old.glo,  use_column{2,4});
C1_E_ = Epoch.old.obs(Epoch.old.gal,  use_column{3,4});
C1_C_ = Epoch.old.obs(Epoch.old.bds,  use_column{4,4});
C1_J_ = Epoch.old.obs(Epoch.old.qzss, use_column{5,4});
C1_ = [C1_G_; C1_R_; C1_E_; C1_C_; C1_J_];
% - phase observation on 1st frequency
L1_G_ = Epoch.old.obs(Epoch.old.gps,  use_column{1,1});
L1_R_ = Epoch.old.obs(Epoch.old.glo,  use_column{2,1});
L1_E_ = Epoch.old.obs(Epoch.old.gal,  use_column{3,1});
L1_C_ = Epoch.old.obs(Epoch.old.bds,  use_column{4,1});
L1_J_ = Epoch.old.obs(Epoch.old.qzss, use_column{5,1});
L1_ = [L1_G_; L1_R_; L1_E_; L1_C_; L1_J_] .* Epoch.old.l1;



%% create clock jump detection observable

% check which satellites are observed in both epochs
[~, idx, idx_] = intersect(Epoch.sats, Epoch.old.sats);

% epoch difference code and phase observations
dC1(idx) = C1(idx) - C1_(idx_);
dL1(idx) = L1(idx) - L1_(idx_);

% clock jump detection observable
S1 = dC1 - dL1;             	% [m], (1), for all satellites



%% receiver clock jump detection

clock_jump_1 = abs(S1) > k1;  	% (3), boolean for all satellite

n = sum(clock_jump_1);          % number of satellites with detected clock jump
n_sats = numel(Epoch.sats);     % number of satellites

if n > n_sats/2  	% > 50% of clock jumps?
    if bool_print
        fprintf('Epoch %d: receiver clock jump detected            \n', Epoch.q)
    end
    
    % calculate magnitude of clock jump
    M = 1e3 * sum(S1(clock_jump_1)) / (n*Const.C); 	% (6), real magnitude
    Js = 0;
    if abs(M - round(M)) <= k2
        Js = round(M);      % (7), integer magnitude  
    end
   
    % (9), adjust phase to keep consistency with code, calculate shift
    K = 1e-3;       % constant for ms jumps
    L1_shift = K * Js * Const.C ./ Epoch.l1;
    L2_shift = K * Js * Const.C ./ Epoch.l2;
    L3_shift = K * Js * Const.C ./ Epoch.l3;
    
    % save shift, will be applied in AdjustPhase2Code
    sats = Epoch.sats(idx);
    init_ambi(1,sats) = init_ambi(1,sats) + L1_shift(idx)';
    init_ambi(2,sats) = init_ambi(2,sats) + L2_shift(idx)';
    init_ambi(3,sats) = init_ambi(3,sats) + L3_shift(idx)';
end










