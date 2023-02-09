function Epoch = CheckSatellitesFixable(Epoch, settings, model, input)
% This function checks which satellites are fixable in regards of:
% - fixing cutoff
% - code biases
% - phase biases
%
% INPUT:
%	Epoch       struct, containing epoch-specific data
%   settings    struct, processing settings from GUI
%   model       struct, observation model
%   input       struct, input data
% OUTPUT:
%	Epoch       Epoch.fixable updated
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| check function for 2xIF and PPP-AR in UC model


% build code and phase bias matrix
switch settings.INPUT.num_freqs
    case 1
        C_bias = Epoch.C1_bias;
        L_bias = Epoch.L1_bias;
    case 2
        C_bias = [Epoch.C1_bias, Epoch.C2_bias];
        L_bias = [Epoch.L1_bias, Epoch.L2_bias]; 
    case 3
        C_bias = [Epoch.C1_bias, Epoch.C2_bias, Epoch.C3_bias];
        L_bias = [Epoch.L1_bias, Epoch.L2_bias, Epoch.L3_bias];
    otherwise
        errordlg('CheckSatellitesFixable.m, an otherwise occurred!', 'Error');
end
        


%% Various reasons for excluding

% satellites under the fixing cutoff are not fixable
Epoch.fixable(model.el < settings.AMBFIX.cutoff) = false;

% satellites with cycle slips are not fixable
Epoch.fixable(Epoch.cs_found) = false;



%% Satellites excluded from fixing in general
% from GUI or
% for example, CNES WL recovery and clocks are not integer recovered:
% ftp://ftpsedr.cls.fr/pub/igsac/readme_ELIMSAT.txt (excludeUnfixedSats.m)
excl_prn = settings.AMBFIX.exclude_sats_fixing;
if ~isempty(excl_prn)
    [~,ind] = ismember(Epoch.sats, excl_prn);
    Epoch.fixable(boolean(ind),:) = false;
end




%% (Code) Biases
switch settings.BIASES.code
    case 'CAS Multi-GNSS DCBs'
        errordlg('CheckSatellitesFixable.m!', 'Error');
        % ||| implement
		
    case 'CAS Multi-GNSS OSBs'
        errordlg('CheckSatellitesFixable.m!', 'Error');
        % ||| implement
		
    case 'DLR Multi-GNSS DCBs'
        errordlg('CheckSatellitesFixable.m!', 'Error');
        % ||| implement
        
    case 'CODE DCBs (P1P2, P1C1, P2C2)'
        errordlg('CheckSatellitesFixable.m!', 'Error');
        % ||| implement
        
    case {'CODE OSBs', 'CODE MGEX'}
        % nothing to do here for the code biases because they are most 
        % likely zero, check phase
        if ~strcmp(settings.BIASES.phase, 'SGG FCBs') && strcmp(settings.ORBCLK.prec_prod, 'CNES')
            % CNES integer recovery clock
            WL_gps = input.ORBCLK.preciseClk_GPS.WL(Epoch.sats(Epoch.gps))';
            WL_gal = input.ORBCLK.preciseClk_GAL.WL(Epoch.sats(Epoch.gal)-200)';
            b_WL = [WL_gps; WL_gal];
            excl2 = (b_WL == 0 | isnan(b_WL));
            excl2 = frequency_convert(excl2, settings);
            Epoch.fixable(excl2) = false;
        elseif strcmp(settings.BIASES.phase, 'off')    
            % CODE phase biases are used for PPP-AR:
            % check phase biases in L_bias
            excl2 = (L_bias == 0);
            excl2 = frequency_convert(excl2, settings);
            Epoch.fixable(excl2) = false;
        end
        
    case {'CNES OSBs', 'CNES MGEX', 'GFZ MGEX', 'WUM MGEX'}
        % check code biases in C_bias
        excl1 = (C_bias == 0);
        excl1 = frequency_convert(excl1, settings);
        Epoch.fixable(excl1) = false;
        % check phase biases in L_bias
        excl2 = (L_bias == 0);
        excl2 = frequency_convert(excl2, settings);
        Epoch.fixable(excl2) = false;
        
    case 'CNES postprocessed'
        % check code biases in C_bias
        excl1 = (C_bias == 0);
        excl1 = frequency_convert(excl1, settings);
        Epoch.fixable(excl1) = false;
        % check phase biases in L_bias
        excl2 = (L_bias == 0);
        excl2 = frequency_convert(excl2, settings);
        Epoch.fixable(excl2) = false;
               
    case 'Broadcasted TGD'
        errordlg('CheckSatellitesFixable.m!', 'Error');
        % ||| implement
        
    case 'manually'         % e.g., TUG products
        if settings.BIASES.code_manually_Sinex_bool
            % check code biases in C_bias
            excl1 = (C_bias == 0);
            excl1 = frequency_convert(excl1, settings);
            Epoch.fixable(excl1) = false;
            % check phase biases in L_bias
            excl2 = (L_bias == 0);
            excl2 = frequency_convert(excl2, settings);
            Epoch.fixable(excl2) = false;
        else
            errordlg('CheckSatellitesFixable.m!', 'Error');
            % ||| implement
        end
        
    case 'Correction Stream'
            % check code biases in C_bias
            excl1 = (C_bias == 0);
            excl1 = frequency_convert(excl1, settings);
            Epoch.fixable(excl1) = false; 
        
    case 'off'
        % nothing to do there
        
    otherwise
        errordlg('CheckSatellitesFixable.m, an otherwise occurred!', 'Error');
end



%% Phase biases
if settings.AMBFIX.bool_AMBFIX
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
            excl2 = (b_NL == 0  | b_WL == 0 | isnan(b_NL) | isnan(b_WL));
            excl2 = frequency_convert(excl2, settings);
            Epoch.fixable(excl2) = false;
            
        case 'WHU phase/clock biases'
            errordlg('CheckSatellitesFixable.m!', 'Error');
            % ||| implement
            
        case 'Correction Stream'
            % check phase biases in L_bias
            excl2 = (L_bias == 0);
            excl2 = frequency_convert(excl2, settings);
            Epoch.fixable(excl2) = false;

        otherwise
            errordlg('CheckSatellitesFixable.m, an otherwise occurred!', 'Error');
    end
end



function boolean = frequency_convert(boolean, settings)
% this function checks which ambiguities can not be fixed depending on the
% processed PPP model and number of frequencies
if settings.INPUT.proc_freqs == 1           % e.g. 2-frequency IF LC
    % only one frequency is used in the fixing process, therefore exclude
    % if any of the observations is unfixable
    boolean = any(boolean,2);  
end

% ||| extend for other PPP-AR models






