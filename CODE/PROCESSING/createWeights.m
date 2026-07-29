function P_diag = createWeights(Epoch, elev, settings, bore)
% Function to create the weights of the observations for the diagonal of
% the weighting matrix P or, in other words, the weight factors for the
% variance of the observations.
% Variants:
% -) weight the observations depending on the procedure described in [02]
% -) weight the observations depending on the elevation of their satellites
% -) weight the observations depending on their signal strength on 1st frequency
%
% INPUT:
%   Epoch           containing epoch-specific data
%   elev            elevation to GNSS satellites of current epoch [°]
%   settings        setting of processing from GUI
%   bore            boresight angle to GNSS satellites of current epoch [°]
% OUTPUT:
%   P_diag          [n sats x input freqs], weight for each satellite and frequency
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


num_freq = settings.INPUT.num_freqs;        % number of input frequencies
n_sats = numel(Epoch.sats);                 % # sats in current epoch
P_diag = ones(n_sats,num_freq);
elev = elev*pi/180; 	% elevation of satellites of this epoch [rad]
elev_n = repmat(elev(:,1),1,num_freq);      % elevation is equal on all frequencies



% --- Weighting according to elevation
if settings.ADJ.weight_elev
    % observations on different frequencies get same weight factor
    if isa(settings.ADJ.elev_weight_fun, 'function_handle')
        P_diag(:,:) = settings.ADJ.elev_weight_fun(elev_n);
    elseif strcmp(settings.ADJ.elev_weight_fun, 'option_0')
        P_diag = sin(elev_n).^2;        % option_0 is sin(e)^2
    else
        fprintf(2, '\nError in createWeights!\n')
    end



elseif settings.ADJ.weight_sign_str
    % --- Weighting using signal to noise ratio (e.g., low-cost equipment), check [05]
    CN0 = [Epoch.S1, Epoch.S2, Epoch.S3];       % collect C/N0 values for all frequencies
    CN0_mean = mean(CN0, 2, 'omitmissing');     % calculate mean for weighting
    CN0_ = repmat(CN0_mean, 1, size(CN0, 2));

    if ischar(settings.ADJ.snr_weight_fun)
        % hardcoded C/N0 weighting function
        switch settings.ADJ.snr_weight_fun
            case 'option_0'
                if ~isempty(Epoch.S1)
                    P_diag = goGPS_SNR_weighting(P_diag, CN0_(:,1), 1);
                end
                if ~isempty(Epoch.S2) && settings.INPUT.proc_freqs >= 2
                    P_diag = goGPS_SNR_weighting(P_diag, CN0_(:,2), 2);
                end
                if ~isempty(Epoch.S3) && settings.INPUT.proc_freqs >= 3
                    P_diag = goGPS_SNR_weighting(P_diag, CN0_(:,3), 3);
                end
            case 'option_1'
                % option_1 = 10.^-(max([55-snr,0])./10)
                expo = 55 - CN0_;
                expo(expo < 0 | isnan(expo)) = 0;
                expo = expo ./ 10;
                P_diag = 10 .^ -expo;
            case 'option_2'
                % similar to option_1, but uses max(CN0_) instead of 55
                CN0_REF = max(CN0_(:,1));
                expo = CN0_REF - CN0_;
                expo(expo < 0 | isnan(expo)) = 0;
                expo = expo ./ 10;
                P_diag = 10 .^ -expo;                
            otherwise
                fprintf(2, '\nError in createWeights!\n')
        end
    elseif isa(settings.ADJ.snr_weight_fun, 'function_handle')
        % C/N0 weighting function from GUI (user input)
        if contains(func2str(settings.ADJ.snr_weight_fun), 'max(')
            % function-handle does not work with max()-function and vector
            for i = 1:n_sats         % ||| more elegant solution than a loop?
                for j = 1:num_freq
                    P_diag(i,j) = settings.ADJ.snr_weight_fun(CN0_(i,j));
                end
            end
        else
            P_diag(:,:) = settings.ADJ.snr_weight_fun(CN0_);
            if settings.INPUT.proc_freqs >= 2
                % replace missing values
                P_diag_1 = P_diag(:,1);
                P_diag_2 = P_diag(:,2);
                bool = isnan(P_diag_2) | P_diag_2 == 0;
                P_diag_2(bool) = P_diag_1(bool);
                P_diag(:,2) = P_diag_2;
            end
            if settings.INPUT.proc_freqs >= 3
                % replace missing values
                P_diag_3 = P_diag(:,3);
                bool = isnan(P_diag_3) | P_diag_3 == 0;
                P_diag_3(bool) = P_diag_1(bool);
                P_diag(:,3) = P_diag_3;
            end
        end
    end
    % ||| check for multi-frequency processing
    % ||| check for IF LC (which S1 to take?)



