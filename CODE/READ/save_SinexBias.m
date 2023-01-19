function [input] = save_SinexBias(input, Biases)
% This function saves the Biases from a SINEX-Bias-File (which were already
% read-in) into the struct input and is necessary if there are multiple
% SINEX-Bias-Files (e.g. one for code and one for phase biases)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


if ~isfield(input, 'BIASES') || ~isfield(input.BIASES, 'sinex')
    input.BIASES.sinex = Biases;
    return
end


% ||| implement





end