function Epoch = apply_biases(Epoch, obs, settings)
% Function to apply the biases from a Multi-GNSS-SINEX-Bias File
% In assign_sinex_biases.m the preparations should have made that the
% application works here.
% ATTENTION: if a satellite has no bias, no bias is applied and satellite
% is NOT excluded from processing. For PPP-AR, satellite biases are checked 
% in CheckSatellitesFixable.m
% 
% Revision:
%   2023/02/01, MFG: adding gps-week into time check (valid biases)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparations
sow = Epoch.gps_time;           % time of current epoch in [sow]
week = Epoch.gps_week;          % gps-week of current epoch
bool_sats = false(1,399);       % create logical vector
bool_sats(Epoch.sats) = true;  	% elements == prns are true



%% determine coefficients for the biases
k_vec_1 = zeros(1,399);     k_vec_2 = zeros(1,399);
% ||| check this condition for e.g. TUG Products and IF-LC
% convert observations to IF-LC of precise products
if settings.ORBCLK.bool_precise && ...
        (~contains(settings.IONO.model, 'IF-LC') || contains(settings.BIASES.code, 'Multi-GNSS DCBs'))
    
    % following [21]: (14), but in raPPPid everything is converted to and 
    % then from the 1st frequency, therefore actually only one coefficient 
    % is needed and this works for 3+ frequencies
     k_vec_1(Epoch.sats) = Epoch.f1.^2 ./ (Epoch.f1.^2 - Epoch.f2.^2);       % e.g., 2.5457 for GPS L1+L2, 2.2606 for GAL E1+E5a
     k_vec_2(Epoch.sats) = Epoch.f2.^2 ./ (Epoch.f1.^2 - Epoch.f2.^2);       % e.g., 1.5457 for GPS L1+L2, 1.2606 for GAL E1+E5a

end


%% Apply Biases to observations
% --- Frequency 1
Epoch.C1_bias = debias(k_vec_2, obs.C1_bias, bool_sats, sow, week, Epoch.sats);
Epoch.L1_bias = debias(k_vec_2, obs.L1_bias, bool_sats, sow, week, Epoch.sats);

% --- Frequency 2
if settings.INPUT.num_freqs > 1
    Epoch.C2_bias = debias(k_vec_2, obs.C2_bias, bool_sats, sow, week, Epoch.sats);
    Epoch.L2_bias = debias(k_vec_2, obs.L2_bias, bool_sats, sow, week, Epoch.sats);
end

% --- Frequency 3
if settings.INPUT.num_freqs > 2
    Epoch.C3_bias = debias(k_vec_2, obs.C3_bias, bool_sats, sow, week, Epoch.sats);
    Epoch.L3_bias = debias(k_vec_2, obs.L3_bias, bool_sats, sow, week, Epoch.sats);
end




function bias_epoch = debias(k_vec, BIAS, bool_sats, sow, week, sats)
% Function to find the correct biases (timely valid)
% INPUT: 
%   k_vec           coefficient for the third bias
%   BIAS            struct, containing value, start and ende (sow & gps-week)
%   bool_sats       1x399, true for the satellites which are observed
%   sow             current point in time, [sow]
%   week 
%   sats            satellite numbers of current epoch
% OUTPUT:
%   bias_epoch      bias which has to be added to observation
% *************************************************************************

% get variables from struct Bias
bias = BIAS.value;   start = BIAS.start;   ende = BIAS.ende; 
week_start = BIAS.week_start;	week_ende = BIAS.week_ende;
% initialize
bias_epoch = zeros(1, sum(bool_sats), 3);
% get only biases of current satellites
bias_obs = bias(:, bool_sats, :);       

% find valid biases
% all SINEX biases starting validity before the current point in time
valid_start = start(:,bool_sats,:) <= sow & week_start(:,bool_sats,:) <= week;   	
% all SINEX biases ending validity after current point in time
valid_ende  = ende(:,bool_sats,:)  >  sow | week_ende(:,bool_sats,:) > week;   	
take = valid_start & valid_ende;    % correct bias has valid start and valid end
valid = logical(sum(take,1));    	% convert do boolean vector

% ||| the following line fails if at a specific point in time two different
% bias corrections are valid (error in the bias file...)
bias_epoch(valid) = bias_obs(take);             % take biases only for satellites which have valid ones

% apply coefficient to convert from C1W to IF-LC-C1W-C2W if necessary:
% therefore the third dimension of the biases is used where the DSB between
% the observation types of the IF LC was saved
COEFF = ones(size(bias_epoch));
COEFF(:,:,3) = repmat(k_vec(sats),size(bias_epoch,1),1);      % ||| necessary?!?!
% k1 = COEFF(:,:,1);   k2 = COEFF(:,:,2);   k3 = COEFF(:,:,3);        % for checking
% bias1 = bias(:,:,1);   bias2 = bias(:,:,2);   bias3 = bias(:,:,3);  % for checking
bias_epoch = bias_epoch .* COEFF;


% convert to [m] and apply biases
bias_epoch = sum(bias_epoch,3) * 10^-9 * Const.C; 	% convert to row-vector and [ns] to [m]
if ~isempty(bias_epoch)
    bias_epoch = - bias_epoch(:);       % apply bias, by SINEX bias definition with minus
else
    fprintf('No SINEX Biases applied!')
    bias_epoch = zeros(1,numel(sats));
end


