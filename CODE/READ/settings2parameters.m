function [parameters] = settings2parameters(settings)

% settings2parameters is used to convert from settings to parameters
% struct. The ides is, that "parameters" contains all session-independent
% (global) settings, while "settings" contains session-dependent
% settings as well.
% INPUT:    settings......struct, settings for processing with PPP_main.m 
% OUTPUT:   parameters....struct, contains parts of settings struct
%
% Coded:
%   ...
%  
% Revision:
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************



% define the equivalent variables
parameters.ORBCLK = settings.ORBCLK;
parameters.TROPO  = settings.TROPO;
parameters.IONO   = settings.IONO;
parameters.BIASES = settings.BIASES;
parameters.OTHER  = settings.OTHER;
parameters.AMBFIX = settings.AMBFIX;
parameters.ADJ    = settings.ADJ;

% define variables which occur only partly
parameters.PROC.method       = settings.PROC.method;
parameters.PROC.elev_mask    = settings.PROC.elev_mask;
parameters.AMBFIX.bool_AMBFIX  = settings.AMBFIX.bool_AMBFIX;