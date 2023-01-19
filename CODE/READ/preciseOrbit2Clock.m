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
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

if settings.INPUT.use_GPS
    input.ORBCLK.preciseClk_GPS.t  = input.ORBCLK.preciseEph_GPS.t(:,1);
    input.ORBCLK.preciseClk_GPS.dT = input.ORBCLK.preciseEph_GPS.dT;
end
if settings.INPUT.use_GLO
    input.ORBCLK.preciseClk_GLO.t  = input.ORBCLK.preciseEph_GLO.t(:,1);
    input.ORBCLK.preciseClk_GLO.dT = input.ORBCLK.preciseEph_GLO.dT;
end
if settings.INPUT.use_GAL
    input.ORBCLK.preciseClk_GAL.t  = input.ORBCLK.preciseEph_GAL.t(:,1);
    input.ORBCLK.preciseClk_GAL.dT = input.ORBCLK.preciseEph_GAL.dT;
end
