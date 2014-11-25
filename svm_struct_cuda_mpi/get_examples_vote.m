function examples = get_examples_vote(cls)

switch cls
    case 'car'
        N = 200;
    case {'bed', 'chair', 'sofa', 'table'}
        N = 300;
end

examples = cell(N,1);

for i = 1:N
    disp(i);
    % load detections
    filename = sprintf('results/%s_vote_%03d.mat', cls, i);
    object = load(filename, 'y');
    labels = object.y;
    examples{i} = labels;
end