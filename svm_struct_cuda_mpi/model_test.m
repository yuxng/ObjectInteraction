% test an aspect layout model for a category
% cls: object category
function model_test(cls)

switch cls
    case 'car'
        index_test = 241:480;
        cls_cad = 'car';
        cls_data = 'car';
        object = load('../CAD/car_full.mat');
    case 'car_3D'
        index_test = 241:480;
        cls_cad = 'car';
        cls_data = 'car_3D';
        object = load('../CAD/car.mat');
    case 'car_3D_final'
        index_test = 241:480;
        cls_cad = 'car';
        cls_data = 'car_3D';
        object = load('../CAD/car_final.mat');
    case 'car_3D_full'
        index_test = 241:480;
        cls_cad = 'car';
        cls_data = 'car_3D';
        object = load('../CAD/car_full.mat');
    case 'bed'
        object = load('data/bed.mat');
        index_test = object.index_test;
        cls_data = 'bed';
        cls_cad = 'bed';
        object = load('../CAD/bed.mat');
    case 'chair'
        object = load('data/chair.mat');
        index_test = object.index_test;
        cls_data = 'chair';
        cls_cad = 'chair';
        object = load('../CAD/chair.mat');         
    case 'sofa'
        object = load('data/sofa.mat');
        index_test = object.index_test;
        cls_data = 'sofa';        
        cls_cad = 'sofa';
        object = load('../CAD/sofa.mat');
    case 'table'
        object = load('data/table.mat');
        index_test = object.index_test;
        cls_data = 'table';
        cls_cad = 'table';
        object = load('../CAD/table.mat');        
    otherwise
        return;
end

% load cad model
cad = object.(cls_cad);

% read positive test images
fprintf('Read positive samples\n');
pos = read_test_positive(cls_data, index_test, cad(1));

neg = [];

% write training samples to file
fprintf('Writing data\n');
filename = sprintf('data/%s.tst', cls);
write_test_data(filename, pos, neg);

% read test images
function pos = read_test_positive(cls, index_test, cad)

N = numel(index_test);
path_image = sprintf('../Images/%s', cls);
path_anno = sprintf('../Annotations/%s', cls);

count = 0;
for i = 1:N
    index = index_test(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, index);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    view = object.view;
    
    index_diff = find(object.difficult == 0);
    ind = index_diff(1);
    
    file_img = sprintf('%s/%04d.jpg', path_image, index);
    I = imread(file_img);
    
    count = count + 1;
    pos(count).image = I;
    pos(count).object_label = 1;
    pos(count).cad_label = 1;
    
    aind = find(cad.azimuth == view(ind,1))-1;
    eind = find(cad.elevation == view(ind,2))-1;
    dind = find(cad.distance == view(ind,3))-1;
    view_label = aind*numel(cad.elevation)*numel(cad.distance) + ...
        eind*numel(cad.distance) + dind + 1;
    pos(count).view_label = view_label;
    
    % part label
    pos(count).part_label = zeros(numel(cad.pnames),2);
    for k = 1:numel(cad.pnames)
        if isempty(cad.parts2d(view_label).(cad.parts2d_front(k).pname)) == 0
            if isfield(object.part{ind}, cad.parts2d_front(k).pname) == 1 && ...
                    object.part{ind}.(cad.parts2d_front(k).pname)(1) ~= 0
                pos(count).part_label(k,:) = object.part{ind}.(cad.parts2d_front(k).pname);
            elseif isfield(object.part{ind}, cad.parts2d_front(k).pname) == 0 && ...
                    cad.roots(k) == 1
                % compute the part center coordinate of the aspectlet
                part_index = find(cad.parts2d(view_label).graph(:,k) == 1);
                part_label = zeros(numel(part_index), 2);
                for l = 1:numel(part_index)
                    part_label(l,:) = object.part{ind}.(cad.parts2d_front(part_index(l)).pname);
                end
                pos(count).part_label(k,:) = compute_center_aspectlet(cad.parts2d(view_label), cad.pnames, part_label, part_index);
                pos(count).part_label(k,:) = pos(count).part_label(k,:);
            else
                fprintf('error!\n');
            end
        else
            pos(count).part_label(k,:) = [0 0];
        end
    end

    % occlusion flag
    pos(count).occlusion = zeros(numel(cad.pnames),1);
    for k = 1:numel(cad.pnames)
        if isfield(object.occlusion{ind}, cad.parts2d_front(k).pname) == 1
            pos(count).occlusion(k) = object.occlusion{ind}.(cad.parts2d_front(k).pname);
        else
            pos(count).occlusion(k) = 0;
        end
    end     
    
    pos(count).bbox = bbox(ind,:);
end

% compute the bounding box center of aspectlet
function center = compute_center_aspectlet(part2d, pnames, part_label, index)

x1 = inf;
x2 = -inf;
y1 = inf;
y2 = -inf;
for k = 1:size(part_label, 1)
    if part_label(k,1) ~= 0
        part = part2d.(pnames{index(k)}) + repmat(part_label(k,:), 5, 1);
        x1 = min(x1, min(part(:,1)));
        x2 = max(x2, max(part(:,1)));
        y1 = min(y1, min(part(:,2)));
        y2 = max(y2, max(part(:,2)));
    end
end

center = [(x1+x2)/2 (y1+y2)/2];

function write_test_data(filename, pos, neg)

fid = fopen(filename, 'w');

% write sample number
np = numel(pos);
nn = numel(neg);
n = np + nn;
fprintf(fid, '%d\n', n);

% write samples
for i = 1:n
    if i <= np
        s = pos(i);
    else
        s = neg(i-np);
    end
    % write object label
    fprintf(fid, '%d ', s.object_label);
    if s.object_label == 1
        % write cad label
        fprintf(fid, '%d ', s.cad_label-1);
        % write view label
        fprintf(fid, '%d ', s.view_label-1);        
        % write part label
        num = numel(s.part_label);
        P = reshape(s.part_label, num, 1);
        fprintf(fid, '%f ', P);
        % write occlusion label
        fprintf(fid, '%d ', s.occlusion);
        % write bounding box
        bbox = [s.bbox(1) s.bbox(2) s.bbox(1)+s.bbox(3) s.bbox(2)+s.bbox(4)];
        fprintf(fid, '%f ', bbox);        
    end
    % write image size
    dim = size(s.image);
    fprintf(fid, '%d ', numel(dim));
    fprintf(fid, '%d ', dim);
    % write image pixel
    num = numel(s.image);
    I = reshape(s.image, num, 1);
    fprintf(fid, '%u ', I);
    fprintf(fid, '\n');
end

fclose(fid);