% load precise ephemeris file
orbfile = '..\DATA\ORBIT\2022\261\WUM0MGXFIN_20222610000_01D_15M_ORB.SP3';
[GPS, GLO, GAL, BDS] = read_precise_eph(orbfile);

% create gif file
filename = 'Animated.gif';

% set marker and font size and delay time of gif and seconds of day
s = 80;             % marker size
fs = 6;             % font size
dtime = 0.20;       % speed of gif
m_int = 15;              % orbit interval, [min]
axlim = [-4 4] *1e7;    % axes limits
b_col = 'w';        % color background       
t_col = 'k';        % text color

% create plot
h = figure;
h = style_plot(h, axlim);
set(gcf,'color',b_col);
set(gca,'Color',b_col);
drawnow

% write into gif
% capture the plot as an image
frame = getframe(h);
im = frame2im(frame);
[imind,cm] = rgb2ind(im,256);
% write
imwrite(imind,cm,filename,'gif', 'Loopcount',inf, 'DelayTime',dtime);

m = 0;
for q = 1:1:size(GPS.X,1)
%     % plot gps satellites
%     for i = 1:size(GPS.X,2)
%         X_sat = GPS.X(q,i);
%         Y_sat = GPS.Y(q,i);
%         Z_sat = GPS.Z(q,i);
%         notnan = ~isnan(X_sat);
%         if notnan
%             % plot position
%             scatter3(X_sat,Y_sat,Z_sat, s, 'MarkerEdgeColor',[255, 0, 0]/255, 'Marker', '.', 'MarkerFaceColor','none')
%             % plot PRN
%             text(X_sat, Y_sat, Z_sat, ['G', sprintf('%02.0f',i)], 'FontSize',fs, 'Color', t_col);
%         end
%     end
    
%     % plot glonass satellites
%     for i = 1:size(GLO.X,2)
%         X_sat = GLO.X(q,i);
%         Y_sat = GLO.Y(q,i);
%         Z_sat = GLO.Z(q,i);
%         scatter3(X_sat,Y_sat,Z_sat, s, 'MarkerEdgeColor',[0, 255, 255]/255, 'Marker', '.', 'MarkerFaceColor','none')
%         text(X_sat, Y_sat, Z_sat, ['R', sprintf('%02.0f',i)], 'FontSize',fs, 'Color', t_col);
%     end
%     
%     % plot galileo satellitesedit 
%     for i = 1:size(GAL.X,2)
%         X_sat = GAL.X(q,i);
%         Y_sat = GAL.Y(q,i);
%         Z_sat = GAL.Z(q,i);
%         scatter3(X_sat,Y_sat,Z_sat, s, 'MarkerEdgeColor',[0, 0, 255]/255, 'Marker', '.', 'MarkerFaceColor','none')
%         text(X_sat, Y_sat, Z_sat, ['E', sprintf('%02.0f',i)], 'FontSize',fs, 'Color', t_col);
%     end
%     
    % plot beidou satellites
    for i = 6:size(BDS.X,2)     % ignore GEO satellites
        X_sat = BDS.X(q,i);
        Y_sat = BDS.Y(q,i);
        Z_sat = BDS.Z(q,i);
        scatter3(X_sat,Y_sat,Z_sat, s, 'MarkerEdgeColor',[255, 0, 255]/255, 'Marker', '.', 'MarkerFaceColor','none')
        text(X_sat, Y_sat, Z_sat, ['C', sprintf('%02.0f',i)], 'FontSize',fs, 'Color', t_col);
    end
    
    % plot time
    DateVector = [2022,09,18, floor(m/60), mod(m,60), 00];
    text(0, -4*1e7, 3*1e7, datestr(DateVector), 'FontSize',fs+4, 'Color', t_col)
    m = m + m_int;
    
    % write into gif
    set(gcf,'color', b_col);
    set(gca,'Color', b_col);
    drawnow
    % Capture the plot as an image
    frame = getframe(h);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    % write
    imwrite(imind,cm,filename,'gif','WriteMode','append', 'DelayTime',dtime);
    
    clf
    h = style_plot(h, axlim);
    
end


function h = style_plot(h, axlim)
earth_sphere(h,'m')
ylim(axlim)
xlim(axlim)
zlim(axlim)
set(gca, 'XColor', 'none','YColor','none','ZColor','none')
hold on
end


% %% plot axes
% plot3([0 10^7],	[0 0],      [0 0], '-k',    'LineWidth',3)
% plot3([0 0],    [0 10^7],   [0 0], '-k',    'LineWidth',3)
% plot3([0 0],    [0 0],      [0 10^7], '-k', 'LineWidth',3)
% text(10^7, 0, 0, 'X', 'FontSize',16);
% text(0, 10^7, 0, 'Y', 'FontSize',16);
% text(0, 0, 10^7, 'Z', 'FontSize',16);



% %% Create GIF
% h = figure;
% axis tight manual % this ensures that getframe() returns a consistent size
% filename = 'testAnimated.gif';
% for n = 1:0.5:5
%     % Draw plot for y = x.^n
%     x = 0:0.01:1;
%     y = x.^n;
%     plot(x,y)
%     drawnow
%     % Capture the plot as an image
%     frame = getframe(h);
%     im = frame2im(frame);
%     [imind,cm] = rgb2ind(im,256);
%     % Write to the GIF File
%     if n == 1
%         imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
%     else
%         imwrite(imind,cm,filename,'gif','WriteMode','append');
%     end
% end