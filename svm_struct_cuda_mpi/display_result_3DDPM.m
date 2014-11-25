function display_result_3DDPM(cls, detections)

switch cls
    case {'car'}
        index_test = 1:200;      
end

N = numel(index_test);
path_anno = sprintf('../Annotations/%s', cls);
path_image = sprintf('../Images/%s', cls);

figure;
for i = 1:N
    % read detections
    num = numel(detections(i).scores);    
    
    if i ~= 1 && mod(i-1, 4) == 0
        pause;
    end
    ind = mod(i-1,4)+1;
    
    % read ground truth
    index = index_test(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, index);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    n = size(bbox, 1);
    
    image_path = fullfile(path_image, object.image);
    I = imread(image_path);
    subplot(2, 2, ind);
    imshow(I);
    hold on;
    
    for j = 1:n
        % ground truth bounding box
        bbox_gt = [bbox(j,1) bbox(j,2) bbox(j,1)+bbox(j,3) bbox(j,2)+bbox(j,4)];
        for k = 1:num
            % get predicted bounding box
            bbox_pr = detections(i).BB(k,:);
            o = box_overlap(bbox_gt, bbox_pr);
            if o >= 0.5
                bbox_pr(1) = max(bbox_pr(1), 1);
                bbox_pr(2) = max(bbox_pr(2), 1);
                bbox_pr(3) = min(bbox_pr(3), size(I, 2));
                bbox_pr(4) = min(bbox_pr(4), size(I, 1));
                
                % draw bounding box
                bbox_draw = [bbox_pr(1), bbox_pr(2), bbox_pr(3)-bbox_pr(1), bbox_pr(4)-bbox_pr(2)];
                rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth',2);
                str = sprintf('%d: %.2f', k, detections(i).scores(k));
                text(bbox_draw(1), bbox_draw(2)-15, str, 'fontsize', 24, 'color', 'r');
                break;
            end
        end
    end
    
    subplot(2, 2, ind);
    hold off;
end