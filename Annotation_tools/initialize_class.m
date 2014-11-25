function initialize_class(cls)

switch cls
    case 'car'
        N = 200;
    case 'bed'
        N = 400;
    case 'chair'
        N = 770;
    case 'sofa'
        N = 800;
    case 'table'
        N = 670;
end
path_anno = sprintf('../Annotations/%s', cls);

for i = 1:N
    disp(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    n = size(object.bbox, 1);
    object.class = cell(n, 1);
    for j = 1:n
        object.class{j} = cls;
    end
    save(file_ann, 'object');
end