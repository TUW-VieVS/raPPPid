function [Adjust, Epoch] = fixedAdjustment_IF(Epoch, Adjust, model, b_WL, b_NL, wrongFixes)
% Adjustment with fixed Ambiguities as a 2nd adjustment with ZD float
% solution. Uses all available observations and weights the ones with fixed
% ambiguities accordingly high
% 
% INPUT:
%   Epoch       epoch specific data for current epoch [struct]
%   Adjust      adjustment data and matrices [struct]
%   model    	model corrections for all visible satellites [struct]
%   b_WL,b_NL	WL/NL corrections for satellites of current epoch, SD
%   wrongFixes  string, setting for detection of wrong fixes from GUI
% OUTPUT:
%   Adjust      updated with results of fixed adjustment
%   Epoch       updated with results of fixed adjustment
%
%   Revision:
%   	...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


NO_PARAM = Adjust.NO_PARAM;         % number of estimated parameters
% Cut clock offsets and Troposphere estimate/columns from A-matrix, take already estimated values
A_float = Adjust.A;       			% Design Matrix from float adjustment
A_float(:, 4:NO_PARAM) = [];
n = size(A_float,2);                % number of columns of A-Matrix
no_GLO = sum(Epoch.glo);            % number of Glonass satellites


%% Prepare observations
[model_code_fix, model_phase_fix] = ...
    model_IF_fixed_observations(model, Epoch, Adjust.param);

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
no_fixed_GPS = numel(prn_fixed_GPS);
no_fixed_GAL = numel(prn_fixed_GAL);
no_fixed_BDS = numel(prn_fixed_BDS);

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
NL_part =  f1      ./(f1+f2)       .* (Epoch.NL_12(prn_fixed)-b_NL(idx_fixed));
WL_part = (f1.*f2)./(f1.^2-f2.^2) .*  Epoch.WL_12(prn_fixed);
N_IF_fixed = (WL_part + NL_part) .* lam1;
% add pseudo-observation of fixed SD ambiguity to observed-minus-computed vector
omc_fixed = [omc; N_IF_fixed];


%% A-Matrix
% Generate additional A-matrix for GPS
A_GPS = [];
if Epoch.refSatGPS_idx ~= 0
    A_GPS = createFixedA(idx_fixed_gps, no_fixed_GPS, n, Epoch.refSatGPS_idx);
end
% Generate additional A-matrix for Galileo
A_GAL = [];
if Epoch.refSatGAL_idx ~= 0
    A_GAL = createFixedA(idx_fixed_gal, no_fixed_GAL, n, Epoch.refSatGAL_idx);
end
% Generate additional A-matrix for BeiDou
A_BDS = [];
if Epoch.refSatBDS_idx ~= 0
    A_BDS = createFixedA(idx_fixed_bds, no_fixed_BDS, n, Epoch.refSatBDS_idx);
end
% Build A-Matrix with pseudo-observations
A_fixed = [A_float; A_GPS; A_GAL; A_BDS];


%% P-Matrix
P_fixed = createFixedP(idx_fixed_gps, no_fixed_GPS, Epoch.refSatGPS_idx, ...
    idx_fixed_gal, no_fixed_GAL, Epoch.refSatGAL_idx, ...
    idx_fixed_bds, no_fixed_BDS, Epoch.refSatBDS_idx, ...
    model.el*pi/180, Adjust.P);


%% Adjustment
% Least-Squares-Adjustment, only 3 coordinates and ambiguities get estimated
dx = adjustment(A_fixed, P_fixed, omc_fixed, 3);
% save variables from fixed adjustment into Adjust
Adjust = saveFixedAdjustment(dx, Adjust, Epoch);



