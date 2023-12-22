% Script to plot the modelled error sources from the struct 'model_save '
% which has to be in the workspace. Useful for finding bugs.
% It is possible to plot the modelled values, the difference between two
% consecutive epochs or the difference of the difference between two
% consecutive epochs


% 0 = simple values; 1 = difference between two epochs; 2 = difference of difference between epochs
derivation = 0;



%% ENABLE PLOTS:
modelled_code       =   false; 
modelled_phase      =   false; 
theoretic_range     =   false; 
cutoff_plot         =   false; 
sat_pos             =   false; 
sat_vel             =   false; 
code_IFLC_plot       = 	false; 
phase_IFLC_plot      = 	false; 
satellite_clock     =   false; 
relativistic_clock  =   false; 
signal_runtime      =   false; 
brdc_ephemeris      =   false; 
signal_emission     =   false; 
tropo_plot          =   false; 
ZTD_plot            =   false; 
ZHD_plot            =   false; 
ZWD_plot            =   false; 
iono_plot           =   false; 
wmf_plot            =   false; 
hmf_plot            =   false; 
windup              =   false; 
solid_tides         =   false; 
ocean_loading       =   false;
polar_tides         =   true;
rec_PCOPCV          =   true; 
rec_ARP             =   false; 
sat_PCOPCV          =   false; 
sat_orbs_3d         = 	false;
code_obs_plot       =   false; 
phase_obs_plot      =   false; 


%% PLOTS
% Preparations:
hsv_color = hsv(36);
dur = size(model_save.rho,1);

% modelled code range
if modelled_code
    simplePlot(model_save.code, hsv_color, 'Modelled Code Observation', derivation)
end


% modelled phase range
if modelled_phase
    simplePlot(model_save.phase, hsv_color, 'Modelled Phase Observation', derivation)
end

% theoretic range
if theoretic_range
    simplePlot(model_save.rho, hsv_color, 'Theoretic Range', derivation)
end

% cutoff
%if cutoff_plot
%    figure('Name','Cutoff-Plot for GPS','NumberTitle','off')
%    cutoff_GPS = model_save.cutoff(:,1:32);
%    cutoff_GPS(isnan(cutoff_GPS)) = 0.5;    % not observed
%    imagesc(cutoff_GPS);
%    colormap(gray);     % grey: not observed; white: under cutoff; black: o
%    xlabel('Satellite PRN')
%    ylabel('Epoch-Number')
%    xticks(1:32)
%    title('black: over cutoff; grey: not observed; white: under cutoff')
%     figure('Name','Cutoff-Plot for Galileo','NumberTitle','off')
%     cutoff_GAL = model_save.cutoff(:,201:232);
%     cutoff_GAL(isnan(cutoff_GAL)) = 0.5;    % not observed
%     imagesc(cutoff_GAL);
%     colormap(gray);     % grey: not observed; white: under cutoff; black: o
%     xlabel('Satellite PRN')
%     ylabel('Epoch-Number')
%     xticks(1:32)
%     title('black: over cutoff; grey: not observed; white: under cutoff')
%end

% coordinates satellite position
if sat_pos
    simplePlot(model_save.Rot_X(:,:,1), hsv_color, 'X-Coordinate Satellite Position', derivation)
    simplePlot(model_save.Rot_X(:,:,2), hsv_color, 'Y-Coordinate Satellite Position', derivation)
    simplePlot(model_save.Rot_X(:,:,3), hsv_color, 'Z-Coordinate Satellite Position', derivation)
end

% components of satellite velocity
if sat_pos
    simplePlot(model_save.Rot_V(:,:,1), hsv_color, 'X-Coordinate Satellite Velocity', derivation)
    simplePlot(model_save.Rot_V(:,:,2), hsv_color, 'Y-Coordinate Satellite Velocity', derivation)
    simplePlot(model_save.Rot_V(:,:,3), hsv_color, 'Z-Coordinate Satellite Velocity', derivation)
end


% satellite clock
if satellite_clock
    simplePlot(model_save.dT_sat, hsv_color, 'Modelled Satellite Clock Correction', derivation)
end

% relativistic clock
if relativistic_clock
    simplePlot(model_save.dTrel, hsv_color, 'Modelled Relativistic Correction', derivation)
end


% number of column of broadcast ephemeris
if brdc_ephemeris
    simplePlot(model_save.k, hsv_color, 'Broadcast Ephemeris', derivation)
end

