function [DopplerPRate, exclude] = DopplerCheckPR(Epoch, n, thresh, IONO_model)
% This function uses the Doppler Shift to check the change of the
% pseudorange since the last epoch.
% 
% INPUT:
%   Epoch           struct, epoch-wise data
%   n               number of input frequencies
%   thresh          threshold [m/s]
%   IONO_model      string, PPP model of processing
% OUTPUT:
%	exclude         #frqs x # sats, boolean, exclude satellite?
%   DopplerPRate    #frqs x # sats, difference between pseudorange rate and Doppler
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


n_sats = numel(Epoch.sats);         % number of satellites in current epoch

% initialize
C_old = NaN(3, n_sats);   C_now = NaN(3, n_sats);   D_now = NaN(3, n_sats);



%% get observations 

% check 
[now, old] = ismember(Epoch.sats, Epoch.old.sats);
old(old == 0) = [];

% first frequency
C_old(1, now) = Epoch.old.C1(old);
C_now(1, now) = Epoch.C1(now);
D_now(1, now) = Epoch.D1(now);
% seconds frequency
if n >= 2
    C_old(2, now) = Epoch.old.C2(old);
    C_now(2, now) = Epoch.C2(now);
    D_now(2, now) = Epoch.D2(now);
end
% third frequency
if n >= 3
    C_old(3, now) = Epoch.old.C3(old);
    C_now(3, now) = Epoch.C3(now);
    D_now(3, now) = Epoch.D3(now);
end



%% check range rate with Doppler

dt = abs(Epoch.gps_time - Epoch.old.gps_time);      % time difference between epochs

% calculate mean of Doppler, which is used for checking the change of the pseudorange
Doppler = mean(D_now,1, "omitmissing");

% calculate the change of the pseudorange (pseudorange rate) [m/s]
ChangePR = (C_now - C_old) / dt;

% usually, sign convention of the Doppler shift is a fixed property of the 
% receiver -> decide sign once for all satellites
res_plus  = ChangePR + Doppler;
res_minus = ChangePR - Doppler;
spread_plus  = sum(abs(res_plus(:)  - median(res_plus(:),  "omitmissing")), "omitmissing");
spread_minus = sum(abs(res_minus(:) - median(res_minus(:), "omitmissing")), "omitmissing");
% take residuals with smaller spread
residual = res_plus;
if spread_minus <= spread_plus
    residual = res_minus;
end

% remove median from residuals (e.g., remove receiver clock (drift))
clk = median(residual, 2, "omitmissing");       % common-mode per frequency [m/s]
DopplerPRate = abs(residual - clk);

% compare difference with threshold
exclude = DopplerPRate > thresh;



%% format output
exclude = exclude(1:n, :)';

% reduce exclusion vector depending on processed linear combination
if strcmp(IONO_model, '2-Frequency-IF-LCs') && n == 2
    exclude = exclude(:,1) | exclude(:,2);
elseif strcmp(IONO_model, '2-Frequency-IF-LCs') && n == 3
    exclude = [exclude(:,1) | exclude(:,2), exclude(:,2) | exclude(:,3)];
elseif strcmp(IONO_model, '3-Frequency-IF-LC')
    exclude = exclude(:,1) | exclude(:,2) | exclude(:,3);
end
