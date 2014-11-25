% train an aspect layout model for a category
% cls: object category
function model_train(cls)

switch cls   
    case 'car_3D'
        index_train = 1:240;
        cls_data = 'car_3D';
        cls_cad = 'car';
        isnegative = 1;
        object = load('../CAD/car.mat');
    case 'car_3D_final'
        index_train = 1:480;
        cls_data = 'car_3D';
        cls_cad = 'car';
        isnegative = 1;
        object = load('../CAD/car_final.mat');
    case 'car_3D_full'
        index_train = 1:240;
        cls_data = 'car_3D';
        cls_cad = 'car';
        isnegative = 1;
        object = load('../CAD/car_full.mat'); 
    case 'bed_full'
        object = load('data/bed.mat');
        index_train = object.index_train;
        cls_data = 'bed';
        cls_cad = 'bed';
        isnegative = 1;
        object = load('../CAD/bed_full.mat');
    case 'bed'
        object = load('data/bed.mat');
        index_train = object.index_train;
        cls_data = 'bed';
        cls_cad = 'bed';
        isnegative = 1;
        object = load('../CAD/bed.mat');
    case 'bed_final'
%         object = load('data/bed.mat');
%         index_train = object.index_train;
        index_train = 1:400;
        cls_data = 'bed';
        cls_cad = 'bed';
        isnegative = 1;
        object = load('../CAD/bed_final.mat');        
    case 'chair_full'
        object = load('data/chair.mat');
        index_train = object.index_train;
        cls_data = 'chair';
        cls_cad = 'chair';
        isnegative = 1;
        object = load('../CAD/chair_full.mat');
    case 'chair'
        object = load('data/chair.mat');
        index_train = object.index_train;
        cls_data = 'chair';
        cls_cad = 'chair';
        isnegative = 1;
        object = load('../CAD/chair.mat');
    case 'chair_final'
        object = load('data/chair.mat');
        index_train = object.index_train;
        cls_data = 'chair';
        cls_cad = 'chair';
        isnegative = 1;
        object = load('../CAD/chair_final.mat');         
    case 'sofa_full'
        object = load('data/sofa.mat');
        index_train = object.index_train;
        cls_data = 'sofa';        
        cls_cad = 'sofa';
        isnegative = 1;
        object = load('../CAD/sofa_full.mat');
    case 'sofa'
        object = load('data/sofa.mat');
        index_train = object.index_train;
        cls_data = 'sofa';        
        cls_cad = 'sofa';
        isnegative = 1;
        object = load('../CAD/sofa.mat');
    case 'sofa_final'
        object = load('data/sofa.mat');
        index_train = object.index_train;
        cls_data = 'sofa';        
        cls_cad = 'sofa';
        isnegative = 1;
        object = load('../CAD/sofa_final.mat');         
    case 'table_full'
        object = load('data/table.mat');
        index_train = object.index_train;
        cls_data = 'table';
        cls_cad = 'table';
        isnegative = 1;
        object = load('../CAD/table_full.mat');
    case 'table'
        object = load('data/table.mat');
        index_train = object.index_train;
        cls_data = 'table';
        cls_cad = 'table';
        isnegative = 1;
        object = load('../CAD/table.mat');
    case 'table_final'
        object = load('data/table.mat');
        index_train = object.index_train;
        cls_data = 'table';
        cls_cad = 'table';
        isnegative = 1;
        object = load('../CAD/table_final.mat');        
    otherwise
        return;
end

% load cad model
cad = object.(cls_cad);

% write cad model to file
write_cad(cad, cls);

% read positive training images
fprintf('Read positive samples\n');
pos = read_positive(cls_data, index_train, cad(1));

% sample negative training images
if isnegative == 1
    fprintf('Randomize negative PASCAL samples\n');
    maxnum = numel(pos);
    VOC2006 = false;
    neg = rand_negative(cls_cad, maxnum, VOC2006);
else
    neg = [];
end

% write training samples to file
fprintf('Writing data\n');
filename = sprintf('data_new/%s.dat', cls);
write_data(filename, pos, neg);


% randomly select negative training images from pascal data set
function neg = rand_negative(cls, maxnum, VOC2006)

