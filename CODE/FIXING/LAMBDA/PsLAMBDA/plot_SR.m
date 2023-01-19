% plot output of SR_GUI
close all
FN = 'GEB_2f_10I_18p_5ep';

load(FN)

PsILS = vertcat(output.PsILS);
PsB = vertcat(output.PsB);
PsR = vertcat(output.PsR);

figure
set(gcf,'defaultlinelinewidth',2)
plot(PsILS(:,3),'--','color',[0 0.5 0])
hold on
plot(PsILS(:,1),'-','color',[0 0.5 0])
plot(PsILS(:,2),'b-')
plot(PsR(:,1),'r-')
plot(PsR(:,2),'r--')
set(gca,'xlim',[1 25],'ylim',[0 1]);
xlabel('time index'), ylabel('success rate')
legend('ILS: UB','ILS: simulation','B: exact','R: simulation','R: LB','location','SouthWest')

print('-djpeg','-r300',FN)

figure
set(gcf,'defaultlinelinewidth',2)
plot([0 1],[0 1],'k')
hold on
plot(PsILS(:,1),PsILS(:,2),'.','color',[0 0.5 0],'markersize',8)
plot(PsILS(:,1),PsILS(:,3),'r.','markersize',8)
set(gca,'xlim',[0 1],'ylim',[0 1]);
xlabel('AP: simulation'), ylabel('LB: bootstrapping (green) / UB: ADOP (red)')
% legend('ILS: UB','ILS: simulation','B: exact','R: simulation','R: LB','location','SouthWest')
axis square
FN2=[FN '_scat'];
print('-djpeg','-r300',FN2)
