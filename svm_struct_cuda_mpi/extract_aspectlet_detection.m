function extract_aspectlet_detection(cls)

matlabpool open 6

switch cls
    case 'car';
        N = 200;
    case {'bed', 'chair', 'sofa', 'table'};
        N = 300;
end

parfor i = 1:N
    % load detections
    filename = sprintf('results/%s_%03d.mat', cls, i);
    object = load(filename, 'labels');
    examples = object.labels{1};

    % do nms according to bounding box overlap
    for k = 1:numel(examples)
        example = examples{k};
        num = numel(example);
        flag = zeros(num, 1);

        for ii = 1:num
            flag(ii) = 1;
            for jj = 1:ii-1
                o = box_overlap(example(ii).bbox, example(jj).bbox);
                if flag(jj) > 0 && o >= 0.5
                    flag(ii) = 0;
                    break;
                end
            end
        end
        examples{k} = example(flag > 0);
    end    
    
    % save results
    filename = sprintf('results_aspectlet/%s_%03d.mat', cls, i);
    parsave(filename, examples);    
    fprintf('%s_%03d.mat saved\n', cls, i);
end

matlabpool close

function parsave(filename, examples)

save(filename, 'examples', '-v7.3');