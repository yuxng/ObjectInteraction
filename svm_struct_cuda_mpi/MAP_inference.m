function y = MAP_inference(tree, cad)

energy = -inf;
for i = 1:numel(tree)
    view = tree{i};
    for j = 1:numel(view)
        [a, b] = max(view(j).root_score);
        [c, d] = max(a);
        if(c > energy)
            px = d;
            py = b(d);
            cad_label = i;
            view_label = j;
            energy = c;
        end
    end
end
fprintf('px=%d, py=%d\n', px, py);
% compute part label
part_num = numel(cad{cad_label}.pnames);
part_label = zeros(part_num, 2);
index = tree{cad_label}(view_label).root_index;
sbin = 6;
[padx, pady] = get_padding(cad);
part_label = label_from_backtrace(index, px-1, py-1, tree{cad_label}(view_label), part_label, sbin, padx, pady);

% compute bounding box
bbox = compute_bbox(view_label, part_label, cad{cad_label});

y.object_label = 1;
y.cad_label = cad_label;
y.view_label = view_label;
y.part_label = part_label;
y.energy = energy;
y.bbox = bbox;

function part_label = label_from_backtrace(index, px, py, view, part_label, sbin, padx, pady)

if index == view.root_index
    xmax = px;
    ymax = py;
else
    xmax = view.parts(index).location(py, px, 1);
    ymax = view.parts(index).location(py, px, 2);
end
part_label(index, 1) = sbin*xmax + sbin/2 - padx;
part_label(index, 2) = sbin*ymax + sbin/2 - pady;

for i = 1:numel(view.parts(index).children)
    child = view.parts(index).children(i);
    part_label = label_from_backtrace(child, xmax+1, ymax+1, view, part_label, sbin, padx, pady);
end

function bbox = compute_bbox(view_label, part_label, cad)

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