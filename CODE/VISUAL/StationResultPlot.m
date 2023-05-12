function [] = StationResultPlot(TABLE, PlotStruct)
% This function creates various plots to compare the performace of
% different stations (e.g., convergence, ZTD, accuracy)
%
% INPUT:
%   TABLE       cell, content of Multi-Plot table
%   PlotStruct  struct, containing booleans defining the plots which will
%               be started and thresholds which define convergence
% OUTPUT:
%   []
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

[unique_labels, ~, idx_label] = unique(TABLE(:,7), 'stable');
n_labels = numel(unique_labels);
coleurs = colorcube(n_labels);     % colors for each label
% to store data for the station mean convergence graph
G_conv_2D_mean = cell(1);   G_conv_3D_mean = cell(1);
% to store data for the station median convergence graph
G_conv_2D_medi = cell(1);   G_conv_3D_medi = cell(1);
% to store data for the station accuracy graph
G_acc_2D  = cell(1);        G_acc_3D  = cell(1);
% to store data for the station accuracy graph
G_ZTD_68  = cell(1);        G_ZTD_95  = cell(1);
% to create ZTD plots
PlotStruct.tropo = true;

for j = 1:n_labels
    TABLE_now = TABLE(idx_label == j, :);
    curr_label = unique_labels{j};
    
    % create waitbar and enable stop of calculations
    WBAR = waitbar(0, 'Start plotting Station Graph', 'Name', ['Progress for ' curr_label]);
    global STOP_CALC;   STOP_CALC = 0;
    
    % for the following variables each row corresponds to a processing
    PATHS = TABLE_now(:,1);                	% paths to result-folders
    STATIONS = TABLE_now(:,2);              % station names
    XYZ_true = cell2mat(TABLE_now(:,3:5));  % true ECEF coordinates
    
    % check which stations in the table and get unique 4-digit-station name and
    % coordinates (first row is taken)
    [unique_stations, idx_a, ~] = unique(STATIONS, 'stable');
    unique_XYZ =  XYZ_true(idx_a,:);        % coordinates of unique stations
    n_unique = numel(unique_stations);  	% number of different stations
    
    % initialize variables for Time to First Fix Plot and Box Plot
    TTFF = cell(1, n_unique);  TTCF = cell(1, n_unique);
    % initialize variable storing the 95% quantile of the 2D and 3D
    % error of all epochs for each station
    ACC_2D = zeros(n_unique,1);     ACC_3D = zeros(n_unique,1);
    % initialize variable storing mean time of float 2D and 3D
    % convergence for each station
    CONV_2D_mean = zeros(n_unique,1);    CONV_3D_mean = zeros(n_unique,1);
    % initialize variable storing median time of float 2D and 3D
    % convergence for each station
    CONV_2D_medi = zeros(n_unique,1);    CONV_3D_medi = zeros(n_unique,1);    
    % initialize variable storing 0.68 and 0.95 quantile of ZTD estimation
    ZTD_68 = zeros(n_unique,1);     ZTD_95 = zeros(n_unique,1);
    
    % loop over different stations
    for i = 1:n_unique
        
        curr_stat = unique_stations{i};          	% get current station name
        bool_stat = strcmpi(STATIONS, curr_stat);	% look for the rows of this station
        n_files = sum(bool_stat);                  	% number of files of current station
        paths = PATHS(bool_stat, :);                % cell, paths of current label
        xyz_true = XYZ_true(bool_stat, :);          % cell, true coordinates of current label
        
        % initialize variables in struct d for current label
        d.dT = []; d.Time = []; d.FIXED = []; d.N = []; d.E = []; d.H = []; d.ZTD = [];
        
        
        for ii = 1:n_files
            %% loop over files of current label
            try         % load variables of current processing
                fpath = GetFullPath([paths{ii} 'data4plot.mat']);
                load(fpath, 'storeData', 'obs');    %  variables not used: 'satellites', 'settings', 'model_save'
            catch
                errordlg({['Loading File #' sprintf('%d',ii) ' of ' ], [curr_stat ' failed!']}, 'Error')
                continue
            end
            % get position data
            [pos_3D, pos_UTM] = getPositionData(storeData, obs, curr_stat, PlotStruct);
            % get true position
            [pos_3D_true, pos_geo_true, North_true, East_true] = ...
                getTruePosition(xyz_true(ii,:), pos_3D);
            % calculate coordinate differences for whole processing
            dN = pos_UTM(:,1) - North_true;
            dE = pos_UTM(:,2) - East_true;
            dH = pos_UTM(:,3) - pos_geo_true.h;
            % get troposphere estimation and calculate difference to IGS
            dZTD = TropoDifference(storeData, obs);
            
            reset_epochs = storeData.float_reset_epochs;    % epochs where solution was resetted during processing
            no_epochs = numel(storeData.float);             % number of epochs of current processing
            
            % reshape processing results to convergence periods
            d = Reshape2ConvergePeriods(storeData, dN, dE, dH, dZTD, reset_epochs, no_epochs, d, PlotStruct);
            
            % update waitbar
            if ishandle(WBAR)
                progress = i/n_unique;      % 1/100 [%]
                mess_1 = sprintf('%s%02.2f%s', 'Station Graph: ', progress*100, '% are finished.');
                mess_2 = ['Current station: ' curr_stat];
                waitbar(progress, WBAR, {mess_1; mess_2})
            end
            % check if user pushed STOP button
            if STOP_CALC; if ishandle(WBAR); close(WBAR); end; return; end
        end
        
        
        % check and prepare variables
        d = checkVariables(d);
        
        % check if a solution has been calculated at all
        if isempty(d.dT)
            continue    % all epochs have no solution, continue
        end
        
        % looking for points in time where convergence is reached (for all convergence periods)
        [~, ~, ~, conv_2D, conv_3D] = find_convergence(d.N, d.E, d.H, d.dT, PlotStruct);
        % find time to first fix and time to correct fix
        if PlotStruct.fixed
            [TTFF, TTCF] = prepTTFF(TTFF, TTCF, d.FIXED,  PlotStruct.thresh_2D, d.dT, d.E, d.N, i);
        end
        % calculate station accuracy
        d2D = sqrt(d.N.^2 + d.E.^2);
        d3D = sqrt(d.N.^2 + d.E.^2 + d.H.^2);
        % calculate mean station convergence
        CONV_2D_mean(i) = mean(conv_2D, 'omitnan');
        CONV_3D_mean(i) = mean(conv_3D, 'omitnan');
        % calculate median station convergence
        CONV_2D_medi(i) = median(conv_2D, 'omitnan');
        CONV_3D_medi(i) = median(conv_3D, 'omitnan');        
        % calculate quantiles
        ACC_2D(i) = calc_quantile(d2D(:), .95);
        ACC_3D(i) = calc_quantile(d3D(:), .95);
        ZTD_68(i) = calc_quantile(abs(d.ZTD(:)), .68);
        ZTD_95(i) = calc_quantile(abs(d.ZTD(:)), .95);
        
    end         % end of loop over files of current label
    
    
    %% Prepare Station Graph
    if PlotStruct.graph
        
        % --- Prepare Station Convergence Graph
        n_stat = numel(unique_stations);
        row = j + 1;
        if j == 1
            G_conv_2D_mean(1,1:n_stat) = unique_stations;
            G_conv_3D_mean(1,1:n_stat) = unique_stations;
            G_conv_2D_medi(1,1:n_stat) = unique_stations;
            G_conv_3D_medi(1,1:n_stat) = unique_stations;            
        end
        stat_list = G_conv_3D_mean(1,:);
        for iii = 1:n_stat
            station = unique_stations{iii};
            if contains(station, stat_list)
                bool = contains(stat_list, station);
                G_conv_2D_mean{row,bool} = CONV_2D_mean(iii);
                G_conv_3D_mean{row,bool} = CONV_3D_mean(iii);
                G_conv_2D_medi{row,bool} = CONV_2D_medi(iii);
                G_conv_3D_medi{row,bool} = CONV_3D_medi(iii);                
            else
                col = size(G_conv_3D_mean,2) + 1;
                G_conv_2D_mean{1,col} = station;
                G_conv_3D_mean{1,col} = station;
                G_conv_2D_medi{1,col} = station;
                G_conv_3D_medi{1,col} = station;                
                G_conv_2D_mean{row,col} = CONV_2D_mean(iii);
                G_conv_3D_mean{row,col} = CONV_3D_mean(iii);
                G_conv_2D_medi{row,col} = CONV_2D_medi(iii);
                G_conv_3D_medi{row,col} = CONV_3D_medi(iii);                
            end
        end
        
        % --- Prepare Station Accuracy Graph
        n_stat = numel(unique_stations);
        row = j + 1;
        if j == 1
            G_acc_2D(1,1:n_stat) = unique_stations;
            G_acc_3D(1,1:n_stat) = unique_stations;
        end
        stat_list = G_acc_3D(1,:);
        for iii = 1:n_stat
            station = unique_stations{iii};
            if contains(station, stat_list)
                bool = contains(stat_list, station);
                G_acc_2D{row,bool} = ACC_2D(iii);
                G_acc_3D{row,bool} = ACC_3D(iii);
            else
                col = size(G_acc_3D,2) + 1;
                G_acc_2D{1,col} = station;
                G_acc_2D{row,col} = ACC_2D(iii);
                G_acc_3D{1,col} = station;
                G_acc_3D{row,col} = ACC_3D(iii);
            end
        end
    end
    
    % --- Prepare Station ZTD Graph
    n_stat = numel(unique_stations);
    row = j + 1;
    if j == 1
        G_ZTD_68(1,1:n_stat) = unique_stations;
        G_ZTD_95(1,1:n_stat) = unique_stations;
    end
    stat_list = G_ZTD_95(1,:);
    for iii = 1:n_stat
        station = unique_stations{iii};
        if contains(station, stat_list)
            bool = contains(stat_list, station);
            G_ZTD_68{row,bool} = ZTD_68(iii);
            G_ZTD_95{row,bool} = ZTD_95(iii);
        else
            col = size(G_ZTD_95,2) + 1;
            G_ZTD_68{1,col} = station;
            G_ZTD_68{row,col} = ZTD_68(iii);
            G_ZTD_95{1,col} = station;
            G_ZTD_95{row,col} = ZTD_95(iii);
        end
    end
    
