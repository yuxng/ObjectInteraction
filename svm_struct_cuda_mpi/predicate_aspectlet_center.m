% predicate the aspectlet center according the root center locations
function center = predicate_aspectlet_center(root_center, cor, cad, view_label)

part2d = cad.parts2d(view_label);
pnames = cad.pnames;
part_num = numel(pnames);

for i = part_num:-1:1
    if part2d.centers(i,1) ~= 0
        cx1 = part2d.centers(i,1);
        cy1 = part2d.centers(i,2);
        break;
    end
end

part_label = zeros(part_num, 2);
for i = 1:part_num
    if part2d.centers(i,1) ~= 0 && isempty(find(cor == i, 1)) == 0
        cx2 = part2d.centers(i,1);
        cy2 = part2d.centers(i,2);
        dc = sqrt((cx1-cx2)*(cx1-cx2) + (cy1-cy2)*(cy1-cy2));
        ac = atan2(cy2-cy1, cx2-cx1);        
        
        x = root_center(1);
        y = root_center(2);
        
        part_label(i,1) = x + dc*cos(ac);
        part_label(i,2) = y + dc*sin(ac);
    end
end

bbox = mcmc_compute_bbox(view_label, part_label, cad);
center = [(bbox(1)+bbox(3))/2 (bbox(2)+bbox(4))/2];