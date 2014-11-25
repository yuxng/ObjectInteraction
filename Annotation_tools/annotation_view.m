function varargout = annotation_view(varargin)
% ANNOTATION_VIEW M-file for annotation_view.fig
%      ANNOTATION_VIEW, by itself, creates a new ANNOTATION_VIEW or raises the existing
%      singleton*.
%
%      H = ANNOTATION_VIEW returns the handle to a new ANNOTATION_VIEW or the handle to
%      the existing singleton*.
%
%      ANNOTATION_VIEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNOTATION_VIEW.M with the given input arguments.
%
%      ANNOTATION_VIEW('Property','Value',...) creates a new ANNOTATION_VIEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before annotation_view_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to annotation_view_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help annotation_view

% Last Modified by GUIDE v2.5 19-Jun-2011 16:57:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @annotation_view_OpeningFcn, ...
                   'gui_OutputFcn',  @annotation_view_OutputFcn, ...
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


% --- Executes just before annotation_view is made visible.
function annotation_view_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to annotation_view (see VARARGIN)

% Choose default command line output for annotation_view
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes annotation_view wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = annotation_view_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in pushbutton_dir.
function pushbutton_dir_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
directory_name = uigetdir;

% display cad model
addpath('../CAD');
idx = strfind(directory_name, filesep);
cls = directory_name(idx(end)+1:end-3);

switch cls
    case 'car'
        M = 48;
        splotx = 6;
        sploty = 8;
        cls_cad = 'car';
    case {'chair'}
        M = 72;
        splotx = 6;
        sploty = 12;
        cls_cad = 'chair';
    case {'bed'}
        M = 39;
        splotx = 3;
        sploty = 13;
        cls_cad = 'bed';
    case {'sofa'}
        M = 39;
        splotx = 3;
        sploty = 13;
        cls_cad = 'sofa';        
    case {'table', 'room'}
        M = 24;
        splotx = 2;
        sploty = 12;
        cls_cad = 'table';
    otherwise
        return;
end

cad = load(sprintf('../CAD/%s_full.mat', cls_cad));
chair = cad.(cls_cad);

parts2d = chair.parts2d;
pnames = chair.pnames;
dis_num = numel(chair.distance);
        
for i = 1:M
    subplot(splotx, sploty, i, 'Parent', handles.uipanel1);
    axis equal;
    axis off;
    hold on;
    index = (i-1)*dis_num + 1;
    for j = 1:numel(chair.parts)
        a = parts2d(index).azimuth;
        e = parts2d(index).elevation;
        d = parts2d(index).distance;
        part = parts2d(index).(pnames{j});
        center = parts2d(index).centers(j,:);
        if isempty(part) == 0
            part = part + repmat(center, size(part,1), 1);
            set(gca,'YDir','reverse');
            if j == 1
                patch(part(:,1), part(:,2), 'b');
            else
                patch(part(:,1), part(:,2), 'r');
            end
            til = sprintf('a:%.1f, e:%.1f, \nd:%.1f', a, e, d);
            title(til);
        end
    end
end

