function draw_parts_front(cad)

parts2d_front = cad.parts2d_front;
figure;
axis equal;
M = numel(parts2d_front);
root_index = find(cad.roots == -1);

for k = 1:numel(root_index)
    hold on;
    for i = 1:M
        if i == root_index(k) || cad.roots(i) == root_index(k)
            disp(i);
            center = parts2d_front(i).center;
            part = parts2d_front(i).vertices;
            part = part + repmat(center, size(part,1), 1);
            set(gca,'YDir','reverse');
            patch(part(:,1), part(:,2), 'r', 'FaceAlpha', 0.1);
            plot(center(1), center(2), 'o');
            pause;
        end
    end
    pause;
    clf;
    axis equal;
    hold on;    
end