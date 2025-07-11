function [] = MultiPlot(PATHS, XYZ_true, LABELS, PlotStruct)
% This function creates Multi-Plots which indicate the convergence of the
% PPP solution. It uses either one or multiple files with resets of the 
% solution to create plots of coordinate differences and convergence time.
%
% INPUT:
%   PATHS       cell, each row contains the path to the folder of a
%               processing from which the data4plot.mat-file is loaded
%   XYZ_true    matrix, true ECEF coordinates for each processing, #files x 3
%   LABELS      cell, containing string with label in each row
%   PlotStruct  struct, containing booleans defining the plots which will
%               be started and thresholds which define convergence
% OUTPUT:
%   []
%
% using distinguishable_colors.m (c) 2010-2011, Tim Holy
% 
% Revision:
%   2024/02/12, MFWG: removing variable TTFF, calculation of TTCF
% 
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************

% create waitbar
WBAR = waitbar(0, 'Creating Multi-Plot...', 'Name','Progress of creating Multi-Plot');

% create some variables
global STOP_CALC;   STOP_CALC = 0;
unique_labels = unique(LABELS, 'stable');  	% existing labels, keep order
n_unique = numel(unique_labels);          	% number of different labels
coleur = createDistinguishableColors(n_unique);
PlotStruct.coleurs = coleur;                % colors for each label

PlotStruct.solution = 'float';
if PlotStruct.fixed; PlotStruct.solution = 'fixed'; end

% initialize variables for Bar Plot of Convergence
bars_minutes = PlotStruct.bar_position;          % point in time for bar plot
BARS = zeros(n_unique, numel(bars_minutes)+1, 4);     % row = label, col = points in time (+sum), dim = E/N/H/2D
% initialize variables for Time to First Fix Plot and Box Plot
TTCF = cell(1, n_unique);   BOX = cell(1, n_unique);
% initialize variables for Quantile Convergence Plot, each row for one label
Q68 = cell(n_unique, 6);    % 0.68 quantile for North, East, Height, 2D, 3D, ZTD
Q95 = cell(n_unique, 6);    % 0.95 quantile for North, East, Height, 2D, 3D, ZTD
Q_dT = cell(n_unique,1);    % points in time all convergence periods have in common
% initialize variable for ConvAccur Plot
CA = cell(n_unique, 2);     % 2D convergence, 3D accuracy at the end, label
% initialize variable to store statistics in calcPerformanceIndicators.m
STATS = cell(9, n_unique+1);


% loop over different labels
for i = 1:n_unique   
    
    curr_label = unique_labels{i};              % get current label
    bool_label = strcmpi(LABELS, curr_label);	% look for the rows of this label
    n_label = sum(bool_label);                  % number of files of current label
    paths = PATHS(bool_label, :);               % cell, paths of current label
    xyz_true = XYZ_true(bool_label, :);         % cell, true coordinates of current label
    
    % initialize variables in struct d for current label
    d.dT = []; d.Time = []; d.FIXED = []; d.N = []; d.E = []; d.H = []; d.ZTD = [];
    
    % loop over files of current label
    for ii = 1:n_label
        storeData = []; obs = [];  	% reset variables from last iteration
        
        % load variables of current processing
        try
            fpath_data4plot = GetFullPath([paths{ii} 'data4plot.mat']);
            load(fpath_data4plot, 'storeData', 'obs');      %  variables not used: 'satellites', 'settings', 'model_save'
            if isempty(storeData); storeData = recover_storeData(paths{ii}); end
            if isempty(obs); obs = recover_obs(paths{ii}); end
        catch
            try
                storeData = recover_storeData(paths{ii});   % e.g., no data4plot.mat file
                obs = recover_obs(paths{ii});
            catch
                errordlg({['Loading File #' sprintf('%d',ii) ' of label ' ], [curr_label ' failed!']}, 'Error')
                continue
            end
        end

        % get position data
        [pos_3D, pos_UTM] = getPositionData(storeData, obs, curr_label, PlotStruct);
        % get true position
        [~, pos_geo_true, North_true, East_true] = ...
            getTruePosition(xyz_true(ii,:), pos_3D);
        % calculate coordinate differences for whole processing
        dN = pos_UTM(:,1) - North_true;
        dE = pos_UTM(:,2) - East_true;
        dH = pos_UTM(:,3) - pos_geo_true.h;
        % calculate difference of troposphere estimation to IGS troposphere product
        dZTD = TropoDifference(storeData, obs, PlotStruct);
                
        reset_epochs = storeData.float_reset_epochs;    % epochs where solution was resetted during processing
        no_epochs = numel(storeData.gpstime);           % number of epochs of current processing
        
        % reshape processing results to convergence periods
        d = Reshape2ConvergePeriods(storeData, dN, dE, dH, dZTD, reset_epochs, no_epochs, d, PlotStruct);
        
        % update waitbar
        if ishandle(WBAR)
            progress = ii/n_label;      % 1/100 [%]
            mess = sprintf('%02.2f%s', progress*100, ['% of label ' curr_label ' are finished.']);
            waitbar(progress, WBAR, mess)
        end
        % check if user pushed STOP button
        if STOP_CALC; if ishandle(WBAR); close(WBAR); end; return; end
        
    end     % end of loop over files of current label
    
    % check and prepare variables
    d = checkVariables(d);
    
    % check if a solution has been calculated at all
    if isempty(d.dT)
        continue    % all epochs have no solution, continue
    end    
    
    % looking for points in time where convergence is reached (for all
    % convergence periods)
    [conv_dN, conv_dE, conv_dH, conv_2D, conv_3D] = find_convergence(d.N, d.E, d.H, d.dT, PlotStruct);
    if PlotStruct.fixed;   TTCF{i} = conv_2D;   end         % save time to correct fix 
        
    % find quantiles and points in time which all convergence periods have
    [Q68, Q95, Q_dT] = prepMultiPlot(d, Q68, Q95, Q_dT, i);
    dT_all = Q_dT{i};
    q68 = Q68(i, :);
    q95 = Q95(i, :);
    
    
