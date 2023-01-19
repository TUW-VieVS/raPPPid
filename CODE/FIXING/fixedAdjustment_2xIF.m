function [Adjust, Epoch] = fixedAdjustment_2xIF(Epoch, Adjust, input, model, TUW_corr, wrongFixes)
% ||| EXPERIMENTAL FUNCTION
% 
% Adjustment with fixed Ambiguities as a 2nd adjustment with ZD float
% solution. Uses all available observations and weights the ones with fixed
% ambiguities accordingly high
% INPUT:
%   Epoch       epoch specific data for current epoch [struct]
%   Adjust      adjustment data and matrices [struct]
%   input     	input data e.g. ephemeris [struct]
%   model       model corrections for all visible satellites [struct]
%   TUW_corr	boolean, true if TUW-UPD-corrections are enabled
%   wrongFixes 	string, setting for detection of wrong fixes from GUI
% OUTPUT:
%   Adjust      updated with results of fixed adjustment
%   Epoch       updated with results of fixed adjustment
%
%   Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


NO_PARAM = Adjust.NO_PARAM;         % number of estimated parameters
% Cut clock offsets and Troposphere estimate/columns from A-matrix, take already estimated values
A_float = Adjust.A;       			% Design Matrix from float adjustment
A_float(:, 4:NO_PARAM) = [];
n = size(A_float,2);              	% number of columns of A-Matrix


%% Prepare observations
[model_code_fix, model_phase_fix] = ...
    model_fixed_observations(model, Epoch, Adjust.param);

% calculate observed minus computed exlude satellites under cutoff-angle
% for code and phase as vector alternately
omc(1:2:2*length(Epoch.sats),1:2) =  (Epoch.code -  model_code_fix).*(~Epoch.exclude);
omc(2:2:2*length(Epoch.sats),1:2) = (Epoch.phase - model_phase_fix).*(~Epoch.exclude);

% Get only PRNs with fix for WL and NL and exclude reference satellite
prn_fix_1 = intersect(Epoch.sats(~Epoch.exclude(:,1)), find(~isnan(Epoch.NL_12)) );
prn_fix_1(prn_fix_1 == Epoch.refSatGPS) = [];
prn_fix_1(prn_fix_1 == Epoch.refSatGAL) = [];
prn_fix_1_GPS = prn_fix_1(prn_fix_1 < 100);
prn_fix_1_GAL = prn_fix_1(prn_fix_1 > 200);
no_fix_1_GPS = numel(prn_fix_1_GPS);
no_fix_1_GAL = numel(prn_fix_1_GAL);
% Get only PRNs with fix for EW and EN and exclude reference satellite
prn_fix_2 = intersect(Epoch.sats(~Epoch.exclude(:,2)), find(~isnan(Epoch.NL_23)) );
prn_fix_2(prn_fix_2 == Epoch.refSatGPS) = [];
prn_fix_2(prn_fix_2 == Epoch.refSatGAL) = [];
prn_fix_2_GPS = prn_fix_2(prn_fix_2 < 100);
prn_fix_2_GAL = prn_fix_2(prn_fix_2 > 200);
no_fix_2_GPS = numel(prn_fix_2_GPS);
no_fix_2_GAL = numel(prn_fix_2_GAL);

% calculate corresponding Narrow-Lane correction
b_NL = zeros(size(prn_fix_1,1),1);      % corrections from CNES-stream or simulated data
if TUW_corr      % Use only prns with corrections
    prn_corr = find(~isnan(input.TUCor_NL));    % ||| check if ever used
    prn_fix_1 = intersect(prn_fix_1,prn_corr);
    b_NL = input.TUCor_NL(prn_fix_1);
end
% calculate corresponding Narrow-Lane correction
b_NL2 = zeros(size(prn_fix_2,1),1);      % corrections from CNES-stream or simulated data
if TUW_corr      % Use only prns with corrections
    prn_corr = find(~isnan(input.TUCor_NL));    % ||| check if ever used
    prn_fix_2 = intersect(prn_fix_2,prn_corr);
    b_NL2 = input.TUCor_NL(prn_fix_2);
end