rsize = [400 300];
% sample pascal images from training set
neg_images = [];
num = 0;
pascal_init;
ids = textread(sprintf(VOCopts.imgsetpath, 'trainval'), '%s');
for i = 1:length(ids);
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    clsinds = strmatch(cls, {rec.objects(:).class}, 'exact');
    if isempty(clsinds)
        num = num + 1;
        neg_images{num} = [VOCopts.datadir rec.imgname];
    end
end

% sample patches from the negative training images
numneg = numel(neg_images);
rndneg = max(floor(maxnum/numneg), 1);
count = 0;
for i = 1:numneg
    if count >= maxnum
        break;
    end
    I = imread(neg_images{i});
    if size(I,1) > rsize(2) && size(I,2) > rsize(1)
        for j = 1:rndneg
            count = count + 1;
            x = random('unid', size(I,2)-rsize(1)+1);
            y = random('unid', size(I,1)-rsize(2)+1);
            neg(count).image = I(y:y+rsize(2)-1, x:x+rsize(1)-1,:);
            neg(count).object_label = -1;
            neg(count).part_label = [];
            neg(count).occlusion = [];
            neg(count).cad_label = [];
            neg(count).view_label = [];
            neg(count).bbox = [];
        end
    end
end

% read positive training images
function pos = read_positive(cls, index_train, cad)

N = numel(index_train);
path_image = sprintf('../Images/%s', cls);
path_anno = sprintf('../Annotations/%s', cls);

count = 0;
for i = 1:N
    index = index_train(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, index);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    view = object.view;

    index_diff = find(object.difficult == 0);
    num = numel(index_diff);
       
    file_img = sprintf('%s/%04d.jpg', path_image, index);
    I = imread(file_img);
    
    for j = 1:num
        ind = index_diff(j);
        if num == 1
            origin = [0 0];
        else
            origin = bbox(ind, 1:2);
        end
        count = count + 1;
        pos(count).object_label = 1;
        
        pos(count).cad_label = 1;
        
        aind = find(cad.azimuth == view(ind,1))-1;
        eind = find(cad.elevation == view(ind,2))-1;
        dind = find(cad.distance == view(ind,3))-1;
        view_label = aind*numel(cad.elevation)*numel(cad.distance) + eind*numel(cad.distance) + dind + 1;
        pos(count).view_label = view_label;
        
        % part label
        pos(count).part_label = zeros(numel(cad.pnames),2);
        for k = 1:numel(cad.pnames)
            if isempty(cad.parts2d(view_label).(cad.parts2d_front(k).pname)) == 0
                if isfield(object.part{ind}, cad.parts2d_front(k).pname) == 1 && ...
                        object.part{ind}.(cad.parts2d_front(k).pname)(1) ~= 0
                    pos(count).part_label(k,:) = object.part{ind}.(cad.parts2d_front(k).pname) - origin;
                elseif isfield(object.part{ind}, cad.parts2d_front(k).pname) == 0 && ...
                        cad.roots(k) == 1
                    % compute the part center coordinate of the aspectlet
                    part_index = find(cad.parts2d(view_label).graph(:,k) == 1);
                    part_label = zeros(numel(part_index), 2);
                    for l = 1:numel(part_index)
                        part_label(l,:) = object.part{ind}.(cad.parts2d_front(part_index(l)).pname);
                    end
                    pos(count).part_label(k,:) = compute_center_aspectlet(cad.parts2d(view_label), cad.pnames, part_label, part_index);
                    pos(count).part_label(k,:) = pos(count).part_label(k,:) - origin;
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
        
        pos(count).bbox = [bbox(ind,1)-origin(1)+1 bbox(ind,2)-origin(2)+1 bbox(ind,3) bbox(ind,4)];

        % image
        if num == 1
            pos(count).image = I;
        else
            pos(count).image = crop_bbox(I, bbox(ind,:));
        end
    end
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

function B = crop_bbox(I, bbox)

x1 = max(1, round(bbox(1)));
x2 = min(size(I,2), round(bbox(1)+bbox(3)));
y1 = max(1, round(bbox(2)));
y2 = min(size(I,1), round(bbox(2)+bbox(4)));
B = I(y1:y2, x1:x2, :);