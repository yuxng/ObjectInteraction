% compute recall and viewpoint accuracy
function [recall, pcp] = compute_recall_pcp(cls, isfigure)

switch cls
    case 'car_3D'
        cls_data = 'car_3D';
        cls_cad = 'car';
        index_test = 241:480;
        cad_num = 1;      
end

% load cad model
cad = cell(cad_num,1);
for i = 1:cad_num
    if i > 1
        object = load(sprintf('../CAD/%s%d.mat', cls_cad, i));
        cad{i} = object.([cls_cad num2str(i)]);
    else
        object = load(sprintf('../CAD/%s.mat', cls_cad));
        cad{i} = object.(cls_cad);
    end
end

a = cad{1}.azimuth;
e = cad{1}.elevation;
d = cad{1}.distance;
pnames = cad{1}.pnames;

if strcmp(cls, 'bicycle') == 1
    isbicycle = 1;
    pnames = {'left', 'right'};
else
    isbicycle = 0;
end

M = numel(index_test);
path_anno = sprintf('../Annotations/%s', cls_data);

% open prediction file
pre_file = sprintf('data/%s.pre', cls);
fpr = fopen(pre_file, 'r');

energy = [];
correct = [];
correct_part = [];
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
    
    % read ground turth part shape
    view = object.view;
    part = [];
    for j = 1:count(i)
        aind = find(a == view(j,1))-1;
        eind = find(e == view(j,2))-1;
        dind = find(d == view(j,3))-1;
        index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
        part2d = cad{1}.parts2d(index);

        if isbicycle == 1
            root_index = find_interval(view(j, 1), 8);
        end

        for k = 1:numel(cad{1}.parts)
            if isbicycle == 1
                part_name = sprintf('%s%d', pnames{k}, root_index);
            else
                part_name = pnames{k};
            end
            if isfield(part2d, part_name) == 1 && isempty(part2d.(part_name)) == 0 && object.part{j}.(pnames{k})(1) ~= 0
                % annotated part center
                center = [object.part{j}.(pnames{k})(1), object.part{j}.(pnames{k})(2)];
                part(j).(pnames{k}) = part2d.(part_name) + repmat(center, 5, 1);
                if ispolycw(part(j).(pnames{k})(:,1), part(j).(pnames{k})(:,2)) == 0
                    [part(j).(pnames{k})(:,1), part(j).(pnames{k})(:,2)] = poly2cw(part(j).(pnames{k})(:,1), part(j).(pnames{k})(:,2));
                end                    
            else
                part(j).(pnames{k}) = [];
            end
        end
    end  

    num(i) = fscanf(fpr, '%d', 1);
    % for each predicted bounding box
    for j = 1:num(i)
        num_pr = num_pr + 1;
        example = read_sample(fpr, cad, 0);
        energy(num_pr) = example.energy;
        % get predicted bounding box
        bbox_pr = example.bbox';
        if exist('bbox_factor')
            bbox_pr = rescale_bbox(bbox_pr, bbox_factor);
        end
        
        % get predicted part shape
        view_label = example.view_label + 1;
        part2d = cad{1}.parts2d(view_label);
        part_pr = [];
        if isbicycle == 1
            root_index = find_interval(part2d.azimuth, 8);
        end
        for k = 1:numel(cad{1}.parts)
            if isbicycle == 1
                part_name = sprintf('%s%d', pnames{k}, root_index);
                part_index = root_index;
            else
                part_name = pnames{k};
                part_index = k;
            end

            if isfield(part2d, part_name) == 1 && isempty(part2d.(part_name)) == 0 && example.part_label(part_index,1) ~= 0
                % annotated part center
                center = [example.part_label(part_index,1), example.part_label(part_index,2)];
                part_pr.(pnames{k}) = part2d.(part_name) + repmat(center, 5, 1);
                if ispolycw(part_pr.(pnames{k})(:,1), part_pr.(pnames{k})(:,2)) == 0
                    [part_pr.(pnames{k})(:,1), part_pr.(pnames{k})(:,2)] = poly2cw(part_pr.(pnames{k})(:,1), part_pr.(pnames{k})(:,2));
                end
            else
                part_pr.(pnames{k}) = [];
            end
        end      
        
        % compute box overlap
        if isempty(bbox) == 0
            o = box_overlap(bbox, bbox_pr);
            index = find(o >= 0.5);
            overlap{end+1} = index;
            if numel(index) >= 1
                correct(num_pr) = 1;
                % correct part
                for k = 1:numel(cad{1}.parts)
                    correct_part(num_pr).(pnames{k}) = zeros(numel(index),1);
                    for kk = 1:numel(index)
                        max_index = index(kk);
                        if isempty(part(max_index).(pnames{k})) == 0 && isempty(part_pr.(pnames{k})) == 0
                            [intersect.x intersect.y] = polybool('intersection', part(max_index).(pnames{k})(:,1), ...
                                part(max_index).(pnames{k})(:,2), part_pr.(pnames{k})(:,1), part_pr.(pnames{k})(:,2));
                            [union.x union.y] = polybool('union', part(max_index).(pnames{k})(:,1), ...
                                part(max_index).(pnames{k})(:,2), part_pr.(pnames{k})(:,1), part_pr.(pnames{k})(:,2));
                            if((polyarea(intersect.x, intersect.y) / polyarea(union.x, union.y)) >= 0.5)
                                correct_part(num_pr).(pnames{k})(kk) = 1;
                            else
                                correct_part(num_pr).(pnames{k})(kk) = 0;
                            end
                        elseif isempty(part(max_index).(pnames{k})) == 1 && isempty(part_pr.(pnames{k})) == 1
                            correct_part(num_pr).(pnames{k})(kk) = 1;
                        else
                            correct_part(num_pr).(pnames{k})(kk) = 0;
                        end
                    end
                end                
            else
                correct(num_pr) = 0;
                for k = 1:numel(cad{1}.parts)
                    correct_part(num_pr).(pnames{k}) = 0;
                end       
            end               
        else
            overlap{num_pr} = [];
            correct(num_pr) = 0;
            for k = 1:numel(cad{1}.parts)
                correct_part(num_pr).(pnames{k}) = 0;
            end            
        end
    end
