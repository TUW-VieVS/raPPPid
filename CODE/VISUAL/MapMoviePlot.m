function [] = MapMoviePlot(lat, lon, bool_true, lat_true, lon_true, station_date, floatfix, iskinematic, time)
% This function plots the PPP trajectory on a map and shows an animation 
% for the movement.
% If available also the reference trajectory is plotted
%
% INPUT:
%   lat             [°], latitude of PPP trajectory
%   lon             [°], longitude of PPP trajectory
%   bool_true       boolean, true if reference trajectory is available
%   lat_true        [°], latitude of reference trajectory
%   lon_true        [°], longitude of reference trajectory
%   station_date    string, date of the observation
%   floatfix        string, float/fix
%   iskinematic     boolean, true if kinematic processing
%   time            datetime, time of epochs
% OUTPUT:
%	[]
%
% Revision:
%   2026/09/10, MFWG: added "Save" button to export animation as animation.GIF
%
% This function belongs to raPPPid, Copyright (c) 2025, M.F. Wareyka-Glaner
% *************************************************************************


fig_map = figure('Name','Map Movie Plot', 'units','normalized', 'outerposition',[0.1 0.1 0.9 0.9], 'NumberTitle','off', 'Color', 'w');
title([station_date ', ' floatfix], 'fontsize',11, 'FontWeight','bold')

% animation setup
n = numel(lat);     % number of epochs
sec_total = 2;      % target total duration of animation [s]

% initial plot
h_trajectory = geoplot(lat, lon, '-', 'LineWidth', 2, 'Color', 'r', 'DisplayName', 'Trajectory');
% attach metadata to reference trajectory
h_trajectory.UserData.epochs = 1:numel(time);
h_trajectory.UserData.times = time;
% configure custom datatip
row1 = dataTipTextRow('Epoch', 1:numel(lat));
row2 = dataTipTextRow('Time', string(time));
row3 = dataTipTextRow('Latitude', lat);
row4 = dataTipTextRow('Longitude', lon);
h_trajectory.DataTipTemplate.DataTipRows = [row1 row2 row3 row4];

hold on

% plot reference trajectory
if bool_true
    h_reference = geoplot(lat_true, lon_true, 'ro', 'MarkerSize', 4, 'LineWidth', 1, 'Color', 'g', 'DisplayName', 'Reference');
    % attach metadata to reference trajectory
    h_reference.UserData.epochs = 1:numel(time);
    h_reference.UserData.times = time;
    % configure custom datatip
    row1 = dataTipTextRow('Epoch', 1:numel(lat_true));
    row2 = dataTipTextRow('Time', string(time));
    row3 = dataTipTextRow('Latitude', lat_true);
    row4 = dataTipTextRow('Longitude', lon_true);
    h_reference.DataTipTemplate.DataTipRows = [row1 row2 row3 row4];
end

if iskinematic
    % highlight first position
    h_current = geoplot(lat(1), lon(1), 'bx', 'LineWidth', 2, 'MarkerSize', 10, 'DisplayName', 'Current Epoch');
end

% add legend
legend

% drop-down to switch the background map (also available if not kinematic)
basemaps = {'streets-light', 'streets', 'streets-dark', 'satellite', 'topographic', 'none'};
basemap_labels = {'Streets (light)', 'Streets', 'Streets (dark)', 'Satellite', 'Topographic', 'None'};
h_basemap = uicontrol(fig_map, 'Style','popupmenu', 'String',basemap_labels, ...
    'Units','normalized', 'Position',[0.58 0.02 0.13 0.05], ...
    'FontWeight','bold', ...
    'Value',find(strcmp(basemaps, geobasemap(h_trajectory.Parent)), 1), ...
    'Callback', @change_basemap);

