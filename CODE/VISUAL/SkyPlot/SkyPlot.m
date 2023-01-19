function varargout = SkyPlot(varargin)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************
%
% SKYPLOT MATLAB code for SkyPlot.fig
%      SKYPLOT, by itself, creates a new SKYPLOT or raises the existing
%      singleton*.
%
%      H = SKYPLOT returns the handle to a new SKYPLOT or the handle to
%      the existing singleton*.
%
%      SKYPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SKYPLOT.M with the given input arguments.
%
%      SKYPLOT('Property','Value',...) creates a new SKYPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SkyPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SkyPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SkyPlot

% Last Modified by GUIDE v2.5 20-May-2020 11:35:12

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;      % set to zero for multiple windows
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SkyPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @SkyPlot_OutputFcn, ...
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


% --- Executes just before SkyPlot is made visible.
function SkyPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SkyPlot (see VARARGIN)
satellites = varargin{1};
storeData = varargin{2};
vec_epochs   = varargin{3};         % vector of epochs
station_date = varargin{4};         % string, station name and date
isGPS = varargin{5};                % true, if GNSS is plotted
isGLO = varargin{6};
isGAL = varargin{7};
isBDS = varargin{8};
cutoff = varargin{9};               % elevation cutoff from GUI
bool_fixed = varargin{10};          % true, if fixed residuals to use

epoch_last = vec_epochs(end);   % last epoch

% get variables from structs
[time_sow, AZ, EL, SNR, C_res, P_res, I_res, MP_LC] = ...
    GetSkyPlotVariables(satellites, storeData, bool_fixed);
if isempty(P_res); handles.radiobutton_phase_res.Enable = 'off'; end
if isempty(I_res); handles.radiobutton_iono_res.Enable  = 'off'; end
if isempty(MP_LC); handles.radiobutton_mp_lc.Enable     = 'off'; end

% remove GNSS which are not plotted
[AZ, EL, SNR, C_res, P_res, I_res, MP_LC] = ...
    vis_removeGNSS(AZ, EL, SNR, C_res, P_res, I_res, MP_LC, isGPS, isGLO, isGAL, isBDS);

% set reasonable value in last n epochs text-field
n = numel(vec_epochs)/5;        % a fifth of all epochs
set(handles.edit_last_epochs, 'String', num2str(round(n)));

% Set epoch end to the right side of the slider
set(handles.text_epoch_end, 'String', sprintf('%d', epoch_last));

% put name and date into plot
set(handles.text10, 'String', station_date);

% prepare for skyplot
[satx, saty, satz] = vis_prepareSkyPlot3d(AZ, EL);

% save everything which is needed in the future in struct handles
handles.epochs = vec_epochs;
handles.satx = satx;
handles.saty = saty;
handles.satz = satz;
handles.SNR = SNR;
handles.C_res = C_res;
handles.P_res = P_res;
handles.I_res = I_res;
handles.MP_LC = MP_LC;
handles.time_sow = time_sow;
handles.cutoff = cutoff;

% -+-+-+- create skyplot, but do not plot all epochs -+-+-+-
handles.checkbox_all.Value = 0;
checkbox_all_Callback(hObject, eventdata, handles)
handles = CreateSkyplot(handles, 1);

% Choose default command line output for SkyPlot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SkyPlot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SkyPlot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get everything what is needed from struct handles
vec_epochs = handles.epochs;
last_epoch = vec_epochs(end);
time_sow = handles.time_sow;

% get how much epochs before should also be plotted from text-field
n = get(handles.edit_last_epochs, 'String');
n = abs(round(str2double(n)));          % round and abs in case of stupid input
if isnan(n); n = 1; handles.edit_last_epochs.String = '1'; end

slider_pos = handles.slider1.Value;     % get position of slider
idx_ = 1;
if slider_pos ~= 0                      % convert slider-position into epoch
    idx_ = round(slider_pos*last_epoch);    % index of the slider position
end
idx = (idx_-n):idx_;  	% indices of the chosen epochs and the n epochs before
idx = idx(idx>0);       % take only positive epochs

% write epoch in text-field
set(handles.edit_epoch, 'String', sprintf('%d', vec_epochs(idx_)));

% write time of epoch
[~, hour, min, sec] = sow2dhms(time_sow(idx_));
str_time = ['Time: ', sprintf('%02d', hour), ':' ,sprintf('%02d', min), ':' , sprintf('%02d', sec)];
set(handles.text_time, 'String', str_time);

% -+-+-+- create skyplot -+-+-+-
handles = CreateSkyplot(handles, idx);

% Update handles structure
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit_epoch_Callback(hObject, eventdata, handles)
% manual input of epoch
ep = get(handles.edit_epoch, 'String');
ep = str2double(ep);                % get value of entered epoch

if isnan(ep); ep = 1; end

vec_epochs = handles.epochs;        % vector with epochs
no_epochs = numel(vec_epochs);      % number of epochs

if ep > no_epochs           % entered epoch is too big
    ep = no_epochs;
    set(handles.edit_epoch, 'String', num2str(ep))
end
if ep < 1                   % entered epoch is too small
    ep = 1;
    set(handles.edit_epoch, 'String', num2str(ep))
end

slider_pos = ep/no_epochs;          % convert epoch into slider position
handles.slider1.Value = slider_pos; % set slider to position
slider1_Callback(hObject, eventdata, handles)   % refresh plot


