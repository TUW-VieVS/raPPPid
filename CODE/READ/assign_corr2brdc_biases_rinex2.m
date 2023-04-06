function [obs] = assign_corr2brdc_biases_rinex2(obs, input)
% finds the correct code and/or phase biases from CNES stream and assigns
% it to obs.L1/L2/L3/C1/C2/C3_bias for RINEX 2
% INPUT:
%   obs     struct, ...
%   input   struct, ...
% OUTPUT:
%   obs     struct, updated with obs.C1/C2/C3_corr and obs.L1/L2/L3_corr
%         	and used_biases
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% ||| 2023/03/28: function is not up-to-date, has to be debugged


obs.used_biases_GPS = cell(3,2);    % 1st column phase, 2nd column code

% Code Biases
idx_c1 = obs.use_column{1, 4};
bool_P1 = strcmp('P1', obs.types_gps(2*idx_c1-1:2*idx_c1));
if bool_P1
    obs.C1_corr(:,1:32) = input.ORBCLK.corr2brdc_GPS.cbias.C1W;
    obs.used_biases_GPS{2,1} = 'C1W';
else
    obs.C1_corr(:,1:32) = input.ORBCLK.corr2brdc_GPS.cbias.C1C;
    obs.used_biases_GPS{2,1} = 'C1C';
end
idx_c2 = obs.use_column{1, 5};
bool_P2 = strcmp('P2', obs.types_gps(2*idx_c2-1:2*idx_c2));
if bool_P2
    obs.C2_corr(:,1:32) = input.ORBCLK.corr2brdc_GPS.cbias.C2W;
    obs.used_biases_GPS{2,2} = 'C2W';
else
    obs.C2_corr(:,1:32) = input.ORBCLK.corr2brdc_GPS.cbias.C2C;
    obs.used_biases_GPS{2,2} = 'C2C';
end

% Phase Biases
if bool_P1
    obs.L1_corr(:,1:32) = input.ORBCLK.corr2brdc_GPS.pbias.L1W;
    obs.used_biases_GPS{1,1} = 'L1W';
else
    obs.L1_corr(:,1:32) = input.ORBCLK.corr2brdc_GPS.pbias.L1C;
    obs.used_biases_GPS{1,1} = 'L1C';
end
obs.L2_corr(:,1:32) = input.ORBCLK.corr2brdc_GPS.pbias.L2W;
obs.used_biases_GPS{2,1} = 'L2W';

% set to zero because 3rd frequency does not exist in Rinex 2:
obs.C3_corr = 0*input.ORBCLK.corr2brdc_GPS.cbias.C2W;
obs.L3_corr = 0*input.ORBCLK.corr2brdc_GPS.pbias.L2W;

% no Galileo in Rinex 2
obs.used_biases_GAL = cell(3,2);    


end