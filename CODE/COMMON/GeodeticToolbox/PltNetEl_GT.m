echo on
%--------------------------------------------------
% PltNetEl_GT
%   Plots network error ellipses at each point.
%   Note: Use a square aspect ratio for plot;
%   i.e., use axis('square') command.
%   M-files: plterrel_GT.m
% 7 Jul 96
%--------------------------------------------------
%clear
clear plterrel_GT

%----- Define 2d network coordinates
n=10;
rand('normal');
rand('seed',123456);
x=rand(n,1)*100;  % north
y=rand(n,1)*100;  % east

%----- Define network covariance matrix
r1=0.02;
r2=0.01;
az=45*pi/180;
R=[cos(az) -sin(az); sin(az) cos(az)];
Ci=R*diag([r1^2,r2^2])*R';
C=zeros(n*2,n*2);
for i=1:n
  ind=(i-1)*2+(1:2);
  C(ind,ind)=Ci;
end
s=1000;  % Scale factor for error ellipses

%----- Plot network points & ellipses (plterrel_GT)
clg;
axis('square');
plot(y,x,'o');
hold on;
t=clock;
for i=1:n
  ind=(i-1)*2+(1:2);
  plterrel_GT(x(i),y(i),C(ind,ind),s);
  hold on;
end
etime(clock,t)  % elapsed time
grid;
title(['Network Error Ellipses (',num2str(s),'x scale)']);
xlabel('East');
ylabel('North');
hold off;
axis('normal');
