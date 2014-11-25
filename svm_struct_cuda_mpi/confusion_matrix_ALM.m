function [cmatrix, ctable, accuracy, mae] = confusion_matrix_ALM(cls, vnum)

switch cls
    case 'car'
        cls_data = 'car';
        cls_cad = 'car';
        index_test = 1:150;
    case 'car_3D'
        cls_data = 'car_3D';
        cls_cad = 'car';
        index_test = 241:480;
end

cmatrix = zeros(vnum);

% load cad model
object = load(sprintf('../CAD/%s_full.mat', cls_cad));
cad = object.(cls_cad);

N = numel(index_test);
path_anno = sprintf('../Annotations/%s', cls_data);
path_image = sprintf('../Images/%s', cls_data);

% prediction
fpr = fopen(sprintf('data_new/%s_full.pre', cls), 'r');

count = 0;
angle = 0;
for i = 1:N
    % read detections
    num = fscanf(fpr, '%d', 1);
    if num == 0
        fprintf('no detection for test image %d\n', i);
        continue;
    else
        A = cell(num, 1);
        for j = 1:num
            A{j} = read_sample(fpr, cad, 0);
        end
    end
    
    % read ground truth
    index = index_test(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, index);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    view = object.view;
    n = size(view, 1);

    % read image
    file_image = sprintf('%s/%04d.jpg', path_image, index);
    I = imread(file_image);     

    for j = 1:n
        % ground truth viewpoint
        azimuth_gt = view(j,1);
        ind_gt = find_interval(azimuth_gt, vnum);
        % ground truth bounding box
        bbox_gt = [bbox(j,1) bbox(j,2) bbox(j,1)+bbox(j,3) bbox(j,2)+bbox(j,4)];
        for k = 1:num
            % get predicted bounding box
            bbox_pr = A{k}.bbox';
            
            bbox_pr(1) = max(1, bbox_pr(1));
            bbox_pr(2) = max(1, bbox_pr(2));
            bbox_pr(3) = min(bbox_pr(3), size(I,2));
            bbox_pr(4) = min(bbox_pr(4), size(I,1));
            
            o = box_overlap(bbox_gt, bbox_pr);
            if o >= 0.5
                view_label = A{k}.view_label + 1;
                azimuth_pr = cad.parts2d(view_label).azimuth;
                ind_pr = find_interval(azimuth_pr, vnum);
                cmatrix(ind_gt, ind_pr) = cmatrix(ind_gt, ind_pr) + 1;
                
                count = count + 1;
                angle = angle + abs(azimuth_gt - azimuth_pr);
                break;
            end
        end
    end
end

fclose(fpr);

ctable = cmatrix;
for i = 1:vnum
    if sum(cmatrix(i,:)) ~= 0
        cmatrix(i,:) = cmatrix(i,:) ./ sum(cmatrix(i,:));
    end
end
fprintf('Average Accuracy: %.2f%%\n', sum(diag(cmatrix)) / sum(sum(cmatrix)) * 100);
accuracy = sum(diag(cmatrix)) / sum(sum(cmatrix));
mae = angle / count;
fprintf('MAE = %.2f\n', mae);

function ind = find_interval(azimuth, num)

if num == 8
    a = 22.5:45:337.5;
elseif num == 24
    a = 7.5:15:352.5;
elseif num == 16
    a = 11.25:22.5:348.75;
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