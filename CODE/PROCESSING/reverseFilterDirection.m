function Epoch = reverseFilterDirection(Epoch, settings)
% This functions prepares some variables for a change of filter direction.
% For example, it deletes some old data to avoid irregularities in the
% algorithms due to duplicate data from the past.
%
% INPUT:
%   Epoch           struct, epoch-specific data
%   settings        struct, settings from GUI for PPP processing
% OUTPUT:
%   Epoch           struct, prepared for change of filter direction
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************

Epoch.bool_2nd = true;
% reset some variables
if settings.OTHER.mp_detection
    Epoch.mp_C1_diff(2:end,:) = NaN;
    Epoch.mp_C2_diff(2:end,:) = NaN;
    Epoch.mp_C3_diff(2:end,:) = NaN;
    Epoch.mp_last(:,:) = NaN;
end
if settings.OTHER.CS.l1c1
    Epoch.cs_L1C1(2:end,:) = NaN;
end
if settings.OTHER.CS.TimeDifference
    Epoch.cs_phase_obs(2:end,:) = NaN;
    Epoch.cs_time_obs(2:end,:) = NaN;
end
if settings.OTHER.CS.HMW
    Epoch.cs_HMW_k(:,:)   = 0;
    Epoch.cs_HMW_av(:,:)  = 0;
    Epoch.cs_HMW_var(:,:) = 0;
end
Epoch.tracked(:) = 0;           % reset number of epochs each satellite was tracked 

% ||| complete?