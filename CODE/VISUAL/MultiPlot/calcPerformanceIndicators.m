function STATS = calcPerformanceIndicators(d, conv, TTCF, TIME_all, q68, q95, label, PlotStruct, STATS, i)
% This function calculates various performance indicators of a label from
% the multi plot table.
%
% INPUT:
%	d               struct, time, position and ZTD difference of all convergence periods
%   conv            vector, 2D convergence time [minutes]
%   TTCF            time to correct fix [minutes]
%   TIME_all        vector, time stamps contained in all convergence periods
%   q68             cell, 0.68 quantile of dN, dE, dH, 2D, 3D for current label
%   q95             cell, 0.95 quantile of dN, dE, dH, 2D, 3D for current label
%   label           char array, name of current label
%   PlotStruct      struct, settings for Multi Plots
%   STATS           cell, stores statistics at the end of this function
%   i               index of label
% OUTPUT:
%   STATS           updated with statistics of current label
%       and output to the command window
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% (de)activate here

% convergence
mean___convergence = true;
median_convergence = true;
no_convergence = true;

% ZTD
ZTD_diff_mean = true;
ZTD_diff_median = true;
ZTD_diff_68_quantile = true;
ZTD_diff_95_quantile = true;

% position error all epochs
mean___2D_error_all_epochs = true;
mean___3D_error_all_epochs = true;
median_2D_error_all_epochs = true;
median_3D_error_all_epochs = true;

% position error after n minutes
mean___2D_error_after = true;
mean___3D_error_after = true;
median_2D_error_after = true;
median_3D_error_after = true;
std_3D_after_n_minutes = true;

% percentage of epochs below threshold
percentage_2D_below_thres = true;
percentage_3D_below_thres = true;


%% Preparation
dN = d.N; dE = d.E; dH = d.H;
TIME = d.dT;

d2D = sqrt(dN.^2 + dE.^2);          	% 2D position error
d3D = sqrt(dN.^2 + dE.^2 + dH.^2);      % 3D position error

thresh_2D = sprintf('%5.3f', PlotStruct.thresh_2D);     % 2D threshold [m]
thresh_3D = sprintf('%5.3f', PlotStruct.thresh_3D);     % 3D threshold [m]

% remove outliers
thresh = 10;                            % [m], seems to be a good value
d2D(d2D > thresh) = NaN;
d3D(d3D > thresh) = NaN;

n = max(TIME_all);                      % last point in time which all convergence periods have [s]
n_min = ceil(n/60);                     % round up [minutes]
n_str = sprintf('%05.2f', n_min);        % convert to string

TIME = round(TIME);                     % time after reset [s]
d2D_n = d2D(TIME == n);                 % 2D position error after n
d3D_n = d3D(TIME == n);                 % 3D position error after n

idx = 1;        % index to store statistics in STATS


%% Calculation
if PlotStruct.float
    % average convergence time
    average_conv = mean(conv, 'omitnan');               % [minutes]

    % median convergence time
    median_conv  = median(conv, 'omitnan');             % [minutes]

    % percentage of no convergence
    not_conv = sum(isnan(conv) | conv > n_min);
    not_conv = not_conv / numel(conv) * 100;            % [%]

elseif PlotStruct.fixed
    % average time to correct fix
    average_ttff = mean(TTCF, 'omitnan');               % [minutes]

    % median time to correct fix
    median_ttff  = median(TTCF, 'omitnan');             % [minutes]

    % percentage no correct fix after n minutes
    no_fix = sum(isnan(TTCF) | TTCF > n_min);
    no_fix = no_fix / numel(TTCF) * 100;                % [%]
end

% average 2D position error for all epochs
average_2D    = mean(d2D(:), 'omitnan') * 100;         % [cm]

% average 3D position error for all epochs
average_3D    = mean(d3D(:), 'omitnan') * 100;         % [cm]

% median 2D position error for all epochs
median_2D    = median(d2D(:), 'omitnan') * 100;         % [cm]

% median 3D position error for all epochs
median_3D    = median(d3D(:), 'omitnan') * 100;         % [cm]

