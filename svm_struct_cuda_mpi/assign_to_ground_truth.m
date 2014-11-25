% object is the ground truth annotation
% example is detection results
function object_new = assign_to_ground_truth(I, object, example, cads)

bbox = object.bbox;
bbox = [bbox(:,1) bbox(:,2) bbox(:,1)+bbox(:,3) bbox(:,2)+bbox(:,4)];
count = size(bbox, 1);
det = zeros(count, 1);

% example = select_top_example(5, example, cads);
threshold = -5.2211;
example = trip_example(example, threshold);
num = numel(example);
% for each predicted bounding box
for i = 1:num
    % get predicted bounding box
    bbox_pr = example(i).bbox;
    if isfield(example(i), 'class') == 1
        cls = example(i).class;
    else
        cls = 'car';
    end
    index_cls = find(strcmp(cls, object.class) == 1);
    bbox_gt = bbox(index_cls,:);

    bbox_pr(1) = max(1, bbox_pr(1));
    bbox_pr(2) = max(1, bbox_pr(2));
    bbox_pr(3) = min(bbox_pr(3), size(I,2));
    bbox_pr(4) = min(bbox_pr(4), size(I,1));                   

    if isempty(bbox_gt) == 0
        o = box_overlap(bbox_gt, bbox_pr);
        [maxo, index] = max(o);
        if maxo >= 0.5 && det(index_cls(index)) == 0
            det(index_cls(index)) = i;       
        end
    end
end

% construct the output
object_new = object;
object_new.difficult = object.difficult;
object_new.energy = zeros(count,1);
for i = 1:count
    object_new.occlude(i) = 0;    
    if det(i) == 0
        object_new.difficult(i) = 1;
        continue;
    end
    ind = det(i);
    object_new.energy(i) = example(ind).energy;
    bbox = example(ind).bbox;
    bbox = [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)];
    object_new.bbox(i,:) = bbox;
    
    cad_label = example(ind).cad_label;
    pnames = cads{cad_label}(1).pnames;
    for j = 1:numel(pnames)
        object_new.part{i}.(pnames{j}) = example(ind).part_label(j,:);
    end
    
    view_label = example(ind).view_label;
    object_new.view(i,1) = cads{cad_label}(1).parts2d(view_label).azimuth;
    object_new.view(i,2) = cads{cad_label}(1).parts2d(view_label).elevation;
    object_new.view(i,3) = cads{cad_label}(1).parts2d(view_label).distance;
end

function example_new = select_top_example(K, example, cads)

if numel(cads) == 1
    cls_cad = {'car'};
else
    cls_cad = {'bed', 'chair', 'sofa', 'table'};
end

cad_num = numel(cads);
count = zeros(cad_num, 1);
N = numel(example);
flag = zeros(N, 1);

for i = 1:N
    cad_label = find(strcmp(example(i).class, cls_cad) == 1);
    if count(cad_label) < K
        flag(i) = 1;
        count(cad_label) = count(cad_label) + 1;
    end
end

example_new = example(flag == 1);

function example_new = trip_example(example, threshold)

N = numel(example);
flag = 0;
for i = 1:N
    if example(i).energy > threshold
        flag = 1;
        example_new(i) = example(i);
    else
        break;
    end
end

if flag == 0 
    example_new = [];
end