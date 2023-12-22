function varargout = TropoPlot(varargin)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************
%
% TROPOPLOT MATLAB code for TropoPlot.fig
%      TROPOPLOT, by itself, creates a new TROPOPLOT or raises the existing
%      singleton*.
%
%      H = TROPOPLOT returns the handle to a new TROPOPLOT or the handle to
%      the existing singleton*.
%
%      TROPOPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TROPOPLOT.M with the given input arguments.
%
%      TROPOPLOT('Property','Value',...) creates a new TROPOPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TropoPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TropoPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TropoPlot

% Last Modified by GUIDE v2.5 30-Jun-2020 14:05:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @TropoPlot_OpeningFcn, ...
    'gui_OutputFcn',  @TropoPlot_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before TropoPlot is made visible.
function TropoPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TropoPlot (see VARARGIN)

% get input
hours = varargin{1};
label_x = varargin{2};
storeData = varargin{3};
reset_h = varargin{4};
startdate = varargin{5};
station = varargin{6};

% save variables for later to handles
handles.h = hours;
handles.reset_h = reset_h;
handles.label_x = label_x;
handles.startdate = startdate;
handles.station = station;
handles.zhd_model = storeData.zhd;      % modeled ZHD
handles.zwd_model = storeData.zwd;      % modeled ZWD
handles.zwd_est   = storeData.param(:,4);    % estimated ZWD
handles.IGS_est   = []; handles.checkbox_IGS_ZTD.Enable = 'off';
handles.leg_txt   = [];

% check if IGS troposphere file already exists
stat = lower(handles.station);
% get date of current station
date = handles.startdate;
jd = cal2jd_GT(date(1), date(2), date(3));
% convert (from julian date) into other formats
[doy, yyyy] = jd2doy_GT(jd);
% output date
yyyy    = sprintf('%04d',yyyy);
doy 	= sprintf('%03d',doy);
tropofile = [Path.DATA 'TROPO/' yyyy '/' doy '/' stat doy '0.' yyyy(3:4) 'zpd'];
if exist(tropofile, 'file')
    % read file
    tropodata = readTropoFile(tropofile, handles.station);
    tropodata(:,3) = tropodata(:,3) / 3600;     % convert to [hours]
    % save into handles
    handles.IGS_est = tropodata(:,3:4);
    handles.checkbox_IGS_ZTD.Enable = 'on';
end

% create plot
handles = plotTropoGUI(handles);

% Choose default command line output for TropoPlot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TropoPlot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TropoPlot_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in checkbox_ZTD.
function checkbox_ZTD_Callback(hObject, eventdata, handles)
handles = plotTropoGUI(handles);
guidata(hObject, handles);

% --- Executes on button press in checkbox_ZWD_model.
function checkbox_ZWD_model_Callback(hObject, eventdata, handles)
handles = plotTropoGUI(handles);
guidata(hObject, handles);

% --- Executes on button press in checkbox_ZWD_est.
function checkbox_ZWD_est_Callback(hObject, eventdata, handles)
handles = plotTropoGUI(handles);
guidata(hObject, handles);

% --- Executes on button press in checkbox_ZHD_model.
function checkbox_ZHD_model_Callback(hObject, eventdata, handles)
handles = plotTropoGUI(handles);
guidata(hObject, handles);

% --- Executes on button press in checkbox_IGS_ZTD.
function checkbox_IGS_ZTD_Callback(hObject, eventdata, handles)
handles = plotTropoGUI(handles);
guidata(hObject, handles);

% --- Executes on button press in checkbox_ZTD_model.
function checkbox_ZTD_model_Callback(hObject, eventdata, handles)
handles = plotTropoGUI(handles);
guidata(hObject, handles);

% --- Executes on button press in pushbutton_figure.
function pushbutton_figure_Callback(hObject, eventdata, handles)
% open figure and print current skyplot there
fig = figure('Name','Troposphere Plot');
newAxes = copyobj(handles.axes1, fig);   % copy skyplot to new figure
hLegend = findobj(fig, 'Type', 'Legend');
if ~isempty(handles.leg_txt)        % legend has to be created manually somehow
    legend(handles.leg_txt)
end
% add customized datatip
dcm = datacursormode(fig);
datacursormode on
set(dcm, 'updatefcn', @vis_customdatatip_h)

% --- Executes on button press in pushbutton_download.
function pushbutton_download_Callback(hObject, eventdata, handles)
handles = load_read_IGS_estimation(handles);
guidata(hObject, handles);

% --- Executes on button press in checkbox_resets.
function checkbox_resets_Callback(hObject, eventdata, handles)
handles = plotTropoGUI(handles);
guidata(hObject, handles);


function handles = plotTropoGUI(handles)
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
% *************************************************************************

hours = handles.h;
label_x = handles.label_x;
reset_h = handles.reset_h;

axes(handles.axes1);
cla             % clear last plot
hold on
leg_txt = {};

if ~any([handles.checkbox_ZTD.Value, handles.checkbox_ZHD_model.Value, handles.checkbox_ZWD_model.Value, handles.checkbox_ZWD_est.Value, handles.checkbox_IGS_ZTD.Value, handles.checkbox_ZTD_model.Value])
    return
end

zhd_model = handles.zhd_model;
zwd_model = handles.zwd_model;
ztd_model = zhd_model + zwd_model;
zwd_est = handles.zwd_est;

y_min = []; y_max = [];

% plot total troposphere zenith delay
if handles.checkbox_ZTD.Value
    ztd = zhd_model+zwd_model+zwd_est;
    plot(hours, ztd, '.', 'Color', [.44 1 .44]);
    leg_txt{end+1} = 'ZTD';
    y_min = min([y_min; ztd]);
    y_max = max([y_max; ztd]);