% get indices of fixed satellites in Epoch.sats
[~, idx_fix_1] = intersect(Epoch.sats, prn_fix_1);      % indices of fixed satellites in Epoch.sats
[~, idx_fix_1_gps] = intersect(Epoch.sats, prn_fix_1(prn_fix_1<100));
[~, idx_fix_1_gal] = intersect(Epoch.sats, prn_fix_1(prn_fix_1>200));
[~, idx_fix_2] = intersect(Epoch.sats, prn_fix_2);      % indices of fixed satellites in Epoch.sats
[~, idx_fix_2_gps] = intersect(Epoch.sats, prn_fix_2(prn_fix_2<100));
[~, idx_fix_2_gal] = intersect(Epoch.sats, prn_fix_2(prn_fix_2>200));
% wavelength 1st frequency of fixed satellites
lam1 = Epoch.l1(idx_fix_1);
lam2 = Epoch.l2(idx_fix_2);
% frequencies of fixed satellites
f1_1 = Epoch.f1(idx_fix_1);
f2_1 = Epoch.f2(idx_fix_1);
f3_1 = Epoch.f3(idx_fix_1);
f1_2 = Epoch.f1(idx_fix_2);
f2_2 = Epoch.f2(idx_fix_2);
f3_2 = Epoch.f3(idx_fix_2);

% Generate pseudo-observation fixed ambiguity for 1st IF-LC, [00]: (4.21)
% WL-correction is missing in comparison with [00]: (4.21) ??
NL_part1 =  f1_1      ./(f1_1+f2_1)        .* (Epoch.NL_12(prn_fix_1)-b_NL);
WL_part1 = (f1_1.*f2_1)./(f1_1.^2-f2_1.^2) .*  Epoch.WL_12(prn_fix_1);
N_IF1_fixed = (NL_part1 + WL_part1) .* lam1;
% Generate pseudo-observation fixed ambiguity for 2nd IF-LC
EN_part =  f2_2      ./(f2_2+f3_2)         .* (Epoch.NL_23(prn_fix_2)-b_NL2);
EW_part = (f2_2.*f3_2)./(f2_2.^2-f3_2.^2)  .*  Epoch.WL_23(prn_fix_2);
N_IF2_fixed = (EN_part + EW_part) .* lam2;

% add pseudo-observation of fixed ambiguity to observed-minus-computed vector
omc_fixed = [omc(:); N_IF1_fixed; N_IF2_fixed];


%% A-Matrix
% Generate additional A-matrix for GPS
no_sats = numel(Epoch.sats);
A_GPS_1 = []; A_GPS_2 = [];
if Epoch.refSatGPS_idx ~= 0
    A_GPS_1 = createFixedA(idx_fix_1_gps, no_fix_1_GPS, n, Epoch.refSatGPS_idx);
    A_GPS_2 = createFixedA(no_sats+idx_fix_2_gps, no_fix_2_GPS, n, no_sats+Epoch.refSatGPS_idx);
end
% Generate additional A-matrix for Galileo
A_GAL_1 = []; A_GAL_2 = [];
if Epoch.refSatGAL_idx ~= 0
    A_GAL_1 = createFixedA(idx_fix_1_gal, no_fix_1_GAL, n, Epoch.refSatGAL_idx);
    A_GAL_2 = createFixedA(no_sats+idx_fix_2_gal, no_fix_2_GAL, n, no_sats+Epoch.refSatGAL_idx);
end
% Build A-Matrix with pseudo-observations
A_fixed = [A_float; A_GPS_1; A_GAL_1; A_GPS_2; A_GAL_2];


%% P-Matrix
P_fix_1 = createFixedP(idx_fix_1_gps, no_fix_1_GPS, Epoch.refSatGPS_idx, ...
    idx_fix_1_gal, no_fix_1_GAL, Epoch.refSatGAL_idx, model.el*pi/180);
P_fix_2 = createFixedP(idx_fix_2_gps, no_fix_2_GPS, Epoch.refSatGPS_idx, ...
    idx_fix_2_gal, no_fix_2_GAL, Epoch.refSatGAL_idx, model.el*pi/180);
P_float = Adjust.P;
P_fix = blkdiag(P_float, P_fix_1, P_fix_2);


%% Adjustment
% Least-Squares-Adjustment, only 3 coordinates and ambiguities get estimated
dx = adjustment(A_fixed, P_fix, omc_fixed, 3);
% save variables from fixed adjustment into Adjust
Adjust = saveFixedAdjustment_2xIF(dx, Adjust, Epoch.no_sats);



