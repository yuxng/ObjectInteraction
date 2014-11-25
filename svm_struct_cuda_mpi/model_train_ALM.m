% train a 3D pictorial structure model for a category
% cls: object category
function model_train_ALM

cls = 'car';
cad_num = 1;
cls_cad = {'car'};
% load cad model
cad = cell(cad_num,1);
for i = 1:cad_num
    object = load(sprintf('../CAD/%s_ALM.mat', cls_cad{i}));
    cad{i} = object.(cls_cad{i});
end
% write cad model to file
write_cad_ALM(cad, cls);

% read positive training images
fprintf('Read positive samples\n');
pos = read_positive('car_3D', cls_cad, 1:240, cad);

% sample negative training images
fprintf('Randomize negative PASCAL samples\n');
maxnum = numel(pos);
VOC2006 = false;
neg = rand_negative('car', maxnum, VOC2006);

% write training samples to file
fprintf('Writing data\n');
filename = sprintf('data/%s_ALM.dat', cls);
write_data_ALM(filename, pos, neg);


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
            neg(count).cad_label = [];
            neg(count).view_label = [];
            neg(count).bbox = [];
        end
    end
end

% read positive training images
function pos = read_positive(cls, cls_cad, index_train, cad)

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
        
        cad_label = find(strcmp(object.class{ind}, cls_cad) == 1);
        pos(count).cad_label = cad_label;
        
        aind = find(cad{cad_label}.azimuth == view(ind,1))-1;
        eind = find(cad{cad_label}.elevation == view(ind,2))-1;
        dind = find(cad{cad_label}.distance == view(ind,3))-1;
        view_label = aind*numel(cad{cad_label}.elevation)*numel(cad{cad_label}.distance) + ...
            eind*numel(cad{cad_label}.distance) + dind + 1;
        pos(count).view_label = view_label;
        
        pos(count).part_label = zeros(numel(cad{cad_label}.pnames),2);
        for k = 1:numel(cad{cad_label}.pnames)
            if object.part{ind}.(cad{cad_label}.parts2d_front(k).pname)(1) ~= 0
                pos(count).part_label(k,:) = object.part{ind}.(cad{cad_label}.parts2d_front(k).pname) - origin;
            else
                pos(count).part_label(k,:) = [0 0];
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

function B = crop_bbox(I, bbox)

x1 = max(1, round(bbox(1)));
x2 = min(size(I,2), round(bbox(1)+bbox(3)));
y1 = max(1, round(bbox(2)));
y2 = min(size(I,1), round(bbox(2)+bbox(4)));
B = I(y1:y2, x1:x2, :);

% write cad model to file

function write_cad_ALM(cads, cls)

filename = sprintf('data/%s_ALM.cad', cls);
fid = fopen(filename, 'w');

% write number of cad models
fprintf(fid, '%d\n', numel(cads));

% write each cad models
for c = 1:numel(cads)
    cad = cads{c};

    % write part number
    part_num = numel(cad.pnames);
    fprintf(fid, '%d\n', part_num);

    % write part names
    for i = 1:part_num
        fprintf(fid, '%s\n', cad.pnames{i});
    end

    % write part 2d front
    for i = 1:part_num
        fprintf(fid, '%d ', cad.parts2d_front(i).width);
        fprintf(fid, '%d ', cad.parts2d_front(i).height);
    end
    fprintf(fid, '\n');

    % write view number
    view_num = numel(cad.parts2d);
    fprintf(fid, '%d\n', view_num);

    % write part 2d
    for i = 1:view_num
        fprintf(fid, '%f ', cad.parts2d(i).azimuth);
        fprintf(fid, '%f ', cad.parts2d(i).elevation);
        fprintf(fid, '%f ', cad.parts2d(i).distance);
        fprintf(fid, '%d ', cad.parts2d(i).viewport);
        centers = reshape(cad.parts2d(i).centers, 2*part_num, 1);
        fprintf(fid, '%f ', centers);
        for j = 1:part_num
            if isempty(cad.parts2d(i).homographies{j}) == 0
                H = reshape(cad.parts2d(i).homographies{j}, 9, 1);
                fprintf(fid, '%.12f ', H);
            end
        end
        for j = 1:part_num
            if isempty(cad.parts2d(i).(cad.pnames{j})) == 0
                P = reshape(cad.parts2d(i).(cad.pnames{j})(1:4,:), 8, 1);
                fprintf(fid, '%f ', P);
            end
        end
        fprintf(fid, '%d ', cad.parts2d(i).graph);
        fprintf(fid, '%d\n', cad.parts2d(i).root-1);
    end
end

fclose(fid);

% write training samples to file

function write_data_ALM(filename, pos, neg)

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