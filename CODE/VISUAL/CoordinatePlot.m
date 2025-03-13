function varargout = CoordinatePlot(varargin)
%
% This function belongs to raPPPid, Copyright (c) 2023, M.F. Glaner
% *************************************************************************
%
% COORDINATEPLOT M-file for CoordinatePlot.fig
%      COORDINATEPLOT, by itself, creates a new COORDINATEPLOT or raises the existing
%      singleton*.
%
%      H = COORDINATEPLOT returns the handle to a new COORDINATEPLOT or the handle to
%      the existing singleton*.
%
%      COORDINATEPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COORDINATEPLOT.M with the given input arguments.
%
%      COORDINATEPLOT('Property','Value',...) creates a new COORDINATEPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CoordinatePlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CoordinatePlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CoordinatePlot

% Last Modified by GUIDE v2.5 14-Feb-2018 11:32:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CoordinatePlot_OpeningFcn, ...
                   'gui_OutputFcn',  @CoordinatePlot_OutputFcn, ...
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

% --- Executes just before CoordinatePlot is made visible.
function CoordinatePlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CoordinatePlot (see VARARGIN)

% using vline.m or hline.m (c) 2001, Brandon Kuczenski

epochs = varargin{1};       % vector, 1:#epochs
dN = varargin{2};
dE = varargin{3};
dh = varargin{4};
time = varargin{5};         % time [sow]
strXAxis_epochs = varargin{6};
seconds = varargin{7};      % time [s] from beginning of processing
resets = varargin{8};       % time [s] of resets from beginning of processing
station_date = varargin{9};	% string
floatfix = varargin{10};  	% string

% Choose default command line output for CoordinatePlot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% find limits for plot
lim1 = max([ abs(min([dN,dE])); max([dN,dE]) ]);   
lim2 = max([ abs(min(dh));      max(max(dh)) ]);        
default_ylim_hor =  [-lim1,lim1]; 
default_ylim_vert = [-lim2,lim2];  
if isequal(default_ylim_hor, [0,0])   
    default_ylim_hor =  [-1,1];
end                                     
if isequal(default_ylim_vert, [0,0])      
    default_ylim_vert = [-1,1];       
end                                 

% create ticks for time
duration = seconds(end)-seconds(1); 	% processed time-span in [s]
if duration < 300                   % less than 5min processed
    take_time = (mod(seconds,30) == 0);         % all 30sec
elseif duration < 1200              % less than 20min processed
    take_time = (mod(seconds,180) == 0);    	% all 3min
elseif duration < 3600             	% less than 1h processed
    take_time = (mod(seconds,600) == 0);    	% all 10min
elseif duration < 14400             % less than 4h processed
    take_time = (mod(seconds,1800) == 0);       % all 30min
elseif duration < 28800             % less than 8h processed
    take_time = (mod(seconds,3600) == 0);       % all 60min
else                                % more than 8h processed
    take_time = (mod(seconds,7200) == 0);       % all 2h
end
idx = 1:numel(take_time);
idx = idx(take_time);       % get indices to easier remove duplicates
vec_time = time(idx);       % get time in sow
[vec_time, idx_] = unique(vec_time);	% remove potential identical times
idx = idx(idx_);         
ticks_time = sow2hhmm(vec_time); 	% calculate ticks to time
vec_time   = seconds(idx);          % get epoch of tick

% create ticks for epochs
total_eps = numel(dE);              % number of processed epochs
epochs = 1:total_eps;
if total_eps < 150
    take_eps = (mod(epochs,   10) == 0);
elseif total_eps < 250
    take_eps = (mod(epochs,   25) == 0);
elseif total_eps < 300
    take_eps = (mod(epochs,   50) == 0);
elseif total_eps < 1000
    take_eps = (mod(epochs,  100) == 0); 
elseif total_eps < 3000
    take_eps = (mod(epochs,  250) == 0);
elseif total_eps < 10000 
    take_eps = (mod(epochs, 1000) == 0); 
elseif total_eps < 25000
    take_eps = (mod(epochs, 2500) == 0);
else                                % more than 25000 epochs processed
    take_eps = (mod(epochs,10000) == 0);
end
ticks_eps = epochs(take_eps);
vec_eps   = seconds(take_eps);             	% get epoch of tick

% write station and date
set(handles.text7, 'String', [station_date ', ' floatfix]);
% set values into the four edit boxes
set(handles.edit_YlimHz1,'String', '1');
set(handles.edit_YlimHz2,'String',  '-1');
set(handles.edit_YlimV1,'String', '2');
set(handles.edit_YlimV2,'String',  '-2');

