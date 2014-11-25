function aps = compute_aps_per_image(cls, examples, examples_baseline)

N = numel(examples);
aps = zeros(N, 2);
temp = cell(1,1);

for i = 1:N
    temp{1} = examples{i};
    aps(i,1) = compute_ap(cls, temp, i);
    temp{1} = examples_baseline{i};
    aps(i,2) = compute_ap(cls, temp, i);
end

figure;
bar(1:N, aps); 

% compute recall and precision
function ap = compute_ap(cls, examples, index_test)

switch cls
    case 'car'
        cls_data = 'car';
    case {'bed', 'chair', 'sofa', 'table'}
        cls_data = 'room';
end

for k = 1:numel(examples)
    example = examples{k};
    num = numel(example);
    flag = zeros(num, 1);
    for i = 1:num
        if (isfield(example(i), 'class') == 1 && strcmp(cls, example(i).class) == 0)
            flag(i) = 1;
        end
    end
    examples{k} = example(flag == 0);
end

% sort examples
for k = 1:numel(examples)
    example = examples{k};
    num = numel(example);
    
    % sort examples
    p = zeros(num, 1);
    for i = 1:num
        p(i) = example(i).energy;
    end
    [~,index] = sort(p, 'descend');
    example = example(index);
    examples{k} = example;
end

% do nms according to bounding box overlap
% for k = 1:numel(examples)
%     example = examples{k};
%     num = numel(example);
%     flag = zeros(num, 1);
%     
%     for i = 1:num
%         flag(i) = 1;
%         for j = 1:i-1
%             o = box_overlap(example(i).bbox, example(j).bbox);
%             if flag(j) > 0 && o >= 0.5
%                 flag(i) = 0;
%             end
%         end
%     end
%     examples{k} = example(flag > 0);
% end

M = numel(index_test);
path_anno = sprintf('../Annotations/%s', cls_data);
path_image = sprintf('../Images/%s', cls_data);

energy = [];
correct = [];
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
    if isfield(object, 'class') == 1
        tmp = strcmp(cls, object.class);
        bbox = bbox(tmp,:);
    end    
    bbox = [bbox(:,1) bbox(:,2) bbox(:,1)+bbox(:,3) bbox(:,2)+bbox(:,4)];
    count(i) = size(bbox, 1);
    det = zeros(count(i), 1);
    
    % read image
    file_image = sprintf('%s/%04d.jpg', path_image, index);
    I = imread(file_image);    

    example = examples{i};
    num(i) = numel(example);
    % for each predicted bounding box
    for j = 1:num(i)
        num_pr = num_pr + 1;
        energy(num_pr) = example(j).energy;
        if isnan(energy(num_pr)) == 1 || isinf(energy(num_pr)) == 1
            fprintf('bad energy, image %d object %d\n', i, j);
        end
        % get predicted bounding box
        bbox_pr = example(j).bbox;
        
        bbox_pr(1) = max(1, bbox_pr(1));
        bbox_pr(2) = max(1, bbox_pr(2));
        bbox_pr(3) = min(bbox_pr(3), size(I,2));
        bbox_pr(4) = min(bbox_pr(4), size(I,1));        
        
        % compute box overlap
        if isempty(bbox) == 0
            o = box_overlap(bbox, bbox_pr);
            [maxo, index] = max(o);
            if maxo >= 0.5 && det(index) == 0
                overlap{num_pr} = index;
                correct(num_pr) = 1;
                det(index) = 1;
            else
                overlap{num_pr} = [];
                correct(num_pr) = 0;        
            end
        else
            overlap{num_pr} = [];
            correct(num_pr) = 0;
        end
    end
end
overlap = overlap';

threshold = unique(sort(energy));
n = numel(threshold);
recall = zeros(n,1);
precision = zeros(n,1);
for i = 1:n
    % compute precision
    num_positive = numel(find(energy >= threshold(i)));
    num_correct = sum(correct(energy >= threshold(i)));
    if num_positive ~= 0
        precision(i) = num_correct / num_positive;
    else
        precision(i) = 0;
    end
    
    % compute recall
    correct_recall = correct;
    correct_recall(energy < threshold(i)) = 0;
    num_correct = 0;
    start = 1;
    for j = 1:M
        for k = 1:count(j)
            for s = start:start+num(j)-1
                if correct_recall(s) == 1 && numel(find(overlap{s} == k)) ~= 0
                    num_correct = num_correct + 1;
                    break;
                end
            end
        end
        start = start + num(j);
    end
    if sum(count) ~= 0
        recall(i) = num_correct / sum(count);
    else
        recall(i) = 0;
    end
end

ap = VOCap(recall(end:-1:1), precision(end:-1:1));