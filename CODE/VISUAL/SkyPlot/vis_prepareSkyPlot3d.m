function [satx, saty, satz] = vis_prepareSkyPlot3d(AZ, EL)
% Preparations for the skyplot in the GUI
% INPUT:
%   AZ      epochs x 410, azimuth of all satellites and epochs, matrix
%   EL      epochs x 410, elevation of all satellites and epochs, matrix
% OUTPUT:
%   satx        epochs x 410, satellite x position for skyplot
%   saty        epochs x 410, satellite y position for skyplot
%   satz        epochs x 410, satellite z position for skyplot
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% calculate satellite xyz for all sats and epochs for plotting
AZ = (pi/2)-AZ.*(pi/180);
EL = EL.*(pi/180);
cosel = cos(EL);        % cosphi(1) = 0;    cosphi(n+1) = 0;
sinaz = sin(AZ);        % sintheta(1) = 0;  sintheta(n+1) = 0;
satx = cosel.*cos(AZ);
saty = cosel.*sinaz;
satz = sin(EL);

end