function varargout = annotation_part(varargin)
% ANNOTATION_PART M-file for annotation_part.fig
%      ANNOTATION_PART, by itself, creates a new ANNOTATION_PART or raises the existing
%      singleton*.
%
%      H = ANNOTATION_PART returns the handle to a new ANNOTATION_PART or the handle to
%      the existing singleton*.
%
%      ANNOTATION_PART('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNOTATION_PART.M with the given input arguments.
%
%      ANNOTATION_PART('Property','Value',...) creates a new ANNOTATION_PART or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before annotation_part_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to annotation_part_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help annotation_part

% Last Modified by GUIDE v2.5 17-Feb-2012 12:54:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @annotation_part_OpeningFcn, ...
                   'gui_OutputFcn',  @annotation_part_OutputFcn, ...
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


% --- Executes just before annotation_part is made visible.
function annotation_part_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to annotation_part (see VARARGIN)

% Choose default command line output for annotation_part
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes annotation_part wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = annotation_part_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined/net/ludington/v/yuxiang/Projects/ObjectInteraction/Annotation_tools in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_dir.
function pushbutton_dir_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
directory_name = uigetdir;
idx = strfind(directory_name, filesep);
cls = directory_name(idx(end)+1:end-3);
switch cls
    case 'car'
        pnames = {'head', 'left', 'right', 'front', 'back', 'tail'};        
    case {'bed', 'bed_uiuc'}
        pnames = {'front', 'left', 'right', 'up', 'back'};
    case 'chair'
        pnames = {'back', 'seat', 'leg1', 'leg2', 'leg3', 'leg4'};        
    case 'sofa'
        pnames = {'front', 'seat', 'back', 'left', 'right'};
    case 'table'
        pnames = {'top', 'leg1', 'leg2', 'leg3', 'leg4'};      
    otherwise
        pnames = {'back', 'seat', 'leg1', 'leg2', 'leg3', 'leg4'};
end

% set radio button names
for i = 1:9
    id = sprintf('radiobutton%d', i);
    if i <= numel(pnames)
        set(handles.(id), 'String', pnames{i});
    else
        set(handles.(id), 'String', '');
    end
end
set(handles.radiobutton_null, 'Value', 1);
set(handles.checkbox1,'Value',0);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);
set(handles.checkbox4,'Value',0);

files = dir(directory_name);
N = numel(files);
i = 390;
flag = 0;
while i <= N && flag == 0
    if files(i).isdir == 0
        filename = files(i).name;
        [pathstr, name, ext] = fileparts(filename);
        if isempty(imformats(ext(2:end))) == 0
            I = imread(fullfile(directory_name, filename));
            set(handles.figure1,'CurrentAxes',handles.axes_image);
            imshow(I);
            set(handles.text_filename, 'String', [filename '(' num2str(size(I,1)) ', ' num2str(size(I,2)) ')']);
            set(handles.pushbutton_next, 'Enable', 'On');
            flag = 1;
            % display original image
            nums = sscanf(name, '%d_%d');
            image_num = nums(1);
            file_image = sprintf('../Images/%s/%04d.jpg', cls, image_num);
            I1 = imread(file_image);
            set(handles.figure1,'CurrentAxes',handles.axes2);
            imshow(I1);
            % load annotation
            bbox_num = nums(2);
            file_anno = sprintf('../Annotations/%s/%04d.mat', cls, image_num);
            image = load(file_anno);
            object = image.object;
            % draw the bounding box
            bbox = object.bbox(bbox_num,:);
            hold on;
            if object.difficult(bbox_num) == 0
                rectangle('Position', bbox, 'EdgeColor', 'g');
            else
                rectangle('Position', bbox, 'EdgeColor', 'r');
            end
            hold off;
            % select part names
            if isfield(object, 'class') == 1
                pnames = get_part_name(object.class{bbox_num});
                % set radio button names
                for j = 1:9
                    id = sprintf('radiobutton%d', j);
                    if j <= numel(pnames)
                        set(handles.(id), 'String', pnames{j});
                    else
                        set(handles.(id), 'String', '');
                    end
                end
            end
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
    handles.partname = pnames{1};
    handles.files = files;
    handles.filepos = i;
    handles.cls = cls;
    handles.pnames = pnames;
    guidata(hObject, handles);
end

function pnames = get_part_name(cls)

