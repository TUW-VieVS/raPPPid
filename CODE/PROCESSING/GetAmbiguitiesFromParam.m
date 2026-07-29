function [N_float, idx] = GetAmbiguitiesFromParam(param, NO_PARAM, n, proc_freq)
% This function extracts the float ambiguities from the parameter vector.
% 
% INPUT:
%   param       column vector, parameter vector
%   NO_PARAM    number of parameters of PPP model
%   n           number of satellites
%   proc_freq   number of processed frequencies
% OUTPUT:
%	N_float     column vector, extracted ambiguities from parameter vector
%   idx         indices of float ambiguities in parameter vector
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% indices of float ambiguities
idx = (NO_PARAM+1):(NO_PARAM+n*proc_freq);      

% get float ambiguities
N_float = param(idx);                    