% --- Executes during object creation, after setting all properties.
function edit_epoch_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_epoch (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function edit_last_epochs_Callback(hObject, eventdata, handles)
% new value in "plot last n epochs"
slider1_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function edit_last_epochs_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_last_epochs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox_all
function checkbox_all_Callback(hObject, eventdata, handles)
if handles.checkbox_all.Value       % plot all epochs
    % -+-+-+- create skyplot -+-+-+-
    handles = CreateSkyplot(handles, handles.epochs);
    % Disable stuff on GUI
    handles.text5.Enable = 'off';
    handles.text8.Enable = 'off';
    handles.text_epoch_start.Enable = 'off';
    handles.text_epoch_end.Enable = 'off';
    handles.slider1.Enable = 'off';
    handles.text_time.Enable = 'off';
    handles.edit_epoch.Enable = 'off';
    handles.edit_last_epochs.Enable = 'off';
else                                % plot with slider
    % Enable stuff on GUI
    handles.text5.Enable = 'on';
    handles.text8.Enable = 'on';
    handles.text_epoch_start.Enable = 'on';
    handles.text_epoch_end.Enable = 'on';
    handles.slider1.Enable = 'on';
    handles.text_time.Enable = 'on';
    handles.edit_epoch.Enable = 'on';
    handles.edit_last_epochs.Enable = 'on';
    % refresh plot
    slider1_Callback(hObject, eventdata, handles)
end


% --- Executes on button press in checkbox_all
function checkbox_default_Callback(hObject, eventdata, handles)
if handles.checkbox_default.Value           % reset to default values of color-coding
    handles.text_snr_max.Enable = 'Off';
    handles.text_snr_min.Enable = 'Off';
    checkbox_all_Callback(hObject, eventdata, handles)
else                                        % enable entering own values for color-coding
    handles.text_snr_max.Enable = 'On';
    handles.text_snr_min.Enable = 'On';
end


% --- Executes on button press in checkbox_prn
function checkbox_prn_Callback(hObject, eventdata, handles)
checkbox_all_Callback(hObject, eventdata, handles)



% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% open figure and print current skyplot there
fig = figure('Name','Skyplot');
newAxes = copyobj(handles.axes_skyplot, fig);   % copy skyplot to new figure
colormap bone;          % remove colors
title({handles.text10.String,''});
newAxes = copyobj(handles.axes_legend, fig);    % copy legend to new figure
axis equal



function uibuttongroup_colorcoding_SelectionChangeFcn(hObject, eventdata, handles)
% reset color-coding to default
handles.checkbox_default.Value = 1;
handles.text_snr_max.Enable = 'Off';
handles.text_snr_min.Enable = 'Off';
% replot
checkbox_all_Callback(hObject, eventdata, handles)


function text_snr_max_Callback(hObject, eventdata, handles)
checkbox_all_Callback(hObject, eventdata, handles)


% -------------------------- end of main code -----------------------------


% -+-+-+- create skyplot function -+-+-+-
function handles = CreateSkyplot(handles, idx)
satx = handles.satx(idx,:);
saty = handles.saty(idx,:);
satz = handles.satz(idx,:);

% get variable for color-coding depending on choice
string_colorcod = handles.uibuttongroup_colorcoding.SelectedObject.String;
switch string_colorcod
    case 'SNR'
        Value = handles.SNR(idx,:);
        handles.text_unit.String = '[dB-Hz]';
    case 'Code Residuals'
        Value = handles.C_res(idx,:);
        handles.text_unit.String = '[m]';
    case 'Phase Residuals'
        Value = handles.P_res(idx,:);
        handles.text_unit.String = '[mm]';
    case 'Iono Residuals'
        Value = handles.I_res(idx,:);
        handles.text_unit.String = '[cm]';
    case 'Multipath LC'
        Value = handles.MP_LC(idx,:);
        % remove constant part of MP LC before plotting
        Value(isnan(Value)) = 0;        % replace zeros with NaN
        for i = 1:size(Value,2)
            vec = Value(:,i);           % MP LC for current satellite
            if any(~isnan(vec) & vec~=0)
                mask = logical(vec');                       % force row vector
                starts = strfind([false, mask], [0 1]);     % data begins
                stops = strfind([mask, false], [1 0]);      % data ends
                n = numel(starts);
                for ii = 1:n            % loop over data series of current satellite
                    s1 = starts(ii);
                    s2 = stops(ii);
                    if s1 == s2
                        continue        % skip if only one epoch observed
                    end
                    vec(s1:s2) = vec(s1:s2) - mean(vec(s1:s2));     % remove mean
                end
                Value(:,i) = vec;       % save after mean was removed
            end
            
        end
        Value = abs(Value);             % plot absolute values
        handles.text_unit.String = '[cm]';
end

% prepare color-coding of Skyplot
bool_def = handles.checkbox_default.Value;
val_max = str2double(handles.text_snr_max.String);
val_min = str2double(handles.text_snr_min.String);
[val_min, val_max, LUT] = vis_prepareColorCoding(Value, bool_def, val_max, val_min);

% Plot Skyplot for selected epochs
axes(handles.axes_skyplot);
cla reset       % clear last skyplot
bool_txt = handles.checkbox_prn.Value;
vis_skyPlot3d(satx, saty, satz, val_min, val_max, LUT, Value, bool_txt);

% Plot legend
handles = vis_SkyPlotLegend(handles, val_min, val_max, LUT);

