function Adjust = fixedAdjustment_IF(Epoch, Adjust, model, b_WL, b_NL, settings)
% Calculates the fixed solution with a seperate LSQ adjustment on top of 
% the float solution. Uses all available observations and introduces the 
% fixed ambiguities with high weights. 
% 
% INPUT:
%   Epoch       struct, epoch specific data for current epoch
%   Adjust      struct, adjustment data and matrices
%   model    	struct, model corrections for all visible satellites 
%   b_WL,b_NL	WL/NL corrections for satellites of current epoch, SD
%   settings  	struct, processing settings from GUI
% OUTPUT:
%   Adjust      updated with results of fixed adjustment
%
%   Revision:
%   2025/06/11, MFWG: remove unnecessary code (wrong fix detection)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% number of parameters estimated in fixed solution
NO_PARAM_FIX = Adjust.NO_PARAM;     


%% Prepare observations
[model_code_fix, model_phase_fix] = ...
    model_IF_fixed_observations(model, Epoch, Adjust.param, settings);

% calculate observed minus computed; for code and phase as vector alternately
omc(1:2:2*length(Epoch.sats),1) =  (Epoch.code -  model_code_fix).*(~Epoch.exclude);
omc(2:2:2*length(Epoch.sats),1) = (Epoch.phase - model_phase_fix).*(~Epoch.exclude).*(~Epoch.cs_found);

% Get only PRNs with fix 
prn_fixed = intersect(Epoch.sats(~Epoch.exclude), find(~isnan(Epoch.NL_12)) );
% exclude reference satellites
prn_fixed(prn_fixed == Epoch.refSatGPS) = [];
prn_fixed(prn_fixed == Epoch.refSatGAL) = [];
prn_fixed(prn_fixed == Epoch.refSatBDS) = [];
% booleans of fixed satellites for each GNSS 
bool_gps_fix = prn_fixed < 100;
bool_gal_fix = prn_fixed > 200 & prn_fixed < 300;
bool_bds_fix = prn_fixed > 300;
% get fixed satellites for each GNSS
prn_fixed_GPS = prn_fixed(bool_gps_fix);
prn_fixed_GAL = prn_fixed(bool_gal_fix);
prn_fixed_BDS = prn_fixed(bool_bds_fix);
% number of fixed satellites for each GNSS
n_fix_GPS = numel(prn_fixed_GPS);
n_fix_GAL = numel(prn_fixed_GAL);
n_fix_BDS = numel(prn_fixed_BDS);

% get indices of fixed satellites of each GNSS in Epoch.sats
[~, idx_fixed] = intersect(Epoch.sats, prn_fixed);      % indices of fixed satellites in Epoch.sats
[~, idx_fixed_gps] = intersect(Epoch.sats, prn_fixed(bool_gps_fix));
[~, idx_fixed_gal] = intersect(Epoch.sats, prn_fixed(bool_gal_fix));
[~, idx_fixed_bds] = intersect(Epoch.sats, prn_fixed(bool_bds_fix));
% wavelength 1st frequency of fixed satellites
lam1 = Epoch.l1(idx_fixed);
% frequency 1st and 2nd frequency of fixed satellites
f1 = Epoch.f1(idx_fixed);
f2 = Epoch.f2(idx_fixed);

% Generate pseudo-observation for ambiguity, [00]: (4.21) (Note: there is an unecessary WL-correction in the equation)
NL_part =  f1      ./(f1+f2)      .* (Epoch.NL_12(prn_fixed)-b_NL(idx_fixed));
WL_part = (f1.*f2)./(f1.^2-f2.^2) .*  Epoch.WL_12(prn_fixed);
N_IF_fixed = (WL_part + NL_part) .* lam1;
% add pseudo-observation of fixed SD ambiguity to observed-minus-computed vector
omc_fixed = [omc; N_IF_fixed];


%% A-Matrix

A_float = Adjust.A;       			% Design Matrix from float adjustment
n = size(A_float,2);                % number of columns of A-Matrix

% Generate additional A-matrix for GPS
A_GPS = [];
if Epoch.refSatGPS_idx ~= 0
    A_GPS = createFixedA(idx_fixed_gps, n_fix_GPS, n, NO_PARAM_FIX, Epoch.refSatGPS_idx);
end
% Generate additional A-matrix for Galileo
A_GAL = [];
if Epoch.refSatGAL_idx ~= 0
    A_GAL = createFixedA(idx_fixed_gal, n_fix_GAL, n, NO_PARAM_FIX, Epoch.refSatGAL_idx);
end
% Generate additional A-matrix for BeiDou
A_BDS = [];
if Epoch.refSatBDS_idx ~= 0
    A_BDS = createFixedA(idx_fixed_bds, n_fix_BDS, n, NO_PARAM_FIX, Epoch.refSatBDS_idx);
end

% Build A-Matrix with pseudo-observations
A_fixed = [A_float; A_GPS; A_GAL; A_BDS];


