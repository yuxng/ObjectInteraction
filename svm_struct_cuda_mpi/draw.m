% display a set of CAD models
function draw(I, cads, O, C, alpha, cad_label, example)

figure(1);
% plot 2D
subplot(1,2,1);
imshow(I);
hold on;

num = numel(example);
for i = 1:num
    cad = cads{example(i).cad_label}(example(i).aspectlet_label);
    view_label = example(i).view_label;
    pnames = cad.pnames;
    part_num = numel(pnames);
    part2d = cad.parts2d(view_label);

    for j = 1:part_num
        if isempty(part2d.homographies{j}) == 0
            c = example(i).part_label(j,:);
            % render parts
            part = part2d.(pnames{j}) + repmat(c, 5, 1);
            patch('Faces', [1 2 3 4 5], 'Vertices', part, 'EdgeColor', 'r', 'FaceColor', 'r', 'FaceAlpha', 0.1);           
        end
    end
    
    % draw bounding box
    bbox_pr = example(i).bbox;
    bbox_draw = [bbox_pr(1), bbox_pr(2), bbox_pr(3)-bbox_pr(1), bbox_pr(4)-bbox_pr(2)];
    rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth',2);
    text(bbox_pr(1), bbox_pr(2), num2str(i), 'BackgroundColor', 'r');
    fprintf('2D object %d, model=%d, a=%.2f, e=%.2f, d=%.2f, energy=%e\n', i, ...
        example(i).aspectlet_label, part2d.azimuth, part2d.elevation, part2d.distance, example(i).energy);
    pause;
end
hold off;

% plot 3D
subplot(1,2,2);
cla;
hold on;

num = size(O,2);
for i = 1:num
    model = cads{cad_label(i)}(1);
    parts = model.parts;
    % rotation matrix
    alpha(i) = -1 * alpha(i);
    R = [cos(alpha(i)) -sin(alpha(i)) 0; sin(alpha(i)) cos(alpha(i)) 0; 0 0 1];

    for j = 1:numel(parts)
        F = parts(j).vertices;
        % rotate 
        F = (R*F')';        
        % shift
        F = F + repmat(O(:,i)', 5, 1);
        if model.roots(j) == 0
            patch(F(:,1), F(:,2), F(:,3), 'r', 'FaceAlpha', 0.5);
        end
    end
    fprintf('3D object %d, (%.2f, %.2f, %.2f), alpha=%.2f, cad_label=%d\n', i, ...
        O(1,i), O(2, i), O(3,i), alpha(i)*180/pi, cad_label(i));
end
fprintf('camera: %.2f, %.2f, %.2f\n', C(1), C(2), C(3));
plot3(C(1), C(2), C(3), 'o', 'LineWidth', 5);
axis equal;
axis tight;
xlabel('x');
ylabel('y');
zlabel('z');
hold off;

view(45, 30);