end
fclose(fpr);
overlap = overlap';

threshold = sort(energy);
n = numel(threshold);
recall = zeros(n,1);
for k = 1:numel(cad{1}.parts)
    pcp.(pnames{k}) = zeros(n,1);
end
for i = 1:n
    % compute recall
    correct_recall = correct;
    correct_recall(energy < threshold(i)) = 0;
    num_correct = 0;
    for k = 1:numel(cad{1}.parts)
        num_correct_part.(pnames{k}) = 0;
    end
    start = 1;
    for j = 1:M
        for k = 1:count(j)
            % find highest score correct detecion for object k
            max_ind = 0;
            for s = start:start+num(j)-1
                index = find(overlap{s} == k);
                if correct_recall(s) == 1 && isempty(index) == 0
                    max_ind = s;
                    max_index = index;
                    break;
                end
            end
            if max_ind > 0
                num_correct = num_correct + 1;
                for kk = 1:numel(cad{1}.parts)
                    if correct_part(max_ind).(pnames{kk})(max_index) == 1
                        num_correct_part.(pnames{kk}) = num_correct_part.(pnames{kk}) + 1;
                    end
                end
            end
        end
        start = start + num(j);
    end
    recall(i) = num_correct / sum(count);
    for k = 1:numel(cad{1}.parts)
        pcp.(pnames{k})(i) = num_correct_part.(pnames{k}) / num_correct;
    end
end

if isfigure == 1
    % draw recall-precision curve
    figure;
    curve_color = {'r', 'g', 'b', 'c', 'm', 'k'};
    for k = 1:numel(cad{1}.parts)
        color_index = mod(k,6) + 1;
        plot(recall, pcp.(pnames{k}), 'Color', curve_color{color_index}, 'LineWidth', 3);
        hold on;
        ap = VOCap(recall(end:-1:1), pcp.(pnames{k})(end:-1:1));
        if strcmp(cls, 'bed') == 1 && k == 4
            leg{k} = sprintf('%s (%.2f)', 'top', ap);
        else
            leg{k} = sprintf('%s (%.2f)', pnames{k}, ap);
        end
    end

    h = legend(leg, 'Location', 'SouthWest');
    set(h,'FontSize',16);
    h = xlabel('Recall');
    set(h,'FontSize',16);
    h = ylabel('PCP');
    set(h,'FontSize',16);
    % tit = sprintf('Average Precision = %.1f', 100*ap);
    tit = sprintf('%s', cls);
    tit(1) = upper(tit(1));
    tit(tit == '_') = ' ';
    h = title(tit);
    set(h,'FontSize',16);
end

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