end
% plot modeled ztd
if handles.checkbox_ZTD_model.Value
    plot(hours, ztd_model, '.', 'Color', [.22 .22 .22]);
    leg_txt{end+1} = 'Modeled ZTD';
    y_min = min([y_min; ztd_model]);
    y_max = max([y_max; ztd_model]);
end
% plot modeled zhd
if handles.checkbox_ZHD_model.Value
    plot(hours, zhd_model, '.', 'Color', [.77 .77 .77]);
    leg_txt{end+1} = 'Modeled ZHD';
    y_min = min([y_min; zhd_model]);
    y_max = max([y_max; zhd_model]);
end
% plot modeled zwd
if handles.checkbox_ZWD_model.Value
    plot(hours, zwd_model, '.', 'Color', [.44 .44 .44]);
    leg_txt{end+1} = 'Modeled ZWD';
    y_min = min([y_min; zwd_model]);
    y_max = max([y_max; zwd_model]);
end
% plot estimated residual zwd
if handles.checkbox_ZWD_est.Value
    plot(hours, zwd_est, '.', 'Color', [.18 0 1]);
    % plot black dots where no zwd was estimated
    nonzero = (zwd_est ~= 0);
    plot(hours(~nonzero), zwd_est(~nonzero), 'k.')
    leg_txt{end+1} = 'Estimated ZWD';
    y_min = min([y_min; zwd_est]);
    y_max = max([y_max; zwd_est]);
end
% plot ZTD estimation from IGS
if ~isempty(handles.IGS_est) && handles.checkbox_IGS_ZTD.Value
    IGS_hours = handles.IGS_est(:,1);
    IGS_est = handles.IGS_est(:,2);
    plot(IGS_hours, IGS_est, '--', 'Color', [1 .44 .44], 'LineWidth', 2);
    leg_txt{end+1} = 'ZTD IGS';
    y_min = min([y_min; IGS_est]);
    y_max = max([y_max; IGS_est]);
end

% style
title('Troposphere Plot')
xlabel(label_x)
ylabel('Delay [m]')
grid on;
xlim([hours(1) hours(end)])
Grid_Xoff_Yon()
legend(leg_txt)
dy = 0.05*abs(y_min);
if y_min==0 && dy==0; y_min = -Inf; end
if y_max==0 && dy==0; y_max =  Inf; end    
ylim([y_min-dy, y_max + dy])

% save legend for creating a figure
handles.leg_txt = leg_txt;

% show resets with grid lines
if ~isempty(reset_h) && handles.checkbox_resets.Value
    ax = gca;
    ax.XGrid = 'on';
    set(gca,'xtick', reset_h)
end




function handles = load_read_IGS_estimation(handles)
% Download IGS estimation for current station from ftp-server and read the
% data in
% get date of current station
date = handles.startdate;
date = date(1,:);       % take first row of date for plotting from Multi Plot table
jd = cal2jd_GT(date(1), date(2), date(3));
% convert (from julian date) into other formats
[doy, yyyy] = jd2doy_GT(jd);
% download tropofile
[tropofile, success] = DownloadTropoFile(handles.station, yyyy, doy);
if ~success
    handles.checkbox_IGS_ZTD.Enable = 'off';
    return      % download failed
end
% read file
tropodata = readTropoFile(tropofile, handles.station);
tropodata(:,3) = tropodata(:,3) / 3600;     % convert to [hours]
% save into handles
handles.IGS_est = tropodata(:,3:4);
handles.checkbox_IGS_ZTD.Enable = 'on';


% --- Executes on button press in pushbutton_histo.
function pushbutton_histo_Callback(hObject, eventdata, handles)
if 2 ~= sum([handles.checkbox_ZTD.Value, handles.checkbox_ZHD_model.Value, handles.checkbox_ZWD_model.Value, handles.checkbox_ZWD_est.Value, handles.checkbox_IGS_ZTD.Value, handles.checkbox_ZTD_model.Value])
    fprintf(2,'\nPlease enable exactly two checkboxes!\n');
    return
end
histo_data = [];    i = 1;
if handles.checkbox_ZTD.Value
    histo_data(:,1) = handles.zhd_model+handles.zwd_model+handles.zwd_est;
    i = i + 1;
end
if handles.checkbox_ZTD_model.Value
    histo_data(:,i) = handles.zwd_model + handles.zhd_model;
    i = i + 1;
end
if handles.checkbox_ZHD_model.Value
    histo_data(:,i) = handles.zhd_model;
    i = i + 1;
end
if handles.checkbox_ZWD_model.Value
    histo_data(:,i) = handles.zwd_model;
    i = i + 1;
end
if handles.checkbox_ZWD_est.Value
    histo_data(:,i) = handles.zwd_est;
    i = i + 1;
end
if handles.checkbox_IGS_ZTD.Value
    IGS_est = interp1(handles.IGS_est(:,1), handles.IGS_est(:,2), handles.h);
    histo_data(:,i) = IGS_est;
end

% Plot
diff = histo_data(:,1) - histo_data(:,2);
diff(isnan(diff)) = [];     % remove NaN values
figure('Name','Troposphere Histogram Plot', 'NumberTitle','off');
histogram(diff, 'Normalization', 'probability')

% Style
std_trop = std(diff, 'omitnan');
bias_trop = mean(diff, 'omitnan');
xlabel(sprintf('std-dev = %2.3f, bias = %2.3f, [m]\n', std_trop, bias_trop))
xlim(4*[-std_trop std_trop])
ylabel('[%]')
yticklabels(yticks*100)



