function bbox = mcmc_compute_bbox(view_label, part_label, cad)

pnames = cad.pnames;
part_num = numel(pnames);

part2d = cad.parts2d(view_label);
x1 = inf;
x2 = -inf;
y1 = inf;
y2 = -inf;

for i = 1:part_num
    if part_label(i,1) ~= 0
        part_shape = part2d.(pnames{i}) + repmat(part_label(i,:), 5, 1);
        x1 = min(x1, min(part_shape(:,1)));
        x2 = max(x2, max(part_shape(:,1)));
        y1 = min(y1, min(part_shape(:,2)));
        y2 = max(y2, max(part_shape(:,2)));
    end
end

bbox(1) = x1;
bbox(2) = y1;
bbox(3) = x2;
bbox(4) = y2;