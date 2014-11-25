function display_result_mcmc(cls, cads, examples, samples)

switch cls
    case 'car'
        cls_data = 'car';
        index_test = 1:200;         
end

% do nms according to bounding box overlap
% for k = 1:numel(examples)
%     example = examples{k};
%     num = numel(example);
%     flag = zeros(num, 1);
%     
%     % sort examples
%     p = zeros(num, 1);
%     for i = 1:num
%         p(i) = example(i).energy;
%     end
%     [~,index] = sort(p, 'descend');
%     example = example(index);
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

N = numel(index_test);
path_anno = sprintf('../Annotations/%s', cls_data);
path_img = sprintf('../Images/%s', cls_data);

figure;
for k = 1:N
    disp(k);
    % read detections
    example = examples{k};
    num = numel(example);
    if num == 0
        fprintf('no detection for test image %d\n', k);
        continue;
    end
    
    % read ground truth
    index = index_test(k);
    file_ann = sprintf('%s/%04d.mat', path_anno, index);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    n = size(bbox, 1);
    
    image_path = sprintf('%s/%04d.jpg', path_img, index);
    I = imread(image_path);
    
    % plot 2D
    subplot(1,2,1);
    imshow(I);
    hold on;

    for i = 1:num
        cad = cads{example(i).cad_label}(1);
        view_label = example(i).view_label;
        pnames = cad.pnames;
        part_num = numel(pnames);
        part2d = cad.parts2d(view_label);

        for j = 1:part_num
            if isempty(part2d.homographies{j}) == 0
                c = example(i).part_label(j,:);
                % render parts
                part = part2d.(pnames{j}) + repmat(c, 5, 1);
                patch('Faces', [1 2 3 4 5], 'Vertices', part, 'EdgeColor', 'r', 'FaceColor', 'r', 'FaceAlpha', 0.1);           
            end
        end

        % draw bounding box
        bbox_pr = example(i).bbox;
        flag = 0;
        for j = 1:n
             % ground truth bounding box
            bbox_gt = [bbox(j,1) bbox(j,2) bbox(j,1)+bbox(j,3) bbox(j,2)+bbox(j,4)];       
            o = box_overlap(bbox_gt, bbox_pr);
            if o >= 0.5
                % draw bounding box
                flag = 1;
                break;
            end
        end
        bbox_draw = [bbox_pr(1), bbox_pr(2), bbox_pr(3)-bbox_pr(1), bbox_pr(4)-bbox_pr(2)];
        if flag == 1
            rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth',2);
        else
            rectangle('Position', bbox_draw, 'EdgeColor', 'r', 'LineWidth',2);
        end    
        text(bbox_pr(1), bbox_pr(2), num2str(i), 'BackgroundColor', 'r');
        fprintf('2D object %d, a=%.2f, e=%.2f, d=%.2f, energy=%e\n', i, part2d.azimuth, part2d.elevation, part2d.distance, example(i).energy);    
    end
    hold off;

    % plot 3D
    subplot(1,2,2);
    cla;
    hold on;

    O = samples{k}.O;
    cad_label = samples{k}.cad_label;
    alpha = samples{k}.alpha;
    C = samples{k}.C;

    num = size(O,2);
    for i = 1:num
        model = cads{cad_label(i)}(1);
        parts = model.parts;
        % rotation matrix
        alpha(i) = -1 * alpha(i);
        R = [cos(alpha(i)) -sin(alpha(i)) 0; sin(alpha(i)) cos(alpha(i)) 0; 0 0 1];

        for j = 1:numel(parts)
            F = parts(j).vertices;
            % rotate 
            F = (R*F')';        
            % shift
            F = F + repmat(O(:,i)', 5, 1);
            if model.roots(j) == 0
                patch(F(:,1), F(:,2), F(:,3), 'r', 'FaceAlpha', 0.5);
            end
        end
        fprintf('3D object %d, (%.2f, %.2f, %.2f), alpha=%.2f, cad_label=%d\n', i, ...
            O(1,i), O(2, i), O(3,i), alpha(i)*180/pi, cad_label(i));
    end
    fprintf('camera: %.2f, %.2f, %.2f\n', C(1), C(2), C(3));
    plot3(C(1), C(2), C(3), 'o', 'LineWidth', 5);
    axis equal;
    axis tight;
    xlabel('x');
    ylabel('y');
    zlabel('z');
    hold off;

    view(45, 30);
    pause;
%     hf = figure(1);
%     saveas(hf, sprintf('/n/ludington/v/yuxiang/Projects/ObjectInteraction/results/%04d.png', k));    
end