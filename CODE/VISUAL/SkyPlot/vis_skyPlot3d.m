function [snr_min, snr_max, LUT] = ...
    vis_skyPlot3d(satx, saty, satz, snr_min, snr_max, LUT, Value, bool_txt)
% skyPlot3d generates a 3d SkyPlot. 
% INPUT:
%   ...
%   bool_txt    boolean, true to plot satellite number as text
% OUTPUT:
%   ...
% Based on:
%   SPHERE
%   Clay M. Thompson 4-24-91, CBM 8-21-92.
%   Copyright 1984-2002 The MathWorks, Inc.
%   $Revision: 5.8.4.1 $  $Date: 2002/09/26 01:55:25 $
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

n = 30;
divs = 6;

no_colors = size(LUT,1);  	% number of different colors
no_sats = size(Value,2); 	% number of columns = satellites

% -pi <= theta <= pi is a row vector.
% -pi/2 <= phi <= pi/2 is a column vector.
theta = (-n:2:n)/n*pi;
phi = (0:1:n)'/n*pi/2;
cosphi = cos(phi);      % cosphi(1) = 0; cosphi(n+1) = 0;
sintheta = sin(theta);  % sintheta(1) = 0; sintheta(n+1) = 0;

x_sphere = cosphi*cos(theta);
y_sphere = cosphi*sintheta;
z_sphere = sin(phi)*ones(1,n+1);

cax = newplot([]);
surf(x_sphere, y_sphere, z_sphere, 'parent', cax);
colormap bone;
alpha(.4);
shading interp;
zlim([0 2]);
axis(cax, 'off');
view(2);
hold on;
for i = 1:no_sats
    if any(~isnan(satx(:,i)))
        idx = floor(Value(:,i) - snr_min) + 1;
        idx(isnan(idx)) = 1;                % avoid NaNs
        idx(idx < 1) = 1;                   % avoid negative indices
        idx(idx > no_colors) = no_colors;   % avoid not defined colors
        couleur = LUT(idx, :);
        x = satx(:,i);          y = saty(:,i);          z = satz(:,i);
        scatter3(x, y, z, 25, couleur, 'o', 'filled')       % plot
        x = x(~isnan(x));       x = x(end); % satellite label at last/current position/time
        y = y(~isnan(y));       y = y(end);
        z = z(~isnan(z));       z = z(end);
        if bool_txt
            if i > 400              % prn > 400: QZSS
                prn_text = ['J', num2str(i-400, '%02.0f')];            
            elseif i > 300              % prn > 300: BeiDou
                prn_text = ['C', num2str(i-300, '%02.0f')];
            elseif i > 200        	% prn > 200: Galileo
                prn_text = ['E', num2str(i-200, '%02.0f')];
            elseif i > 100          % prn > 100: GLONASS
                prn_text = ['R', num2str(i-100, '%02.0f')];
            elseif i > 0            % GPS
                prn_text = ['G', num2str(i    , '%02.0f')];
            end
        text(x, y, z, prn_text, 'color','k', 'FontWeight','bold', 'FontSize',10);
        end
    end
end


xc = zeros(1,n+1);
yc = zeros(1,n+1);
for j=1:n+1
    xc(j)=cos((j-1)*2*pi/n);
    yc(j)=sin((j-1)*2*pi/n);
end
% --- Plot elevation circles and text
for i = 1:divs-1
    plot3(xc*cos(i*pi/(2*divs)),yc*cos(i*pi/(2*divs)),ones(1,n+1)*sin(i*pi/(2*divs)),'k:');
    text(0,-cos(i*pi/(2*divs)),sin(i*pi/(2*divs)),['  ',num2str(floor(i*90/divs))]);
end
tc = get(cax, 'xcolor');
%--- Find spoke angles ----------------------------------------------------
% Only divs lines are needed to divide circle into 12 parts
th = (1:divs) * 2*pi / (2*divs);

%--- Convert spoke end point coordinate to Cartesian system ---------------
cst = cos(th); snt = sin(th);
cs = [cst; -cst];
sn = [snt; -snt];

%--- Plot the spoke lines -------------------------------------------------
line(sn, cs, 'linestyle', ':', 'color', tc, 'linewidth', 0.5, ...
    'handlevisibility', 'off');
rt = 1.1;

for i = 1:max(size(th))
    
    %--- Write text in the first half of the plot -------------------------
    text(rt*snt(i), rt*cst(i), int2str(i*30), ...
        'horizontalalignment', 'center', 'handlevisibility', 'off');
    
    if i == max(size(th))
        loc = int2str(0);
    else
        loc = int2str(180 + i*30);
    end
    
    %--- Write text in the opposite half of the plot ----------------------
    text(-rt*snt(i), -rt*cst(i), loc, ...
        'handlevisibility', 'off', 'horizontalalignment', 'center');
end