%% Check for wrong fixes
% ||| maybe do this check only if a satellite was fixed newly
if numel(idx_fixed) > 3            % 4 Fixes are necessary to detect a wrong fix
    no_sats = Epoch.no_sats;
    switch wrongFixes
        
        case 'Difference to float solution'
            coord_float = Adjust.param(1:3);            % coordinates from fixed adjustment
            coord_fixed = coord_float + dx.x(1:3);          % coordinates from fixed adjustment
            diff_ff = coord_float - coord_fixed;
            if norm(diff_ff) > .25
                
                diffs = NaN(1, length(idx_fixed));    % to store the maximum residuals
                for i = 1:length(idx_fixed)
                    dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fixed, i, model.el*pi/180);
                    diffs(i) = norm( coord_float - (coord_float + dx_new.x(1:3)) );
                end
                if min(diffs) < .10
                    idx_excl = find(min(diffs) == diffs);       % index of bad satellite
                    prn_excl = Epoch.sats(idx_fixed(idx_excl(1)));
                    fprintf('\tNL Fix of PRN %03d should be changed                          \n', prn_excl);
                    Epoch.NL_12(prn_excl) = NaN;
                    % perform this adjustment again
                    dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fixed, i, model.el*pi/180);
                    Adjust = saveFixedAdjustment(dx_new, Adjust, Epoch);
                end
            end
            
        case 'vTPv'
            vTPv_all = dx.v'*dx.P*dx.v;
            
%             idx_float = 1:2*numel(Epoch.sats);
%             vTPv_all_float = dx.v(idx_float)'*dx.P(idx_float,idx_float)*dx.v(idx_float);
%             index_fixed = (2*numel(Epoch.sats) + 1) : (2*numel(Epoch.sats)+numel(idx_fixed));
%             vTPv_all_fixed = dx.v(index_fixed)'*dx.P(index_fixed,index_fixed)*dx.v(index_fixed);
            
            vtPvs = NaN(1, length(idx_fixed));      % to store the maximum residuals
            for i = 1:length(idx_fixed)
                dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fixed, i, model.el*pi/180);
                vtPvs(i) = dx_new.v'*dx_new.P*dx_new.v;      % save "Verbesserungsquadratsumme"
                
%                 idx_float = 1:2*numel(Epoch.sats);
%                 vTPvs_float(i) = dx_new.v(idx_float)'*dx_new.P(idx_float,idx_float)*dx_new.v(idx_float);
%                 index_fixed = (2*numel(Epoch.sats) +1) : (2*numel(Epoch.sats)+numel(idx_fixed)-1);
%                 vTPvs_fixed(i) = dx_new.v(index_fixed)'*dx_new.P(index_fixed,index_fixed)*dx_new.v(index_fixed);
                
                
            end
            % check if exclusion of one satellite significantly improves Verbesserungsquadratsumme
            if min(vtPvs) <= vTPv_all - 2*std(vtPvs) && (std(vtPvs) > 3)        % ||| very random threshold
                idx_excl = find(min(vtPvs) == vtPvs);       % index of bad satellite
                prn_excl = Epoch.sats(idx_fixed(idx_excl(1)));
                fprintf('\tNL Fix of PRN %03d should be changed                          \n', prn_excl);
                Epoch.NL_12(prn_excl) = NaN;
                % perform this adjustment again
                dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fixed, i, model.el*pi/180);
                Adjust = saveFixedAdjustment(dx_new, Adjust, Epoch);
            end