if iskinematic
    % ---- animated trajectory playback ------------------------------------
    % The animation is driven by a timer object instead of a blocking
    % for-loop with pause(). A blocking loop monopolises the MATLAB main
    % thread, so clicks on the Stop/Pause buttons are only serviced once the
    % loop yields - which, with the very small pause() intervals used here,
    % caused a large delay before the action took effect (clearly visible in
    % MATLAB R2026a). With a timer the main thread stays free and the
    % buttons react immediately between ticks.

    % indices of the epochs that are visualised during the animation
    anim_idx = unique([1 : ceil(n/1000) : n, n]);
    anim_pos = 1;                                    % next step to draw
    % timer period [s]; clamped so the timer stays reliable
    anim_period = round(max(sec_total/numel(anim_idx), 0.02), 3);

    anim_timer = timer('ExecutionMode','fixedRate', 'Period',anim_period, ...
        'BusyMode','drop', 'TimerFcn',@animation_step);

    % always clean up the timer when the figure is closed
    fig_map.CloseRequestFcn = @close_figure;

    % "Stop"/"Start" button: ends the animation, then replays it on click
    h_stop = uicontrol(fig_map, 'Style','pushbutton', 'String','Stop', ...
        'Units','normalized', 'Position',[0.90 0.02 0.08 0.05], ...
        'FontWeight','bold', ...
        'Callback', @stop_animation);
    % "Pause"/"Resume" toggle button: suspends/continues the animation
    h_pause = uicontrol(fig_map, 'Style','togglebutton', 'String','Pause', ...
        'Units','normalized', 'Position',[0.81 0.02 0.08 0.05], ...
        'FontWeight','bold', ...
        'Callback', @pause_toggle);
    % "Save" button: writes the animation to animation.GIF in the WORK folder
    h_save = uicontrol(fig_map, 'Style','pushbutton', 'String','Save', ...
        'Units','normalized', 'Position',[0.72 0.02 0.08 0.05], ...
        'FontWeight','bold', ...
        'Callback', @save_animation);

    start(anim_timer);
