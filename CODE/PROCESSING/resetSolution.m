function [Adjust, Epoch, settings, HMW_12, HMW_23, HMW_13, storeData, init_ambiguities] = ...
    resetSolution(Adjust, Epoch, settings, HMW_12, HMW_23, HMW_13, storeData, obs_int, init_ambiguities)
% function to reset the float and fixed solution to start a new convergence
% of the (coordinate) solution. Be careful: at this point of the loop /
% epoch-wise processing Epoch contains the epoch-specific data from the
% last epoch.
%
% INPUT:
%   Adjust
%   Epoch
%   settings
%   HMW_12, HMW_23, HMW_13
%   storeData
%   obs_int
%   bool_float      true if float solution shall be resetted
%   bool_fixed      true if fixed solution shall be resetted
% OUTPUT:
%   Adjust
%   Epoch
%   settings
%   HMW_12, HMW_23, HMW_13
%   storeData
% 
% Revision:
%   ...
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

q = Epoch.q;
resetnow = false;
bool_float = settings.PROC.reset_float;
bool_fixed = settings.PROC.reset_fixed;

% initialize Adjust.reset_time for e.g. the first epoch, this variable is 
% also needed if no reset is performed
if isnan(Adjust.reset_time)
    Adjust.reset_time = Epoch.gps_time;
end


%% check if solution is resetted in current epoch
% - input from GUI
if settings.PROC.reset_fixed || settings.PROC.reset_float
    if settings.PROC.reset_bool_epoch        	% - reset after defined number of epochs
        resetnow = mod(q, settings.PROC.reset_after) == 0;
    elseif settings.PROC.reset_bool_min      	% - reset after defined number of minutes
        dt_last_reset = (Epoch.gps_time - Adjust.reset_time)/60;            % time since last reset [min]
        resetnow = (settings.PROC.reset_after - dt_last_reset) < 1e-3;      % because of rounding error
    end
end

% - something went wrong in the estimation
if any(isnan(Adjust.param) | isinf(Adjust.param))
    resetnow = true;
    bool_float = true;      % to make sure that a reset is performed
%     bool_fixed = true;      % ||| not sure about this
    if ~settings.INPUT.bool_parfor
        fprintf('Epoch %d: RESET of solution (ERROR in estimation in last epoch!)           \n\n', q)
    end
end



%% reset solution
if resetnow
    if ~settings.INPUT.bool_parfor
        fprintf('Epoch %d: RESET of solution            \n\n', q)
    end
    
    % reset float solution (other parameters are handled in adjustmentPreparation)
    if bool_float
        Adjust.float = false;
        Adjust.float_reset_epochs = [Adjust.float_reset_epochs, q];
        Adjust.reset_time = Epoch.gps_time;
    end
        
    % reset fixed solution
    if bool_fixed && settings.AMBFIX.bool_AMBFIX
        Adjust.fixed = false;
        Adjust.fixed_reset_epochs = [Adjust.fixed_reset_epochs, q];
        Adjust.reset_time = Epoch.gps_time;
        % reset reference satellites GPS & Galileo and fixed EW/WL/NL
        Epoch = resetRefSatGPS(Epoch);
        Epoch = resetRefSatGAL(Epoch);
        % restart fixing in [GUI-definded] epochs
        settings.AMBFIX.start_fixing(end+1, :) = ...    % -1 as we are already in epoch where reset is happening
            [q+settings.AMBFIX.start_WL-1, q+settings.AMBFIX.start_NL-1];   
        % reset Melboure-Wübbena LCs (ATTENTION: values of MW are overwritten!)
        HMW_12(1:q,:) = 0;
        HMW_23(1:q,:) = 0;
        HMW_13(1:q,:) = 0;
        % create new entry in time to first fix
        storeData.ttff(end+1) = NaN;
    end
    
    Epoch.tracked(:) = 0;           % reset number of epochs each satellite is tracked
    
    % reset collected data of cycle slip detection
    if settings.OTHER.CS.l1c1
        Epoch.cs_L1C1(:,:) = NaN;
    end
    if settings.OTHER.CS.TimeDifference
        Epoch.cs_phase_obs(:,:) = NaN;
    end
    
    % reset collected data of multipath detection
    if settings.OTHER.mp_detection
        Epoch.mp_C1_diff(:,:) = NaN; 
		Epoch.mp_C2_diff(:,:) = NaN; 
		Epoch.mp_C3_diff(:,:) = NaN;
		Epoch.mp_C_diff(:,:) = NaN;
        Epoch.mp1_last(:) = NaN;
    end
    
    % handle old Epoch: this is not a total reset but sufficient
    Epoch.old = EpochlyReset_Epoch(Epoch.old);
    
    % reset initialization of ambiguities (otherwise the reset would not be
    % a total restart of the processing)
    init_ambiguities = NaN(3, 410);
    
    % reset broadcast column
    Epoch.BRDCcolumn = NaN(410,1);
    
    % corrections from real-time correction stream
    Epoch.corr2brdc_orb = zeros(8,410);		% timestamp, radial, along, outof, v_radial, v_along, v_outof, IOD
    Epoch.corr2brdc_clk = zeros(5,410);		% timestamp, a0, a1, a2, IOD
    
end