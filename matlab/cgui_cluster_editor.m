function varargout = cgui_cluster_editor(varargin)
% CGUI_CLUSTER_EDITOR M-file for cgui_cluster_editor.fig
%      CGUI_CLUSTER_EDITOR, by itself, creates a new CGUI_CLUSTER_EDITOR or raises the existing
%      singleton*.
%
%      H = CGUI_CLUSTER_EDITOR returns the handle to a new CGUI_CLUSTER_EDITOR or the handle to
%      the existing singleton*.
%
%      CGUI_CLUSTER_EDITOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CGUI_CLUSTER_EDITOR.M with the given input arguments.
%
%      CGUI_CLUSTER_EDITOR('Property','Value',...) creates a new CGUI_CLUSTER_EDITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cgui_cluster_editor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cgui_cluster_editor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cgui_cluster_editor

% Last Modified by GUIDE v2.5 03-Jun-2009 13:32:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @cgui_cluster_editor_OpeningFcn, ...
                   'gui_OutputFcn',  @cgui_cluster_editor_OutputFcn, ...
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


% --- Executes just before cgui_cluster_editor is made visible.
function cgui_cluster_editor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cgui_cluster_editor (see VARARGIN)

% Choose default command line output for cgui_cluster_editor
handles.output = hObject;
handles.hasBeenEdited = false;
handles.MyCluster = [];
global VERSION;
set(handles.text_version,'String',VERSION);
handles.cutoff = 0.25;
% Update handles structure
guidata(hObject, handles);
if ~isempty(varargin),
  try
    load(varargin{2},'-MAT');
    handles.MyCluster = MyCluster;
    guidata(hObject,handles);
    nSigIDs = length(handles.MyCluster.signal_ids);
    patList = {handles.MyCluster.clust.cluster_ids{1}{:}};
    nPat = length(patList);
    set(handles.slider_cutoff,'Value',1/nPat);
    set(handles.popupmenu1,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,1]));
    set(handles.popupmenu2,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,2]));
    set(handles.popupmenu3,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,3]));
    set(handles.popupmenu4,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,4]));
    gui_UpdateGUI(hObject, eventdata, handles);
  catch ERR
    fprintf(2,'ERROR: Failed to open cluster file "%s" for editing\n',varargin{1});
    cws.errTrace(ERR);
  end
end
% UIWAIT makes cgui_cluster_editor wait for user response (see UIRESUME)
% uiwait(handles.editor_main);


% --- Outputs from this function are returned to the command line.
function varargout = cgui_cluster_editor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function menu_File_Callback(hObject, eventdata, handles)
% hObject    handle to menu_File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_Tools_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Tools (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hasBeenEdited = true;
guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_New_Callback(hObject, eventdata, handles)
% hObject    handle to menu_New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_New(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menu_Open_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_Open(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menu_Save_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_Save(hObject, eventdata, handles);


% --------------------------------------------------------------------
function menu_Exit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_Exit(hObject, eventdata, handles);


function cancel = check_Discard_Changes(hObject, eventdata, handles, command)
  cancel = false;
  if handles.hasBeenEdited,
    Answer = questdlg(['Changes have not been saved. ' command ' anyway?'],...
      [command ' without save?'],'Yes','No','Cancel','Cancel');
    switch Answer,
      case {'Yes'}
        cancel = false;
      case {'No'}
        cancel = gui_Save(hObject, eventdata, handles);
      case {'Cancel'}
        cancel = true;
        questdlg([command ' cancelled.'],[command ' cancelled'],'Ok','Ok');
    end
  end
  

function gui_Exit(hObject, eventdata, handles)
  cancel = check_Discard_Changes(hObject, eventdata, handles, 'Exit');
  if cancel,
    return;
  end
  close(handles.editor_main);
  
  
function cancel = gui_Save(hObject, eventdata, handles)
  cancel = false;
  [filename, pathname] = uiputfile( {'*.edsc;*.mat','CANARY Pattern Library Files (*.edsc, *.mat)'; ...
    '*.*', 'All files (*.*)'}, ...
    'Save as');
  if isequal(filename,0) || isequal(pathname,0),
    cancel = true;
    return;
  end
  MyCluster = handles.MyCluster;
  save(fullfile(pathname,filename),'MyCluster','-MAT');
  handles.hasBeenEdited = false;
  guidata(hObject,handles);
  gui_UpdateGUI(hObject, eventdata, handles);

  
function cancel = gui_Open(hObject, eventdata, handles)
  cancel = check_Discard_Changes(hObject, eventdata, handles, 'Load file');
  if cancel, 
    return; 
  end;
  [filename, pathname] = uigetfile( {'*.edsc;*.mat','CANARY Pattern Library Files (*.edsc, *.mat)'; ...
    '*.*', 'All files (*.*)'}, ...
    'Open pattern file');
  if isequal(filename,0) || isequal(pathname,0),
    cancel = true;
    return;
  end
  load(fullfile(pathname,filename),'-MAT');
  handles.hasBeenEdited = false;
  handles.MyCluster = MyCluster;
  guidata(hObject,handles);
  patList = {handles.MyCluster.clust.cluster_ids{1}{:}};
  nPat = length(patList);
  set(handles.slider_cutoff,'Value',1/nPat);
  nSigIDs = length(handles.MyCluster.signal_ids);
  set(handles.popupmenu1,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,1]));
  set(handles.popupmenu2,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,2]));
  set(handles.popupmenu3,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,3]));
  set(handles.popupmenu4,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,4]));
  gui_UpdateGUI(hObject, eventdata, handles);
  
  
