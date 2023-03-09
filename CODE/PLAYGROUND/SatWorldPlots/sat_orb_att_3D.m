%% LOAD
% load precise ephemeris file
sp3_file = '..\DATA\ORBIT\2023\012\COD0MGXFIN_20230120000_01D_05M_ORB.SP3';
[~, ~, GAL, ~] = read_precise_eph(sp3_file);

% load attitude from ORBEX file
orbex_file = '..\DATA\ORBIT\2023\012\COD0MGXFIN_20230120000_01D_30S_ATT.OBX';
if ~exist([orbex_file '.mat'], 'file')
    OBX = read_orbex(orbex_file);
    save([orbex_file '.mat'], 'OBX');     % save as .mat-file for next processing (faster loading)
else
    load([orbex_file '.mat'], 'OBX');     % load .mat-file
end

%% HARDCODE SETTINGS

date = [2023 01 12];
viewangle = [80 30];

% define satellite
sat = 201;
prn = 1;

axlim = [-4 4] *1e7;    % axes limits
b_col = 'w';        % color background       


% create plot
h = planet3D('Earth');       % https://www.mathworks.com/matlabcentral/fileexchange/86483-3d-earth-and-celestial-bodies-planet3d
set(gcf, 'Position',  [100, 100, 500, 400])
ylim(axlim)
xlim(axlim)
zlim(axlim)
set(gca, 'XColor', 'none','YColor','none','ZColor','none')
set(gcf,'color',b_col);
set(gca,'Color',b_col);
view(viewangle)
drawnow


m = 0;
i = 1;
for q = 1:1:size(GAL.X,1)
    % plot galileo satellites
    X_sat = GAL.X(q,prn);    Y_sat = GAL.Y(q,prn);    Z_sat = GAL.Z(q,prn);
    XYZ_sat = [X_sat; Y_sat; Z_sat];
    
    % find corresponding attitude from ORBEX
    t = GAL.t(q,1);
    idx = OBX.ATT.sow == t;
    q0 = OBX.ATT.q0(idx, sat); q1 = OBX.ATT.q1(idx, sat); q2 = OBX.ATT.q2(idx, sat); q3 = OBX.ATT.q3(idx, sat);
    
    % calculate satellite orientation
    hour = mod(t,86400)/3600;
    sunECEF  = sunPositionECEF (date(1), date(2), date(3), hour);
    SatOr_ECEF = getSatelliteOrientation(XYZ_sat, sunECEF*1000);
    x_axis(i,1:3) = SatOr_ECEF(:,1);    
    y_axis(i,1:3) = SatOr_ECEF(:,2);    
    z_axis(i,1:3) = SatOr_ECEF(:,3);
    i = i+1;
end

X = GAL.X(:,prn);
Y = GAL.Y(:,prn);
Z = GAL.Z(:,prn);
U1 = x_axis(:,1);
V1 = x_axis(:,2);
W1 = x_axis(:,3);
U2 = y_axis(:,1);
V2 = y_axis(:,2);
W2 = y_axis(:,3);
U3 = z_axis(:,1);
V3 = z_axis(:,2);
W3 = z_axis(:,3);

hold on
axis off
plot3(X,Y,Z, 'b-')
res = 5;
quiver3(X(1:res:end),Y(1:res:end),Z(1:res:end),U1(1:res:end),V1(1:res:end),W1(1:res:end), 'r')
quiver3(X(1:res:end),Y(1:res:end),Z(1:res:end),U2(1:res:end),V2(1:res:end),W2(1:res:end), 'b')
quiver3(X(1:res:end),Y(1:res:end),Z(1:res:end),U3(1:res:end),V3(1:res:end),W3(1:res:end), 'k')

% style manually