none = (dN==0 & dE==0 & dh==0);         % indices of epochs without solution
lgth_sol = length(dN);
seconds = seconds(1:lgth_sol);          % last epochs of processing delivered no solution

% --- Plot dN with time of day on x-axis
axes(handles.axes1);
cla
hold off
plot(seconds,dN,'color','r','linewidth',1);
hold on
plot(seconds(none),dN(none),'.', 'color', 'k');
ylabel('dN [m]')
xlim([seconds(1),seconds(end)]);
ylim(default_ylim_hor);         % set the y-limits to the max-min-values of the data
xticks(vec_time)
xticklabels(cellstr(ticks_time))
Grid_Xoff_Yon();
set(handles.xlabel_top, 'String', ['Time' strXAxis_epochs(4:end)]);
if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets

% --- Plot dE  with number of epoch on x-axis
axes(handles.axes2);
cla
hold off
plot(seconds,dE,'color','b','linewidth',1);
hold on
plot(seconds(none),dE(none),'.', 'color','k');
ylabel('dE [m]')
xlim([seconds(1),seconds(end)]);
ylim(default_ylim_hor);         % set the y-limits to the max-min-values of the data
xticks(vec_eps)
xticklabels(sprintfc('%d', ticks_eps))
Grid_Xoff_Yon();
set(handles.xlabel_middle, 'String', 'Epochs');
if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets

% --- Plot dh with seconds of processing on x-axis---
axes(handles.axes3);
cla
hold off
plot(seconds,dh,'color','g','linewidth',1);
hold on
plot(seconds(none),dh(none),'.', 'color','k');
ylabel('dh [m]')
xlim([seconds(1),seconds(end)]);
ylim(default_ylim_vert);
Grid_Xoff_Yon();
set(handles.xlabel_bottom, 'String', 'Seconds');
if ~isempty(resets); vline(resets, 'k:'); end	% plot vertical lines for resets

linkaxes([handles.axes1,handles.axes2,handles.axes3],'x')

% UIWAIT makes CoordinatePlot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CoordinatePlot_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get y-limits from the four edit boxes
try
    hzlim = [sscanf(get(handles.edit_YlimHz2,'String'), '%f'), ...
        sscanf(get(handles.edit_YlimHz1,'String'), '%f')];
catch
    hzlim = [-1 1];
end
try
    vlim = [ sscanf(get(handles.edit_YlimV2,'String'),  '%f'), ...
        sscanf(get(handles.edit_YlimV1,'String'),  '%f')];
catch
    vlim = [-2 2];
end

% Set y-limits of the three plot-windows
axes(handles.axes1);
ylim(hzlim);
axes(handles.axes2);
ylim(hzlim);
axes(handles.axes3);
ylim(vlim);


function edit_YlimHz1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_YlimHz1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = str2double(get(hObject,'String'));
set(handles.edit_YlimHz2, 'String', num2str(-value));
pushbutton1_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of edit_YlimHz1 as text
%        str2double(get(hObject,'String')) returns contents of edit_YlimHz1 as a double


% --- Executes during object creation, after setting all properties.
function edit_YlimHz1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_YlimHz1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_YlimV1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_YlimV1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
value = str2double(get(hObject,'String'));
set(handles.edit_YlimV2, 'String', num2str(-value));
pushbutton1_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of edit_YlimV1 as text
%        str2double(get(hObject,'String')) returns contents of edit_YlimV1 as a double


% --- Executes during object creation, after setting all properties.
function edit_YlimV1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_YlimV1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_YlimHz2_Callback(hObject, eventdata, handles)
pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_YlimHz2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_YlimHz2 as text
%        str2double(get(hObject,'String')) returns contents of edit_YlimHz2 as a double


% --- Executes during object creation, after setting all properties.
function edit_YlimHz2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_YlimHz2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_YlimV2_Callback(hObject, eventdata, handles)
pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to edit_YlimV2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_YlimV2 as text
%        str2double(get(hObject,'String')) returns contents of edit_YlimV2 as a double


% --- Executes during object creation, after setting all properties.
function edit_YlimV2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_YlimV2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_comm_Callback(hObject, eventdata, handles)
% hObject    handle to edit_comm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_comm as text
%        str2double(get(hObject,'String')) returns contents of edit_comm as a double


% --- Executes during object creation, after setting all properties.
function edit_comm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_comm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
