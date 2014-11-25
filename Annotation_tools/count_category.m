function count_category

N = 300;
path_anno = '../Annotations/room';

count_bed = 0;
count_chair = 0;
count_sofa = 0;
count_table = 0;

for i = 1:N
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    n = size(object.bbox, 1);
    for j = 1:n
        cls = object.class{j};
        switch cls
            case 'bed'
                count_bed = count_bed + 1;
            case 'chair'
                count_chair = count_chair + 1;
            case 'sofa'
                count_sofa = count_sofa + 1;
            case 'table'
                count_table = count_table + 1;
        end
    end
end

fprintf('Total: %d\n', count_bed+count_chair+count_sofa+count_table);
fprintf('Bed: %d\n', count_bed);
fprintf('Chair: %d\n', count_chair);
fprintf('Sofa: %d\n', count_sofa);
fprintf('Table: %d\n', count_table);