%% Check for wrong fixes
% ||| re-design for 2xIF-PPP-AR
% ||| maybe do this check only if a satellite was fixed newly
% if numel(idx_fix_1) > 3            % 4 Fixes are necessary to detect a wrong fix
%     no_sats = Epoch.no_sats;
%     switch wrongFixes
%         
%         case 'Difference to float solution'
%             coord_float = Adjust.param(1:3);            % coordinates from fixed adjustment
%             coord_fixed = coord_float + dx.x(1:3);          % coordinates from fixed adjustment
%             diff_ff = coord_float - coord_fixed;
%             if norm(diff_ff) > .25
%                 
%                 diffs = NaN(1, length(idx_fix_1));    % to store the maximum residuals
%                 for i = 1:length(idx_fix_1)
%                     dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fix_1, i, model.el*pi/180);
%                     diffs(i) = norm( coord_float - (coord_float + dx_new.x(1:3)) );
%                 end
%                 if min(diffs) < .10
%                     idx_excl = find(min(diffs) == diffs);       % index of bad satellite
%                     prn_excl = Epoch.sats(idx_fix_1(idx_excl(1)));
%                     fprintf('\tNL Fix of PRN %03d should be changed                          \n', prn_excl);
%                     Epoch.NL_12(prn_excl) = NaN;
%                     % perform this adjustment again
%                     dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fix_1, i, model.el*pi/180);
%                     Adjust = saveFixedAdjustment(dx_new, Adjust, no_sats);
%                 end
%             end
%             
%         case 'vTPv'
%             vTPv_all = dx.v'*dx.P*dx.v;
%             
% %             idx_float = 1:2*numel(Epoch.sats);
% %             vTPv_all_float = dx.v(idx_float)'*dx.P(idx_float,idx_float)*dx.v(idx_float);
% %             index_fixed = (2*numel(Epoch.sats) + 1) : (2*numel(Epoch.sats)+numel(idx_fixed));
% %             vTPv_all_fixed = dx.v(index_fixed)'*dx.P(index_fixed,index_fixed)*dx.v(index_fixed);
%             
%             vtPvs = NaN(1, length(idx_fix_1));      % to store the maximum residuals
%             for i = 1:length(idx_fix_1)
%                 dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fix_1, i, model.el*pi/180);
%                 vtPvs(i) = dx_new.v'*dx_new.P*dx_new.v;      % save "Verbesserungsquadratsumme"
%                 
% %                 idx_float = 1:2*numel(Epoch.sats);
% %                 vTPvs_float(i) = dx_new.v(idx_float)'*dx_new.P(idx_float,idx_float)*dx_new.v(idx_float);
% %                 index_fixed = (2*numel(Epoch.sats) +1) : (2*numel(Epoch.sats)+numel(idx_fixed)-1);
% %                 vTPvs_fixed(i) = dx_new.v(index_fixed)'*dx_new.P(index_fixed,index_fixed)*dx_new.v(index_fixed);
%                 
%                 
%             end
%             % check if exclusion of one satellite significantly improves Verbesserungsquadratsumme
%             if min(vtPvs) <= vTPv_all - 2*std(vtPvs) && (std(vtPvs) > 3)        % ||| very random threshold
%                 idx_excl = find(min(vtPvs) == vtPvs);       % index of bad satellite
%                 prn_excl = Epoch.sats(idx_fix_1(idx_excl(1)));
%                 fprintf('\tNL Fix of PRN %03d should be changed                          \n', prn_excl);
%                 Epoch.NL_12(prn_excl) = NaN;
%                 % perform this adjustment again
%                 dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fix_1, i, model.el*pi/180);
%                 Adjust = saveFixedAdjustment(dx_new, Adjust, no_sats);
%             end
% 
% 
% 
% 
% %             % check if exclusion of one satellite significantly improves Verbesserungsquadratsumme
% %             if min(vTPvs_fixed) <= vTPv_all - 2*std(vTPvs_fixed) && (std(vTPvs_fixed) > .5)        % ||| very random threshold
% %                 idx_excl = find(min(vTPvs_fixed) == vTPvs_fixed);       % index of bad satellite
% %                 prn_excl = Epoch.sats(idx_fixed(idx_excl(1)));
% %                 fprintf('\tNL Fix of PRN %03d should be changed                          \n', prn_excl);
% %                 Epoch.NL_12(prn_excl) = NaN;
% %                 % perform this adjustment again
% %                 dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fixed, i, model.el*pi/180);
% %                 Adjust = saveFixedAdjustment(dx_new, Adjust, no_sats);
% %             end
%             
%         case '?????'
% 
%             % ||| maybe check of residuals or observed-computed
%             
%     end
% end