%     % TEST PLOT ACCURACY OVER TIME, EXPERIMENTAL!
%     PlotAccuracyOverHours(Time, dN_, dE_, dH_, conv_2D, curr_label, PlotStruct)
    
    
    % Create Plots for current label
    CreateCurrent(d.N, d.E, d.H, d.dT, d.ZTD, q68, q95, dT_all, PlotStruct, curr_label, conv_dN, conv_dE, conv_dH, conv_2D, i);
    
    % Preparations for plots for all labels
    if PlotStruct.box            	% Box Plot
        BOX{i} = conv_2D;
    end
    if PlotStruct.bar            	% Bar Plot
        BARS = prepConvergenceBars(conv_dN, conv_dE, conv_dH, conv_2D, BARS, i, bars_minutes);
    end
    if PlotStruct.convaccur        	% Convergence/Accuracy Plot
        CA = prepConvaccurPlot(CA, d, i, conv_2D, unique_labels, PlotStruct.bar_position(end));
    end
    
    % print perfomance and statistic of current label to command window
    STATS = calcPerformanceIndicators(d, conv_2D, TTCF{i}, dT_all, q68, q95, curr_label, PlotStruct, STATS, i);
    
end         % end of loop over different labels


% Create Plots for all labels which were prepared before 
CreateAll(Q68, Q95, Q_dT, BOX, BARS, TTCF, CA, unique_labels, bars_minutes, PlotStruct);

% Print statistics to command window (in the case of multiple labels)
if n_unique > 1
    r = STATS(2:end, 1); c = STATS(1, 2:end);
    T = cell2table(STATS(2:end, 2:end), 'VariableNames', c, 'RowNames', r);
    disp(T); fprintf('\n')
end

% close waitbar
if ishandle(WBAR);        close(WBAR);    end


function [] = CreateCurrent(dN, dE, dH, dT, dZTD, q68, q95, dT_all, PlotStruct, label, conv_dN, conv_dE, conv_dH, conv_2D, i)
% Creates plots for the current label
% Position Convergence
if PlotStruct.pos_conv
    PositionConvergence(dN, dE, dH, dT, q68, q95, dT_all, PlotStruct, label);
end
% Coordinate Convergence
if PlotStruct.coord_conv
    CoordinateConvergence(dN, dE, dH, dT, q68, q95,  dT_all, PlotStruct, label);
end
% Troposphere Convergence
if PlotStruct.tropo
    TroposphereConvergence(dZTD, q68{6}, q95{6}, dT, dT_all, PlotStruct, label);
    plotZTDHisto(dZTD, PlotStruct, label, i)
end
% Histogram of Convergence
if PlotStruct.histo_conv
    ConvergenceHistogram(conv_dN, conv_dE, conv_dH, conv_2D, label, PlotStruct);
end
% % Position Accuracy (currently not included in GUI)
% PositionAccuracy(dN, dE, label, PlotStruct)

function CreateAll(Q68, Q95, Q_dT, BOX, BARS, TTCF, CA, unique_labels, bars_minutes, PlotStruct)
% Creates plots which contain all labels
coleurs = PlotStruct.coleurs;   % colors for each label
% Quantile Convergence
if PlotStruct.quant_conv
    QuantileConvergence(Q68, Q95, Q_dT, unique_labels, PlotStruct, coleurs);
end
% Box plot (of convergence)
if PlotStruct.box
    vis_BoxPlot(BOX, unique_labels, PlotStruct.float, coleurs);
end
% Bar plot of convergence
if PlotStruct.bar
    vis_ConvergenceBars(BARS, unique_labels, bars_minutes, PlotStruct, coleurs);
end
% Time to First Fix Plot
if PlotStruct.fixed && PlotStruct.ttff 
    vis_plot_ttff(TTCF, unique_labels, coleurs);
end
% Troposphere Quantile Convergence
if PlotStruct.tropo
    ZTDQuantileConvergence(Q68, Q95, Q_dT, unique_labels, PlotStruct, coleurs);
end
% Convergence/Accuracy Plot
if PlotStruct.convaccur
    ConvAccurPlot(CA, coleurs, PlotStruct);
end



