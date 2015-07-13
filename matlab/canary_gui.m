function varargout = canary_gui(varargin)
  % CANARY_GUI M-file for canary_gui.fig
  %      CANARY_GUI, by itself, creates a new CANARY_GUI or raises the existing
  %      singleton*.
  %
  %      H = CANARY_GUI returns the handle to a new CANARY_GUI or the handle to
  %      the existing singleton*.
  %
  %      CANARY_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
  %      function named CALLBACK in CANARY_GUI.M with the given input arguments.
  %
  %      CANARY_GUI('Property','Value',...) creates a new CANARY_GUI or raises the
  %      existing singleton*.  Starting from the left, property value pairs are
  %      applied to the GUI before canary_gui_OpeningFcn gets called.  An
  %      unrecognized property name or invalid value makes property application
  %      stop.  All inputs are passed to canary_gui_OpeningFcn via varargin.
  %
  %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
  %      instance to run (singleton)".
  %
  % CANARY: Water Quality Event Detection Algorithm Test & Evaluation Tool
  % Copyright 2007-2009 Sandia Corporation.
  % This source code is distributed under the LGPL License.
  % Under the terms of Contract DE-AC04-94AL85000 with Sandia Corporation,
  % the U.S. Government retains certain rights in this software.
  %
  % This library is free software; you can redistribute it and/or modify it
  % under the terms of the GNU Lesser General Public License as published by
  % the Free Software Foundation; either version 2.1 of the License, or (at
  % your option) any later version. This library is distributed in the hope
  % that it will be useful, but WITHOUT ANY WARRANTY; without even the
  % implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  % See the GNU Lesser General Public License for more details.
  %
  % You should have received a copy of the GNU Lesser General Public License
  % along with this library; if not, write to the Free Software Foundation,
  % Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
  %
  % This software was written as part of an Inter-Agency Agreement between
  % Sandia National Laboratories and the US EPA NHSRC.
  
  % Edit the above text to modify the response to help canary_gui
  
  % Last Modified by GUIDE v2.5 16-Feb-2009 12:34:07
  
  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @canary_gui_OpeningFcn, ...
    'gui_OutputFcn',  @canary_gui_OutputFcn, ...
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
  
  
  % --- Executes just before canary_gui is made visible.
function canary_gui_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
  % This function has no output args, see OutputFcn.
  % hObject    handle to figure
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  % varargin   command line arguments to canary_gui (see VARARGIN)
  
  % Choose default command line output for canary_gui
  handles.data = varargin{1};
  
  handles.output = hObject;
  handles.running = 1;
  % t = timerfindall;
  % handles.timer = t(length(t));
  %  if isempty(handles.timer),
  %     error('Timer not found!');
  %  end
  set(handles.statusText, 'String', 'CANARY is running...');
  global VERSION;
  global DEBUG_LEVEL;
  set(handles.version_text,'String',VERSION);
  set(handles.debugTogBtn,'Value',(DEBUG_LEVEL>0));
  % Update handles structure
  guidata(hObject, handles);
  
  if strcmpi(handles.data.MESSENGER.msgr_type,'EDDIES'),
    set(handles.quitBtn,'String','Quit via EDDIES','Enable','off');
    set(handles.pauseBtn,'Enable','off');
    set(handles.resumeBtn,'Enable','off');
  end
  % UIWAIT makes canary_gui wait for user response (see UIRESUME)
  % uiwait(handles.figure1);
  
  
  % --- Outputs from this function are returned to the command line.
function varargout = canary_gui_OutputFcn(hObject, eventdata, handles)
  % varargout  cell array for returning output args (see VARARGOUT);
  % hObject    handle to figure
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Get default command line output from handles structure
  varargout{1} = handles.output;
  
  
  % DEPRECATED
  % --- Executes on button press in pauseBtn.
function pauseBtn_Callback(hObject, eventdata, handles) %#ok<INUSL>
  % hObject    handle to pauseBtn (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  %set(handles.timer_text, 'String', 'CANARY is paused');
  if handles.running ~= 0,
    if ~isempty(timerfind('Name','tsUpdate'))
      stop(timerfind('Name','tsUpdate'));
    end
    if ~isempty(timerfind('Name','tsProcess'))
      stop(timerfind('Name','tsProcess'));
    end
    set(handles.statusText,'String','CANARY has been paused...');
  end
  handles.running = 0;
  guidata(hObject, handles);
  
  
  % DEPRECATED
  % --- Executes on button press in resumeBtn.
function resumeBtn_Callback(hObject, eventdata, handles) %#ok<INUSL>
  % hObject    handle to resumeBtn (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  %set(handles.statusText, 'String', 'CANARY is running');
  if handles.running ~= 1,
    if ~isempty(timerfind('Name','tsUpdate'))
      start(timerfind('Name','tsUpdate'));
    end
    if ~isempty(timerfind('Name','tsProcess'))
      start(timerfind('Name','tsProcess'));
    end
    set(handles.statusText,'String','CANARY is running...');
  end
  handles.running = 1;
  guidata(hObject, handles);
  
  
  % --- Executes on button press in saveBtn.
function saveBtn_Callback(hObject, eventdata, handles) %#ok<INUSL,*DEFNU>
  % hObject    handle to saveBtn (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  % Save Files
  message = cws.Message('to', 'canary', 'from', 'control', 'subj', 'SAVE');
  handles.data.MESSENGER.send(message);
  set(handles.statusText,'String','CANARY is saving data...');
  
  
  % --- Executes on button press in debugTogBtn.
function debugTogBtn_Callback(hObject, eventdata, handles) %#ok<*INUSD>
  % hObject    handle to debugTogBtn (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of debugTogBtn
  global DEBUG_LEVEL;
  DEBUG_LEVEL = get(hObject,'Value');
  
  
  
  % --- Executes on button press in quitBtn.
function quitBtn_Callback(hObject, eventdata, handles)
  % hObject    handle to quitBtn (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  message = cws.Message('to', 'CANARY', 'from', 'CANARY', 'subj', 'SHUTDOWN');
  handles.data.MESSENGER.send(message);
  if handles.running == 1,
    set(handles.statusText,'String','CANARY is exiting...');
  end
  %close(handles.figure1);
  
  
function probText_Callback(hObject, eventdata, handles)
  % hObject    handle to probText (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hints: get(hObject,'String') returns contents of probText as text
  %        str2double(get(hObject,'String')) returns contents of probText as a double
  
  
  % --- Executes during object creation, after setting all properties.
function probText_CreateFcn(hObject, eventdata, handles)
  % hObject    handle to probText (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    empty - handles not created until after all CreateFcns called
  
  % Hint: edit controls usually have a white background on Windows.
  %       See ISPC and COMPUTER.
  if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
  end
  
  
  % --- Executes on button press in cb_isInitialized.
function cb_isInitialized_Callback(hObject, eventdata, handles)
  % hObject    handle to cb_isInitialized (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of cb_isInitialized
  
  
  % --- Executes on button press in cb_isMessaging.
function cb_isMessaging_Callback(hObject, eventdata, handles)
  % hObject    handle to cb_isMessaging (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of cb_isMessaging
  
  
  % --- Executes on button press in cb_isRunning.
function cb_isRunning_Callback(hObject, eventdata, handles)
  % hObject    handle to cb_isRunning (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of cb_isRunning
  
  
