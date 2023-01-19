function varargout = CorrelationPlot(varargin)
%
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************
%
% CORRELATIONPLOT MATLAB code for CorrelationPlot.fig
%      CORRELATIONPLOT, by itself, creates a new CORRELATIONPLOT or raises the existing
%      singleton*.
%
%      H = CORRELATIONPLOT returns the handle to a new CORRELATIONPLOT or the handle to
%      the existing singleton*.
%
%      CORRELATIONPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CORRELATIONPLOT.M with the given input arguments.
%
%      CORRELATIONPLOT('Property','Value',...) creates a new CORRELATIONPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CorrelationPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CorrelationPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CorrelationPlot

% Last Modified by GUIDE v2.5 10-Apr-2019 11:09:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CorrelationPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @CorrelationPlot_OutputFcn, ...
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


% --- Executes just before CorrelationPlot is made visible.
function CorrelationPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CorrelationPlot (see VARARGIN)

storeData = varargin{1};      	% struct
satellites = varargin{2};       % struct
settings = varargin{3};         % struct
vec_epochs = varargin{4};       % vector of epochs

     
epoch_last = vec_epochs(end);   % last epoch
time_sow = storeData.gpstime;      % vector with time of epochs in [sow]

% Plot correlationplot for all epochs
axes(handles.axes_corr);
cla             % clear last plot
plotCovarianceAdjustment(storeData, satellites, settings, 1);

% Set epoch end to the right side of the slider
set(handles.text_epoch_end, 'String', sprintf('%d', epoch_last));

% Choose default command line output for CorrelationPlot
handles.output = hObject;

% save everything which is needed in the future in struct handles
handles.epochs = vec_epochs;
handles.storeData = storeData;
handles.satellites = satellites;
handles.settings = settings;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CorrelationPlot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CorrelationPlot_OutputFcn(hObject, eventdata, handles) 
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
storeData = handles.storeData;
satellites = handles.satellites;
settings = handles.settings;
time_sow = storeData.gpstime;

slider_pos = handles.slider1.Value;     % get position of slider
idx = 1;
if slider_pos ~= 0              % convert slider-position into epoch
    idx = round(slider_pos*last_epoch);
end

% plot the chosen epochs
axes(handles.axes_corr);
cla             % clear last skyplot
plotCovarianceAdjustment(storeData, satellites, settings, idx);

% write epoch in text-field
set(handles.edit_epoch, 'String', sprintf('%d', vec_epochs(idx)));

% write time of epoch
[~, hour, min, sec] = sow2dhms(time_sow(idx));
str_time = ['Time: ', sprintf('%02d', hour), ':' ,sprintf('%02d', min), ':' , sprintf('%02d', sec)];
set(handles.text_time, 'String', str_time);



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
