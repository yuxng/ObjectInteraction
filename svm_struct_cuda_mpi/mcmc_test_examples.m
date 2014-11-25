function examples = mcmc_test_examples(cls, samples, map_indexes, pars)

matlabpool open 2

switch cls
    case 'car';
        N = 150;
        cls_cad = {'car'};
    case 'room'
        N = 300;
        cls_cad = {'bed', 'chair', 'sofa', 'table'};
end

% load cad model
cad_num = numel(cls_cad);
cads = cell(cad_num, 1);
for i = 1:cad_num
    object = load(sprintf('data_final/%s.mat', cls_cad{i}));
    cads{i} = object.(cls_cad{i});
end

% load samples
% filename = sprintf('results_%s.mat', cls);
% object = load(filename);
% samples = object.samples;
% pars = object.pars;

examples = cell(N,1);

parfor i = 1:N    
    % load detections
    filename = sprintf('results/%s_%03d.mat', cls, i);
    object = load(filename);
    trees = object.trees;
    % load detections
    filename = sprintf('results/%s_vote_%03d.mat', cls, i);
    object = load(filename);
    scores = object.scores;
    y = object.y;
    % run MCMC
    examples{i} = mcmc_output(samples{i}, map_indexes(i), pars{i}, y, scores, trees, cads);
    % examples{i} = mcmc_output_marginal(samples{i}, pars{i}, trees, cads);
    fprintf('Image %d, %d object detected\n', i, numel(examples{i}));
    trees = [];
end

matlabpool close