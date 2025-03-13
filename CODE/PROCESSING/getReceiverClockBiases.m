function model = getReceiverClockBiases(model, Epoch, param, settings)
% This function extract the estimated values for the receiver clock error,
% offsets, and biases from the parameter vector. This values are saved into
% the struct model and used to model the observations (e.g., in
% model_observations.m)
%
% INPUT:
%   model       struct, observation model
%   param       parameter vector of the float solution
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
%     - receiver clock errors for code and phase

if ~DecoupledClockModel
    % receiver clock error is the same for code and phase observation
    model.dt_rx_clock(Epoch.gps,  :) = param( 5);
    model.dt_rx_clock(Epoch.glo,  :) = param( 5) + param( 8);
    model.dt_rx_clock(Epoch.gal,  :) = param( 5) + param(11);
    model.dt_rx_clock(Epoch.bds,  :) = param( 5) + param(14);
    model.dt_rx_clock(Epoch.bds,  :) = param( 5) + param(14);
    model.dt_rx_clock(Epoch.qzss, :) = param( 5) + param(17);
elseif DecoupledClockModel
    % code receiver clock error
    model.dt_rx_clock_code(Epoch.gps,  :) = param( 5);
    model.dt_rx_clock_code(Epoch.glo,  :) = param( 6);
    model.dt_rx_clock_code(Epoch.gal,  :) = param( 7);
    model.dt_rx_clock_code(Epoch.bds,  :) = param( 8);
    model.dt_rx_clock_code(Epoch.qzss, :) = param( 9);
    % phase receiver clock error
    model.dt_rx_clock_phase(Epoch.gps, :) = param(10);
    model.dt_rx_clock_phase(Epoch.glo, :) = param(11);
    model.dt_rx_clock_phase(Epoch.gal, :) = param(12);
    model.dt_rx_clock_phase(Epoch.bds, :) = param(13);
    model.dt_rx_clock_phase(Epoch.qzss,:) = param(14);
end


%% receiver biases 
% get either:
%     - receiver DCB(s)
%   OR
%     - receiver IFB, L2 bias, and L3 bias

if settings.BIASES.estimate_rec_dcbs && ~DecoupledClockModel
    % receiver DCB_12 and DCB_13 are estimated
    if num_freq > 1
        model.dcbs(Epoch.gps,  2) = param( 6);
        model.dcbs(Epoch.glo,  2) = param( 9);
        model.dcbs(Epoch.gal,  2) = param(12);
        model.dcbs(Epoch.bds,  2) = param(15);
        model.dcbs(Epoch.qzss, 2) = param(18);
    end
    if num_freq > 2
        model.dcbs(Epoch.gps,  3) = param( 7);
        model.dcbs(Epoch.glo,  3) = param(10);
        model.dcbs(Epoch.gal,  3) = param(13);
        model.dcbs(Epoch.bds,  3) = param(16);
        model.dcbs(Epoch.qzss, 3) = param(19);
    end
    
elseif DecoupledClockModel
    % Interfrequency Bias (IFB)
    if num_freq >= 3
        model.IFB(Epoch.gps, 3) = param(15);
        model.IFB(Epoch.glo, 3) = param(16);
        model.IFB(Epoch.gal, 3) = param(17);
        model.IFB(Epoch.bds, 3) = param(18);
        model.IFB(Epoch.qzss,3) = param(19);        
    end
    
    % L2 and L3 phase bias
    model.L_biases(Epoch.gps, 2) = param(20);
    model.L_biases(Epoch.glo, 2) = param(21);
    model.L_biases(Epoch.gal, 2) = param(22);
    model.L_biases(Epoch.bds, 2) = param(23);
    model.L_biases(Epoch.qzss,2) = param(24);    
    if num_freq >= 3
        model.L_biases(Epoch.gps, 3) = param(25);
        model.L_biases(Epoch.glo, 3) = param(26);
        model.L_biases(Epoch.gal, 3) = param(27);
        model.L_biases(Epoch.bds, 3) = param(28);
        model.L_biases(Epoch.qzss,3) = param(29);
    end
    
end