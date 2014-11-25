function index_test = get_test_index(cls)

N = 300;
path_anno = '../Annotations/room';

flag = zeros(N, 1);
for i = 1:N
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    if isempty(find(strcmp(cls, object.class) == 1, 1)) == 0
        flag(i) = 1;
    end
end

index_test = find(flag == 1);