% calculates coordinates from fixed adjustment
Adjust.xyz_fix = Adjust.param(1:3) + dx.x(1:3);
Adjust.fixed = true;

end


function A_fixed = createFixedA(idx_fixed, no_fixed, n, refSat_idx)
% This function creates the part of the fixed design matrix for a specific GNSS.
% INPUT:
%   idx_fixed       indices of fixed satellites referred to satellites of current epoch
%   no_fixed      	number of fixed satellites for this GNSS
%   n               number of columns in float design matrix
%   refSat_idx      index of reference satellite referred to satellites of current epoch
% OUTPUT:
%   P_fixed         fixed weight matrix
% *************************************************************************

A_fixed = zeros( no_fixed, n);
A_fixed(:,3+refSat_idx) = 1;        % entries of ref. sat. column = 1
elements = sub2ind(size(A_fixed), 1:no_fixed, 3+idx_fixed');
A_fixed(elements) = -1;             % because of single difference

end


function P_fixed = createFixedP(idx_fixed_gps, no_fixed_GPS, refSatGPS_idx, idx_fixed_gal, no_fixed_GAL, refSatGAL_idx, elev)
% This function creates the part of the fixed weight matrix for the fixed
% ambiguity pseudo-observations for GPS + Galileo
% INPUT:
%   idx_fixed_gps/_gal    	indices of fixed satellites referred to satellites of current epoch
%   no_fixed_GPS/_GAL      	number of fixed satellites for this GNSS
%   refSat_idx_GPS/_GAL     index of reference satellite referred to satellites of current epoch
%   elev                    elevation [rad] for all satellites of current epoch
% OUTPUT:
%   P_fixed         fixed weight matrix
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
% Build P-Matrix
P_fixed = blkdiag(P_GPS, P_GAL);

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
C(:,1:end-1) = eye(no_fixed)*-1;
P_GNSS = (C*Q_temp*C')^(-1)*1000^2;      % 1000 seems to be a good choice

end


function [Adjust] = saveFixedAdjustment_2xIF(dx, Adjust, no_sats)
% function to save the variables from the fixed adjustment
Adjust.A_fix = dx.A;                         	% design matrix from fixed adjustment
Adjust.omc_fix = dx.omc;                    	% observed minus computed from fixed adjustment
idx1 = 1:(2*no_sats);
idx2 = (2*no_sats+1):(4*no_sats);
Adjust.res_fix(:,1) = dx.v(idx1);            	% code+phase residuals IF-LC 1 
Adjust.res_fix(:,2) = dx.v(idx2);           	% code+phase residuals IF-LC 2 
Adjust.param_sigma_fix = dx.Qxx;  				% ||| change this!!!!
Adjust.P_fix = dx.P;                         	% part of weight matrix for fixed adjustment
% parameters are saved later
end


function dx = fixedAdjustmentExclude(Adjust, Epoch, prn_fix, i_excl, elev)
% This function calculates new a fixed solution where specific satellites
% are excluded.
% INPUT:
%   Adjust      struct,
%   Epoch       struct,
%   prn_fixed       vector with fixed satellite prns
%   i_excl          index of the satellite from prn_fixed which is excluded
%   elev            [rad]
% OUTPUT:
%   dx
% *************************************************************************

prn_fix_temp = prn_fix;
prn_excl = prn_fix(i_excl);
prn_fix_temp(i_excl) = [];


% create some variables
[~, idx_fixed_gps] = intersect(Epoch.sats, prn_fix_temp(prn_fix_temp<100));
[~, idx_fixed_gal] = intersect(Epoch.sats, prn_fix_temp(prn_fix_temp>200));
no_fixed_GPS = numel(idx_fixed_gps);
no_fixed_GAL = numel(idx_fixed_gal);
% get some variables
no_sats = numel(Epoch.sats);
A = Adjust.A_fix;
omc = Adjust.omc_fix;

% create new weight matrix without excluded fixed satellite and remove it
% from omc and design matrix
delete = 2*no_sats + i_excl;
omc(delete) = [];
A(delete,:) = [];
P = createFixedP(idx_fixed_gps, no_fixed_GPS, Epoch.refSatGPS_idx, ...
    idx_fixed_gal, no_fixed_GAL, Epoch.refSatGAL_idx, elev, Adjust.P);

% new fixed adjustment
dx = adjustment(A, P, omc, 3);

end
