function Epoch = cycleSlip_LLI(Epoch, use_column, settings)
% This function checks if the Loss of Lock Indicator (LLI) bit is set,
% which indicates a cycle slips. A cycle slip is detected for the whole
% satellite if the LLI on any frequency is set to 1.
%
% INPUT:
%	Epoch       data from current epoch
%   use_column	columns of used observation, from obs.use_column
%   settings    struct, processing settings from GUI
% OUTPUT:
%	Epoch       updated with detected cycle slips
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% get and initialize variables
no_sats = numel(Epoch.sats);
n = settings.INPUT.num_freqs;
LLI = zeros(no_sats, n);

% columns and number of columns for each GNSS
gps_col = cell2mat(use_column(1,1:3)); n_gps = numel(gps_col);
glo_col = cell2mat(use_column(2,1:3)); n_glo = numel(glo_col);
gal_col = cell2mat(use_column(3,1:3)); n_gal = numel(gal_col);
bds_col = cell2mat(use_column(4,1:3)); n_bds = numel(bds_col);

% get LLI bit for all satellites and input frequencies
LLI(Epoch.gps,1:n_gps) = Epoch.LLI_bit_rinex(Epoch.gps, gps_col);
LLI(Epoch.glo,1:n_glo) = Epoch.LLI_bit_rinex(Epoch.glo, glo_col);
LLI(Epoch.gal,1:n_gal) = Epoch.LLI_bit_rinex(Epoch.gal, gal_col);
LLI(Epoch.bds,1:n_bds) = Epoch.LLI_bit_rinex(Epoch.bds, bds_col);

% if LLI bit is set on any frequency, the phase observations are excluded
% on all frequencies (||| sensible???)
LLI = logical(sum(LLI,2));

% % print information to command window
% if any(LLI) && ~settings.INPUT.bool_parfor
%     fprintf('Cycle-Slip found for satellite %03.0f (LLI)           \n', Epoch.sats(LLI));
% end

% save detected cycle slips
Epoch.cs_found(LLI, :) = 1;
% Epoch.exclude(LLI, :) = 1;         % use this line to exclude also code observation