% close waitbar
if ishandle(WBAR);        close(WBAR);    end

end



%% Create Station Graph
if PlotStruct.graph
    [n, m] = size(G_conv_3D_mean);
    % replace missing stations values with NaN
    G_conv_2D_mean( cellfun(@isempty, G_conv_2D_mean) ) = {NaN};
    G_conv_3D_mean( cellfun(@isempty, G_conv_3D_mean) ) = {NaN};
    G_conv_2D_medi( cellfun(@isempty, G_conv_2D_medi) ) = {NaN};
    G_conv_3D_medi( cellfun(@isempty, G_conv_3D_medi) ) = {NaN};    
    G_acc_2D ( cellfun(@isempty, G_acc_2D ) ) = {NaN};
    G_acc_3D ( cellfun(@isempty, G_acc_3D ) ) = {NaN};
    G_ZTD_68 ( cellfun(@isempty, G_ZTD_68)  ) = {NaN};
    G_ZTD_95 ( cellfun(@isempty, G_ZTD_95 ) ) = {NaN};
    % sort stations based on the convergence times of the first label
    G_conv_2D_mean = G_conv_2D_mean'; G_conv_2D_mean = sortrows(G_conv_2D_mean, 2); G_conv_2D_mean = G_conv_2D_mean';
    G_conv_3D_mean = G_conv_3D_mean'; G_conv_3D_mean = sortrows(G_conv_3D_mean, 2); G_conv_3D_mean = G_conv_3D_mean';
    G_conv_2D_medi  = G_conv_2D_medi';  G_conv_2D_medi  = sortrows(G_conv_2D_medi, 2);  G_conv_2D_medi  = G_conv_2D_medi';
    G_conv_3D_medi  = G_conv_3D_medi';  G_conv_3D_medi  = sortrows(G_conv_3D_medi, 2);  G_conv_3D_medi  = G_conv_3D_medi';
    G_acc_2D  = G_acc_2D';  G_acc_2D  = sortrows(G_acc_2D,  2); G_acc_2D  = G_acc_2D';
    G_acc_3D  = G_acc_3D';  G_acc_3D  = sortrows(G_acc_3D,  2); G_acc_3D  = G_acc_3D';
    G_ZTD_68  = G_ZTD_68';  G_ZTD_68  = sortrows(G_ZTD_68, 2);  G_ZTD_68  = G_ZTD_68';
    G_ZTD_95  = G_ZTD_95';  G_ZTD_95  = sortrows(G_ZTD_95,  2); G_ZTD_95  = G_ZTD_95';
    % get plot data
    P11 = cell2mat(G_conv_2D_mean(2:n, 1:m));
    P12 = cell2mat(G_conv_3D_mean(2:n, 1:m));
    P21 = cell2mat(G_conv_2D_medi(2:n, 1:m));
    P22 = cell2mat(G_conv_3D_medi(2:n, 1:m));    
    P31 = cell2mat(G_acc_2D (2:n, 1:m));
    P32 = cell2mat(G_acc_3D (2:n, 1:m));
    P41 = cell2mat(G_ZTD_68 (2:n, 1:m));
    P42 = cell2mat(G_ZTD_95 (2:n, 1:m));
    
    % Plot the mean Station Convergence Graph
    str = 'Station Mean Convergence Graph, float solution';
    if PlotStruct.fixed ; str = 'Station Mean TTFF Graph, fixed solution'; end
    fig_stat_conv_ = figure('Name',str, 'NumberTitle','off');
    subplot(2,1,1)
    StationConvergenceGraph(P11, coleurs, G_conv_2D_mean, n, m, unique_labels)
    title(['Station Convergence Graph (2D < ' sprintf('%.3f',PlotStruct.thresh_2D) 'm)'])
    subplot(2,1,2)
    StationConvergenceGraph(P12, coleurs, G_conv_3D_mean, n, m, unique_labels)
    title(['Station Convergence Graph (3D < ' sprintf('%.3f',PlotStruct.thresh_3D) 'm)'])

    % Plot the median Station Convergence Graph
    str = 'Station Median Convergence Graph, float solution';
    if PlotStruct.fixed ; str = 'Station Median TTFF Graph, fixed solution'; end
    fig_stat_conv = figure('Name',str, 'NumberTitle','off');
    subplot(2,1,1)
    StationConvergenceGraph(P21, coleurs, G_conv_2D_medi, n, m, unique_labels)
    title(['Station Convergence Graph (2D < ' sprintf('%.3f',PlotStruct.thresh_2D) 'm)'])
    subplot(2,1,2)
    StationConvergenceGraph(P22, coleurs, G_conv_3D_medi, n, m, unique_labels)
    title(['Station Convergence Graph (3D < ' sprintf('%.3f',PlotStruct.thresh_3D) 'm)'])    
    
    % Plot the Station Accuracy Graph
    str = 'Station Graph Accuracy, float solution';
    if PlotStruct.fixed ; str = 'Station Graph Accuracy, fixed solution'; end
    fig_stat_acc = figure('Name',str, 'NumberTitle','off');
    subplot(2,1,1)
    StationAccuracyGraph(P31, coleurs, G_acc_2D, n, m, unique_labels)
    title('Station 2D Accuracy Graph')
    subplot(2,1,2)
    StationAccuracyGraph(P32, coleurs, G_acc_3D, n, m, unique_labels)
    title('Station 3D Accuracy Graph')
    
    % Plot the Station ZTD Graph
    str = 'Station ZTD Accuracy, float solution';
