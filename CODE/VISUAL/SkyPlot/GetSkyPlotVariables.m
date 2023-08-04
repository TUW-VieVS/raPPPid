function [time_sow, AZ, EL, SNR, C_res, P_res, I_res, MP] = ...
    GetSkyPlotVariables(satellites, storeData, bool_fixed)
% Extract the necessary variables for Skyplots from satellites and storeData
%
% INPUT:
%	satellites
%   storeData
%   bool_fixed      boolean, true if fixed position is plotted
% OUTPUT:
%	...
%
% Revision:
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% Carrier-to-Noise density
if isfield(satellites, 'SNR_3')
    SNR_ = (full(satellites.SNR_1) + full(satellites.SNR_2) + full(satellites.SNR_3)) ./ 3;
elseif isfield(satellites, 'SNR_2')
    SNR_ = (full(satellites.SNR_1) + full(satellites.SNR_2)) ./ 2;
else
    SNR_ = full(satellites.SNR_1);
end


% Code Residuals
if ~bool_fixed
    if isfield(storeData, 'residuals_code_3')
        code_res = (full(storeData.residuals_code_1) + full(storeData.residuals_code_2) + full(storeData.residuals_code_3)) ./ 3;
    elseif isfield(storeData, 'residuals_code_2')
        code_res = (full(storeData.residuals_code_1) + full(storeData.residuals_code_2)) ./ 2;
    else
        code_res = full(storeData.residuals_code_1);
    end
else
    if isfield(storeData, 'residuals_code_fix_3')
        code_res = (full(storeData.residuals_code_fix_1) + full(storeData.residuals_code_fix_2) + full(storeData.residuals_code_fix_3)) ./ 3;
    elseif isfield(storeData, 'residuals_code_fix_2')
        code_res = (full(storeData.residuals_code_fix_1) + full(storeData.residuals_code_fix_2)) ./ 2;
    else
        code_res = full(storeData.residuals_code_fix_1);
    end
end


% Phase Residuals
phase_res = [];
if ~bool_fixed
    if isfield(storeData, 'residuals_phase_3')
        phase_res = (full(storeData.residuals_phase_1) + full(storeData.residuals_phase_2) + full(storeData.residuals_phase_3)) ./3;
    elseif isfield(storeData, 'residuals_phase_2')
        phase_res = (full(storeData.residuals_phase_1) + full(storeData.residuals_phase_2)) ./2;
    elseif isfield(storeData, 'residuals_phase_1')
        phase_res = full(storeData.residuals_phase_1);
    end
else
    if isfield(storeData, 'residuals_phase_fix_3')
        phase_res = (full(storeData.residuals_phase_fix_1) + full(storeData.residuals_phase_fix_2) + full(storeData.residuals_phase_fix_3)) ./3;
    elseif isfield(storeData, 'residuals_phase_fix_2')
        phase_res = (full(storeData.residuals_phase_fix_1) + full(storeData.residuals_phase_fix_2)) ./2;
    elseif isfield(storeData, 'residuals_phase_fix_1')
        phase_res = full(storeData.residuals_phase_fix_1);
    end
end


% Ionosphere Residual
iono_res = [];
if isfield(storeData, 'iono_est') && isfield(storeData, 'iono_corr')
    iono_res = full(storeData.iono_corr) - full(storeData.iono_est);
end

% Multipath-LC
% ||| only code for 2-frequencies
mp_lc = [];
if isfield(storeData, 'mp1') && isfield(storeData, 'mp2')
%     mp_lc = full(storeData.mp1;
    mp_lc = full(storeData.mp2);
%     mp_lc = (full(storeData.mp1) + full(storeData.mp2)) ./ 2;
end


% save variables
time_sow     = storeData.gpstime;       % vector with time of epochs in [sow]
AZ           = full(satellites.az);  	% azimuths
EL           = full(satellites.elev); 	% elevations
SNR          = abs(SNR_);               % Carrier-to-Noise density for color-coding
C_res        = abs(code_res);           % Code residual for color-coding
P_res        = abs(100*phase_res);      % Phase residual [mm] for color-coding
I_res        = abs(10*iono_res);       	% Difference between ionosphere model and estimation
MP           = abs(10*mp_lc);           % Multipath-LC