elseif settings.ADJ.weight_bore
    % --- Weighting according to antenna boresight angle
    bore(isnan(bore)) = 0;                  % might happen in first epoch
    w = (1 + cos(pi * bore / 180)) / 2;     % w = 1 for 0°, w = 0 for 180°
    P_diag = repmat(w, 1, num_freq);



    % --- No weighting of the observations
elseif settings.ADJ.weight_none
    P_diag(:,:) = 1;



elseif settings.ADJ.weight_mplc
    % --- Weighting depending on combination of elevation and MP-LC, check [02]
    if Epoch.q > 5
        w1 = tanh((Epoch.mp1_var.^-1)/100)' + sin(elev);
        w2 = tanh((Epoch.mp2_var.^-1)/100)' + sin(elev);
        w = (w1+w2)/2;
        % variance = NaN (e.g. satellite is not observed for 5 epochs),
        % weight according to sqrt(elevation)
        w(isnan(w)) = sqrt(elev(isnan(w)));
        P_diag(:,1) = w;
        P_diag(:,2) = w;
    else        % not enough epochs to calculate variance so weight depending on elevation
        P_diag = sin(elev_n).^2;
    end


end


% --- GNSS weighting
P_diag(Epoch.gps,:) = P_diag(Epoch.gps,:) / settings.ADJ.fac_GPS;
P_diag(Epoch.glo,:) = P_diag(Epoch.glo,:) / settings.ADJ.fac_GLO;
P_diag(Epoch.gal,:) = P_diag(Epoch.gal,:) / settings.ADJ.fac_GAL;
P_diag(Epoch.bds,:) = P_diag(Epoch.bds,:) / settings.ADJ.fac_BDS;

% very low weight for weights which are NaN, zero, or negative
P_diag(isnan(P_diag)) = 10^-6;
P_diag(P_diag <= 0) = 10^-6;

end





function P_diag = goGPS_SNR_weighting(P_diag, SNR, frq)
% Creating weights depending on Carrier-to-Noise density following [05]: (5.1)
%
% INPUT:
%   P_diag      values for diagonal of weight matrix P
%   C/N0        Carrier-to-Noise Density of current frequency
%   frq         frequency or column of P_diag which should be manipulated
% OUTPUT:
%   P_diag      calculated weights added
% *************************************************************************

% some constants
a = 30;         % defines bending of the curve
s_1 = 50;       % C/N0 > this threshold, weight = 1
s_0 = 20;       % defines C/N0 where function is forced to have the weight defined by A
A = 30;     	% ... however, 1/is used here already
% calculate weights
q_R = 10.^(-(SNR-s_1)/a) .* ( (A/10.^(-(s_0-s_1)/a)-1)./(s_0-s_1).*(SNR-s_1)+1 );
P_diag(:,frq) = P_diag(:,frq) ./ q_R;        	% weight for observations
P_diag(SNR >= s_1, frq) = 1;                    % 1 for C/N0 > snr_1

end