%% P-Matrix
P_fixed = createFixedP(...
    idx_fixed_gps, n_fix_GPS, Epoch.refSatGPS_idx, ...
    idx_fixed_gal, n_fix_GAL, Epoch.refSatGAL_idx, ...
    idx_fixed_bds, n_fix_BDS, Epoch.refSatBDS_idx, ...
    model.el*pi/180, Adjust.P);


%% Adjustment
% Least-Squares-Adjustment
dx = adjustment(A_fixed, P_fixed, omc_fixed, Adjust.NO_PARAM);

% save the variables from the fixed adjustment
Adjust.A_fix   =  dx.A;                         % design matrix from fixed adjustment
Adjust.omc_fix = dx.omc;                    	% observed minus computed from fixed adjustment
Adjust.res_fix = dx.v(1:(2*numel(Epoch.sats)));        	% only code+phase residuals
Adjust.param_sigma_fix = dx.Qxx; 				% ||| change this!!!!
Adjust.P_fix   = dx.P;                          % part of weight matrix for fixed adjustment
Adjust.fixed   = true;

% save fixed parameters
Adjust.param_fix = Adjust.param + dx.x;
end



function A_fixed = createFixedA(idx_fixed, no_fixed, n, NO_PARAM_FIX, refSat_idx)
% This function creates the part of the fixed design matrix for a specific GNSS.
% INPUT:
%   idx_fixed       indices of fixed satellites referred to satellites of current epoch
%   no_fixed      	number of fixed satellites for this GNSS
%   n               number of columns in float design matrix
%   NO_PARAM_FIX    number of parameters estimated during the fixed solution
%   refSat_idx      index of reference satellite referred to satellites of current epoch
% OUTPUT:
%   P_fixed         fixed weight matrix
% *************************************************************************

A_fixed = zeros( no_fixed, n);      % initialize
A_fixed(:,NO_PARAM_FIX+refSat_idx) = 1;        % entries of ref. sat. column = 1
elements = sub2ind(size(A_fixed), 1:no_fixed, NO_PARAM_FIX+idx_fixed');
A_fixed(elements) = -1;             % because of satellite single differences

end

function P_fixed = createFixedP(idx_fixed_gps, no_fixed_GPS, refSatGPS_idx, ...
    idx_fixed_gal, no_fixed_GAL, refSatGAL_idx, idx_fixed_bds, no_fixed_BDS, refSatBDS_idx, elev, P_float)
% This function creates the part of the fixed weight matrix for the fixed
% ambiguity pseudo-observations for GPS + Galileo + BeiDou
% INPUT:
%   idx_fixed_gps/_gal/_bds 	
%               indices of fixed satellites referred to satellites of current epoch
%   no_fixed_GPS/_GAL/_BDS   	
%               number of fixed satellites for this GNSS
%   refSat_idx_GPS/_GAL/_BDS   
%               index of reference satellite referred to satellites of current epoch
%   elev    	elevation [rad] for all satellites of current epoch
%   P_float     weight matrix of float solution
% OUTPUT:
%   P_fixed   	fixed weight matrix
% *************************************************************************
% ||| Richtige Kovarianzfortpflanzung machen???

P_GPS = [];     % Generate P-Matrix for GPS
if refSatGPS_idx ~= 0
    P_GPS = createFixedP_GNSS(idx_fixed_gps, no_fixed_GPS, elev, refSatGPS_idx);
end
P_GAL = [];     % Generate P-Matrix for Galileo
if refSatGAL_idx ~= 0
    P_GAL = createFixedP_GNSS(idx_fixed_gal, no_fixed_GAL, elev, refSatGAL_idx);
end
P_BDS = [];     % Generate P-Matrix for BeiDou
if refSatBDS_idx ~= 0
    P_BDS = createFixedP_GNSS(idx_fixed_bds, no_fixed_BDS, elev, refSatBDS_idx);
end
% Build P-Matrix
P_fixed = blkdiag(P_float, P_GPS, P_GAL, P_BDS);

end

function P_GNSS = createFixedP_GNSS(idx_fixed, no_fixed, elev, refSat_idx)
% This function creates the part of the fixed weight matrix for a specific
% GNSS. The pseudo-observations of the fixed ambiguities get large weights.
% INPUT:
%   idx_fixed       indices of fixed satellites referred to satellites of current epoch
%   no_fixed      	number of fixed satellites for this GNSS
%   elev            elevation [rad] for all satellites of current epoch
%   refSat_idx      index of reference satellite referred to satellites of current epoch
% OUTPUT:
%   P_fixed         fixed weight matrix for this GNSS
% *************************************************************************

Q_temp = diag( 1./sin(elev(idx_fixed)).^2 );
Q_temp(end+1,end+1) = 1/(sin(elev(refSat_idx))^2);
C = zeros(no_fixed,no_fixed+1);
C(:,end) = 1;       % Position of reference-satellite
C(:,1:end-1) = -eye(no_fixed);
P_GNSS = (C*Q_temp*C')^(-1)*1000^2;      % 1000 seems to be a good choice

end

