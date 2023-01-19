function Epoch = resetRefSatGAL(Epoch)
% Function to reset the Galileo reference satellite and the fixed
% Extra-Wide-Lane, Wide-Lane and Narrow-Lane ambiguities of Galileo
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% reset Galileo reference satellite
Epoch.refSatGAL = 0;
Epoch.refSatGAL_idx = [];

% reset EW, WL and NL ambiguities of Galileo
Epoch.WL_23(201:299) = NaN;
Epoch.WL_12(201:299) = NaN;
Epoch.NL_12(201:299) = NaN;
Epoch.NL_23(201:299) = NaN;