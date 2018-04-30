function varargout = setSize(varargin)
% SETSIZE MATLAB code for setSize.fig
%      SETSIZE, by itself, creates a new SETSIZE or raises the existing
%      singleton*.
%
%      H = SETSIZE returns the handle to a new SETSIZE or the handle to
%      the existing singleton*.
%
%      SETSIZE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETSIZE.M with the given input arguments.
%
%      SETSIZE('Property','Value',...) creates a new SETSIZE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before setSize_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to setSize_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help setSize

% Last Modified by GUIDE v2.5 30-Apr-2018 21:19:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @setSize_OpeningFcn, ...
                   'gui_OutputFcn',  @setSize_OutputFcn, ...
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


% --- Executes just before setSize is made visible.
function setSize_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to setSize (see VARARGIN)

% Choose default command line output for setSize
handles.output = 1.;

imshow(varargin{1});
h = imdistline;
api = iptgetapi(h);
api.setLabelVisible(false);

handles.distline = h;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes setSize wait for user response (see UIRESUME)
uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = setSize_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

pixels = str2num(handles.pixelDist.String);
dist = str2num(handles.sizeEdit.String);

varargout{1} = pixels/dist;
delete(handles.figure1);

% --- Executes on button press in okBtn.
function okBtn_Callback(hObject, eventdata, handles)
% hObject    handle to okBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close();




function sizeEdit_Callback(hObject, eventdata, handles)
% hObject    handle to sizeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sizeEdit as text
%        str2double(get(hObject,'String')) returns contents of sizeEdit as a double


% --- Executes during object creation, after setting all properties.
function sizeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sizeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pixelDist_Callback(hObject, eventdata, handles)
% hObject    handle to pixelDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of pixelDist as text
%        str2double(get(hObject,'String')) returns contents of pixelDist as a double


% --- Executes during object creation, after setting all properties.
function pixelDist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pixelDist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in getDistBtn.
function getDistBtn_Callback(hObject, eventdata, handles)
% hObject    handle to getDistBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
hline = handles.distline;

api = iptgetapi(hline);
dist = api.getDistance();

set(handles.pixelDist, 'string', num2str(dist));

function okBtn_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to getDistBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, call UIRESUME
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end
