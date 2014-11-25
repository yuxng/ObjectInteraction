function labels = mcmc_construct_labels(cls)

switch cls
    case 'car'
        N = 200;
        cls_cad = {'car'};
    case 'room'
        N = 300;
        cls_cad = {'bed', 'chair', 'sofa', 'table'};
end
labels = cell(N, 1);

% read labels
for i = 1:N
    disp(i);
    count = 1;
    for j = 1:numel(cls_cad)
        cls = cls_cad{j};
        % load detections
        filename = sprintf('results/%s_vote_%03d.mat', cls, i);
        object = load(filename, 'y');
        y = object.y;
        num = numel(y);
        for k = 1:num
            y(k).cad_label = j;
            y(k).class = cls;
        end
        label(count:count+num-1) = y;
        count = count + num;
    end
    labels{i} = label(1:count-1);
end

% sort labels
for k = 1:numel(labels)
    example = labels{k};
    num = numel(example);
    
    % sort examples
    p = zeros(num, 1);
    for i = 1:num
        p(i) = example(i).energy;
    end
    [~,index] = sort(p, 'descend');
    example = example(index);
    labels{k} = example;
end