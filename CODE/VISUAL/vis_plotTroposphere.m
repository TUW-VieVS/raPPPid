function vis_plotTroposphere(hours, strXAxis, storeData, resets)
% Plots estimated tropospheric zenith wet delay
% 
% INPUT: 
%   hours           vector, time in hours from beginning of processing
%   strXAxis        label for x-axis
%   storeData       data from processing	
%   resets          vector, time of resets in hours
% OUTPUT:
%   []
% using vline.m or hline.m (c) 2001, Brandon Kuczenski
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


zwd_estimate = storeData.param(:,4);      % estimated residual tropospheric ZWD of all processed epochs
zwd_model = storeData.zwd;
zhd_model = storeData.zhd;

% create plot figure
fig_trop = figure('Name','Troposphere Plot', 'NumberTitle','off');

% plot total troposphere zenith delay
tot = plot(hours, zhd_model+zwd_model+zwd_estimate, '.', 'Color', [.44 1 .44]);
hold on
% plot modeled zhd
zhd_m = plot(hours, zhd_model, '.', 'Color', [.77 .77 .77]);
% plot modeled zwd
zwd_m = plot(hours, zwd_model, '.', 'Color', [.44 .44 .44]);
% plot estimated residual zwd
zwd_e = plot(hours, zwd_estimate, '.', 'Color', [.18 0 1]);
% plot black dots where no zwd was estimated
nonzero = (zwd_estimate ~= 0);
plot(hours(~nonzero), zwd_estimate(~nonzero), 'k.')   

% style
title('Troposphere Plot')
xlabel(strXAxis)
ylabel('Delay [m]')
grid on;
% legend off
% if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets
xlim([hours(1) hours(end)])
Grid_Xoff_Yon()
legend([tot zhd_m zwd_m zwd_e], {'ZTD', 'Modeled ZHD', 'Modeled ZWD', 'Estimated ZWD'})
ylim1 = quantile(zwd_estimate, 0.05) - nanstd(zwd_estimate);
ylim2 = quantile(zwd_estimate, 0.95) + nanstd(zwd_estimate);
ylim([ylim1, ylim2])

% add customized datatip
dcm = datacursormode(fig_trop);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_h)



