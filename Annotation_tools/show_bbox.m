% show image with annotation
function show_bbox(cls)

path_image = sprintf('../Images/%s', cls);
path_anno = sprintf('../Annotations/%s', cls);

switch cls
    case 'car'
        N = 150;
    case 'car_3D'
        N = 480;
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
    bbox = object.bbox;
    
    % read original image and annotation
    file_img = sprintf('%s/%s', path_image, object.image);
    I_origin = imread(file_img);
    figure(1);
    imagesc(I_origin);
    axis equal;
    hold on;

    n = size(bbox, 1);
    for j = 1:n
        rectangle('Position', bbox(j,:), 'EdgeColor', 'g', 'LineWidth',2);
        text(bbox(j,1), bbox(j,2), num2str(j), 'fontsize', 24, 'color', 'b');
    end
    figure(1);
    hold off;
    pause;
end