%             % check if exclusion of one satellite significantly improves Verbesserungsquadratsumme
%             if min(vTPvs_fixed) <= vTPv_all - 2*std(vTPvs_fixed) && (std(vTPvs_fixed) > .5)        % ||| very random threshold
%                 idx_excl = find(min(vTPvs_fixed) == vTPvs_fixed);       % index of bad satellite
%                 prn_excl = Epoch.sats(idx_fixed(idx_excl(1)));
%                 fprintf('\tNL Fix of PRN %03d should be changed                          \n', prn_excl);
%                 Epoch.NL_12(prn_excl) = NaN;
%                 % perform this adjustment again
%                 dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fixed, i, model.el*pi/180);
%                 Adjust = saveFixedAdjustment(dx_new, Adjust, no_sats);
%             end
            
        case '?????'
            % test of exclusion of fixed satellites depending on the
            % difference of the fixed to the float IF ambiguity
            
            NO_PARAM = Adjust.NO_PARAM;     % number of estimated parameters
            no_gps = sum(Epoch.gps);    	% number of GPS satellites
            no_gal = sum(Epoch.gal);        % number of Galileo satellites
            no_glo = sum(Epoch.glo);        % number of Glonass satellites
            refSatG_idx = Epoch.refSatGPS_idx;  % index of GPS reference satellite
            refSatE_idx = Epoch.refSatGAL_idx;  % index of Galileo reference satellite
            
            % get float ambiguities
            N = Adjust.param((NO_PARAM+1):(NO_PARAM+no_sats));    % float ambiguities
            N_gps = N(Epoch.gps);       % gps float ambiguities
            N_gal = N(Epoch.gal);       % galileo float ambiguities
            % single difference float ambiguities
            N_gps_SD = N_gps(refSatG_idx) - N_gps;
            N_gal_SD = N_gal(refSatE_idx-no_gps-no_glo) - N_gal;
            N_SD = [N_gps_SD; N_gal_SD];    % build vector of single-differenced ambiguities
            % get float SD ambiguities of fixed satellites only
            bool_fixed = ~isnan(Epoch.NL_12(Epoch.sats)) & ~isnan(Epoch.WL_12(Epoch.sats)) & ~Epoch.exclude;
            bool_fixed(Epoch.refSatGPS_idx) = false;
            bool_fixed(Epoch.refSatGAL_idx) = false;            
            N_float_SD = N_SD(bool_fixed);
            
            % calculate difference between float and fixed ambiguities
            diff = N_float_SD - N_IF_fixed;     % [m]
            i = find(diff==max(diff));
            
            % perform fixed adjustment with one satellite excluded
            dx_new = fixedAdjustmentExclude(Adjust, Epoch, prn_fixed, i, model.el*pi/180);
            Adjust = saveFixedAdjustment(dx_new, Adjust, Epoch);
    end
end


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


function [Adjust] = saveFixedAdjustment(dx, Adjust, Epoch)
no_sats = numel(Epoch.sats);
% function to save the variables from the fixed adjustment
Adjust.A_fix   =  dx.A;                         % design matrix from fixed adjustment
Adjust.omc_fix = dx.omc;                    	% observed minus computed from fixed adjustment
Adjust.res_fix = dx.v(1:(2*no_sats));        	% only code+phase residuals
Adjust.param_sigma_fix = dx.Qxx; 				% ||| change this!!!!
Adjust.P_fix   = dx.P;                          % part of weight matrix for fixed adjustment
% parameters are saved later
end


function dx = fixedAdjustmentExclude(Adjust, Epoch, prn_fix, i_excl, elev)
% This function calculates new a fixed solution where specific satellites
% are excluded.
% INPUT:
%   Adjust          struct, ...
%   Epoch           struct, ...
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
[~, idx_fixed_gal] = intersect(Epoch.sats, prn_fix_temp(prn_fix_temp>200 & prn_fix_temp<300));
[~, idx_fixed_bds] = intersect(Epoch.sats, prn_fix_temp(prn_fix_temp>300));
no_fixed_GPS = numel(idx_fixed_gps);
no_fixed_GAL = numel(idx_fixed_gal);
no_fixed_BDS = numel(idx_fixed_bds);
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
    idx_fixed_gal, no_fixed_GAL, Epoch.refSatGAL_idx, idx_fixed_bds, no_fixed_BDS, Epoch.refSatBDS_idx, elev, Adjust.P);

% new fixed adjustment
dx = adjustment(A, P, omc, 3);

end
