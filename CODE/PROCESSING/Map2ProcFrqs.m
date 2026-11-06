function [vec_out] = Map2ProcFrqs(vec_in, n, IONO_model)
% This function converts from the number of input frequencies to the number
% of processed frequencies n.
% 
% INPUT:
%   vec_in      n_sats x n_input_frqs, boolean
%   n           number of input frequencies
%   IONO_model  from settings.IONO.model
% OUTPUT:
%	vec_out     n_sats x n_proc_frqs, boolean, reduced from vec_in
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************

% initialize (e.g., uncombined model)
vec_out = vec_in;

% reduce exclusion vector depending on processed linear combination
if (strcmp(IONO_model, '2-Frequency-IF-LCs') && n == 2) || strcmp(IONO_model, '3-Frequency-IF-LC')
    vec_out = any(vec_in,2);
elseif strcmp(IONO_model, '2-Frequency-IF-LCs') && n == 3
    vec_out = [vec_in(:,1) | vec_in(:,2), vec_in(:,2) | vec_in(:,3)];
end