% median 3D position error after n minutes
median_3D_n  = median(d3D_n(:), 'omitnan') * 100;       % [cm]

% average 3D position error after n minutes
average_3D_n = mean(d3D_n(:), 'omitnan') * 100;         % [cm]

% standard deviation 3D position error after n minutes
stdev_3D_n = std(d3D_n(:), 'omitnan') * 100;            % [cm]

% average 2D position error after n minutes
average_2D_n = mean(d2D_n(:), 'omitnan') * 100;         % [cm]

% median 2D position error after n minutes
median_2D_n = median(d2D_n(:), 'omitnan') * 100;        % [cm]

% percentage below 2D and 3D threshold
perc_2D_thresh = sum(d2D(:) < PlotStruct.thresh_2D, 'omitnan') / numel(d2D) * 100;     % [%]
perc_3D_thresh = sum(d3D(:) < PlotStruct.thresh_3D, 'omitnan') / numel(d3D) * 100;     % [%]

% average of the ZTD difference
ZTD = abs(d.ZTD(:));
ZTD_average = mean(ZTD, 'omitnan') * 100;        % [cm]

% median of the ZTD difference
ZTD_50 = median(ZTD, 'omitnan') * 100;        % [cm]

% 68% quantile of the ZTD difference
ZTD_68 = calc_quantile(ZTD, .68) * 100;    % [cm]

% 95% quantile of the ZTD difference
ZTD_95 = calc_quantile(ZTD, .95) * 100;    % [cm]



%% Print to command window and store in STATS
fprintf([label ' '])
if PlotStruct.float
    fprintf('(float)');
    STATS{idx, 1}   = 'float';
    STATS{idx, i+1} = matlab.lang.makeValidName(label);
elseif PlotStruct.fixed
    fprintf('(fixed)');
    STATS{idx, 1}   = 'fixed';
    STATS{idx, i+1} = matlab.lang.makeValidName(label);
end
idx = idx + 1;
fprintf('\n')

if PlotStruct.float
    if mean___convergence       % average convergence
        fprintf(['Average convergence time (2D < ' thresh_2D 'm):        '])
        if average_conv > 1
            fprintf('% 6.2f', average_conv)
            fprintf(' [min]\n')         % print in [minutes]
        else
            fprintf('% 6.2f', average_conv*60)
            fprintf(' [s]\n')           % print in [seconds]
        end
        STATS{idx, 1} = ['Average convergence time (2D < ' thresh_2D 'm) [min]'];
        STATS{idx, i+1} = round(average_conv, 2);
        idx = idx + 1;
    end


    if median_convergence       % median convergence
        fprintf(['Median  convergence time (2D < ' thresh_2D 'm):        '])
        if median_conv > 1
            fprintf('% 6.2f', median_conv)
            fprintf(' [min]\n')         % print in [minutes]
        else
            fprintf('% 6.2f', median_conv*60)
            fprintf(' [s]\n')           % print in [seconds]
        end
        STATS{idx, 1} = ['Median  convergence time (2D < ' thresh_2D 'm) [min]'];
        STATS{idx, i+1} = round(median_conv, 2);
        idx = idx + 1;
    end


    if no_convergence           % percentage without convergence
        fprintf('Percentage of no convergence:                  ')
        fprintf('% 6.2f', not_conv)
        fprintf(' %s', '[%]')
        fprintf('\n')
        STATS{idx, 1} = 'Percentage of no convergence: [%]';
        STATS{idx, i+1} = round(not_conv, 2);
        idx = idx + 1;
    end

