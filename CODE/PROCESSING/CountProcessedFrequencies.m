function [num_freqs, proc_freqs] = CountProcessedFrequencies(settings)
% This function determines the number of input and processed frequencies.
% Through building a LC the number of processed frequencies might be lower
% than the number of the input frequencies. 
% 
% INPUT:
%   settings        struct, processing settings from GUI
% OUTPUT:
%	proc_freqs      number of processed frequencies
%   num_freqs       number of input frequencies
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


% number of input frequencies (1 or 2 or 3) 
num_freqs = max([ ... 
    settings.INPUT.use_GPS*numel(settings.INPUT.gps_freq(~strcmpi(settings.INPUT.gps_freq,'OFF'))), ...
    settings.INPUT.use_GLO*numel(settings.INPUT.glo_freq(~strcmpi(settings.INPUT.glo_freq,'OFF'))), ...
    settings.INPUT.use_GAL*numel(settings.INPUT.gal_freq(~strcmpi(settings.INPUT.gal_freq,'OFF'))), ...
    settings.INPUT.use_BDS*numel(settings.INPUT.bds_freq(~strcmpi(settings.INPUT.bds_freq,'OFF')))      ]);

% number of processed frequencies
proc_freqs = num_freqs;   
if strcmpi(settings.IONO.model,'2-Frequency-IF-LCs')
    % through building LC one frequency less is processed and the number
    % of input and processed frequencies is different
    proc_freqs = proc_freqs - 1;              
elseif strcmpi(settings.IONO.model,'3-Frequency-IF-LC')  
    proc_freqs = 1;
end  