%     if PlotStruct.fixed ; str = 'Station Graph Accuracy, fixed solution'; end
    fig_stat_ztd = figure('Name',str, 'NumberTitle','off');
    subplot(2,1,1)
    StationZTDGraph(P41, coleurs, G_ZTD_68, n, m, unique_labels)
    title('Station ZTD 0.68 Quantile')
    ylabel('68% Quantile [m]')
    subplot(2,1,2)
    StationZTDGraph(P42, coleurs, G_ZTD_95, n, m, unique_labels)
    title('Station ZTD 0.95 Quantile')
    ylabel('95% Quantile [m]')
    
    % add customized datatip mean convergence
    dcm = datacursormode(fig_stat_conv_);
    datacursormode on
    set(dcm, 'updatefcn', @customdatatip_StationGraph)    
    % add customized datatip median convergence
    dcm = datacursormode(fig_stat_conv);
    datacursormode on
    set(dcm, 'updatefcn', @customdatatip_StationGraph)
    % add customized datatip accuracy
    dcm = datacursormode(fig_stat_acc);
    datacursormode on
    set(dcm, 'updatefcn', @customdatatip_StationGraph)
    % add customized datatip ZTD
    dcm = datacursormode(fig_stat_ztd);
    datacursormode on
    set(dcm, 'updatefcn', @customdatatip_StationGraph)
    