elseif PlotStruct.fixed

    if mean___convergence           % average time to first fix
        fprintf(['Average time to correct fix (2D < ' thresh_2D 'm):     '])
        if average_ttff > 1
            fprintf('% 6.2f', average_ttff)
            fprintf(' [min]\n')         % print in [minutes]
        else
            fprintf('% 6.2f', average_ttff*60)
            fprintf(' [s]\n')           % print in [seconds]
        end        
        STATS{idx, 1} = ['Average time to correct fix (2D < ' thresh_2D 'm) [min]'];
        STATS{idx, i+1} = round(average_ttff, 2);
        idx = idx + 1;
    end


    if median_convergence           % median time to first fix
        fprintf(['Median  time to correct fix (2D < ' thresh_2D 'm):     '])
        if median_ttff > 1
            fprintf('% 6.2f', median_ttff)
            fprintf(' [min]\n')         % print in [minutes]
        else
            fprintf('% 6.2f', median_ttff*60)
            fprintf(' [s]\n')           % print in [seconds]
        end        
        STATS{idx, 1} = ['Median time to correct fix (2D < ' thresh_2D 'm) [min]'];
        STATS{idx, i+1} = round(median_ttff, 2);
        idx = idx + 1;
    end


    if no_convergence               % percentage without correct fix
        fprintf('Percentage of no correct fix:                  ')
        fprintf('% 6.2f', no_fix)
        fprintf(' %s', '[%]')
        fprintf('\n')
        STATS{idx, 1} = 'Percentage of no correct fix [%]';
        STATS{idx, i+1} = round(no_fix, 2);
        idx = idx + 1;
    end
end


if PlotStruct.tropo

    % -------------------------------------------------------------------------
    STATS{idx, 1} = '----';
    STATS{idx, i+1} = NaN;
    idx = idx + 1;
    % -------------------------------------------------------------------------

    if ZTD_diff_mean          % average ZTD difference
        fprintf('Average of the ZTD difference:                 ')
        fprintf('% 6.2f', ZTD_average)
        fprintf(' %s', '[cm]')
        fprintf('\n')
        STATS{idx, 1} = 'Average of the ZTD difference: [cm]';
        STATS{idx, i+1} = round(ZTD_average, 2);
        idx = idx + 1;
    end


    if ZTD_diff_median          % median ZTD difference
        fprintf('Median of the ZTD difference:                  ')
        fprintf('% 6.2f', ZTD_50)
        fprintf(' %s', '[cm]')
        fprintf('\n')
        STATS{idx, 1} = 'Median of the ZTD difference: [cm]';
        STATS{idx, i+1} = round(ZTD_50, 2);
        idx = idx + 1;
    end


    if ZTD_diff_68_quantile     % 68% quantile of ZTD difference
        fprintf('68%% quantile of the ZTD difference:            ')
        fprintf('% 6.2f', ZTD_68)
        fprintf(' %s', '[cm]')
        fprintf('\n')
        STATS{idx, 1} = '68% quantile of the ZTD difference';
        STATS{idx, i+1} = round(ZTD_68, 2);
        idx = idx + 1;
    end


    if ZTD_diff_95_quantile     % 95% quantile of ZTD difference
        fprintf('95%% quantile of the ZTD difference:            ')
        fprintf('% 6.2f', ZTD_95)
        fprintf(' %s', '[cm]')
        fprintf('\n')
        STATS{idx, 1} = '95% quantile of the ZTD difference';
        STATS{idx, i+1} = round(ZTD_95, 2);
        idx = idx + 1;
    end
end


% -------------------------------------------------------------------------
STATS{idx, 1} = '-----';
STATS{idx, i+1} = NaN;
idx = idx + 1;
% -------------------------------------------------------------------------


if mean___2D_error_all_epochs       % average 2D error of all epochs
    fprintf('Average 2D position error of all epochs:       ')
    fprintf('% 6.2f', average_2D)
    fprintf(' [cm]\n')
    STATS{idx, 1} = 'Average 2D position error of all epochs [cm]';
    STATS{idx, i+1} = round(average_2D, 2);
    idx = idx + 1;
end


if mean___3D_error_all_epochs       % average 3D error of all epochs
    fprintf('Average 3D position error of all epochs:       ')
    fprintf('% 6.2f', average_3D)
    fprintf(' [cm]\n')
    STATS{idx, 1} = 'Average 3D position error of all epochs [cm]';
    STATS{idx, i+1} = round(average_3D, 2);
    idx = idx + 1;
end


