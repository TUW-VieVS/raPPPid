function Epoch = resetRefSatBDS(Epoch)
% Function to reset the BeiDou reference satellite and the fixed
% Extra-Wide-Lane, Wide-Lane and Narrow-Lane ambiguities of BeiDou
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% reset BeiDou reference satellite
Epoch.refSatBDS = 0;
Epoch.refSatBDS_idx = [];

% reset EW, WL and NL ambiguities of BeiDou
Epoch.WL_23(301:399) = NaN;
Epoch.WL_12(301:399) = NaN;
Epoch.NL_12(301:399) = NaN;
Epoch.NL_23(301:399) = NaN;