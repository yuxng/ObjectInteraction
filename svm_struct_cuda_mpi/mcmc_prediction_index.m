function mcmc_prediction_index(cls, index)

switch cls
    case 'car';
        path_image = '../Images/car';
        cls_cad = {'car'};
    case 'room'
        path_image = '../Images/room';
        cls_cad = {'bed', 'chair', 'sofa', 'table'};
end

% load cad model
cad_num = numel(cls_cad);
cads = cell(cad_num, 1);
for i = 1:cad_num
    object = load(sprintf('data_final/%s.mat', cls_cad{i}));
    cads{i} = object.(cls_cad{i});
end

% padding of original image
[padx, pady] = get_padding(cads);

i = index;
% read image
filename = sprintf('%s/%04d.jpg', path_image, i);
I = imread(filename);
% run detectors
labels = cell(cad_num, 1);
trees = cell(cad_num, 1);    
for j = 1:cad_num
    num = numel(cads{j});
    labels{j} = cell(num, 1);
    trees{j} = cell(num, 1);
    % for each aspectlets
    for k = 1:num
        filename = sprintf('data_final/%s_3D_final_cad%03d.mod', cls_cad{j}, k-1);
        cad_one = cell(1,1);
        cad_one{1} = cads{j}(k);
        model = read_model(filename, cad_one);
        model.padx = padx;
        model.pady = pady;
        [y, tree] = svm_empty_classify_matlab(double(I), cad_one, model, 1);
        labels{j}{k} = y;
        trees{j}{k} = tree{1};
        fprintf('Image %d, cad %d, model %d: %d object detected\n', i, j, k, numel(y));
    end
end
filename = sprintf('results/%s_%03d.mat', cls, i);
parsave(filename, labels, trees);

function parsave(filename, labels, trees)

save(filename, 'labels', 'trees', '-v7.3');