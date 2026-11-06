function Epoch = CheckSatellitesFixable(Epoch, settings, model, input)
% This function checks which observations are suitable for integer
% ambiguity fixing. Particularly, the existence of biases is checked.
%
% INPUT:
%	Epoch       struct, containing epoch-specific data
%   settings    struct, processing settings from GUI
%   model       struct, observation model
%   input       struct, input data
% OUTPUT:
%	Epoch       updated (Epoch.fixable and, potentially, Epoch.useCode)
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| check function for 2xIF and PPP-AR in UC model


% get current vector fixable
fixable = Epoch.fixable;

% check if DCM is used
DecoupledClock = strcmp(settings.IONO.model, 'Estimate, decoupled clock');

% build matrix with code/phase biases and code/phase observations
switch settings.INPUT.num_freqs
    case 1
        C_bias = Epoch.C1_bias; 
        L_bias = Epoch.L1_bias;
        C_exists = (Epoch.C1 ~= 0 & ~isnan(Epoch.C1));
        L_exists = (Epoch.L1 ~= 0 & ~isnan(Epoch.L1));
    case 2
        C_bias = [Epoch.C1_bias, Epoch.C2_bias];
        L_bias = [Epoch.L1_bias, Epoch.L2_bias]; 
        C_exists = [Epoch.C1 ~= 0 & ~isnan(Epoch.C1), Epoch.C2 ~= 0 & ~isnan(Epoch.C2)];
        L_exists = [Epoch.L1 ~= 0 & ~isnan(Epoch.L1), Epoch.L2 ~= 0 & ~isnan(Epoch.L2)];        
    case 3
        C_bias = [Epoch.C1_bias, Epoch.C2_bias, Epoch.C3_bias];
        L_bias = [Epoch.L1_bias, Epoch.L2_bias, Epoch.L3_bias];
        C_exists = [Epoch.C1 ~= 0 & ~isnan(Epoch.C1), Epoch.C2 ~= 0 & ~isnan(Epoch.C2), Epoch.C3 ~= 0 & ~isnan(Epoch.C3)];
        L_exists = [Epoch.L1 ~= 0 & ~isnan(Epoch.L1), Epoch.L2 ~= 0 & ~isnan(Epoch.L2), Epoch.L3 ~= 0 & ~isnan(Epoch.L3)];              
    otherwise
        fprintf(2, '\nCheckSatellitesFixable.m, an otherwise occurred!\n');
end
        


%% Various reasons for excluding

% excluded satellite are not fixable
fixable(~Epoch.useCode) = false;

% satellites under the AMBIGUITY FIXING cutoff are not fixable
fixable(model.el < settings.AMBFIX.cutoff) = false;

% satellites with cycle slips are not fixable
fixable(~Epoch.usePhase) = false;

% Satellites excluded from ambiguity fixing
% from GUI or, for example, CNES WL recovery and clocks are not integer recovered:
% ftp://ftpsedr.cls.fr/pub/igsac/readme_ELIMSAT.txt (excludeUnfixedSats.m)
excl_prn = settings.AMBFIX.exclude_sats_fixing;
if ~isempty(excl_prn)
    [~,ind] = ismember(Epoch.sats, excl_prn);
    fixable(logical(ind),:) = false;
end