% signal emission time
if signal_emission
    data = full(model_save.Ttr);
    data(data==0) = NaN;
    data = data - (1:dur)';
    simplePlot(data, hsv_color, 'Signal Emission Time', derivation)
end

% troposphere delay
if tropo_plot
    simplePlot(model_save.trop, hsv_color, 'Troposphere Delay', derivation)
end

% troposphere total zenith delay
if ZTD_plot
    simplePlot(model_save.ZTD, hsv_color, 'Troposphere Total Zenith Delay', derivation)
end

% hydrostatic zenith delay
if ZHD_plot
    simplePlot(model_save.zhd, hsv_color, 'Hydrostatic Zenith Delay', derivation)
end

% wet zenith delay
if ZWD_plot
    simplePlot(model_save.zwd, hsv_color, 'Wet Zenith Delay', derivation)
end

% ionospheric range correction
if iono_plot
    simplePlot(model_save.iono, hsv_color, 'Ionospheric Range Correction', derivation)
end

% troposphere wet mapping function
if wmf_plot
    simplePlot(model_save.mfw, hsv_color, 'Wet Troposphere Mapping Function', derivation)
end

% troposphere hydrostatic mapping function
if wmf_plot
    simplePlot(model_save.mfh, hsv_color, 'Hydrostatic Troposphere Mapping Function', derivation)
end

% windup correction
if windup
    simplePlot(model_save.windup, hsv_color, 'WindUp Correction', derivation)
end

% solid tides correction
if solid_tides
    simplePlot(model_save.solid_tides, hsv_color, 'Solid Tides Correction', derivation)
end

% ocean loading correction
if ocean_loading
    simplePlot(model_save.ocean_loading, hsv_color, 'Ocean Loading Correction', derivation)
end

% polar motion correction
if polar_tides
    simplePlot(model_save.polar_tides, hsv_color, 'Polar Motion Correction', derivation)
end

% receiver phase center offset + variation
if rec_PCOPCV
    simplePlot(model_save.PCO_rec, hsv_color, 'Receiver Phase Center Offset', derivation)
    simplePlot(model_save.PCV_rec, hsv_color, 'Receiver Phase Center Variation', derivation)
end

% receiver antenna reference point correction
if rec_ARP
    simplePlot(model_save.ARP_ECEF, hsv_color, 'Receiver Antenna Reference Point Correction', derivation)
end

% satellite phase center offset + variation
if sat_PCOPCV
    simplePlot(model_save.PCO_sat, hsv_color, 'Satellite Phase Center Offset', derivation)
    simplePlot(model_save.PCV_sat, hsv_color, 'Satellite Phase Center Varation', derivation)
end



%% Plot modelled satellite orbits
if sat_orbs_3d
    % plot earth
    figure
    h1 = gca;
    earth_sphere(h1,'m')
    hold on
    
    % plot approximate receiver position
    rec_pos = settings.INPUT.pos_approx;
    scatter3(rec_pos(1), rec_pos(2), rec_pos(3),'MarkerEdgeColor','k', 'MarkerFaceColor','r' )
    view(rec_pos)
    
    % plot gps satellite orbits
    X_sat = model_save.Rot_X(:,:,1);
    Y_sat = model_save.Rot_X(:,:,2);
    Z_sat = model_save.Rot_X(:,:,3);
    colour = [30 144 255]/255;
    for i = 1:size(X_sat,2)
        notnan = ~isnan(X_sat(:,i));
        if any(notnan)
            % plot trajectory
            %         plot3(X_sat(:,i),Y_sat(:,i),Z_sat(:,i), 'Color', [30 144 255]/255, 'LineWidth',2)
            scatter3(X_sat(:,i),Y_sat(:,i),Z_sat(:,i), 'MarkerEdgeColor',colour, 'MarkerFaceColor','none')
            % plot PRN
            idx = find(notnan,1, 'last');
            text(X_sat(idx,i), Y_sat(idx,i), Z_sat(idx,i), [sprintf('%3.0f',i)], 'FontSize',12, 'Color', 'k');
        end
        
    end
    
    % plot axis
    plot3([0 10^7],	[0 0],      [0 0], '-k',    'LineWidth',3)
    plot3([0 0],    [0 10^7],   [0 0], '-k',    'LineWidth',3)
    plot3([0 0],    [0 0],      [0 10^7], '-k', 'LineWidth',3)
    text(10^7, 0, 0, 'X', 'FontSize',16);
    text(0, 10^7, 0, 'Y', 'FontSize',16);
    text(0, 0, 10^7, 'Z', 'FontSize',16);
    
    % other styling
    title('Modelled Satellite Orbits')
    axis off
