R = 6371000;
el = 0:0.01:90; % [°]
% zenith angle [°]
z = (90 - el)*pi/180; % [rad]
% zenith angle in the IPP [°]
zi = asin((R)/(R+450000)*sin(z));

% for IGS-TEC-Maps
mf_igs = cos(zi).^-1;            
% for Regiomontan-TEC-Maps
mf_tuw = 1./sqrt(1 - ((R/(R+350000))*cos(el/180*pi)).^2);

figure
plot(el,mf_igs,'g')
hold on
plot(el,mf_tuw,'b')
legend('igs','tuw')
xlabel('elevation [°]')
ylabel('value of mf')
title('comparison iono-mf: igs vs. tuw')

figure
plot(el,mf_tuw-mf_igs,'r')
xlabel('elevation [°]')
ylabel('diff. of mf-values')
title('difference tuw_{mf} - igs_{mf}')
