function [samples, examples] = mcmc_test(cls)

matlabpool open 3

switch cls
    case 'car';
        path_image = '../Images/car';
        N = 200;
        cls_cad = {'car'};
    case 'room'
        path_image = '../Images/room';
        N = 300;
        cls_cad = {'bed', 'chair', 'sofa', 'table'};
end

% load cad model
cad_num = numel(cls_cad);
cads = cell(cad_num, 1);
for i = 1:cad_num
    object = load(sprintf('data_new/%s.mat', cls_cad{i}));
    cads{i} = object.(cls_cad{i});
end

samples = cell(N,1);
examples = cell(N,1);

parfor i = 1:N
%for i = 1:N
    % read image
    filename = sprintf('%s/%04d.jpg', path_image, i);
    I = imread(filename);
    % load detections
    filename = sprintf('results_new/%s_vote_%03d.mat', cls, i);
    object = load(filename, 'y');
    y = object.y;
    % run MCMC
    [samples{i}, examples{i}] = mcmc(I, y, cads, 0);
    fprintf('Image %d, %d sample generated\n', i, size(samples{i}.O,2));   
end

matlabpool close