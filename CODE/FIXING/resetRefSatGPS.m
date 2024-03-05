function Epoch = resetRefSatGPS(Epoch)
% Function to reset the GPS reference satellite and the fixed
% Extra-Wide-Lane, Wide-Lane and Narrow-Lane ambiguities of GPS
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% reset reference satellite of GPS
Epoch.refSatGPS = 0;
Epoch.refSatGPS_idx = [];

% reset EW, WL and NL ambiguities of GPS
Epoch.WL_23(1:99) = NaN;
Epoch.WL_12(1:99) = NaN;
Epoch.NL_12(1:99) = NaN;
Epoch.NL_23(1:99) = NaN;