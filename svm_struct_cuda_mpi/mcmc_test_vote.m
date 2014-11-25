function examples = mcmc_test_vote(cls)

matlabpool open 3

switch cls
    case 'car';
        N = 200;
        cls_cad = {'car'};
    case 'bed';
        N = 300;
        cls_cad = {'bed'};
    case 'sofa';
        N = 300;
        cls_cad = {'sofa'}; 
    case 'chair';
        N = 300;
        cls_cad = {'chair'};
    case 'table';
        N = 300;
        cls_cad = {'table'};         
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

examples = cell(N,1);

% load full models
models = cell(cad_num, 1);
for i = 1:cad_num
    filename = sprintf('data_final/%s_final_cad000.mod', cls_cad{i});
    cad_one = cell(1,1);
    cad_one{1} = cads{i}(1);
    models{i} = read_model(filename, cad_one);
end

parfor i = 1:N
    % load detections
    filename = sprintf('results/%s_%03d.mat', cls, i);
    object = load(filename);
    labels = object.labels;
    trees = object.trees;
    % Hough transform
    scores = mcmc_vote_view(labels, trees, cads, models);
    y = mcmc_candidate(scores, trees, cads);
    examples{i} = y;
    fprintf('Image %d, %d object detected\n', i, numel(examples{i}));
    labels = [];
    trees = [];
    % save results
    filename = sprintf('results_new/%s_vote_%03d.mat', cls, i);
    parsave(filename, scores, y);    
end

matlabpool close

function parsave(filename, scores, y)

save(filename, 'scores', 'y', '-v7.3');