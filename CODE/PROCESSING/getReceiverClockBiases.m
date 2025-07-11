function model = getReceiverClockBiases(model, Epoch, param_, settings)
% This function extract the estimated values for the receiver clock error,
% offsets, and biases from the parameter vector. This values are saved into
% the struct model and used to model the observations (e.g., in
% model_observations.m)
%
% INPUT:
%   model       struct, observation model
%   param_      parameter vector of the float solution, prediction
%   Epoch       struct, epoch-specific data
%   settings    struct, settings from GUI
% OUTPUT:
%	model       updated with values for receiver clock error, offsets, and biases
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2024, M.F. Wareyka-Glaner
% *************************************************************************


DecoupledClockModel = strcmp(settings.IONO.model, 'Estimate, decoupled clock');
num_freq = settings.INPUT.proc_freqs;   % number of processed frequencies


%% receiver clock
% get either:
%     - receiver clock error and receiver clock offset(s) 
%   OR
%     - receiver clock errors for code and phase (decoupled clock model)

if ~DecoupledClockModel
    % receiver clock error is the same for code and phase observation
    model.dt_rx_clock(Epoch.gps,  :) = param_( 8);
    model.dt_rx_clock(Epoch.glo,  :) = param_( 8) + param_(11);
    model.dt_rx_clock(Epoch.gal,  :) = param_( 8) + param_(14);
    model.dt_rx_clock(Epoch.bds,  :) = param_( 8) + param_(17);
    model.dt_rx_clock(Epoch.qzss, :) = param_( 8) + param_(20);
elseif DecoupledClockModel
    % code receiver clock error
    model.dt_rx_clock_code(Epoch.gps,  :) = param_( 8);
    model.dt_rx_clock_code(Epoch.glo,  :) = param_( 9);
    model.dt_rx_clock_code(Epoch.gal,  :) = param_(10);
    model.dt_rx_clock_code(Epoch.bds,  :) = param_(11);
    model.dt_rx_clock_code(Epoch.qzss, :) = param_(12);
    % phase receiver clock error
    model.dt_rx_clock_phase(Epoch.gps, :) = param_(13);
    model.dt_rx_clock_phase(Epoch.glo, :) = param_(14);
    model.dt_rx_clock_phase(Epoch.gal, :) = param_(15);
    model.dt_rx_clock_phase(Epoch.bds, :) = param_(16);
    model.dt_rx_clock_phase(Epoch.qzss,:) = param_(17);
end


%% receiver biases 
% get either:
%     - receiver DCB(s) (uncombined model)
%   OR
%     - receiver IFB, L2 bias, and L3 bias (decoupled clock model)

if settings.BIASES.estimate_rec_dcbs && ~DecoupledClockModel
    % receiver DCB_12 and DCB_13 are estimated
    if num_freq > 1
        model.dcbs(Epoch.gps,  2) = param_( 9);
        model.dcbs(Epoch.glo,  2) = param_(12);
        model.dcbs(Epoch.gal,  2) = param_(15);
        model.dcbs(Epoch.bds,  2) = param_(18);
        model.dcbs(Epoch.qzss, 2) = param_(21);
    end
    if num_freq > 2
        model.dcbs(Epoch.gps,  3) = param_(10);
        model.dcbs(Epoch.glo,  3) = param_(13);
        model.dcbs(Epoch.gal,  3) = param_(16);
        model.dcbs(Epoch.bds,  3) = param_(19);
        model.dcbs(Epoch.qzss, 3) = param_(22);
    end
    
elseif DecoupledClockModel
    % Interfrequency Bias (IFB)
    if num_freq >= 3
        model.IFB(Epoch.gps, 3) = param_(18);
        model.IFB(Epoch.glo, 3) = param_(19);
        model.IFB(Epoch.gal, 3) = param_(20);
        model.IFB(Epoch.bds, 3) = param_(21);
        model.IFB(Epoch.qzss,3) = param_(22);        
    end
    
    % L2 and L3 phase bias
    if num_freq >= 2
        model.L_biases(Epoch.gps, 2) = param_(23);
        model.L_biases(Epoch.glo, 2) = param_(24);
        model.L_biases(Epoch.gal, 2) = param_(25);
        model.L_biases(Epoch.bds, 2) = param_(26);
        model.L_biases(Epoch.qzss,2) = param_(27);
    end
    if num_freq >= 3
        model.L_biases(Epoch.gps, 3) = param_(28);
        model.L_biases(Epoch.glo, 3) = param_(29);
        model.L_biases(Epoch.gal, 3) = param_(30);
        model.L_biases(Epoch.bds, 3) = param_(31);
        model.L_biases(Epoch.qzss,3) = param_(32);
    end
    
end