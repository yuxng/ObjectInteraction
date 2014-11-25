% train an aspect layout model for a category
% cls: object category
function model_train_vote(cls)

switch cls   
    case 'car'
        index_train = 1:96;
        cls_data = 'car_3D';
        isnegative = 1;      
    otherwise
        return;
end

% read positive training images
fprintf('Read positive samples\n');
pos = read_positive(cls_data, index_train);

% sample negative training images
if isnegative == 1
    fprintf('Randomize negative PASCAL samples\n');
    maxnum = numel(pos);
    VOC2006 = false;
    neg = rand_negative(cls, maxnum, VOC2006);
else
    neg = [];
end

% write image
fprintf('Writing images\n');
np = numel(pos);
nn = numel(neg);
n = np + nn;
% write samples
for i = 1:n
    if i <= np
        s = pos(i);
    else
        s = neg(i-np);
    end
    filename = sprintf('../Images/%s_vote/%04d.jpg', cls, i);
    imwrite(s.image, filename);
end


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
        end
    end
end

% read positive training images
function pos = read_positive(cls, index_train)

N = numel(index_train);
path_image = sprintf('../Images/%s', cls);

for i = 1:N
    index = index_train(i);      
    file_img = sprintf('%s/%04d.jpg', path_image, index);
    I = imread(file_img);
    pos(i).image = I;
end