function display_result(cls)

switch cls
    case 'car'
        cls_data = 'car';
        cls_cad = 'car';
        index_test = 1:200;   
    case 'car_3D'
        cls_cad = 'car';
        cls_data = cls;
        index_test = 241:480;     
end

% load cad model
cad_file = sprintf('../CAD/%s.mat', cls_cad);
cad = load(cad_file);
cad = cad.(cls_cad);

cad = cad(30);

pnames = cad.pnames;
part_num = numel(pnames);

N = numel(index_test);
path_img = sprintf('../Images/%s', cls_data);

% open prediction file
pre_file = sprintf('data/%s_cad029.pre', cls);
fpr = fopen(pre_file, 'r');

figure;
for i = 1:N
    % read detections
    num = fscanf(fpr, '%d', 1);
    if num == 0
        fprintf('no detection for test image %d\n', i);
        continue;
    else
        examples = cell(num, 1);
        for j = 1:num
            examples{j} = read_sample(fpr, cad, 0);
        end
    end    
    
    if i ~= 1 && mod(i-1, 16) == 0
        pause;
    end
    ind = mod(i-1,16)+1;
    
    % read ground truth
    index = index_test(i);    
    image_path = sprintf('%s/%04d.jpg', path_img, index);
    I = imread(image_path);
    subplot(4, 4, ind);
    imshow(I);
    hold on;

    for k = 1:1
        % get predicted bounding box
        bbox_pr = examples{k}.bbox;
        view_label = examples{k}.view_label + 1;
        part2d = cad.parts2d(view_label);
        til = sprintf('prediction: a=%d, e=%d, d=%d', part2d.azimuth, part2d.elevation, part2d.distance);
        title(til);
        part_label = examples{k}.part_label;
        for a = 1:part_num
            if isempty(part2d.homographies{a}) == 0 && part_label(a,1) ~= 0 && part_label(a,2) ~= 0
                plot(part_label(a,1), part_label(a,2), 'ro');
                % render parts
                part = part2d.(pnames{a}) + repmat(part_label(a,:), 5, 1);
                patch('Faces', [1 2 3 4 5], 'Vertices', part, 'FaceColor', 'r', 'EdgeColor', 'r', 'FaceAlpha', 0.1);           
            end
        end
        % draw bounding box
        bbox_draw = [bbox_pr(1), bbox_pr(2), bbox_pr(3)-bbox_pr(1), bbox_pr(4)-bbox_pr(2)];
        rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth',2);
    end
    
    subplot(4, 4, ind);
    hold off;
end

fclose(fpr);