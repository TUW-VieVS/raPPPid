function f_glo = calcFrequencyGLO(frq_name, channels)
% Function to calculate the frequency of Glonass observations for all
% Glonass satellites and one frequency of current epoch 
% 
% INPUT:
%   frq_name        string, name of Glonass frequency
%   channels        vector, channel numbers of all satellites 
% OUTPUT:
%   f_glo           vector, frequencies of satellites
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


switch frq_name
    case 'G1'
        f_glo = Const.GLO_F1 + Const.GLO_k1 .* channels * 1e6; 

    case 'G2'
        f_glo = Const.GLO_F2 + Const.GLO_k2 .* channels * 1e6; 
        
    case 'G3'           % CDMA
        f_glo = ones(numel(channels),1) .* Const.GLO_F3;
        
    case 'OFF'
        f_glo = zeros(numel(channels),1);
end
