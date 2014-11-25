% build the candidate labels
function y = mcmc_candidate(scores, trees, cads)

N = 100;
y = [];
count = 1;
sbin = 6;
[padx, pady] = get_padding(cads);
for k = 1:numel(scores)
    % non-maximum suppression
    view_num = numel(cads{k}(1).parts2d);
    score = scores{k}{end};
    for v = 1:view_num
        mask = non_maximum_suppression(score(:,:,v));
        score(:,:,v) = score(:,:,v) .* mask;
    end
    m = size(score, 1);
    n = size(score, 2);

    s = score(:);
    [~, index] = sort(s, 'descend');

    % extract labels
    part_num = numel(cads{k}(1).pnames);
    for i = 1:N
        ind = index(i) - 1;
        if s(index(i)) == 0
            break;
        end
        pv = floor(ind / (m*n)) + 1;
        r = mod(ind, m*n);
        % select the top K viewpoints
        px = floor(r / m) + 1;
        py = mod(r, m) + 1;

        y(count).object_label = 1;
        y(count).cad_label = k;
        y(count).view_label = pv;
        part_label = zeros(part_num, 2);
        part_label = mcmc_label_from_backtrace(trees{k}{1}(pv).root_index, px-1, py-1, ...
            trees{k}{1}(pv), part_label, sbin, padx, pady);
        y(count).part_label = part_label;
        y(count).occlusion = [];
        y(count).bbox = mcmc_compute_bbox(pv, part_label, cads{k}(1));
        y(count).energy = s(index(i));
        % store the scores of aspectlets
        y(count).scores = zeros(numel(cads{k}),1);
        for j = 1:numel(cads{k})
            y(count).scores(j) = scores{k}{j}(py,px,pv);
        end
        count = count + 1;
    end    
end

% do nms according to bounding box overlap
num = numel(y);
% sort examples
p = zeros(num, 1);
for i = 1:num
    p(i) = y(i).energy;
end
[~,index] = sort(p, 'descend');
y = y(index);

flag = zeros(num, 1);
for i = 1:num
    flag(i) = 1;
    for j = 1:i-1
        o = box_overlap(y(i).bbox, y(j).bbox);
        if flag(j) > 0 && o >= 0.5
            flag(i) = 0;
        end
    end
end
y = y(flag > 0);