end





function [] = StationConvergenceGraph(P, coleurs, GRAPH_conv, n, m, unique_labels)
hold on
for i = 1:n-1
    x = 1:m; y = P(i,:);                	% get plot data for current label
    x(isnan(y)) = []; y(isnan(y)) = [];   	% remove NaN for continous line
    if ~isempty(x)
        plot(x, y, '-o', 'color', coleurs(i,:), 'MarkerFaceColor',coleurs(i,:));
    end
end
legend(unique_labels, 'Location','southeast')	% create legend with labels
xticks(1:m)                     % write station names to x-axis
xticklabels(GRAPH_conv(1,1:m))
xtickangle(270)                 % rotate ticks
xlabel('Stations')
ylabel('Convergence [min]')
ylim([0 Inf])

function [] = StationAccuracyGraph(P, coleurs, GRAPH_acc, n, m, unique_labels)
hold on
for i = 1:n-1
    x = 1:m; y = P(i,:);                   % get plot data for current label
    x(isnan(y)) = []; y(isnan(y)) = [];     % remove NaN for continous line
    if ~isempty(x)
        plot(x, y, '-o', 'color', coleurs(i,:), 'MarkerFaceColor',coleurs(i,:));
    end
end
legend(unique_labels)           % create legend with labels
xticks(1:m)                     % write station names to x-axis
xticklabels(GRAPH_acc(1,1:m))
xtickangle(270)                 % rotate ticks
xlabel('Stations')
ylabel('95% Quantile [m]')
ylim([0 Inf])

function [] = StationZTDGraph(P, coleurs, GRAPH_acc, n, m, unique_labels)
hold on
for i = 1:n-1
    x = 1:m; y = P(i,:);                   % get plot data for current label
    x(isnan(y)) = []; y(isnan(y)) = [];     % remove NaN for continous line
    if ~isempty(x)
        plot(x, y, '-o', 'color', coleurs(i,:), 'MarkerFaceColor',coleurs(i,:));
    end
end
legend(unique_labels)           % create legend with labels
xticks(1:m)                     % write station names to x-axis
xticklabels(GRAPH_acc(1,1:m))
xtickangle(270)                 % rotate ticks
xlabel('Stations')
ylim([0 Inf])
