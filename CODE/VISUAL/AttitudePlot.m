function [] = AttitudePlot(storeData, settings)
% This function plots the attitude (roll, pitch, yaw) estimated from the
% INS solution over time, together with the zero-velocity-update (ZUPT)
% probability and the detected motion state (e.g., static, quasi-static,
% moving).
%
% INPUT:
%   storeData       [struct], results of processing
%   settings        [struct], processing settings from GUI
% OUTPUT:
%	none, creates plots
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2026, M.F. Wareyka-Glaner
% *************************************************************************


% extract some variables
gpstime = storeData.gpstime;
quat = storeData.quat;
ZUPT_prob = storeData.ZUPT_prob;
motionState = storeData.motionState;

% convert the attitude quaternions to Euler angles (vectorized)
[yaw, pitch, roll] = quat2angle(quat, 'ZYX');
roll_deg  = rad2deg(roll);
pitch_deg = rad2deg(pitch);
% unwrap yaw so it does not jump between -180/+180 degree
yaw_deg   = rad2deg(unwrap(yaw));

% colors for the plots
col_roll  = [0.85 0.33 0.10];   % orange
col_pitch = [0.00 0.45 0.74];   % blue
col_yaw   = [0.47 0.67 0.19];   % green
col_zupt  = [0.49 0.18 0.56];   % purple

% create figure
figure('Name','Attitude Plot', 'NumberTitle','off')



%% --- plot attitude angles (roll, pitch, yaw) ---
subplot(2,1,1)
hold on
% plot
h_roll  = plot(gpstime, roll_deg,  'Color', col_roll,  'DisplayName', 'Roll');
h_yaw   = plot(gpstime, yaw_deg,   'Color', col_yaw,   'DisplayName', 'Yaw');
h_pitch = plot(gpstime, pitch_deg, 'Color', col_pitch, 'DisplayName', 'Pitch');
% style plot
ylabel('Angle [°]')
xlabel('GPS time')
xlim([gpstime(1) gpstime(end)])
legend
title('Euler Angles')

% add custom datatips
attachLineDataTip(h_roll)
attachLineDataTip(h_yaw)
attachLineDataTip(h_pitch)



%% --- plot ZUPT probability and detected motion state ---
ax2 = subplot(2,1,2);
hold on

% shade the background by motion state
shadeMotionState(ax2, gpstime, motionState, [0 1])

% plot
h_zupt = plot(gpstime, ZUPT_prob, 'Color', col_zupt, 'DisplayName', 'ZUPT Probability');
% thresholds used by the ZUPT detector
yline(Const.IMU_ZUPT_THRESH_QUASI, 'k--', 'DisplayName', 'Threshold Quasi-Static')
yline(Const.IMU_ZUPT_THRESH_STATIC, 'k--', 'DisplayName', 'Threshold Static')
xlim([gpstime(1) gpstime(end)])
ylim([0 1])
ylabel('ZUPT Probability')
title('State of Motion')

legend

% add custom datatips
attachLineDataTip(h_zupt)

% register one custom datatip formatter for the whole figure (lines and
% patches use it via their UserData, set in attachLineDataTip/attachPatchDataTip)
dcm = datacursormode(gcf);
dcm.UpdateFcn = @customDataTipText;

end



%% Auxiliary Functions

function attachLineDataTip(h)
% stores the info needed for a custom datatip (series, epoch, time, value) in h.UserData
h.UserData = struct('kind', 'line', ...
    'series', h.DisplayName, 'time', h.XData(:), 'value', h.YData(:));
end



function shadeMotionState(ax, gpstime, motionState, y_range)
% colors the background of ax in contiguous blocks according to the
% motion state (0 = static, 1 = quasi-static, 2 = moving/walking)

shown = false(1,3);   % tracks which states already have a legend entry

i = find(~isnan(motionState), 1, 'first');
n = numel(motionState);

while ~isempty(i) && i <= n

    state = motionState(i);

    % find the end of this contiguous block of the same state
    j = i;
    while j+1 <= n && motionState(j+1) == state
        j = j+1;
    end

    [col, nm] = motionStateStyle(state);
    h = patch(ax, gpstime([i j j i]), y_range([1 1 2 2]), col, ...
        'EdgeColor', 'none', 'FaceAlpha', 0.25);
    h.DisplayName = nm;

    if shown(state+1)
        h.HandleVisibility = 'off';   % keep only one legend entry per state
    else
        shown(state+1) = true;
    end

    attachPatchDataTip(h, i, j, gpstime)

    % jump to the start of the next non-NaN block
    i = j + 1;
    while i <= n && isnan(motionState(i))
        i = i + 1;
    end
end
end



function attachPatchDataTip(h, iStart, iEnd, gpstime)
% stores the info needed for a custom datatip (state name, epoch range,
% time range, duration) in h.UserData; a shaded block spans a range of
% epochs, so there is no single epoch/value to report like for a line
h.UserData = struct('kind', 'patch', 'series', h.DisplayName, ...
    'epochStart', iStart, 'epochEnd', iEnd, ...
    'timeStart', gpstime(iStart), 'timeEnd', gpstime(iEnd), ...
    'duration', gpstime(iEnd) - gpstime(iStart));
end


function txt = customDataTipText(~, event_obj)
% builds the datatip text for both lines (attachLineDataTip) and shaded
% motion-state patches (attachPatchDataTip) from their UserData, since
% patch objects do not support DataTipTemplate in all MATLAB versions
ud = event_obj.Target.UserData;

switch ud.kind
    case 'line'
        idx = event_obj.DataIndex;
        txt = {sprintf('Series: %s', ud.series), ...
               sprintf('Epoch: %d', idx), ...
               sprintf('GPS Time: %.3f', ud.time(idx)), ...
               sprintf('Value: %.4f', ud.value(idx))};
    case 'patch'
        txt = {sprintf('Motion State: %s', ud.series), ...
               sprintf('Epoch: %d - %d', ud.epochStart, ud.epochEnd), ...
               sprintf('GPS Time: %.3f - %.3f', ud.timeStart, ud.timeEnd), ...
               sprintf('Duration [s]: %.3f', ud.duration)};
end
end


function [col, nm] = motionStateStyle(state)
% background color and legend name for a given motion state
switch state
    case 0
        col = [1.0 0.6 0.6];   nm = 'Static';         % red
    case 1
        col = [1.0 1.0 0.6];   nm = 'Quasi-Static';    % yellow
    case 2
        col = [0.6 1.0 0.6];   nm = 'Moving';          % green
    otherwise
        col = [1.0 1.0 1.0];   nm = 'Unknown';
end
end

