% sat_bahn = MODEL2TXT(:,2:8);
% 
% prns = sat_bahn(:,1);
% x = MODEL2TXT(:,3);
% y = MODEL2TXT(:,3);
% z = MODEL2TXT(:,3);
% 
% X_sat = zeros(1000, 32);
% Y_sat = zeros(1000, 32);
% Z_sat = zeros(1000, 32);
% rows = length(prns);
% ep = 0;
% for i = 1:rows
%     if ischar(sat_bahn{i,1}) && contains(sat_bahn{i,1}, 'PRN')
%         ep = ep + 1;
%     else
%         prn = sat_bahn{i,1};
%         X_sat(ep,prn) = sat_bahn{i,2};
%         Y_sat(ep,prn) = sat_bahn{i,3};
%         Z_sat(ep,prn) = sat_bahn{i,4};
%     end
% end

% load precise ephemeris file
[GPS, GLO, GAL] = read_precise_eph('..\DATA\ORBIT\2020\001\COM20863.EPH');

% plot earth
figure
h1 = gca;
earth_sphere(h1,'m')
hold on

% plot gps satellites
X_sat = GPS.X;
Y_sat = GPS.Y;
Z_sat = GPS.Z;
for i = 1:size(GPS.X,2)
    notnan = ~isnan(X_sat(:,i));
    if any(notnan)
         % plot trajectory
%         plot3(X_sat(:,i),Y_sat(:,i),Z_sat(:,i), 'Color', [30 144 255]/255, 'LineWidth',2)
        scatter3(X_sat(:,i),Y_sat(:,i),Z_sat(:,i), 'MarkerEdgeColor',[30 144 255]/255, 'MarkerFaceColor','none')
%         % plot PRN
%         idx = find(notnan,1, 'last');
%         text(X_sat(idx,i), Y_sat(idx,i), Z_sat(idx,i), ['G', sprintf('%02.0f',i)], 'FontSize',12, 'Color', 'k');     
    end
end

% plot glonass satellites
X_sat = GLO.X;
Y_sat = GLO.Y;
Z_sat = GLO.Z;
for i = 1:size(GLO.X,2)
%     plot3(X_sat(:,i),Y_sat(:,i),Z_sat(:,i), 'Color', [205 38 38]/255, 'LineWidth',2)
    scatter3(X_sat(:,i),Y_sat(:,i),Z_sat(:,i), 'MarkerEdgeColor',[205 38 38]/255, 'MarkerFaceColor','none')
end

% plot galileo satellites
X_sat = GAL.X;
Y_sat = GAL.Y;
Z_sat = GAL.Z;
for i = 1:size(GAL.X,2)
%     plot3(X_sat(:,i),Y_sat(:,i),Z_sat(:,i), 'Color', [34 139 34]/255, 'LineWidth',2)
    scatter3(X_sat(:,i),Y_sat(:,i),Z_sat(:,i), 'MarkerEdgeColor',[34 139 34]/255, 'MarkerFaceColor','none')
end

% plot axes
plot3([0 10^7],	[0 0],      [0 0], '-k',    'LineWidth',3)
plot3([0 0],    [0 10^7],   [0 0], '-k',    'LineWidth',3)
plot3([0 0],    [0 0],      [0 10^7], '-k', 'LineWidth',3)
text(10^7, 0, 0, 'X', 'FontSize',16);
text(0, 10^7, 0, 'Y', 'FontSize',16);
text(0, 0, 10^7, 'Z', 'FontSize',16);