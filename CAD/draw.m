% display a CAD model

function draw(model, aspectlet)

if nargin == 1
    aspectlet = [];
end
color = ['r','y','b','c','w','m'];
parts = model.parts;

figure(1);
cla;
hold on;
count_color = 0;
for i = 1:numel(parts)
    if model.roots(i) == 1
        count_color = count_color + 1;
        col = color(count_color);
    end
    if model.roots(i) == 0
        F = parts(i).vertices;
        if isempty(aspectlet) == 0 && isempty(find(aspectlet.cor == i, 1)) == 0
            patch(F(:,1), F(:,2), F(:,3), 'b', 'FaceAlpha', 0.5);
        else
            patch(F(:,1), F(:,2), F(:,3), 'r', 'FaceAlpha', 0.5);
        end
    end
%     center = parts(i).center;
%     plot3(center(1), center(2), center(3), 'o');
%     text(center(1), center(2), center(3), num2str(i));
end
axis equal;
axis tight;
axis off;
% xlabel('x');
% ylabel('y');
% zlabel('z');
if isempty(aspectlet) == 0
    ind = round(numel(aspectlet.parts2d) / 3);
    a = aspectlet.parts2d(ind).azimuth;
    e = min(aspectlet.parts2d(ind).elevation + 10, 30);
    view(a, e);
else
    view(340, 30);
end