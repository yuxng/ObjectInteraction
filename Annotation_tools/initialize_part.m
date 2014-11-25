function initialize_part(cls)

switch cls
    case 'car'
        N = 200;
    case 'room'
        N = 300;
end
path_anno = sprintf('../Annotations/%s', cls);

for i = 1:N
    disp(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    n = size(object.bbox, 1);
    object.difficult = zeros(n,1);
    object.truncate = zeros(n,1);
    object.occlude = zeros(n,1);
    object.part = cell(n,1);
    object.occlusion = cell(n,1);
    for j = 1:n
        pnames = get_part_name(object.class{j});
        part_num = numel(pnames);
        for k = 1:part_num
            object.part{j}.(pnames{k}) = [0 0];
            object.occlusion{j}.(pnames{k}) = 0;
        end
    end
    save(file_ann, 'object');
end