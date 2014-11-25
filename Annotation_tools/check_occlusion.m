function check_occlusion(cls)

path_anno = sprintf('../Annotations/%s', cls);

switch cls
    case 'car'
        N = 200;
        names = {'car'};
    case 'room'
        N = 300;
        names = {'bed', 'chair', 'sofa', 'table'};
    otherwise
        return;
end

num = numel(names);
count = zeros(num,1);
count_trunc = zeros(num,1);
count_occld = zeros(num,1);
for i = 1:N
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    n = size(object.bbox,1);
    for j = 1:n
        ind = find(strcmp(object.class{j}, names) == 1);
        count(ind) = count(ind) + 1;
        count_trunc(ind) = count_trunc(ind) + object.truncate(j);
        count_occld(ind) = count_occld(ind) + object.occlude(j);
    end
end
for i = 1:num
    fprintf('%s\n', names{i});
    fprintf('Total objects %d\n', count(i));
    fprintf('Truncated objects %d\n', count_trunc(i));
    fprintf('Occluded objects %d\n', count_occld(i));
end

fprintf('\nTotal objects %d\n', sum(count));
fprintf('Truncated objects %d\n', sum(count_trunc));
fprintf('Occluded objects %d\n', sum(count_occld));