anno_path = sprintf('../Annotations/%s', cls);
files = dir(directory_name);
N = numel(files);
i = 1;
flag = 0;
while i <= N && flag == 0
    if files(i).isdir == 0
        filename = files(i).name;
        [pathstr, name, ext] = fileparts(filename);
        if isempty(imformats(ext(2:end))) == 0
            nums = sscanf(name, '%d_%d');
            image_num = nums(1);
            bbox_num = nums(2);
            file = sprintf('%s/%04d.mat', anno_path, image_num);
            image = load(file);
            object = image.object;
            % skip different category
            if strcmp(object.class{bbox_num}, cls_cad) ~= 1
                i = i+1;
                continue;
            end
            
            I = imread(fullfile(directory_name, filename));
            set(handles.figure1,'CurrentAxes',handles.axes_image);
            imshow(I);
            axis on;
            set(handles.text_filename, 'String', [filename '(' num2str(size(I,1)) ', ' num2str(size(I,2)) ')']);
            set(handles.pushbutton_next, 'Enable', 'On');
            
            % display previous labeled viewpoint
            if object.difficult(bbox_num) == 1
                rectangle('Position', [1 1 size(I,2)-1, size(I,1)-1], 'EdgeColor', 'r');
            end
            if isfield(object, 'view') ~= 0
                azimuth = object.view(bbox_num, 1);
                elevation = object.view(bbox_num, 2);
                distance = object.view(bbox_num, 3);
                handles.azimuth = azimuth;
                handles.elevation = elevation;
                handles.distance = distance;
                set(handles.edit1, 'String', num2str(azimuth));
                set(handles.edit2, 'String', num2str(elevation));
                set(handles.edit3, 'String', num2str(distance));
                
                % show aligned parts
                hold on;
                a = chair.azimuth;
                e = chair.elevation;
                d = chair.distance;
                aind = find(a == handles.azimuth)-1;
                eind = find(e == handles.elevation)-1;
                dind = find(d == handles.distance)-1;
                if isempty(aind) == 0 && isempty(eind) == 0 && isempty(dind) == 0
                    index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
                    part2d = chair.parts2d(index);
                    pnames = chair.pnames;
                    for k = 1:numel(chair.parts)
                        if isfield(object.part{bbox_num}, pnames{k}) == 1 && object.part{bbox_num}.(pnames{k})(1) ~= 0
                            % annotated part center
                            center = [object.part{bbox_num}.(pnames{k})(1)-object.bbox(bbox_num,1), object.part{bbox_num}.(pnames{k})(2)-object.bbox(bbox_num,2)];
                            plot(center(1), center(2), 'ro');
                            if isempty(part2d.(pnames{k})) == 0
                                part = part2d.(pnames{k}) + repmat(center, 5, 1);
                                % rendered part
                                patch('Faces', [1 2 3 4 5], 'Vertices', part, 'FaceColor', 'r', 'FaceAlpha', 0.3);
                            end
                        end
                    end
                end
                hold off;                  
            else
                handles.azimuth = 0;
                handles.elevation = 0;
                handles.distance = 3;
                set(handles.edit1, 'String', '0');
                set(handles.edit2, 'String', '0');
                set(handles.edit3, 'String', '3');
            end
            flag = 1;
        end
    end
    i = i + 1;
end
if flag == 0
    errordlg('No image file in the fold');
else
    handles.cad = chair;
    handles.image = I;
    handles.name = name;
    handles.source_dir = directory_name;
    handles.files = files;
    handles.filepos = i;
    handles.cls = cls;
    handles.cls_cad = cls_cad;
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
anno_path = sprintf('../Annotations/%s', handles.cls);