switch cls
    case 'chair'
        pnames = {'back', 'seat', 'leg1', 'leg2', 'leg3', 'leg4'};
    case 'car'
        pnames = {'head', 'left', 'right', 'front', 'back', 'tail'};
    case 'bed'
        pnames = {'front', 'left', 'right', 'up', 'back'};        
    case 'sofa'
        pnames = {'front', 'seat', 'back', 'left', 'right'};
    case 'table'
        pnames = {'top', 'leg1', 'leg2', 'leg3', 'leg4'};
    otherwise
        pnames = [];
        return;
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
            set(handles.figure1,'CurrentAxes',handles.axes_image);
            imshow(I);
            set(handles.text_filename, 'String',  [filename '(' num2str(size(I,1)) ', ' num2str(size(I,2)) ')']);
            set(handles.checkbox1,'Value',0);
            set(handles.checkbox2,'Value',0);
            set(handles.checkbox3,'Value',0);
            set(handles.checkbox4,'Value',0);
            set(handles.radiobutton_null, 'Value', 1);
            flag = 1;
            % display original image
            nums = sscanf(name, '%d_%d');
            image_num = nums(1);
            file_image = sprintf('../Images/%s/%04d.jpg', handles.cls, image_num);
            I1 = imread(file_image);
            set(handles.figure1,'CurrentAxes',handles.axes2);
            imshow(I1);
            % load annotation
            bbox_num = nums(2);
            file_anno = sprintf('../Annotations/%s/%04d.mat', handles.cls, image_num);
            image = load(file_anno);
            object = image.object;
            % draw the bounding box
            bbox = object.bbox(bbox_num,:);
            hold on;
            if object.difficult(bbox_num) == 0
                rectangle('Position', bbox, 'EdgeColor', 'g');
            else
                rectangle('Position', bbox, 'EdgeColor', 'r');
            end
            hold off;
            % select part names            
            if isfield(object, 'class') == 1
                pnames = get_part_name(object.class{bbox_num});
                handles.pnames = pnames;
                % set radio button names
                for j = 1:9
                    id = sprintf('radiobutton%d', j);
                    if j <= numel(pnames)
                        set(handles.(id), 'String', pnames{j});
                    else
                        set(handles.(id), 'String', '');
                    end
                end
                set(handles.radiobutton1,'Value',1);
                handles.partname = pnames{1};
            end            
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

% --- Executes on button press in radiobutton1.
function radiobutton1_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton1
handles.partname = handles.pnames{1};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);


% --- Executes on button press in radiobutton2.
function radiobutton2_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton2
handles.partname = handles.pnames{2};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);

% --- Executes on button press in radiobutton3.
function radiobutton3_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton3
handles.partname = handles.pnames{3};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);

% --- Executes on button press in radiobutton4.
function radiobutton4_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton4
handles.partname = handles.pnames{4};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);

% --- Executes on button press in radiobutton5.
function radiobutton5_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton5
handles.partname = handles.pnames{5};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);

% --- Executes on button press in radiobutton6.
function radiobutton6_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton6
handles.partname = handles.pnames{6};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton_label.
function pushbutton_label_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_label (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.figure1,'CurrentAxes',handles.axes_image);
imshow(handles.image);
[x, y] = ginput(1);
hold on;
plot(x, y, 'ro');
hold off;
set(handles.edit1, 'String', num2str(x));
set(handles.edit2, 'String', num2str(y));
handles.x = x;
handles.y = y;
guidata(hObject, handles);

path = sprintf('../Annotations/%s', handles.cls);
nums = sscanf(handles.name, '%d_%d');
image_num = nums(1);
bbox_num = nums(2);
file = sprintf('%s/%04d.mat', path, image_num);
image = load(file);
object = image.object;
object.part{bbox_num}.(handles.partname)(1) = handles.x + object.bbox(bbox_num,1);
object.part{bbox_num}.(handles.partname)(2) = handles.y + object.bbox(bbox_num,2);
save(file, 'object');


% --- Executes on button press in radiobutton7.
function radiobutton7_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton7
handles.partname = handles.pnames{7};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);


% --- Executes on button press in radiobutton8.
function radiobutton8_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton8
handles.partname = handles.pnames{8};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);

% --- Executes on button press in radiobutton9.
function radiobutton9_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton9
handles.partname = handles.pnames{9};
guidata(hObject, handles);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);

