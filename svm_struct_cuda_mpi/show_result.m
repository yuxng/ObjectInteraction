function show_result(I, cads, y)

N = numel(y);

figure(1);
cla;
imshow(I);
hold on;
for i = 1:N
    bbox_pr = y(i).bbox;
    bbox_pr(1) = max(bbox_pr(1), 1);
    bbox_pr(2) = max(bbox_pr(2), 1);
    bbox_pr(3) = min(bbox_pr(3), size(I, 2));
    bbox_pr(4) = min(bbox_pr(4), size(I, 1));
    
    cad = cads{y(i).cad_label}(1);
    pnames = cad.pnames;
    part_num = numel(pnames);
    view_label = y(i).view_label;
    part2d = cad.parts2d(view_label);
    
    fprintf('object %d, a=%.2f, e=%.2f, d=%.2f, energy=%e\n', i, ...
        part2d.azimuth, part2d.elevation, part2d.distance, y(i).energy);

    for a = 1:part_num
        if isempty(part2d.homographies{a}) == 0
            plot(y(i).part_label(a,1), y(i).part_label(a,2), 'ro');
            % render parts
            part = part2d.(pnames{a}) + repmat([y(i).part_label(a,1), y(i).part_label(a,2)], 5, 1);
            patch('Faces', [1 2 3 4 5], 'Vertices', part, 'EdgeColor', 'r', 'FaceColor', 'r', 'FaceAlpha', 0.1);           
        end
    end
    % draw bounding box
    bbox_draw = [bbox_pr(1), bbox_pr(2), bbox_pr(3)-bbox_pr(1), bbox_pr(4)-bbox_pr(2)];
    % compute line width
    rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth', y(i).energy/400+3);
    pause;
    hold off;
    imshow(I);
    hold on;
end

hold off;