function [samples, examples] = mcmc_test_room(index_test)

matlabpool open 8

path_image = '../Images/room';
N = numel(index_test);

object = load('work_room.mat');
cads = object.cads;
labels = object.labels;

samples = cell(N,1);
examples = cell(N,1);

parfor i = 1:N
% for i = 1:N
    % read image
    ind = index_test(i);
    filename = sprintf('%s/%04d.jpg', path_image, ind);
    I = imread(filename);
    % load detections
    y = labels{ind};
    % run MCMC
    [samples{i}, examples{i}] = mcmc(I, y, cads, 0);
    if isempty(samples{i}) == 0
        fprintf('Image %d, %d objects in MAP\n', ind, size(samples{i}.O,2));   
    else
        fprintf('Image %d, 0 objects in MAP\n', ind);   
    end
end

matlabpool close