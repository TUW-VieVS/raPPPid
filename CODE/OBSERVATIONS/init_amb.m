function [init_ambs, Epoch] = init_amb(Epoch, init_ambs, prns_old)
% Function to adjust phase data to Code to limit the ambiguities for
% numerical reasons
% 
% INPUT:
%   Epoch       struct, epoch-specific data for current epoch
%   init_ambs       values from reducing ambiguities
%   old_prns        satellites of last epoch
% OUTPUT:
%   init_ambs       updated
%   Epoch       updated
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% keep initialized ambiguities only for satellites which are properly observed
delete = true(3,399);
sats = Epoch.sats(any(~Epoch.exclude & ~Epoch.cs_found,2));
delete(:,sats) = false;
init_ambs(delete) = NaN;

% get variables
prns = Epoch.sats;
init_ambs_ep = init_ambs(:,prns);

% adjust phase observations to code observations for 1st frequency
idx_ep_1 = isnan(init_ambs_ep(1,:));
if any(idx_ep_1)       % check if there are satellites which have none initialization value yet
    init_L1 = floor( (Epoch.C1 - Epoch.L1)./Epoch.l1 );     % difference code - phase in [cy]
    init_ambs(1, prns(idx_ep_1)) = init_L1(idx_ep_1);
end
Epoch.L1 = Epoch.L1 + Epoch.l1 .* init_ambs(1,prns)';

% adjust phase observations to code observations for 2nd frequency
if ~isempty(Epoch.L2)
    idx_ep_2 = isnan(init_ambs_ep(2,:));
    if any(idx_ep_2)
        init_L2 = floor( (Epoch.C1 - Epoch.L2)./Epoch.l2 );
        init_ambs(2, prns(idx_ep_2)) = init_L2(idx_ep_2);
    end
    Epoch.L2 = Epoch.L2 + Epoch.l2 .* init_ambs(2,prns)';
end

% adjust phase observations to code observations for 3rd frequency
if ~isempty(Epoch.L3)
    idx_ep_3 = isnan(init_ambs_ep(3,:));
    if any(idx_ep_3)
        init_L3 = floor( (Epoch.C1 - Epoch.L3)./Epoch.l3 );
        init_ambs(3, prns(idx_ep_3)) = init_L3(idx_ep_3);
    end
    Epoch.L3 = Epoch.L3 + Epoch.l3 .* init_ambs(3,prns)';
end
