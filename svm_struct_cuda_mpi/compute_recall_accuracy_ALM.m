% compute recall and viewpoint accuracy
function [recall, accuracy, ap] = compute_recall_accuracy_ALM(cls, vnum)

switch cls
    case 'car'
        cls_data = 'car';
        cls_cad = 'car';
        index_test = 1:150;
        object = load(sprintf('../CAD/%s_full.mat', cls_cad));
    case 'car_ALM'
        cls_data = 'car';
        cls_cad = 'car';
        index_test = 1:200;
        object = load(sprintf('../../Aspect_Layout_Model/CAD/%s.mat', cls_cad));        
    case 'car_3D'
        cls_data = 'car_3D';
        cls_cad = 'car';
        index_test = 241:480;
        object = load(sprintf('../CAD/%s_full.mat', cls_cad));
    case 'bed'
        object = load('data/bed.mat');
        index_test = object.index_test;
        cls_data = 'bed';
        cls_cad = 'bed';
        object = load(sprintf('../CAD/%s_full.mat', cls_cad));
    case 'chair'
        object = load('data/chair.mat');
        index_test = object.index_test;
        cls_data = 'chair';
        cls_cad = 'chair';     
        object = load(sprintf('../CAD/%s_full.mat', cls_cad));
    case 'sofa'
        object = load('data/sofa.mat');
        index_test = object.index_test;
        cls_data = 'sofa';        
        cls_cad = 'sofa';      
        object = load(sprintf('../CAD/%s_full.mat', cls_cad));
    case 'table'
        object = load('data/table.mat');
        index_test = object.index_test;
        cls_data = 'table';
        cls_cad = 'table';         
        object = load(sprintf('../CAD/%s_full.mat', cls_cad));
end

% load cad model
cad = object.(cls_cad);

M = numel(index_test);
path_anno = sprintf('../Annotations/%s', cls_data);
path_image = sprintf('../Images/%s', cls_data);

% open prediction file
pre_file = sprintf('data/%s.pre', cls);
fpr = fopen(pre_file, 'r');

energy = [];
correct = [];
correct_view = [];
overlap = [];
count = zeros(M,1);
num = zeros(M,1);
num_pr = 0;
for i = 1:M
    % read ground truth bounding box
    index = index_test(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, index);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    bbox = [bbox(:,1) bbox(:,2) bbox(:,1)+bbox(:,3) bbox(:,2)+bbox(:,4)];
    count(i) = size(bbox, 1);
    det = zeros(count(i), 1);    
    view_gt = object.view;
    
    if vnum == 24
        a = [0 15 30 45 315 330 345];
        ind = [];
        for j = 1:count(i)
            %disp(view_gt(j,1));
            if isempty(find(a == view_gt(j,1), 1)) == 1
                ind = [ind j];
            end
        end
        bbox(ind,:) = [];
        view_gt(ind,:) = [];
        count(i) = size(bbox,1);
    end
    
    % read image
    file_image = sprintf('%s/%04d.jpg', path_image, index);
    I = imread(file_image);       

    num(i) = fscanf(fpr, '%d', 1);
    % for each predicted bounding box
    for j = 1:num(i)
        num_pr = num_pr + 1;
        example = read_sample(fpr, cad, 0);
        energy(num_pr) = example.energy;
        % get predicted bounding box
        bbox_pr = example.bbox';
        
        bbox_pr(1) = max(1, bbox_pr(1));
        bbox_pr(2) = max(1, bbox_pr(2));
        bbox_pr(3) = min(bbox_pr(3), size(I,2));
        bbox_pr(4) = min(bbox_pr(4), size(I,1));           
        
        % check viewpoint
        view_label = example.view_label + 1;
        azimuth_pr = cad.parts2d(view_label).azimuth;
        ind_pr = find_interval(azimuth_pr, vnum);        
        
        % compute box overlap
        if isempty(bbox) == 0
            o = box_overlap(bbox, bbox_pr);
            [maxo, index] = max(o);
            if maxo >= 0.5 && det(index) == 0
                overlap{num_pr} = index;
                correct(num_pr) = 1;
                det(index) = 1;
                % compute viewpoint correctness
                azimuth_gt = view_gt(index,1);
                ind_gt = find_interval(azimuth_gt, vnum);
                if ind_gt == ind_pr
                    correct_view(num_pr) = 1;
                else
                    correct_view(num_pr) = 0;
                end          
            else
                overlap{num_pr} = [];
                correct(num_pr) = 0;
                correct_view(num_pr) = 0;
            end
        else
            overlap{num_pr} = [];
            correct(num_pr) = 0;
            correct_view(num_pr) = 0;
        end
    end
end
fclose(fpr);
overlap = overlap';

threshold = sort(energy);
n = numel(threshold);
recall = zeros(n,1);
accuracy = zeros(n,1);
for i = 1:n
    % compute recall
    correct_recall = correct;
    correct_recall(energy < threshold(i)) = 0;
    num_correct = 0;
    num_correct_view = 0;
    start = 1;
    for j = 1:M
        for k = 1:count(j)
            % find highest score correct detecion for object k
            for s = start:start+num(j)-1
                if correct_recall(s) == 1 && numel(find(overlap{s} == k)) ~= 0
                    num_correct = num_correct + 1;
                    if correct_view(s) == 1
                        num_correct_view = num_correct_view + 1;
                    end
                    break;
                end
            end
        end
        start = start + num(j);
    end
    recall(i) = num_correct / sum(count);
    accuracy(i) = num_correct_view / num_correct;
end

ap = VOCap(recall(end:-1:1), accuracy(end:-1:1));
disp(ap);
leg{1} = sprintf('ALM (%.4f)', ap);

% draw recall-precision curve
figure(1);
plot(recall, accuracy, 'b', 'LineWidth',3);
xlabel('Recall');
ylabel('Viewpoint Accuracy');
tit = sprintf('Average Accuracy = %.1f', 100*ap);
title(tit);
h = legend(leg, 'Location', 'SouthWest');
set(h,'FontSize',16);

function ind = find_interval(azimuth, num)

if num == 8
    a = 22.5:45:337.5;
elseif num == 24
    a = 7.5:15:352.5;
end

for i = 1:numel(a)
    if azimuth < a(i)
        break;
    end
end
ind = i;
if azimuth > a(end)
    ind = 1;
end