function cancel = gui_New(hObject, eventdata, handles)
  cancel = check_Discard_Changes(hObject, eventdata, handles, 'Create new library');
  if cancel, 
    return; 
  end;
  handles.MyCluster = cws.ClusterLib();
  [filename, pathname] = uigetfile( {'*.edsd;*.mat','CANARY Data Files (*.edsd, *.mat)'; ...
    '*.*', 'All files (*.*)'}, ...
    'Open data file');
  if isequal(filename,0) || isequal(pathname,0),
    cancel = true;
    return;
  end
  data = load(fullfile(pathname,filename),'-MAT');
  if isfield(data,'CDS'),
    CDS = data.CDS;
  elseif isfield(data,'self'),
    CDS = data.self;
  elseif isfield(data,'V')
    CDS = data.V;
  elseif isfield(data,'SIGNALS')
    CDS = data.SIGNALS;
  else
    error('CANARY:loaddatafile','Unknown data structure in file: %s',filename);
  end

  [s,OK] = listdlg('PromptString','Select a location:',...
    'SelectionMode','single','ListString',{CDS.locations.name});
  if isequal(OK,0)
    cancel = true;
    return;
  end
  LOC = CDS.locations(s).handle;
  handles.MyCluster.clusterize(CDS,LOC,false);
  handles.hasBeenEdited = true;
  guidata(hObject,handles);
  patList = {handles.MyCluster.clust.cluster_ids{1}{:}};
  nPat = length(patList);
  set(handles.slider_cutoff,'Value',1/nPat);
  gui_UpdateGUI(hObject, eventdata, handles);

  
function gui_Print(hObject, eventdata, handles)
  if isa(handles.MyCluster,'cws.ClusterLib'),
    handles.MyCluster.PrintPatternGraphics();
    handles.MyCluster.PrintPatternListFile();
  end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  gui_UpdateGUI(hObject, eventdata, handles);
% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  gui_UpdateGUI(hObject, eventdata, handles);
% Hints: contents = get(hObject,'String') returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  gui_UpdateGUI(hObject, eventdata, handles);
% Hints: contents = get(hObject,'String') returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu4.
function popupmenu4_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  gui_UpdateGUI(hObject, eventdata, handles);
% Hints: contents = get(hObject,'String') returns popupmenu4 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu4


% --- Executes during object creation, after setting all properties.
function popupmenu4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_Save.
function btn_Save_Callback(hObject, eventdata, handles)
% hObject    handle to btn_Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_Save(hObject, eventdata, handles);


