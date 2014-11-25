function varargout = copyimage(varargin)
% COPYIMAGE M-file for copyimage.fig
%      COPYIMAGE, by itself, creates a new COPYIMAGE or raises the existing
%      singleton*.
%
%      H = COPYIMAGE returns the handle to a new COPYIMAGE or the handle to
%      the existing singleton*.
%
%      COPYIMAGE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COPYIMAGE.M with the given input arguments.
%
%      COPYIMAGE('Property','Value',...) creates a new COPYIMAGE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before copyimage_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to copyimage_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help copyimage

% Last Modified by GUIDE v2.5 26-Feb-2011 13:43:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @copyimage_OpeningFcn, ...
                   'gui_OutputFcn',  @copyimage_OutputFcn, ...
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


% --- Executes just before copyimage is made visible.
function copyimage_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to copyimage (see VARARGIN)

% Choose default command line output for copyimage
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes copyimage wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = copyimage_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_source.
function pushbutton_source_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_source (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
directory_name = uigetdir;
set(handles.text_source, 'String', directory_name);
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
            set(handles.pushbutton_copy, 'Enable', 'On');
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
    handles.source_dir = directory_name;
    handles.dest_dir = directory_name;
    handles.files = files;
    handles.filepos = i;
    guidata(hObject, handles);
end


% --- Executes on button press in pushbutton_dest.
function pushbutton_dest_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_dest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
directory_name = uigetdir;
set(handles.text_dest, 'String', directory_name);

handles.dest_dir = directory_name;
guidata(hObject, handles);


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
    handles.filepos = i;
    guidata(hObject, handles);
end


% --- Executes on button press in pushbutton_copy.
function pushbutton_copy_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_copy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dest_path = fullfile(handles.dest_dir, [handles.name '.jpg']);
imwrite(handles.image, dest_path, 'jpg');
pushbutton_next_Callback(hObject, eventdata, handles);
