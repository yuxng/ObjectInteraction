function display_result_aspectlet_SLM_new(cls)

switch cls
    case 'car';
        cls_data = 'car';
        cls_cad = {'car'};
        index_test = 1:200;
    case 'room'
        cls_data = 'room';
        cls_cad = {'bed', 'chair', 'sofa', 'table'};
        index_test = 1:300;
end

% load cad model
cad_num = numel(cls_cad);
cads = cell(cad_num, 1);
for i = 1:cad_num
    object = load(sprintf('../CAD/%s_final.mat', cls_cad{i}));
    cads{i} = object.(cls_cad{i});
end

N = numel(index_test);
path_anno = sprintf('../Annotations/%s', cls_data);
path_img = sprintf('../Images/%s', cls_data);   
    
% for each image
for i = 1:N
    fprintf('image %d\n', i);
    index = index_test(i);
    hf = figure;          
    image_path = sprintf('%s/%04d.jpg', path_img, index);
    I = imread(image_path);
    imshow(I);
    hold on;        

    % load annotation
    file_ann = sprintf('%s/%04d.mat', path_anno, index);
    image = load(file_ann);
    object = image.object;
    view = object.view;

    index_diff = find(object.difficult == 0);
    num_object = numel(index_diff);

    % for each object
    for j = 1:num_object
        ind_diff = index_diff(j);
        cad_label = strcmp(object.class{ind_diff}, cls_cad) == 1;

        % load detections
        filename = sprintf('results_aspectlet/%s_%03d.mat', object.class{ind_diff}, index);
        object_det = load(filename);
        examples = object_det.examples;
        
        cad_index = randperm(numel(cads{cad_label})-1) + 1;
        % for each aspectlet
        for o = cad_index
            cad = cads{cad_label}(o);
            pnames = cad.pnames;
            part_num = numel(pnames);            

            % construct ground truth bounding boxes for aspectlets
            bbox = [];
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
                bbox = [x1 y1 x2 y2];
            end  

            flag = 0;
            if isempty(bbox) == 0
                % ground truth bounding box
                bbox_gt = bbox;
                % get detectinos
                example = examples{o};
                num = numel(example);             
                for k = 1:num
                    % get predicted bounding box
                    bbox_pr = example(k).bbox;                
                    overlap = box_overlap(bbox_gt, bbox_pr);
                    if overlap >= 0.5
                        flag = 1;
                        view_label = example(k).view_label;
                        part2d = cad.parts2d(view_label);
                        for a = 1:part_num
                            if isempty(part2d.homographies{a}) == 0 && cad.roots(a) == 0
                                c = example(k).part_label(a,:);
                                plot(c(1), c(2), 'ro');
                                % render parts
                                part = part2d.(pnames{a}) + repmat(c, 5, 1);
                                patch('Faces', [1 2 3 4 5], 'Vertices', part, 'FaceColor', 'r', 'EdgeColor','r', 'FaceAlpha', 0.3, 'LineWidth',3);
                            end
                        end
                        % draw bounding box
                        bbox_pr(1) = max(bbox_pr(1), 1);
                        bbox_pr(2) = max(bbox_pr(2), 1);
                        bbox_pr(3) = min(bbox_pr(3), size(I, 2));
                        bbox_pr(4) = min(bbox_pr(4), size(I, 1));                    
                        bbox_draw = [bbox_pr(1), bbox_pr(2), bbox_pr(3)-bbox_pr(1), bbox_pr(4)-bbox_pr(2)];
                        rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth',3);
                        break;
                    end
                end
            end
            
            if flag == 1
                break;
            end
        end % end for each aspectlet
    end % end for each object
               
    hold off;
    filename = sprintf('/n/ludington/v/yuxiang/Projects/ObjectInteraction/results_aspectlet/%s_new/%s_%04d.jpg', cls, cls, index);
    saveas(hf, filename);
%     pause;
    close all;
end
close all;