%% (Code) Biases
switch settings.BIASES.code
		
    case {'CODE OSBs', 'CODE MGEX'}
        % nothing to do here for the code biases because they are most 
        % likely zero, check only phase biases
        if ~strcmp(settings.BIASES.phase, 'SGG FCBs') && strcmp(settings.ORBCLK.prec_prod, 'CNES')
            % CNES integer recovery clock
            WL_gps = input.ORBCLK.preciseClk_GPS.WL(Epoch.sats(Epoch.gps))';
            WL_gal = input.ORBCLK.preciseClk_GAL.WL(Epoch.sats(Epoch.gal)-200)';
            b_WL = [WL_gps; WL_gal];
            excl_pbias = (b_WL == 0 | isnan(b_WL));
            excl_pbias = Map2ProcFrqs(excl_pbias, settings.INPUT.num_freqs, settings.IONO.model);
            fixable(excl_pbias) = false;
        elseif strcmp(settings.BIASES.phase, 'off')    
            % CODE phase biases are used for PPP-AR:
            % check phase biases in L_bias
            excl_pbias = (L_bias == 0) & L_exists;
            excl_pbias = Map2ProcFrqs(excl_pbias, settings.INPUT.num_freqs, settings.IONO.model);
            fixable(excl_pbias) = false;
        end
        
    case {'CNES OSBs', 'CNES MGEX', 'GFZ MGEX', 'WUM MGEX', 'WCC MGEX', 'HUST MGEX', 'IGS'...
            'CNES postprocessed'}
        % check code biases in C_bias
        excl_cbias = (C_bias == 0) & C_exists;
        excl_cbias = Map2ProcFrqs(excl_cbias, settings.INPUT.num_freqs, settings.IONO.model);
        fixable(excl_cbias) = false;
        % check phase biases in L_bias
        excl_pbias = (L_bias == 0) & L_exists;
        excl_pbias = Map2ProcFrqs(excl_pbias, settings.INPUT.num_freqs, settings.IONO.model);
        fixable(excl_pbias) = false;
        
    case 'manually'         % e.g., TUG products
        if settings.BIASES.code_manually_Sinex_bool
            % check code biases in C_bias
            excl_cbias = (C_bias == 0) & C_exists;
            excl_cbias = Map2ProcFrqs(excl_cbias, settings.INPUT.num_freqs, settings.IONO.model);
            fixable(excl_cbias) = false;
            % check phase biases in L_bias
            excl_pbias = (L_bias == 0) & L_exists;
            excl_pbias = Map2ProcFrqs(excl_pbias, settings.INPUT.num_freqs, settings.IONO.model);
            fixable(excl_pbias) = false;
        else
            fprintf(2, '\nCheckSatellitesFixable.m, an otherwise occurred!\n');
            % ||| implement
        end
        
    case 'Correction Stream'
            % check code biases in C_bias
            excl_cbias = (C_bias == 0) & C_exists;
            excl_cbias = Map2ProcFrqs(excl_cbias, settings.INPUT.num_freqs, settings.IONO.model);
            fixable(excl_cbias) = false; 
        
    case 'off'
        % nothing to do there
        
    case {'CAS Multi-GNSS DCBs', 'CAS Multi-GNSS OSBs', 'DLR Multi-GNSS DCBs', ...
            'CODE DCBs (P1P2, P1C1, P2C2)', 'Broadcasted TGD'}
        fprintf(2, '\nCheckSatellitesFixable.m, an otherwise occurred!\n');
        % ||| implement

    otherwise
        fprintf(2, '\nCheckSatellitesFixable.m, an otherwise occurred!\n');
end



%% Phase biases
if settings.AMBFIX.bool_AMBFIX || DecoupledClock
    switch settings.BIASES.phase
        case 'off'
            % nothing to do here
        
        case 'SGG FCBs'
            % get WL biases
            b_WL = input.BIASES.WL_UPDs.UPDs(Epoch.sats)';
            % get NL biases
            dt_NL = abs(Epoch.gps_time - input.BIASES.NL_UPDs.sow);
            idx = find(dt_NL == min(dt_NL), 1, 'first');
            b_NL = input.BIASES.NL_UPDs.UPDs(idx, Epoch.sats)';     % (plus is necessary)
            % exclude satellites without WL or NL bias
            excl_pbias = (b_NL == 0  | b_WL == 0 | isnan(b_NL) | isnan(b_WL));
            excl_pbias = Map2ProcFrqs(excl_pbias, settings.INPUT.num_freqs, settings.IONO.model);
            fixable(excl_pbias) = false;
            
        case 'Correction Stream'
            % check phase biases in L_bias
            excl_pbias = (L_bias == 0)  & L_exists;
            excl_pbias = Map2ProcFrqs(excl_pbias, settings.INPUT.num_freqs, settings.IONO.model);
            fixable(excl_pbias) = false;

        case 'WHU phase/clock biases'
            fprintf(2, '\nCheckSatellitesFixable.m, an otherwise occurred!\n');
            % ||| implement

        otherwise
            fprintf(2, '\nCheckSatellitesFixable.m, an otherwise occurred!\n');
    end
end


%% save into Epoch
Epoch.fixable = fixable;
% if DecoupledClock
%     % DCM is sensitive to missing biases -> only use satellites with all biases
%     % Epoch.useCode(~Epoch.fixable & ~Epoch.glo) = false;
% end








