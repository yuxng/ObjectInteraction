% chop image according to the bounding box
function crop_image(cls)

path_image = sprintf('/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/%s', cls);
path_anno = sprintf('/n/ludington/v/yuxiang/Projects/ObjectInteraction/Annotations/%s', cls);
path_dst = sprintf('/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/%s_BB', cls);

switch cls
    case 'car'
        N = 200;
    case 'room'
        N = 300;
    otherwise
        return;
end

for i = 1:N
    disp(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    
    %file_img = sprintf('%s/%s', path_image, object.image);
    file_img = sprintf('%s/%04d.jpg', path_image, i);
    I = imread(file_img);
    
    bbox = object.bbox;
    n = size(bbox, 1);
    for j = 1:n
        x1 = round(bbox(j,1));
        if x1 <= 0
            x1 = 1;
        end
        y1 = round(bbox(j,2));
        if y1 <= 0
            y1 = 1;
        end
        x2 = round(bbox(j,1) + bbox(j,3));
        if x2 > size(I,2)
            x2 = size(I,2);
        end
        y2 = round(bbox(j,2) + bbox(j,4));
        if y2 > size(I,1)
            y2 = size(I,1);
        end
        file = sprintf('%s/%04d_%02d.jpg', path_dst, i, j);
        imwrite(I(y1:y2, x1:x2, :), file, 'jpg');
    end
end