end

    function animation_step(~, ~)
        % advance the current-position marker by one step (called by the timer)
        if ~ishandle(fig_map)
            stop_and_delete_timer();
            return
        end
        if anim_pos > numel(anim_idx)
            % animation finished: show the last epoch and offer a replay
            stop(anim_timer);
            set(h_current, 'XData',lat(n), 'YData',lon(n), 'DisplayName','Last Epoch');
            set(h_stop, 'String','Start', 'Callback',@start_animation);
            if ishandle(h_pause)
                set(h_pause, 'String','Pause', 'Value',h_pause.Min, 'Enable','off');
            end
            return
        end
        q = anim_idx(anim_pos);
        set(h_current, 'XData',lat(q), 'YData',lon(q), 'DisplayName','Current Epoch');
        anim_pos = anim_pos + 1;
    end

    function start_animation(~, ~)
        % (re)start the animation from the beginning
        anim_pos = 1;
        set(h_current, 'XData',lat(1), 'YData',lon(1), 'DisplayName','Current Epoch');
        set(h_stop, 'String','Stop', 'Callback',@stop_animation);
        if ishandle(h_pause)
            set(h_pause, 'String','Pause', 'Value',h_pause.Min, 'Enable','on');
        end
        if isvalid(anim_timer) && strcmp(anim_timer.Running, 'off')
            start(anim_timer);
        end
    end

    function stop_animation(~, ~)
        % stop the animation and relabel the button so it can be replayed
        if isvalid(anim_timer) && strcmp(anim_timer.Running, 'on')
            stop(anim_timer);
        end
        set(h_stop, 'String','Start', 'Callback',@start_animation);
    end

    function pause_toggle(src, ~)
        % suspend / continue the animation without losing the current position
        is_paused = src.Value == src.Max;
        if is_paused
            src.String = 'Resume';
            if isvalid(anim_timer) && strcmp(anim_timer.Running, 'on')
                stop(anim_timer);
            end
        else
            src.String = 'Pause';
            if isvalid(anim_timer) && strcmp(anim_timer.Running, 'off')
                start(anim_timer);
            end
        end
    end

    function change_basemap(src, ~)
        % switch the background map of the geographic axes
        geobasemap(h_trajectory.Parent, basemaps{src.Value});
    end

    function save_animation(~, ~)
        % capture the whole animation and write it to animation.GIF in the
        % current WORK folder. The timer-driven playback is suspended while
        % the frames are grabbed and resumed afterwards.
        gif_path = fullfile(pwd, 'animation.GIF');

        % remember playback state and freeze the animation during capture
        was_running = isvalid(anim_timer) && strcmp(anim_timer.Running, 'on');
        if was_running
            stop(anim_timer);
        end
        resume_pos = anim_pos;                       % restore this afterwards

        % block the controls while the GIF is being written, remembering
        % their previous state (e.g. Pause is disabled once playback ended)
        stop_enable  = get(h_stop,  'Enable');
        pause_enable = get(h_pause, 'Enable');
        set([h_stop h_pause h_save h_basemap], 'Enable','off');
        set(h_save, 'String','Saving...');
        drawnow
        pause(1)            % give the basemap tiles time to finish loading

        % The GIF gets a fixed short duration and only a handful of frames:
        % writing ~1000 frames (as the on-screen animation uses) is slow and
        % produces a huge file. A coarse subsample of the epochs is enough to
        % convey the movement.
        gif_total   = 3;                                 % target GIF length [s]
        gif_nframes = min(45, n);                        % frames in the GIF
        gif_idx     = unique(round(linspace(1, n, gif_nframes)));
        delay       = gif_total / numel(gif_idx);        % delay per frame [s]
        % capture the map axes only, so the buttons are not part of the GIF
        ax = h_trajectory.Parent;

        try
            for k = 1 : numel(gif_idx)
                q = gif_idx(k);
                set(h_current, 'XData',lat(q), 'YData',lon(q), ...
                    'DisplayName','Current Epoch');
                drawnow
                % half resolution: a satellite background otherwise makes the
                % GIF several times larger
                im = imresize(frame2im(getframe(ax)), 0.5);
                % one fixed 128-colour map from the first frame, reused for
                % all frames: keeps colours stable and the file small
                % ('nodither' compresses much better)
                if k == 1
                    [imind, cm] = rgb2ind(im, 128, 'nodither');
                    imwrite(imind, cm, gif_path, 'gif', ...
                        'LoopCount',Inf, 'DelayTime',delay);
                else
                    imind = rgb2ind(im, cm, 'nodither');
                    imwrite(imind, cm, gif_path, 'gif', ...
                        'WriteMode','append', 'DelayTime',delay);
                end
            end
            msgbox(['Animation saved to ' gif_path], 'Save', 'help');
        catch err
            errordlg(['Could not save animation: ' err.message], 'Save');
        end

        % restore the controls and the playback position
        if ishandle(h_save)
            set(h_save, 'String','Save', 'Enable','on');
        end
        if ishandle(h_basemap)
            set(h_basemap, 'Enable','on');
        end
        if ishandle(h_stop)
            set(h_stop, 'Enable',stop_enable);
        end
        if ishandle(h_pause)
            set(h_pause, 'Enable',pause_enable);
        end
        anim_pos = resume_pos;
        if resume_pos > numel(anim_idx)
            % playback had already finished: keep the last-epoch marker
            set(h_current, 'XData',lat(n), 'YData',lon(n), 'DisplayName','Last Epoch');
        else
            p = anim_idx(max(resume_pos,1));
            set(h_current, 'XData',lat(p), 'YData',lon(p), 'DisplayName','Current Epoch');
        end
        if was_running && isvalid(anim_timer) && strcmp(anim_timer.Running, 'off')
            start(anim_timer);
        end
    end

    function close_figure(~, ~)
        % stop/delete the timer before destroying the figure
        stop_and_delete_timer();
        delete(fig_map);
    end

    function stop_and_delete_timer()
        if isa(anim_timer, 'timer') && isvalid(anim_timer)
            stop(anim_timer);
            delete(anim_timer);
        end
    end

end
