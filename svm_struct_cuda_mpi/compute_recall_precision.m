% compute recall and precision
function [recall, precision, ap] = compute_recall_precision(cls, isfigure)

switch cls
    case 'car'
        cls_data = 'car';
        cls_cad = 'car';
        index_test = 1:150;
    case 'car_3D'
        cls_data = 'car_3D';
        cls_cad = 'car';
        index_test = 241:480;
    case 'bed'
        object = load('data/bed.mat');
        index_test = object.index_test;
        cls_data = 'bed';
        cls_cad = 'bed';
    case 'chair'
        object = load('data/chair.mat');
        index_test = object.index_test;
        cls_data = 'chair';
        cls_cad = 'chair';        
    case 'sofa'
        object = load('data/sofa.mat');
        index_test = object.index_test;
        cls_data = 'sofa';        
        cls_cad = 'sofa';
    case 'table'
        object = load('data/table.mat');
        index_test = object.index_test;
        cls_data = 'table';
        cls_cad = 'table';        
end

% load cad model
object = load(sprintf('../CAD/%s.mat', cls_cad));
cads = object.(cls_cad);
cad_num = numel(cads);

M = numel(index_test);
path_anno = sprintf('../Annotations/%s', cls_data);
path_image = sprintf('../Images/%s', cls_data);

recall = cell(cad_num, 1);
precision = cell(cad_num, 1);
ap = zeros(cad_num, 1);

% start with the second aspectlet, the first one is the whole object
for o = 2:cad_num
    cad = cads(o);
    
    % open prediction file
    pre_file = sprintf('data/%s_cad%03d.pre', cls, o-1);
    fpr = fopen(pre_file, 'r');

    energy = [];
    correct = [];
    overlap = [];
    count = zeros(M,1);
    num = zeros(M,1);
    num_pr = 0;
    for i = 1:M
        % construct ground truth bounding boxes for aspectlets
        index = index_test(i);
        file_ann = sprintf('%s/%04d.mat', path_anno, index);
        image = load(file_ann);
        object = image.object;
        view = object.view;

        index_diff = find(object.difficult == 0);
        num_object = numel(index_diff);
        
        bbox = [];
        for j = 1:num_object
            ind = index_diff(j);

            % find the view label
            view_label = -1;
            for k = 1:numel(cad.parts2d)
                if view(ind,1) == cad.parts2d(k).azimuth && view(ind,2) == cad.parts2d(k).elevation...
                        && view(ind,3) == cad.parts2d(k).distance
                    view_label = k;
                    break;
                end
            end
            if view_label ~= -1
                part2d = cad.parts2d(view_label);
                
                % get part label
                part_label = zeros(numel(cad.pnames),2);
                for k = 1:numel(cad.pnames)
                    % only consider aspect parts
                    if cad.roots(k) == 0
                        if object.part{ind}.(cad.parts2d_front(k).pname)(1) ~= 0
                            part_label(k,:) = object.part{ind}.(cad.parts2d_front(k).pname);
                        else
                            fprintf('Error: part label not available\n');
                        end
                    else
                        part_label(k,:) = [0 0];
                    end
                end
                
                % compute the bounding box of aspect parts
                x1 = inf;
                x2 = -inf;
                y1 = inf;
                y2 = -inf;
                for k = 1:size(part_label, 1)
                    if part_label(k,1) ~= 0
                        part = part2d.(cad.pnames{k}) + repmat(part_label(k,:), 5, 1);
                        x1 = min(x1, min(part(:,1)));
                        x2 = max(x2, max(part(:,1)));
                        y1 = min(y1, min(part(:,2)));
                        y2 = max(y2, max(part(:,2)));
                    end
                end
                bbox = [bbox; x1 y1 x2 y2];
            end
        end

        count(i) = size(bbox, 1);
        det = zeros(count(i), 1);

        % read image
        file_image = sprintf('%s/%04d.jpg', path_image, index);
        I = imread(file_image);

        num(i) = fscanf(fpr, '%d', 1);
        % for each predicted bounding box
        for j = 1:num(i)
            example = read_sample(fpr, cad, 0);

            num_pr = num_pr + 1;
            energy(num_pr) = example.energy;
            % get predicted bounding box
            bbox_pr = example.bbox';

            bbox_pr(1) = max(1, bbox_pr(1));
            bbox_pr(2) = max(1, bbox_pr(2));
            bbox_pr(3) = min(bbox_pr(3), size(I,2));
            bbox_pr(4) = min(bbox_pr(4), size(I,1));        

            % compute box overlap
            if isempty(bbox) == 0
                o_area = box_overlap(bbox, bbox_pr);
                [maxo, index] = max(o_area);
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
    fclose(fpr);
    overlap = overlap';

    threshold = sort(energy);
    n = numel(threshold);
    recall{o} = zeros(n,1);
    precision{o} = zeros(n,1);
    for i = 1:n
        % compute precision
        num_positive = numel(find(energy >= threshold(i)));
        num_correct = sum(correct(energy >= threshold(i)));
        if num_positive ~= 0
            precision{o}(i) = num_correct / num_positive;
        else
            precision{o}(i) = 0;
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
        recall{o}(i) = num_correct / sum(count);
    end

    ap(o) = VOCap(recall{o}(end:-1:1), precision{o}(end:-1:1));
    leg{1} = sprintf('object (%.2f)', ap(o));
    disp(ap(o));

    if isfigure == 1
        % draw recall-precision curve
        figure(1);
        cla;
        hold on;
        plot(recall{o}, precision{o}, 'g', 'LineWidth',3);
        h = legend(leg, 'Location', 'SouthWest');
        set(h,'FontSize',16);
        h = xlabel('Recall');
        set(h,'FontSize',16);
        h = ylabel('Precision');
        set(h,'FontSize',16);
        % tit = sprintf('Average Precision = %.1f', 100*ap);
        tit = sprintf('%s', cls);
        tit(1) = upper(tit(1));
        tit(tit == '_') = ' ';
        h = title(tit);
        set(h,'FontSize',16);
    end
%     pause;
end