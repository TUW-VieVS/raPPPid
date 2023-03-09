function [dT_clk, noclock] = satelliteClock(sv, Ttr, input, isGPS, isGLO, isGAL, isBDS, k, settings, corr_clk)
% Calculate (precise satellite) clock.
% 
% INPUT:
% 	sv          satellite vehicle number
% 	Ttr         transmission time (GPStime)
% 	input       Containing several input data (Ephemerides, etc...)
%   isGPS       boolean, GPS-satellite
%   isGLO       boolean, Glonass-satellite
%   isGAL       boolean, Galileo-satellite
%   isBDS       boolean, BeiDou-satellite
% 	k           column of ephemerides according to time and sv
%   settings 	struct with settings from GUI
%   corr_clk    clock correction to broadcast message
% 
% OUTPUT:
%   dT_clk      satellite clock correction, [s]
%   noclock     true if satellite should not be used (missing clock information)
% uses lininterp1 (c) 2010, Jeffrey Wu
% 
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
noclock = false;
if isGPS
    if settings.ORBCLK.bool_brdc
        Eph = input.Eph_GPS;
        toe  = Eph(18,k);   % time of ephemeris, [seconds of week]
        toc  = Eph(21,k);   % time of clock, [seconds of week]
    end
    if settings.ORBCLK.bool_clk
        preciseClk = input.ORBCLK.preciseClk_GPS;
    end
elseif isGLO   
    if settings.ORBCLK.bool_brdc
        Eph = input.Eph_GLO;
        toe = Eph(18,k);    % epoch of ephemerides converted into GPS sow
    end
    if settings.ORBCLK.bool_clk
        preciseClk = input.ORBCLK.preciseClk_GLO;
    end
elseif isGAL  
    if settings.ORBCLK.bool_brdc
        Eph = input.Eph_GAL;
        toe = Eph(18,k);
        toc = Eph(21,k);
    end
    if settings.ORBCLK.bool_clk
        preciseClk = input.ORBCLK.preciseClk_GAL;
    end
elseif isBDS
    if settings.ORBCLK.bool_brdc
        Eph = input.Eph_BDS;
        toe = Eph(18,k);
        toc = Eph(21,k);
    end
    if settings.ORBCLK.bool_clk
        preciseClk = input.ORBCLK.preciseClk_BDS;
    end
end


%% calculation of satellite clock
if settings.ORBCLK.bool_clk       % precise satellite clock enabled
    % --- calculate clock correction from precise clock file
    % Fast Interpolation of precise clock information:
    % cut noPoints sampling points around Ttr to accelerate interpolation
    points = 20;
    midPoints = points/2 + 1;
    
    idx = find(abs(preciseClk.t-Ttr) == min(abs(preciseClk.t-Ttr)));    % index of nearest precise clock 
    idx = idx(1);                                   % preventing errors 
    if idx < midPoints                              % not enough data before
        time_idxs = 1:points;                       % take data from beginning
    elseif idx > length(preciseClk.t)- points/2     % not enough data afterwards
        no_el = numel(preciseClk.t);                % take data until end 
        time_idxs = (no_el-points) : (no_el);       
    else                                            % enough data around
        time_idxs = (idx-points/2) : (idx+points/2);% take data around point in time
    end
    t_prec_clk = preciseClk.t(time_idxs);           % time of precise clocks
    value_prec_clk = preciseClk.dT(time_idxs,sv);   % values of precise clocks
    if any(value_prec_clk==0)
        % one of the values to interpolate is 0 -> do not use
        dT_clk = 0;         % satellite is excluded outside this function in modelErrorSources.m      
    else
%         dT_clk = interp1(t_prec_clk, value_prec_clk, Ttr, 'cubic', 'extrap');
        % Only linear but faster (results hardly change)
        dT_clk = lininterp1(t_prec_clk, value_prec_clk, Ttr);
    end
    
else
    % --- calculate clock correction from navigation message
    % coefficients for navigation clock correction
    if isGPS || isGAL || isBDS
        a2 = Eph(2,k);        a1 = Eph(20,k);        a0 = Eph(19,k);
        if isBDS; Ttr = Ttr - 14; end       % somehow necessary to convert GPST to BDT, ||| check!!!
        dT = check_t(Ttr - toc);            % time difference between transmission time and time of clock
        dT_clk = a2*dT^2 + a1*dT + a0;      % 2nd degree polynomial clock correctionyou
    elseif isGLO
        toe = Eph(18,k);    % sow in GPS time (only leap seconds accounted)
        dT = check_t(Ttr - toe);
        % dT_clk = (-Tau_N) + Gamma_N + (-Tau_C)
        dT_clk = + Eph(2,k) + Eph(3,k)*dT + Eph(16,k);
    end
    
    % --- Clock correction with correction stream
    if settings.ORBCLK.corr2brdc_clk
        dt = Ttr - corr_clk(1); 	% time difference between transmission time and clock correction from stream
        a0 = corr_clk(2);           % coefficients of corrections polynomial
        a1 = corr_clk(3);
        a2 = corr_clk(4);
        dt_clock = a0 + a1*dt + a2*dt^2; % calculate 2nd degree polynomial clock correction, [m]
        brdc_clk_corr = dt_clock/Const.C;        % convert from [m] to [s]
        if abs(brdc_clk_corr) >= 2 || brdc_clk_corr == 0 	% no valid corrections available
            brdc_clk_corr = 0;     noclock = true;       	% eliminate satellite
        end
        dT_clk = dT_clk + brdc_clk_corr;
    end
end

end     % end of satelliteClock.m
