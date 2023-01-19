function [gpt3_grid] = gpt3_5_fast_readGrid

% gpt3_5_fast_readGrid.m
% This routine reads the grid 'gpt3_5.grd' and overgives the respective 
% parameters in a cell. It must be placed ahead of the for loop, which runs 
% through all observations in order to save a huge time amount. The related 
% function "gpt3_5_fast.m" must then replace the default 
% "gpt3_5.m" at the respective location in the text.
%
%
% File created by Daniel Landskron, 2017-04-12
%
% =========================================================================


% read gridfile
fid = fopen('gpt3_5.grd','r');      % located in \CODE\ATMOSPHERE
C = textscan( fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', 'HeaderLines', 1 , 'CollectOutput', true );
C = C{1};
fclose (fid);

p_grid    = C(:,3:7);           % pressure in Pascal
T_grid    = C(:,8:12);          % temperature in Kelvin
Q_grid    = C(:,13:17)/1000;    % specific humidity in kg/kg
dT_grid   = C(:,18:22)/1000;    % temperature lapse rate in Kelvin/m
u_grid    = C(:,23);            % geoid undulation in m
Hs_grid   = C(:,24);            % orthometric grid height in m
ah_grid   = C(:,25:29)/1000;    % hydrostatic mapping function coefficient, dimensionless
aw_grid   = C(:,30:34)/1000;    % wet mapping function coefficient, dimensionless
la_grid   = C(:,35:39);         % water vapor decrease factor, dimensionless
Tm_grid   = C(:,40:44);         % mean temperature in Kelvin
Gn_h_grid = C(:,45:49)/100000;  % hydrostatic north gradient in m
Ge_h_grid = C(:,50:54)/100000;  % hydrostatic east gradient in m
Gn_w_grid = C(:,55:59)/100000;  % wet north gradient in m
Ge_w_grid = C(:,60:64)/100000;  % wet east gradient in m

% combine all data to on cell grid
gpt3_grid = {p_grid, T_grid, Q_grid, dT_grid, u_grid, Hs_grid, ah_grid, aw_grid, la_grid, Tm_grid , Gn_h_grid , Ge_h_grid , Gn_w_grid , Ge_w_grid};