while i <= N && flag == 0
    if files(i).isdir == 0
        filename = files(i).name;
        [pathstr, name, ext] = fileparts(filename);
        if isempty(imformats(ext(2:end))) == 0
            nums = sscanf(name, '%d_%d');
            image_num = nums(1);
            bbox_num = nums(2);
            file = sprintf('%s/%04d.mat', anno_path, image_num);
            image = load(file);
            object = image.object;
            % skip different category
            if strcmp(object.class{bbox_num}, handles.cls_cad) ~= 1
                i = i+1;
                continue;
            end            
            
            I = imread(fullfile(directory_name, filename));
            set(handles.figure1,'CurrentAxes',handles.axes_image);
            imshow(I);
            axis on;
            set(handles.text_filename, 'String',  [filename '(' num2str(size(I,1)) ', ' num2str(size(I,2)) ')']);
            % display previous labeled viewpoint
            if object.difficult(bbox_num) == 1
                rectangle('Position', [1 1 size(I,2)-1, size(I,1)-1], 'EdgeColor', 'r');
            end            
            if isfield(object, 'view') ~= 0
                azimuth = object.view(bbox_num, 1);
                elevation = object.view(bbox_num, 2);
                distance = object.view(bbox_num, 3);
                handles.azimuth = azimuth;
                handles.elevation = elevation;
                handles.distance = distance;
                set(handles.edit1, 'String', num2str(azimuth));
                set(handles.edit2, 'String', num2str(elevation));
                set(handles.edit3, 'String', num2str(distance));
                
                % show aligned parts
                hold on;
                a = handles.cad.azimuth;
                e = handles.cad.elevation;
                d = handles.cad.distance;
                aind = find(a == handles.azimuth)-1;
                eind = find(e == handles.elevation)-1;
                dind = find(d == handles.distance)-1;
                if isempty(aind) == 0 && isempty(eind) == 0 && isempty(dind) == 0
                    index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
                    part2d = handles.cad.parts2d(index);
                    pnames = handles.cad.pnames;
                    for k = 1:numel(handles.cad.parts)
                        if isfield(object.part{bbox_num}, pnames{k}) == 1 && object.part{bbox_num}.(pnames{k})(1) ~= 0
                            % annotated part center
                            center = [object.part{bbox_num}.(pnames{k})(1)-object.bbox(bbox_num,1), object.part{bbox_num}.(pnames{k})(2)-object.bbox(bbox_num,2)];
                            plot(center(1), center(2), 'ro');
                            if isempty(part2d.(pnames{k})) == 0
                                part = part2d.(pnames{k}) + repmat(center, 5, 1);
                                % rendered part
                                patch('Faces', [1 2 3 4 5], 'Vertices', part, 'FaceColor', 'r', 'FaceAlpha', 0.3);
                            end
                        end
                    end
                end
                hold off;                
            end            
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


function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double

handles.azimuth = str2double(get(handles.edit1,'String'));
guidata(hObject, handles);

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
handles.elevation = str2double(get(handles.edit2,'String'));
guidata(hObject, handles);

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


% --- Executes on button press in pushbutton_save.
function pushbutton_save_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

path = sprintf('../Annotations/%s', handles.cls);
nums = sscanf(handles.name, '%d_%d');
image_num = nums(1);
bbox_num = nums(2);
file = sprintf('%s/%04d.mat', path, image_num);
image = load(file);
object = image.object;

n = size(object.bbox, 1);
if isfield(object, 'view') == 0
    object.view = zeros(n, 3);
end
object.view(bbox_num, 1) = handles.azimuth;
object.view(bbox_num, 2) = handles.elevation;
object.view(bbox_num, 3) = handles.distance;
save(file, 'object');

% show aligned parts
set(handles.figure1,'CurrentAxes',handles.axes_image);
imshow(handles.image);
hold on;
a = handles.cad.azimuth;
e = handles.cad.elevation;
d = handles.cad.distance;
aind = find(a == handles.azimuth)-1;
eind = find(e == handles.elevation)-1;
dind = find(d == handles.distance)-1;
if isempty(aind) == 0 && isempty(eind) == 0 && isempty(dind) == 0
    index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
    part2d = handles.cad.parts2d(index);
    pnames = handles.cad.pnames;
    for k = 1:numel(handles.cad.parts)
        if isfield(object.part{bbox_num}, pnames{k}) == 1 && object.part{bbox_num}.(pnames{k})(1) ~= 0
            % annotated part center
            center = [object.part{bbox_num}.(pnames{k})(1)-object.bbox(bbox_num,1), object.part{bbox_num}.(pnames{k})(2)-object.bbox(bbox_num,2)];
            plot(center(1), center(2), 'ro');
            if isempty(part2d.(pnames{k})) == 0
                part = part2d.(pnames{k}) + repmat(center, 5, 1);
                % rendered part
                patch('Faces', [1 2 3 4 5], 'Vertices', part, 'FaceColor', 'r', 'FaceAlpha', 0.3);
            end
        end
    end
end
hold off;


function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double
handles.distance = str2double(get(handles.edit3,'String'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ind = find_interval(azimuth)

a = 22.5:45:337.5;
for i = 1:numel(a)
    if azimuth < a(i)
        break;
    end
end
ind = i;
if azimuth > a(end)
    ind = 1;
end