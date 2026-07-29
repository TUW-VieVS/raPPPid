function [input] = preciseOrbit2Clock(input, settings)
% Used if a precise orbit file is used but no precise clock file to save
% the clock information from the precise orbit file as it would be from
% precise clock file
%
% INPUT:
% 	input       struct, containing all input data
%   settings    struct, settings from GUI
% OUTPUT:
%  input        struct, updated with clock information from precise orbit file
%
% Revision:
%   2026/07/24, MFWG: adding BeiDou and QZSS
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% extract the satellite clocks from the precise orbits of each GNSS. The
% fields are created for all GNSS (empty if there is no data)
input.ORBCLK.preciseClk_GPS  = eph2clk(input.ORBCLK.preciseEph_GPS,  settings.INPUT.use_GPS);
input.ORBCLK.preciseClk_GLO  = eph2clk(input.ORBCLK.preciseEph_GLO,  settings.INPUT.use_GLO);
input.ORBCLK.preciseClk_GAL  = eph2clk(input.ORBCLK.preciseEph_GAL,  settings.INPUT.use_GAL);
input.ORBCLK.preciseClk_BDS  = eph2clk(input.ORBCLK.preciseEph_BDS,  settings.INPUT.use_BDS);
input.ORBCLK.preciseClk_QZSS = eph2clk(input.ORBCLK.preciseEph_QZSS, settings.INPUT.use_QZSS);




function preciseClk = eph2clk(preciseEph, use_gnss)
% Takes the satellite clocks of one GNSS from the precise orbit data.
% An empty output indicates that no clock data is available
% INPUT:
%   preciseEph  struct, precise orbits of current GNSS (read_precise_eph.m)
%   use_gnss    boolean, true if this GNSS is processed
% OUTPUT:
%   preciseClk  struct, .t and .dT of current GNSS (empty if no data)
% *************************************************************************

preciseClk = [];

if ~use_gnss || isempty(preciseEph)
    return          % GNSS is not processed or no precise orbits for it
end

% time-stamps [sow]: read_precise_eph.m stores the epoch time for each
% satellite separately and puts NaN where a satellite has no data
preciseClk.t  = max(preciseEph.t, [], 2);

% satellite clocks [s]
preciseClk.dT = preciseEph.dT;