% --- Executes on button press in btn_Print.
function btn_Print_Callback(hObject, eventdata, handles)
% hObject    handle to btn_Print (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_Print(hObject, eventdata, handles);


% --- Executes on button press in btn_Open.
function btn_Open_Callback(hObject, eventdata, handles)
% hObject    handle to btn_Open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_Open(hObject, eventdata, handles);


% --- Executes on button press in btn_New.
function btn_New_Callback(hObject, eventdata, handles)
% hObject    handle to btn_New (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_New(hObject, eventdata, handles);


% --- Executes on button press in btn_ChangeView.
function btn_ChangeView_Callback(hObject, eventdata, handles)
% hObject    handle to btn_ChangeView (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of btn_ChangeView
switch get(hObject,'Value')
  case 0
    set(hObject,'String','Viewing Raw Data');
  case 1
    set(hObject,'String','Viewing Regression');
end
guidata(hObject, handles);
gui_UpdateGUI(hObject, eventdata, handles);


% --- Executes on selection change in list_Patterns.
function list_Patterns_Callback(hObject, eventdata, handles)
% hObject    handle to list_Patterns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_UpdateGUI(hObject, eventdata, handles);
% Hints: contents = get(hObject,'String') returns list_Patterns contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_Patterns


% --- Executes during object creation, after setting all properties.
function list_Patterns_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_Patterns (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_PatternID_Callback(hObject, eventdata, handles)
% hObject    handle to edit_PatternID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hasBeenEdited = true;
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of edit_PatternID as text
%        str2double(get(hObject,'String')) returns contents of edit_PatternID as a double


% --- Executes during object creation, after setting all properties.
function edit_PatternID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_PatternID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit_Description_Callback(hObject, eventdata, handles)
% hObject    handle to edit_Description (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hasBeenEdited = true;
guidata(hObject, handles);
% Hints: get(hObject,'String') returns contents of edit_Description as text
%        str2double(get(hObject,'String')) returns contents of edit_Description as a double


% --- Executes during object creation, after setting all properties.
function edit_Description_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Description (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btn_UpdateText.
function btn_UpdateText_Callback(hObject, eventdata, handles)
% hObject    handle to btn_UpdateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_UpdateDescriptions(hObject, eventdata, handles);


function gui_UpdateDescriptions(hObject, eventdata, handles)
  if isempty(handles.MyCluster),
    return;
  end
  patID = get(handles.list_Patterns,'Value');
  patText = get(handles.edit_PatternID,'String');
  patDesc = get(handles.edit_Description,'String');
  handles.MyCluster.clust.cluster_ids{1}{patID} = patText;
  handles.MyCluster.clust.cluster_desc{1}{patID} = patDesc;
  guidata(hObject,handles);
  gui_UpdateGUI(hObject, eventdata, handles);
  
  
function gui_UpdateGUI(hObject, eventdata, handles)
  if isempty(handles.MyCluster),
    return;
  end
  patList = {handles.MyCluster.clust.cluster_ids{1}{:}};
  nPat = length(patList);
  curPatID = get(handles.list_Patterns,'Value');
  if curPatID > nPat,
    set(handles.list_Patterns,'String',patList,'Value',1);
    curPatID = 1;
  else
    set(handles.list_Patterns,'String',patList);
  end
  V = get(handles.slider_cutoff,'Value');
  set(handles.text_graphMemCutoff,'String',num2str(V,'%.2f'));
  handles.cutoff = V;
  set(handles.edit_PatternID,'String',handles.MyCluster.clust.cluster_ids{1}{curPatID});
  set(handles.edit_Description,'String',handles.MyCluster.clust.cluster_desc{1}{curPatID});
  set(handles.text_LocName,'String',handles.MyCluster.loc_name);
  nSigIDs = length(handles.MyCluster.signal_ids);
  nMatchEvents = sum(handles.MyCluster.clust.ind{1}==curPatID);
  nMaxProb = max(handles.MyCluster.clust.probs{1}(handles.MyCluster.clust.ind{1}==curPatID,curPatID));
  nMinProb = min(handles.MyCluster.clust.probs{1}(handles.MyCluster.clust.ind{1}==curPatID,curPatID));
  set(handles.text_nMembers,'String',num2str(nMatchEvents,'%.0d'));
  set(handles.text_pMemMax,'String',[num2str(100*nMaxProb,'%.1f') '%']);
  set(handles.text_pMemMin,'String',[num2str(100*nMinProb,'%.1f') '%']);
  set(handles.popupmenu1,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,get(handles.popupmenu1,'Value')]));
  set(handles.popupmenu2,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,get(handles.popupmenu2,'Value')]));
  set(handles.popupmenu3,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,get(handles.popupmenu3,'Value')]));
  set(handles.popupmenu4,'String',handles.MyCluster.signal_ids,'Value',min([nSigIDs,get(handles.popupmenu4,'Value')]));
  handles.MyCluster.graphClusterData(curPatID,handles.axes1,get(handles.popupmenu1,'Value'),get(handles.btn_ChangeView,'Value'),handles.cutoff);
  handles.MyCluster.graphClusterData(curPatID,handles.axes2,get(handles.popupmenu2,'Value'),get(handles.btn_ChangeView,'Value'),handles.cutoff);  
  handles.MyCluster.graphClusterData(curPatID,handles.axes3,get(handles.popupmenu3,'Value'),get(handles.btn_ChangeView,'Value'),handles.cutoff);  
  handles.MyCluster.graphClusterData(curPatID,handles.axes4,get(handles.popupmenu4,'Value'),get(handles.btn_ChangeView,'Value'),handles.cutoff);  
  guidata(hObject,handles);
  

% --- Executes on button press in btn_Exit.
function btn_Exit_Callback(hObject, eventdata, handles)
% hObject    handle to btn_Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_Exit(hObject, eventdata, handles);


% --- Executes on button press in btn_Modify.
function btn_Modify_Callback(hObject, eventdata, handles)
% hObject    handle to btn_Modify (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function slider_cutoff_Callback(hObject, eventdata, handles)
% hObject    handle to slider_cutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gui_UpdateGUI(hObject, eventdata, handles);
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider_cutoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_cutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


