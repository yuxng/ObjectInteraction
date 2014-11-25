% read one sample from file
function examples = read_samples(cls)

switch cls
    case 'car_ALM'
        cls_cad = 'car';
        N = 200;
        object = load(sprintf('../../Aspect_Layout_Model/CAD/%s.mat', cls_cad));
    case 'bed_ALM'
        cls_cad = 'bed';
        N = 300;
        object = load(sprintf('../../Aspect_Layout_Model/CAD/%s.mat', cls_cad));
    case 'chair_ALM'
        cls_cad = 'chair';
        N = 300;
        object = load(sprintf('../../Aspect_Layout_Model/CAD/%s.mat', cls_cad));        
    case 'sofa_ALM'
        cls_cad = 'sofa';
        N = 300;
        object = load(sprintf('../../Aspect_Layout_Model/CAD/%s.mat', cls_cad));
    case 'table_ALM'
        cls_cad = 'table';
        N = 300;
        object = load(sprintf('../../Aspect_Layout_Model/CAD/%s.mat', cls_cad));
    case 'car_pascal2006_ALM'
        cls_cad = 'car';
        N = 2686;
        object = load(sprintf('../../Aspect_Layout_Model/CAD/%s.mat', cls_cad));        
end

% load cad model
cad = object.(cls_cad);

% open prediction file
pre_file = sprintf('data/%s.pre', cls);
fid = fopen(pre_file, 'r');

examples = cell(N,1);
for i = 1:N
    num = fscanf(fid, '%d', 1);
    example = [];
    for j = 1:num
        example(j).object_label = fscanf(fid, '%d', 1);
        example(j).cad_label = fscanf(fid, '%d', 1);
        example(j).view_label = fscanf(fid, '%d', 1) + 1;
        example(j).energy = fscanf(fid, '%f', 1);
        part_num = numel(cad.pnames);
        example(j).part_label = fscanf(fid, '%f', part_num*2);
        example(j).part_label = reshape(example(j).part_label, part_num, 2);
        example(j).bbox = fscanf(fid, '%f', 4)';
        example(j).class = cls_cad;
    end
    examples{i} = example;
end