function [HMW_12, HMW_23, HMW_13] = create_HMW_LC(Epoch, settings, HMW_12, HMW_23, HMW_13, z)
% This function builds the HMW LC (used for WL fixing) depending on the
% number of input frequencies
% Since the HWM LC is used for the WL fixing, the APC model correction is
% applied, check https://doi.org/10.1007/s00190-022-01602-3 or 
% https://doi.org/10.1186/s43020-021-00049-9
%
% INPUT:
%	Epoch           struct, epoch-specific data
%   settings        struct, processing settings from GUI
%   HMW_12,...      matrix, HMW LC for all epochs and satellites between 1st
%                   and 2nd or 2nd and 3rd frequency
%   z               correction due to antenna phase centers
% OUTPUT:
%   HMW_12,...      filled with HMW LC of current epoch
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Prepare
sats = Epoch.sats;  q = Epoch.q;
f1 = Epoch.f1;   	f2 = Epoch.f2;      f3 = Epoch.f3;

% check if APC model is applied
if ~settings.AMBFIX.APC_MODEL
    % APC model is not applied -> set values in z to zero
    z(:,:) = 0;
end

% get raw observations and apply  APC correction on raw observations
L1 = Epoch.L1 + z(:,1);      L2 = Epoch.L2 + z(:,2);
C1 = Epoch.C1 + z(:,1);      C2 = Epoch.C2 + z(:,2);

% Build HMW LC from the first two frequencies
if settings.INPUT.num_freqs >= 2
    % between first and second frequency
    HMW12_epoch = (f1.*L1-f2.*L2) ./ (f1-f2) - ...
        (f1.*C1+f2.*C2) ./ (f1+f2);
    HMW_12(q,sats) = HMW12_epoch .* ((f1-f2)./Const.C); % convert to [cyc] and save
end

% Build HMW LCs using third frequency
if settings.INPUT.num_freqs >= 3
    L3 = Epoch.L3 + z(:,3); 
    C3 = Epoch.C3 + z(:,3);
    % between second and third frequency
    HMW23_epoch = (f2.*L2-f3.*L3) ./ (f2-f3) - ...
        (f2.*C2+f3.*C3) ./ (f2+f3);
    HMW_23(q,sats) = HMW23_epoch .* ((f2-f3)./Const.C); % convert to [cyc] and save
    % between first and third frequency
    HMW13_epoch = (f1.*L1-f3.*L3) ./ (f1-f3) - ...
        (f1.*C1+f3.*C3) ./ (f1+f3);
    HMW_13(q,sats) = HMW13_epoch .* ((f1-f3)./Const.C); % convert to [cyc] and save
end
