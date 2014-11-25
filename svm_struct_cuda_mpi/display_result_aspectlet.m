function display_result_aspectlet(cls)

switch cls
    case 'car'
        cls_data = 'car';
        cls_cad = 'car';
        index_test = 1:200;   
    case 'car_3D'
        cls_cad = 'car';
        cls_data = cls;
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
end

% load cad model
cad_file = sprintf('../CAD/%s.mat', cls_cad);
cads = load(cad_file);
cads = cads.(cls_cad);
cad_num = numel(cads);

% start with the second aspectlet, the first one is the whole object
for o = 2:cad_num
    fprintf('aspectlet %d\n', o);
    cad = cads(o);

    pnames = cad.pnames;
    part_num = numel(pnames);

    N = numel(index_test);
    path_anno = sprintf('../Annotations/%s', cls_data);
    path_img = sprintf('../Images/%s', cls_data);

    % open prediction file
    pre_file = sprintf('data/%s_cad%03d.pre', cls, o-1);
    fpr = fopen(pre_file, 'r');

    figure(1);
    cla;
    for i = 1:N
        % read detections
        num = fscanf(fpr, '%d', 1);
        if num == 0
            fprintf('no detection for test image %d\n', i);
            continue;
        else
            A = zeros(num, 4+part_num*2+4);
            for j = 1:num
                A(j,:) = fscanf(fpr, '%f', 4+part_num*2+4);
            end
        end    

        if i ~= 1 && mod(i-1, 16) == 0
            pause;
        end
        ind = mod(i-1,16)+1;
        
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
            ind_diff = index_diff(j);

            % find the view label
            view_label = -1;
            for k = 1:numel(cad.parts2d)
                if view(ind_diff,1) == cad.parts2d(k).azimuth && view(ind_diff,2) == cad.parts2d(k).elevation...
                        && view(ind_diff,3) == cad.parts2d(k).distance
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
                        if object.part{ind_diff}.(cad.parts2d_front(k).pname)(1) ~= 0
                            part_label(k,:) = object.part{ind_diff}.(cad.parts2d_front(k).pname);
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
        
        n = size(bbox, 1);

        image_path = sprintf('%s/%04d.jpg', path_img, index);
        I = imread(image_path);
        subplot(4, 4, ind);
        imshow(I);
        hold on;

        for j = 1:n
            % ground truth bounding box
            bbox_gt = bbox(j,:);
            for k = 1:num
                % get predicted bounding box
                bbox_pr = A(k,end-3:end)';
                o = box_overlap(bbox_gt, bbox_pr);
                if o >= 0.5
                    bbox_pr(1) = max(bbox_pr(1), 1);
                    bbox_pr(2) = max(bbox_pr(2), 1);
                    bbox_pr(3) = min(bbox_pr(3), size(I, 2));
                    bbox_pr(4) = min(bbox_pr(4), size(I, 1));

                    view_label = A(k,3) + 1;
                    part2d = cad.parts2d(view_label);
                    til = sprintf('prediction: a=%d, e=%d, d=%d', part2d.azimuth, part2d.elevation, part2d.distance);
                    title(til);
                    for a = 1:part_num
                        if isempty(part2d.homographies{a}) == 0
                            plot(A(k,4+a), A(k,4+a+part_num), 'ro');
                            % render parts
                            part = part2d.(pnames{a}) + repmat([A(k,4+a), A(k,4+a+part_num)], 5, 1);
                            patch('Faces', [1 2 3 4 5], 'Vertices', part, 'FaceColor', 'r', 'FaceAlpha', 0.2);           
                        end
                    end
                    % draw bounding box
                    bbox_draw = [bbox_pr(1), bbox_pr(2), bbox_pr(3)-bbox_pr(1), bbox_pr(4)-bbox_pr(2)];
                    rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth',2);
                    break;
                end
            end
        end

        subplot(4, 4, ind);
        hold off;
    end

    fclose(fpr);
end