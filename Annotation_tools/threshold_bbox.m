function threshold_bbox(cls)

path_image = sprintf('/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/%s', cls);
path_anno = sprintf('/n/ludington/v/yuxiang/Projects/ObjectInteraction/Annotations/%s', cls);

switch cls
    case 'room'
        N = 300;
    case 'car'
        N = 150;
    otherwise
        return;
end

for i = 1:N
    disp(i);
    file_image = sprintf('%s/%04d.jpg', path_image, i);
    I = imread(file_image);
    
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    n = size(bbox, 1);
    for j = 1:n
        b = zeros(1,4);
        b(1) = max(1, bbox(j,1));
        b(2) = max(1, bbox(j,2));
        b(3) = min(bbox(j,1)+bbox(j,3), size(I,2));
        b(4) = min(bbox(j,2)+bbox(j,4), size(I,1));
        bbox(j,:) = [b(1) b(2) b(3)-b(1) b(4)-b(2)];
    end
    object.bbox = bbox;
    save(file_ann, 'object');
end