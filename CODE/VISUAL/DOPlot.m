function DOPlot(DOPS, strXAxis_epochs, seconds, resets)
% creates DOP-Plot
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% preparations
lgth_DOP = length(DOPS(1,:));       
idx = 1:lgth_DOP;
seconds = seconds(idx);         % if last epochs of processing delivered no results
fig_dop = figure('name','DOP Plot', 'NumberTitle','off');
title({'Dilution of Precision'}, 'fontsize', 11, 'FontWeight','bold');

% plotting
plot(seconds, DOPS(1,:),'LineWidth',2)       % PDOP
hold on
plot(seconds, DOPS(2,:),'g','LineWidth',2)   % HDOP
plot(seconds, DOPS(3,:),'r','LineWidth',2)   % VDOP
if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets

% styling
Grid_Xoff_Yon();
ylim([0 10])
xlim([seconds(1) seconds(end)])
xlabel(strXAxis_epochs)
ylabel('Value')
legend('PDOP', 'HDOP', 'VDOP')

% add customized datatip
dcm = datacursormode(fig_dop);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip)

end


