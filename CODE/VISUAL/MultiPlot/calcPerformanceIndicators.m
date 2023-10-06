function [] = calcPerformanceIndicators(d, conv, TTCF, TIME_all, q68, q95, label, PlotStruct)
% This function calculates various performance indicators of a label from
% the multi plot table.
%
% INPUT:
%	d               ...
%   conv            ...
%   TTCF            ...
%   TIME_all        ...
%   q68             ...
%   q95             ...
%   label           ...
%   PlotStruct      ...
% OUTPUT:
%	(to the command window)
%
% Revision:
%   ...
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************


%% Preparation
dN = d.N; dE = d.E; dH = d.H; 
TIME = d.dT;

d2D = sqrt(dN.^2 + dE.^2);          	% 2D position error
d3D = sqrt(dN.^2 + dE.^2 + dH.^2);      % 3D position error

thresh_2D = sprintf('%5.3f', PlotStruct.thresh_2D);

% remove outliers
thresh = 10;                            % [m], seems to be a good value
d2D(d2D > thresh) = NaN;
d3D(d3D > thresh) = NaN;

n = max(TIME_all);                      % last point in time which all convergence periods have [s]
n_min = ceil(n/60);                     % round up [minutes]
n_str = sprintf('%.2f', n_min);         % convert to string

TIME = round(TIME);                     % time after reset [s]
d2D_n = d2D(TIME == n);                 % 2D position error after n 
d3D_n = d3D(TIME == n);                 % 3D position error after n 



%% Calculation
if PlotStruct.float
    % average convergence time
    average_conv = mean(conv, 'omitnan');               % [minutes]
    
    % median convergence time
    median_conv  = median(conv, 'omitnan');             % [minutes]
    
    % percentage of no convergence
    not_conv = sum(isnan(conv) | conv > n_min);
    not_conv = not_conv / numel(conv) * 100;       % [%]
    
elseif PlotStruct.fixed
    % average time to correct fix
    average_ttff = mean(TTCF, 'omitnan');               % [minutes]
    
    % median time to correct fix
    median_ttff  = median(TTCF, 'omitnan');             % [minutes]
    
    % percentage no correct fix after n minutes
    no_fix = sum(isnan(TTCF) | TTCF > n); 
    no_fix = no_fix / numel(TTCF) * 100;        % [%]
end

% median 2D position error for all epochs
median_2D    = median(d2D(:), 'omitnan') * 100;         % [cm]

% median 3D position error for all epochs
median_3D    = median(d3D(:), 'omitnan') * 100;         % [cm]

% median 3D position error after n minutes
median_3D_n  = median(d3D_n(:), 'omitnan') * 100;       % [cm]

% average 3D position error after n minutes
average_3D_n = mean(d3D_n(:), 'omitnan') * 100;         % [cm]

% average 2D position error after n minutes
average_2D_n = mean(d2D_n(:), 'omitnan') * 100;         % [cm]

% median 2D position error after n minutes
median_2D_n = median(d2D_n(:), 'omitnan') * 100;        % [cm]

% median of the ZTD difference
ZTD = abs(d.ZTD(:));
ZTD_50 = median(ZTD, 'omitnan') * 100;        % [cm]

% 68% quantile of the ZTD difference
ZTD_68 = calc_quantile(ZTD, .68) * 100;    % [cm]



%% Output to command window
fprintf([label ' '])
if PlotStruct.float; fprintf('(float)'); elseif PlotStruct.fixed; fprintf('(fixed)'); end
fprintf('\n') 

if PlotStruct.float
    fprintf(['Average convergence time (2D < ' thresh_2D 'm):        '])
    fprintf('%06.3f', average_conv)
    fprintf(' [min]\n')
    
    fprintf(['Median  convergence time (2D < ' thresh_2D 'm):        '])
    fprintf('%06.3f', median_conv)
    fprintf(' [min]\n')    
    
    fprintf('Percentage of no convergence:                  ')
    fprintf('%06.3f', not_conv)
    fprintf(' %s', '[%]')   
    fprintf('\n')
    
    if PlotStruct.tropo
    fprintf('Median of the ZTD difference:                  ')
    fprintf('%06.3f', ZTD_50)
    fprintf(' %s', '[cm]')   
    fprintf('\n')
    
    fprintf('68%% quantile of the ZTD difference:            ')
    fprintf('%06.3f', ZTD_68)
    fprintf(' %s', '[cm]')   
    fprintf('\n')
    end
    
elseif PlotStruct.fixed
    fprintf(['Average time to correct fix (2D < ' thresh_2D 'm):     '])
    fprintf('%06.3f', average_ttff)
    fprintf(' [min]\n')       
    
    fprintf(['Median  time to correct fix (2D < ' thresh_2D 'm):     '])
    fprintf('%06.3f', median_ttff)
    fprintf(' [min]\n')       
    
    fprintf('Percentage of no correct fix:                  ')
    fprintf('%06.3f', no_fix)
    fprintf(' %s', '[%]')   
    fprintf('\n')   
end

fprintf('Median  2D position error of all epochs:       ')
fprintf('%06.3f', median_2D)
fprintf(' [cm]\n')

fprintf('Median  3D position error of all epochs:       ')
fprintf('%06.3f', median_3D)
fprintf(' [cm]\n')

% fprintf(['Median  3D position error after ' n_str ' minutes: '])
% fprintf('%06.3f', median_3D_n)
% fprintf(' [cm]\n')

fprintf(['Average 3D position error after ' n_str ' minutes: '])
fprintf('%06.3f', average_3D_n)
fprintf(' [cm]\n')

% fprintf(['Median  2D position error after ' n_str ' minutes: '])
% fprintf('%06.3f', median_2D_n)
% fprintf(' [cm]\n')

fprintf(['Average 2D position error after ' n_str ' minutes: '])
fprintf('%06.3f', average_2D_n)
fprintf(' [cm]\n')

fprintf('\n')  