% --- Executes on button press in pushbutton_clear.
function pushbutton_clear_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.edit1, 'String', '0');
set(handles.edit2, 'String', '0');
set(handles.checkbox1,'Value',0);
set(handles.checkbox2,'Value',0);
set(handles.checkbox3,'Value',0);
set(handles.checkbox4,'Value',0);

path = sprintf('../Annotations/%s', handles.cls);
nums = sscanf(handles.name, '%d_%d');
image_num = nums(1);
bbox_num = nums(2);
file = sprintf('%s/%04d.mat', path, image_num);
image = load(file);
object = image.object;
object.part{bbox_num}.(handles.partname)(1) = 0;
object.part{bbox_num}.(handles.partname)(2) = 0;
object.occlusion{bbox_num}.(handles.partname) = 0;

save(file, 'object');


% --- Executes on button press in checkbox1.
function checkbox1_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox1
if get(handles.checkbox1,'Value') == 1
    path = sprintf('../Annotations/%s', handles.cls);
    nums = sscanf(handles.name, '%d_%d');
    image_num = nums(1);
    bbox_num = nums(2);
    file = sprintf('%s/%04d.mat', path, image_num);
    image = load(file);
    object = image.object;
    object.difficult(bbox_num) = 1;
    save(file, 'object');
end


% --- Executes on button press in checkbox2.
function checkbox2_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox2
if get(handles.checkbox2,'Value') == 1
    path = sprintf('../Annotations/%s', handles.cls);
    nums = sscanf(handles.name, '%d_%d');
    image_num = nums(1);
    bbox_num = nums(2);
    file = sprintf('%s/%04d.mat', path, image_num);
    image = load(file);
    object = image.object;
    object.occlusion{bbox_num}.(handles.partname) = 1;
    save(file, 'object');
end


% --- Executes on button press in checkbox3.
function checkbox3_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox3
if get(handles.checkbox3,'Value') == 1
    path = sprintf('../Annotations/%s', handles.cls);
    nums = sscanf(handles.name, '%d_%d');
    image_num = nums(1);
    bbox_num = nums(2);
    file = sprintf('%s/%04d.mat', path, image_num);
    image = load(file);
    object = image.object;
    object.occlusion{bbox_num}.(handles.partname) = 2;
    save(file, 'object');
end


% --- Executes on button press in checkbox4.
function checkbox4_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox4
if get(handles.checkbox4,'Value') == 1
    path = sprintf('../Annotations/%s', handles.cls);
    nums = sscanf(handles.name, '%d_%d');
    image_num = nums(1);
    bbox_num = nums(2);
    file = sprintf('%s/%04d.mat', path, image_num);
    image = load(file);
    object = image.object;
    object.truncate(bbox_num) = 1;
    save(file, 'object');
end


% --- Executes on button press in radiobutton_bed.
function radiobutton_bed_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_bed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_bed

path = sprintf('../Annotations/%s', handles.cls);
nums = sscanf(handles.name, '%d_%d');
image_num = nums(1);
bbox_num = nums(2);
file = sprintf('%s/%04d.mat', path, image_num);
image = load(file);
object = image.object;
object.class{bbox_num} =  'bed';
save(file, 'object');

% --- Executes on button press in radiobutton_chair.
function radiobutton_chair_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_chair (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_chair
path = sprintf('../Annotations/%s', handles.cls);
nums = sscanf(handles.name, '%d_%d');
image_num = nums(1);
bbox_num = nums(2);
file = sprintf('%s/%04d.mat', path, image_num);
image = load(file);
object = image.object;
object.class{bbox_num} =  'chair';
save(file, 'object');

% --- Executes on button press in radiobutton_sofa.
function radiobutton_sofa_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_sofa (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_sofa
path = sprintf('../Annotations/%s', handles.cls);
nums = sscanf(handles.name, '%d_%d');
image_num = nums(1);
bbox_num = nums(2);
file = sprintf('%s/%04d.mat', path, image_num);
image = load(file);
object = image.object;
object.class{bbox_num} =  'sofa';
save(file, 'object');

% --- Executes on button press in radiobutton_table.
function radiobutton_table_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_table (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_table
path = sprintf('../Annotations/%s', handles.cls);
nums = sscanf(handles.name, '%d_%d');
image_num = nums(1);
bbox_num = nums(2);
file = sprintf('%s/%04d.mat', path, image_num);
image = load(file);
object = image.object;
object.class{bbox_num} =  'table';
save(file, 'object');


% --- Executes on button press in radiobutton_null.
function radiobutton_null_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_null (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_null
