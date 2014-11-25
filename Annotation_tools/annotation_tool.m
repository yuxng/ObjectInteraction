function varargout = annotation_tool(varargin)
% ANNOTATION_TOOL M-file for annotation_tool.fig
%      ANNOTATION_TOOL, by itself, creates a new ANNOTATION_TOOL or raises the existing
%      singleton*.
%
%      H = ANNOTATION_TOOL returns the handle to a new ANNOTATION_TOOL or the handle to
%      the existing singleton*.
%
%      ANNOTATION_TOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNOTATION_TOOL.M with the given input arguments.
%
%      ANNOTATION_TOOL('Property','Value',...) creates a new ANNOTATION_TOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before annotation_tool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to annotation_tool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help annotation_tool

% Last Modified by GUIDE v2.5 27-Feb-2011 23:40:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @annotation_tool_OpeningFcn, ...
                   'gui_OutputFcn',  @annotation_tool_OutputFcn, ...
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


% --- Executes just before annotation_tool is made visible.
function annotation_tool_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to annotation_tool (see VARARGIN)

% Choose default command line output for annotation_tool
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes annotation_tool wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = annotation_tool_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_opendir.
function pushbutton_opendir_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_opendir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

directory_name = uigetdir;
set(handles.text_source, 'String', directory_name);
set(handles.text_dest, 'String', pwd);
files = dir(directory_name);
N = numel(files);
i = 1;
flag = 0;
while i <= N && flag == 0
    if files(i).isdir == 0
        filename = files(i).name;
        [pathstr, name, ext] = fileparts(filename);
        if isempty(imformats(ext(2:end))) == 0
            I = imread(fullfile(directory_name, filename));
            imshow(I);
            set(handles.text_filename, 'String', [filename '(' num2str(size(I,1)) ', ' num2str(size(I,2)) ')']);
            set(handles.pushbutton_next, 'Enable', 'On');
            flag = 1;
        end
    end
    i = i + 1;
end
if flag == 0
    errordlg('No image file in the fold');
else
    handles.image = I;
    handles.name = name;
    handles.bbox = [];
    handles.source_dir = directory_name;
    handles.dest_dir = '.';
    handles.files = files;
    handles.filepos = i;
    guidata(hObject, handles);
end

% --- Executes on button press in pushbutton_next.
function pushbutton_next_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

directory_name = handles.source_dir;
files = handles.files;
i = handles.filepos;
N = numel(files);
flag = 0;

while i <= N && flag == 0
    if files(i).isdir == 0
        filename = files(i).name;
        [pathstr, name, ext] = fileparts(filename);
        if isempty(imformats(ext(2:end))) == 0
            I = imread(fullfile(directory_name, filename));
            imshow(I);
            set(handles.text_filename, 'String',  [filename '(' num2str(size(I,1)) ', ' num2str(size(I,2)) ')']);
            flag = 1;
        end
    end
    i = i + 1;
end
if flag == 0
    errordlg('No image file left');
else
    handles.image = I;
    handles.name = name;
    handles.bbox = [];
    handles.filepos = i;
    guidata(hObject, handles);
end

% --- Executes on button press in pushbutton_save_annotation.
function pushbutton_save_annotation_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_save_annotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.bbox) == 1
    disp('bounding box is empty.');
    return;
end

matfile = sprintf('%s/%s.mat', handles.dest_dir, handles.name);
if exist(matfile, 'file')
    image = load(matfile);
    object = image.object;
    object.bbox = handles.bbox;
else
    object.image = [handles.name '.jpg'];
    object.bbox = handles.bbox;
end
save(matfile, 'object');


% --- Executes on button press in pushbutton_clear.
function pushbutton_clear_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

imshow(handles.image);
if isempty(handles.bbox) == 0
    handles.bbox(end,:) = [];
end
for i = 1:size(handles.bbox,1)
    rectangle('Position', handles.bbox(i,:), 'EdgeColor', 'g');
end
guidata(hObject, handles);


% --- Executes on button press in pushbutton_bb.
function pushbutton_bb_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_bb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

rect = getrect(handles.axes_image);
rectangle('Position', rect, 'EdgeColor', 'g');
handles.bbox = [handles.bbox; rect];
guidata(hObject, handles);


% --- Executes on button press in pushbutton_dst.
function pushbutton_dst_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_dst (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
directory_name = uigetdir;
set(handles.text_dest, 'String', directory_name);

handles.dest_dir = directory_name;
guidata(hObject, handles);
