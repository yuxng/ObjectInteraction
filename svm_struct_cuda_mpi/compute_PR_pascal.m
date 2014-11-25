% compute recall and precision
function [recall, precision] = compute_PR_pascal(cls, examples, index_test)

VOC2006 = true;
pascal_init;
ids = textread(sprintf(VOCopts.imgsetpath, 'test'), '%s');
M = numel(index_test);

energy = [];
correct = [];
overlap = [];
count = zeros(M,1);
num = zeros(M,1);
num_pr = 0;
for i = 1:M
    index = index_test(i);
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{index}));
    clsinds = strmatch(cls, {rec.objects(:).class}, 'exact');
    for j = 1:numel(clsinds)
        if rec.objects(clsinds(j)).difficult == 1
            clsinds(j) = 0;
        end
    end
    clsinds(clsinds == 0) = [];
    count(i) = numel(clsinds);
    if isempty(clsinds) == 0
        % get ground truth bounding box
        bbox = zeros(numel(clsinds),4);
        for j = 1:numel(clsinds)
            bbox(j,:) = rec.objects(clsinds(j)).bbox;
        end
    else
        bbox = [];
    end
    det = zeros(count(i), 1);

    example = examples{i};
    num(i) = numel(example);
    for j = 1:num(i)
        num_pr = num_pr + 1;
        energy(num_pr) = example(j).energy;
        % get predicted bounding box
        bbox_pr = example(j).bbox';

        % compute box overlap
        if isempty(bbox) == 0
            o = box_overlap(bbox, bbox_pr);
            [maxo, index] = max(o);
            if maxo >= 0.5 && det(index) == 0
                overlap{num_pr} = index;
                correct(num_pr) = 1;
                det(index) = 1;
            else
                overlap{num_pr} = [];
                correct(num_pr) = 0;              
            end
        else
            overlap{num_pr} = [];
            correct(num_pr) = 0;
        end
    end
end
overlap = overlap';

threshold = sort(energy);
n = numel(threshold);
recall = zeros(n,1);
precision = zeros(n,1);
for i = 1:n
    num_positive = numel(find(energy >= threshold(i)));
    num_correct = sum(correct(energy >= threshold(i)));
    if num_positive ~= 0
        precision(i) = num_correct / num_positive;
    else
        precision(i) = 0;
    end
    
    correct_recall = correct;
    correct_recall(energy < threshold(i)) = 0;
    num_correct = 0;
    start = 1;
    for j = 1:M
        for k = 1:count(j)
            for s = start:start+num(j)-1
                if correct_recall(s) == 1 && numel(find(overlap{s} == k)) ~= 0
                    num_correct = num_correct + 1;
                    break;
                end
            end
        end
        start = start + num(j);
    end
    recall(i) = num_correct / sum(count);
end

ap = VOCap(recall(end:-1:1), precision(end:-1:1));
disp(ap);
leg{1} = sprintf('DPM (%.4f)', ap);

% draw recall-precision curve
figure(1);hold on;
plot(recall, precision, 'b', 'LineWidth',3);
h = legend(leg, 'Location', 'SouthWest');
set(h,'FontSize',16);
h = xlabel('Recall');
set(h,'FontSize',16);
h = ylabel('Precision');
set(h,'FontSize',16);
tit = sprintf('%s', cls);
tit(1) = upper(tit(1));
tit(tit == '_') = ' ';
h = title(tit);
set(h,'FontSize',16);