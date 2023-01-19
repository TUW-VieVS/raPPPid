function [Epoch] = remove_sats(Epoch, remove)
% This function removes satellites from the struct Epoch
% 
% INPUT:
%   remove      boolean vector, true = remove observation, false = keep observation
% OUTPUT:
%   Epoch       updated (satellite removed)
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% make sure that boolean vector
remove = logical(remove);

% start removing
Epoch.obs(remove,:) = [];
Epoch.LLI_bit_rinex(remove,:) = [];
Epoch.ss_digit_rinex(remove,:) = [];
Epoch.sats(remove) = [];
Epoch.gps(remove) = [];
Epoch.glo(remove) = [];
Epoch.gal(remove) = [];
Epoch.bds(remove) = [];
Epoch.other_systems(remove) = [];