if median_2D_error_all_epochs       % median 2D error of all epochs
    fprintf('Median  2D position error of all epochs:       ')
    fprintf('% 6.2f', median_2D)
    fprintf(' [cm]\n')
    STATS{idx, 1} = 'Median  2D position error of all epochs [cm]';
    STATS{idx, i+1} = round(median_2D, 2);
    idx = idx + 1;
end


if median_3D_error_all_epochs       % median 3D error of all epochs
    fprintf('Median  3D position error of all epochs:       ')
    fprintf('% 6.2f', median_3D)
    fprintf(' [cm]\n')
    STATS{idx, 1} = 'Median  3D position error of all epochs [cm]';
    STATS{idx, i+1} = round(median_3D, 2);
    idx = idx + 1;
end


% -------------------------------------------------------------------------
STATS{idx, 1} = '------';
STATS{idx, i+1} = NaN;
idx = idx + 1;
% -------------------------------------------------------------------------


if mean___2D_error_after            % mean 2D error after n minutes
    fprintf(['Average 2D position error after ' n_str ' minutes: '])
    fprintf('% 6.2f', average_2D_n)
    fprintf(' [cm]\n')
    STATS{idx, 1} = ['Average 2D position error after ' n_str ' minutes [cm]'];
    STATS{idx, i+1} = round(average_2D_n, 2);
    idx = idx + 1;
end


if mean___3D_error_after            % mean 3D error after n minutes
    fprintf(['Average 3D position error after ' n_str ' minutes: '])
    fprintf('% 6.2f', average_3D_n)
    fprintf(' [cm]\n')
    STATS{idx, 1} = ['Average 3D position error after ' n_str ' minutes [cm]'];
    STATS{idx, i+1} =  round(average_3D_n, 2);
    idx = idx + 1;
end


if median_2D_error_after            % median 2D error after n minutes
    fprintf(['Median  2D position error after ' n_str ' minutes: '])
    fprintf('% 6.2f', median_2D_n)
    fprintf(' [cm]\n')
    STATS{idx, 1} = ['Median  2D position error after ' n_str ' minutes [cm]'];
    STATS{idx, i+1} = round(median_2D_n, 2);
    idx = idx + 1;
end


if median_3D_error_after            % median 3D error after n minutes
    fprintf(['Median  3D position error after ' n_str ' minutes: '])
    fprintf('% 6.2f', median_3D_n)
    fprintf(' [cm]\n')
    STATS{idx, 1} = ['Median  3D position error after ' n_str ' minutes [cm]'];
    STATS{idx, i+1} = round(median_3D_n, 2);
    idx = idx + 1;
end


% -------------------------------------------------------------------------
STATS{idx, 1} = '-------';
STATS{idx, i+1} = NaN;
idx = idx + 1;
% -------------------------------------------------------------------------


if std_3D_after_n_minutes           % stdev of 3D error after n minutes
    fprintf(['Std of 3D position errors after ' n_str ' minutes: '])
    fprintf('% 6.2f', stdev_3D_n)
    fprintf(' [cm]\n')
    STATS{idx, 1} = ['Std of 3D position errors after ' n_str ' minutes [cm]'];
    STATS{idx, i+1} =  round(stdev_3D_n, 2);
    idx = idx + 1;
end


if percentage_2D_below_thres        % percentage of epochs below 2D treshold
    fprintf(['Percentage of epochs (2D < ' thresh_2D 'm):            '])
    fprintf('% 6.2f', perc_2D_thresh)
    fprintf(' [%%]\n')
    STATS{idx, 1} = ['Percentage of epochs (2D < ' thresh_2D 'm) [%]'];
    STATS{idx, i+1} = round(perc_2D_thresh, 2);
    idx = idx + 1;
end


if percentage_3D_below_thres        % percentage of epochs below 3D treshold
    fprintf(['Percentage of epochs (3D < ' thresh_3D 'm):            '])
    fprintf('% 6.2f', perc_3D_thresh)
    fprintf(' [%%]\n')
    STATS{idx, 1} = ['Percentage of epochs (3D < ' thresh_3D 'm) [%]'];
    STATS{idx, i+1} =  round(perc_3D_thresh, 2);
    idx = idx + 1;
end


fprintf('\n')








