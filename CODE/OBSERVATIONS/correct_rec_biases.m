function [Epoch] = correct_rec_biases(Epoch, obs)
% Correct observations for receiver biases (e.g. DCBs) which is necessary
% e.g. for handling the ionosphere with ionex constraint
% obs.rec_DCB_gps_C2,... are already converted in [m]
%
% INPUT:
% 	Epoch:   	epoch-specific data for current epoch, [struct]
%   obs:     	containing observation related data [struct]
% OUTPUT:
%   Epoch:      observations corrected with receiver biases
%
% Revision:
%   07 Mar 2019 by M.F.Glaner: adding 3rd frequency
%   14 Mar 2019 by M.F.Glaner: receiver DCBs from SINEX
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


is_gps = Epoch.gps;
is_glo = Epoch.glo;
is_gal = Epoch.gal;
is_bds = Epoch.bds;


% C1
Epoch.C1(is_gps) = Epoch.C1(is_gps) + obs.rec_bias_C1(1);
Epoch.C1(is_glo) = Epoch.C1(is_glo) + obs.rec_bias_C1(2);
Epoch.C1(is_gal) = Epoch.C1(is_gal) + obs.rec_bias_C1(3);
Epoch.C1(is_bds) = Epoch.C1(is_bds) + obs.rec_bias_C1(4);
% C2
if ~isempty(Epoch.C2)
    Epoch.C2(is_gps) = Epoch.C2(is_gps) + obs.rec_bias_C2(1);
    Epoch.C2(is_glo) = Epoch.C2(is_glo) + obs.rec_bias_C2(2);
    Epoch.C2(is_gal) = Epoch.C2(is_gal) + obs.rec_bias_C2(3);
    Epoch.C2(is_bds) = Epoch.C2(is_bds) + obs.rec_bias_C2(4);
end
% C3
if ~isempty(Epoch.C3)
    Epoch.C3(is_gps) = Epoch.C3(is_gps) + obs.rec_bias_C3(1);
    Epoch.C3(is_glo) = Epoch.C3(is_glo) + obs.rec_bias_C3(2);
    Epoch.C3(is_gal) = Epoch.C3(is_gal) + obs.rec_bias_C3(3);
    Epoch.C3(is_bds) = Epoch.C3(is_bds) + obs.rec_bias_C3(4);
end
% L1
Epoch.L1(is_gps) = Epoch.L1(is_gps) + obs.rec_bias_L1(1);
Epoch.L1(is_glo) = Epoch.L1(is_glo) + obs.rec_bias_L1(2);
Epoch.L1(is_gal) = Epoch.L1(is_gal) + obs.rec_bias_L1(3);
Epoch.L1(is_bds) = Epoch.L1(is_bds) + obs.rec_bias_L1(4);
% L2
if ~isempty(Epoch.L2)
    Epoch.L2(is_gps) = Epoch.L2(is_gps) + obs.rec_bias_L2(1);
    Epoch.L2(is_glo) = Epoch.L2(is_glo) + obs.rec_bias_L2(2);
    Epoch.L2(is_gal) = Epoch.L2(is_gal) + obs.rec_bias_L2(3);
    Epoch.L2(is_bds) = Epoch.L2(is_bds) + obs.rec_bias_L2(4);
end
% L3
if ~isempty(Epoch.L3)
    Epoch.L3(is_gps) = Epoch.L3(is_gps) + obs.rec_bias_L3(1);
    Epoch.L3(is_glo) = Epoch.L3(is_glo) + obs.rec_bias_L3(2);
    Epoch.L3(is_gal) = Epoch.L3(is_gal) + obs.rec_bias_L3(3);
    Epoch.L3(is_bds) = Epoch.L3(is_bds) + obs.rec_bias_L3(4);
end