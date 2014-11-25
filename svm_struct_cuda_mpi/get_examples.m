function examples = get_examples(cls)

switch cls
    case 'car'
        N = 200;
    case 'bed'
        N = 300;
end

examples = cell(N,1);

for i = 1:N
    disp(i);
    % load detections
    filename = sprintf('results/%s_%03d.mat', cls, i);
    object = load(filename, 'labels');
    labels = object.labels;
    examples{i} = labels{1}{1};
end