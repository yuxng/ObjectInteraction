function truncate_image

path_anno_src = '../../FunctionRecognition/Annotations/car';
path_anno_dst = '../Annotations/car_3D';
path_img_src = '../../FunctionRecognition/Images/car';
path_img_dst = '../Images/car_3D';
pnames = {'head', 'left', 'right', 'front', 'back', 'tail', ...
    'view1', 'view2', 'view3', 'view4', 'view5', 'view6', 'view7', 'view8'};

for i = 241:480
    disp(i);
    % load original annotation
    file_ann = sprintf('%s/%04d.mat', path_anno_src, i);
    image = load(file_ann);
    object_old = image.object;
    bbox_old = object_old.bbox;
    % load original image
    file_img = sprintf('%s/%04d.jpg', path_img_src, i);
    I_old = imread(file_img, 'jpg');
    width = size(I_old,2);
    height = size(I_old,1);
    
    % rand image border for truncation
    image_border = randi(4);
    switch image_border
        case 1
            ox = round(bbox_old(1) + bbox_old(3)/3);
            oy = 1;
            w = width - ox;
            h = height;
            bbox = [1 bbox_old(2) bbox_old(3)*2/3 bbox_old(4)];
        case 2
            ox = 1;
            oy = 1;
            w = round(bbox_old(1) + bbox_old(3)*2/3);
            h = height;
            bbox = [bbox_old(1) bbox_old(2) bbox_old(3)*2/3 bbox_old(4)];
        case 3
            ox = 1;
            oy = round(bbox_old(2) + bbox_old(4)/3);
            w = width;
            h = height - oy;
            bbox = [bbox_old(1) 1 bbox_old(3) bbox_old(4)*2/3];
        case 4
            ox = 1;
            oy = 1;
            w = width;
            h = round(bbox_old(2) + bbox_old(4)*2/3);
            bbox = [bbox_old(1) bbox_old(2) bbox_old(3) bbox_old(4)*2/3];
    end

    % crop image
    I = I_old(oy:oy+h-1, ox:ox+w-1,:);
    file_img = sprintf('%s/%04d.jpg', path_img_dst, i);
    imwrite(I, file_img, 'jpg');
    
    % create new annotation
    object.image = object_old.image;
    object.bbox = bbox;
    n = size(object.bbox, 1);
    object.difficult = zeros(n,1);
    object.class = {'car'};
    
    % assign part
    object.part = cell(n,1);
    object.occlusion = cell(n,1);
    for j = 1:n
        for k = 1:numel(pnames)
            if object_old.(pnames{k})(j,1) ~= 0
                object.part{j}.(pnames{k}) = object_old.(pnames{k})(j,:) - [ox oy];
            else
                object.part{j}.(pnames{k}) = object_old.(pnames{k})(j,:);
            end
            object.occlusion{j}.(pnames{k}) = 0;
        end
    end
    
    object.view = object_old.view;
    object.truncate = ones(n,1);
    object.occlude = zeros(n,1);

    file_ann = sprintf('%s/%04d.mat', path_anno_dst, i);
    save(file_ann, 'object');
end