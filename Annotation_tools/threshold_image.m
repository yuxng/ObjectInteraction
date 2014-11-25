function threshold_image(cls)

path_image = sprintf('/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/%s', cls);

switch cls
    case 'room'
        N = 442;
    case 'car'
        N = 200;
    otherwise
        return;
end

threshold = 640;
for i = 151:N
    file_image = sprintf('%s/%04d.jpg', path_image, i);
    I = imread(file_image);
    dims = size(I);
    h = dims(1);
    w = dims(2);
    if h > threshold || w > threshold
        disp(i);
        % rescale image
        if h > w
            scale = threshold / h;
        else
            scale = threshold / w;
        end
        I1 = imresize(I, scale);
        imwrite(I1, file_image, 'jpg');
    end
end