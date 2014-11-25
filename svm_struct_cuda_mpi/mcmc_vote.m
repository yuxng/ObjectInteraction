function scores = mcmc_vote(labels, trees, cads, models)

cad_num = numel(cads);
H = ones(3, 3);
sbin = 6;
[padx, pady] = get_padding(cads);
scores = cell(cad_num, 1);
for i = 1:cad_num
    cad_parent = cads{i}(1);
    a = cad_parent.azimuth;
    e = cad_parent.elevation;
    d = cad_parent.distance;

    % for each aspectlet
    num = numel(cads{i});
    scores{i} = cell(num+1,1);
    for j = 1:num
        label = labels{i}{j};
        tree = trees{i}{j};
        score = zeros(size(tree(1).root_score));
        cad = cads{i}(j);
        % each label votes
        for k = 1:numel(label)
            % find corresponding view label
            view_label = label(k).view_label;
            azimuth = cad.parts2d(view_label).azimuth;
            elevation = cad.parts2d(view_label).elevation;
            distance = cad.parts2d(view_label).distance;
            aind = find(a == azimuth)-1;
            eind = find(e == elevation)-1;
            dind = find(d == distance)-1;
            view_label = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;            

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
                s = exp(label(k).energy / models{i}.loss_value);
                score(py, px) = score(py, px) + s;
            end
        end
        % mean filtering and normalization
        score = imfilter(score, H);
        s = sum(sum(score));
        if s ~= 0
            score = score ./ s;
        end

        scores{i}{j} = score;
    end
    % combine scores
    scores{i}{num+1} = scores{i}{1};
    for j = 2:num
        scores{i}{num+1} = scores{i}{num+1} + scores{i}{j};
    end

    % normalization
    s = sum(sum(scores{i}{num+1}));
    if s ~= 0
        scores{i}{num+1} = scores{i}{num+1} ./ s;
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