end

% code observations
if code_obs_plot
    simplePlot(storeData.C1, hsv_color, 'Code Observations on 1st frequency', derivation)
    simplePlot(storeData.C2, hsv_color, 'Code Observations on 2nd frequency', derivation)
    simplePlot(storeData.C3, hsv_color, 'Code Observations on 3rd frequency', derivation)
end

% code observations
if phase_obs_plot
    simplePlot(storeData.L1, hsv_color, 'Phase Observations on 1st frequency', derivation)
    simplePlot(storeData.L2, hsv_color, 'Phase Observations on 2nd frequency', derivation)
    simplePlot(storeData.L3, hsv_color, 'Phase Observations on 3rd frequency', derivation)
end


%% AUXILIARY FUNCTIONS

function [] = simplePlot(data, lescolours, title_string, derivation)
data = zero2nan(data);
if all(data(:) == 0) || all(isnan(data(:)))            
    return                      % nothing to plot
end
n = size(lescolours,1) + 1;     % for colors of satellites
fig = figure('Name',title_string);
prns = [];
hold on
no_col = size(data,2);          % number of columns (sats)
no_epochs = size(data,1);       % number of epochs
for i = 1:no_col
    curr_data = data(:,i);      % data of current satellite
    if any(curr_data~=0)
        curr_data(curr_data == 0) = NaN;
        if i < 100          % style of the plotted GPS line
            l_style = '-';
        else                % style of the plotted Galileo line
            l_style = '--';
        end
        c = mod(i,n); if c==0; c=1; end
        if derivation == 0
            plot( (curr_data), 'color', lescolours(c,:), 'LineStyle', l_style, 'LineWidth',2)
        elseif derivation == 1
            plot( diff(curr_data), 'color', lescolours(c,:), 'LineStyle', l_style, 'LineWidth',2)
        elseif derivation == 2
            plot( diff(diff(curr_data)), 'color', lescolours(c,:), 'LineStyle', l_style, 'LineWidth',2)
        end
        prns(length(prns)+1) = i;
    end
end
gnss = char('G' .* (prns<100)' + 'E' .* (prns>200)');
leg = strcat(gnss, num2str(mod(prns,100)', '%02.0f'));
hleg = legend(leg, 'Location', 'EastOutside');
title(hleg, 'PRN')
grid on
if derivation == 0
    ylabel('value of epoch')
    title_string = [title_string ', 0'];
elseif derivation == 1
    ylabel('Difference between epochs')
    title_string = [title_string ', 1'];
elseif derivation == 2
    ylabel('Difference of Difference between epochs')
    title_string = [title_string ', 2'];
end
title(title_string)
xlabel('Epochs')
xlim([0 no_epochs])

% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_model_save)
end

function output_txt = vis_customdatatip_model_save(obj,event_obj)
% Display the position of the data cursor with relevant information
% INPUT:
%   obj          Currently not used (empty)
%   event_obj    Handle to event object
% OUTPUT:
%   output_txt   Data cursor text string (string or cell array of strings).
% 
% *************************************************************************

if isempty(event_obj.Target.DisplayName)
    output_txt = 'no info';
    return
end


% get position of click (x-value = time [sod], y-value = depends on plot)
pos = get(event_obj,'Position');
sod = pos(1);
value = pos(2);

% calculate epoch from sod (attention: missing epochs are not considered!)
epoch = find(event_obj.Target.XData == sod, 1, 'first');

% calculate time of day from sod
[~, hour, min, sec] = sow2dhms(sod);
% create string with time of day
str_time = [sprintf('%02.0f', hour), ':', sprintf('%02.0f', min), ':', sprintf('%02.0f', sec)];

% create cell with strings as output (which will be shown when clicking)
i = 1;
sat = event_obj.Target.DisplayName;       % name of clicked line e.g. satellite
sat = strrep(sat, 'data', 'PRN: ');
output_txt{i} = sat;
i = i + 1;
output_txt{i} = ['Time: ',  str_time];                  % time of day
i = i + 1;
output_txt{i} = ['Epoch: ', sprintf('%.0f', epoch)];    % epoch
i = i + 1;
output_txt{i} = ['Value: ', sprintf('%.3f', value)];   % value

end