function draw_aspectlets_index(cad, aspectlets)

parts =cad.parts;

for k = 1:size(aspectlets, 1)
    disp(k);
    figure(1);
    cla;
    hold on;
    index = find(aspectlets(k,:) == 1);
    for i = 1:numel(index)
        ind = index(i);
        F = parts(ind).vertices;
        patch(F(:,1), F(:,2), F(:,3), 'r', 'FaceAlpha', 0.5);
    %     center = parts(i).center;
    %     plot3(center(1), center(2), center(3), 'o');
    end
    axis equal;
    axis tight;
    % xlabel('x');
    % ylabel('y');
    % zlabel('z');
    view(330, 30);
    axis off;
    pause;
end