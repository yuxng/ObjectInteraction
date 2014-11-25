function scores = mcmc_vote_view(labels, trees, cads, models)

cad_num = numel(cads);
sbin = 6;
[padx, pady] = get_padding(cads);
weights = get_weights(cads);
scores = cell(cad_num, 1);

for i = 1:cad_num
    cad_parent = cads{i}(1);
    view_num = numel(cad_parent.parts2d);

    % for each aspectlet
    num = numel(cads{i});
    scores{i} = cell(num+1,1);
    for j = 1:num
        label = labels{i}{j};
        
        if j == 1
            % do nms according to bounding box overlap for chair
            example = label;
            n = numel(example);
            flag = zeros(n, 1);

            for ii = 1:n
                flag(ii) = 1;
                for jj = 1:ii-1
                    o = box_overlap(example(ii).bbox, example(jj).bbox);
                    if flag(jj) > 0 && o >= 0.5
                        flag(ii) = 0;
                        break;
                    end
                end
            end
            label = example(flag > 0);   
        end
        
        tree = trees{i}{j};
        score = zeros([size(tree(1).root_score) view_num]);
        cad = cads{i}(j);
        % each label votes
        for k = 1:numel(label)
            % find corresponding view label
            view_label = cad.vcor(label(k).view_label);
            % construct part label for parent
            part_label = label(k).part_label;
            part = [];
            for l = 1:size(part_label, 1)
                if cad.roots(l) == 0 && part_label(l,1) ~= 0
                    part.(cad.pnames{l}) = part_label(l,:);
                end
            end
            % predict the root center
            center = predicate_root_center(part, cad_parent, view_label);
            center = center + [padx pady];

            px = floor(center(1)/sbin)+1;
            py = floor(center(2)/sbin)+1;
            if px >= 1 && px <= size(score, 2) && py >= 1 && py <= size(score, 1)
                % voting score
                % s = exp(10 * label(k).energy / models{i}.loss_value);
                s = exp(100 * label(k).energy / models{i}.loss_value);
                score(py, px, view_label) = score(py, px, view_label) + s;
            end
        end
        % set background probability
        score(score == 0) = exp(-20);
        % normalization
        s = sum(sum(sum(score)));
        if s ~= 0
            score = score ./ s;
        end        
        scores{i}{j} = score;
    end
    % combine scores
    scores{i}{num+1} = zeros(size(scores{i}{1}));
    w = weights{i};
    for j = 1:num
        scores{i}{num+1} = scores{i}{num+1} + w(j).*scores{i}{j};
    end
end
    
% predicate the root center according part center locations
function [center, root_index] = predicate_root_center(part, cad, view_label)

part2d = cad.parts2d(view_label);
pnames = cad.pnames;

for i = numel(pnames):-1:1
    if part2d.centers(i,1) ~= 0
        root_index = i;
        cx2 = part2d.centers(i,1);
        cy2 = part2d.centers(i,2);
        break;
    end
end

center = [0 0];
count = 0;
for i = 1:numel(cad.parts)
    if part2d.centers(i,1) ~= 0 && isfield(part, pnames{i}) == 1 && part.(pnames{i})(1) ~= 0
        cx1 = part2d.centers(i,1);
        cy1 = part2d.centers(i,2);
        dc = sqrt((cx1-cx2)*(cx1-cx2) + (cy1-cy2)*(cy1-cy2));
        ac = atan2(cy2-cy1, cx2-cx1);        
        
        x = part.(pnames{i})(1);
        y = part.(pnames{i})(2);
        
        count = count + 1;
        center(1) = center(1) + x + dc*cos(ac);
        center(2) = center(2) + y + dc*sin(ac);
    end
end
center = center ./ count;