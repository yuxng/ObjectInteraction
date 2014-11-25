% render a CAD model according to viewpoint azimuth a, elevation e and distance d
% parts: project part shape in 2D, may contains multiple polygons
% occluded: occluded percentages for parts
% parts_unoccluded: project part shape without considering self-occlusion
function [parts, occluded, parts_unoccluded] = render(cls, model, a, e, d)

P = projection(a, e, d);
parts3d = model.parts;
N = numel(parts3d);
parts2d = cell(N, 1);

% perspective mapping
for i = 1:N
    F = parts3d(i).vertices;
    plane = parts3d(i).plane;
    center = parts3d(i).center;
    
    % rotate legs of a chair to face the viewpoint
    if (strcmp(cls, 'chair') == 1 && i > 10) || (strcmp(cls, 'table') == 1 && i > 5)
        T = [1 0 0 -center(1); 0 1 0 -center(2); 0 0 1 -center(3); 0 0 0 1];
        alpha = atan2(plane(1), -plane(2));
        theta = a*pi/180 - alpha;
        u = parts3d(i).xaxis;
        if u(3) < 0
            u = -1 * u;
        end
        % rotation matrix
        Rz = [cos(theta)+u(1)*u(1)*(1-cos(theta)) u(1)*u(2)*(1-cos(theta))-u(3)*sin(theta) u(1)*u(3)*(1-cos(theta))+u(2)*sin(theta) center(1); ...
              u(2)*u(1)*(1-cos(theta))+u(3)*sin(theta) cos(theta)+u(2)*u(2)*(1-cos(theta)) u(2)*u(3)*(1-cos(theta))-u(1)*sin(theta) center(2); ...
              u(3)*u(1)*(1-cos(theta))-u(2)*sin(theta) u(3)*u(2)*(1-cos(theta))+u(1)*sin(theta) cos(theta)+u(3)*u(3)*(1-cos(theta)) center(3); ...
              0 0 0 1];
        % rotate the face
        part = Rz*T*[F ones(size(F,1), 1)]';
        part = part(1:3,:)';
        % rotate the plane
        plane = inv(Rz*T)'*plane;
        part = P*[part ones(size(part,1), 1)]';
    else
        part = P*[F ones(size(F,1), 1)]';
    end
    part(1,:) = part(1,:) ./ part(4,:);
    part(2,:) = part(2,:) ./ part(4,:);
    part(3,:) = part(3,:) ./ part(4,:);
    parts3d(i).vertices = part(1:3,:)';
    parts3d(i).plane = inv(P)'*plane;
    center = P*[center, 1]';
    center = center ./ center(4);
    parts3d(i).center = center(1:3)';
    parts2d{i} = part(1:2,:)';
end

% build the unoccluded parts
parts_unoccluded(N).x = [];
parts_unoccluded(N).y = [];
parts_unoccluded(N).center = [];
for i = 1:N
    parts_unoccluded(i).x = parts2d{i}(:,1);
    parts_unoccluded(i).y = parts2d{i}(:,2);
    parts_unoccluded(i).center = parts3d(i).center(1:2);
end

% convert polygon contour to clockwise vertex ordering
for i = 1:N
    [parts2d{i}(:,1), parts2d{i}(:,2)] = poly2cw(parts2d{i}(:,1), parts2d{i}(:,2));
end

% handle self occlusion
% test polygon intersection
intersect = zeros(N, N);
for i = 1:N
    if model.roots(i) ~= 0
        continue;
    end
    for j = i+1:N
        if model.roots(j) ~= 0
            continue;
        end
        x1 = parts2d{i}(1,1);
        y1 = parts2d{i}(1,2);
        x2 = parts2d{j}(1,1);
        y2 = parts2d{j}(1,2);        
        [x3, y3] = polyxpoly(parts2d{i}(:,1), parts2d{i}(:,2), parts2d{j}(:,1), parts2d{j}(:,2));
        if isempty(x3) == 0
            x = x3;
            y = y3;
        elseif inpolygon(x1, y1, parts2d{j}(:,1), parts2d{j}(:,2))
            x = x1;
            y = y1;
        elseif inpolygon(x2, y2, parts2d{i}(:,1), parts2d{i}(:,2))
            x = x2;
            y = y2;
        else
            continue;     % no intersection between part i and part j
        end
        intersect(i,j) = 1;
        intersect(j,i) = -1;
        % compute depthes of (x,y) in part plane i and j
        planei = parts3d(i).plane;
        planej = parts3d(j).plane;  

        diff = zeros(1,numel(x));
        for k = 1:numel(x)
            % compute depth
            zi = (-x(k)*planei(1)-y(k)*planei(2)-planei(4))/planei(3);
            zj = (-x(k)*planej(1)-y(k)*planej(2)-planej(4))/planej(3);
            diff(k) = zi - zj;
        end
        [~,ind] = max(abs(diff));
        if diff(ind) > 0
            intersect(i,j) = 1;   % part i occludes part j
            intersect(j,i) = -1;
        else
            intersect(i,j) = -1;  % part j occludes part i
            intersect(j,i) = 1;
        end            
    end
end

% build unoccluded polygon for each part
parts(N).x = [];
parts(N).y = [];
parts(N).center = [];
for i = 1:N
    parts(i).x = parts2d{i}(:,1);
    parts(i).y = parts2d{i}(:,2);
    parts(i).center = parts3d(i).center(1:2);  
    for j = 1:N
        if intersect(i,j) == -1 && isempty(parts(i).x) == 0 && isempty(parts(i).y) == 0
            [parts(i).x, parts(i).y] = polybool('subtraction', parts(i).x, parts(i).y, parts2d{j}(:,1), parts2d{j}(:,2));
        end
    end
end

% compute occluded percentage
occluded = zeros(N, 1);
for i = 1:N
    if model.roots(i) ~= 0
        continue;
    end    
    area = polyarea(parts2d{i}(:,1), parts2d{i}(:,2));
    area_new = 0;
    if isShapeMultipart(parts(i).x, parts(i).y)
        [xcells, ycells] = polysplit(parts(i).x, parts(i).y);
    else
        xcells = cell(1,1);
        ycells = cell(1,1);
        xcells{1} = parts(i).x;
        ycells{1} = parts(i).y;
    end
    for j = 1:numel(xcells)
        area_new = area_new + polyarea(xcells{j}, ycells{j});
    end
    occluded(i) = (area - area_new) / area;
end
%display
% figure;
% axis equal;
% xlabel('x');
% ylabel('y');
% zlabel('z');
% % hold on;
% for i = 1:N
%     if isShapeMultipart(parts(i).x, parts(i).y)
%         [xcells, ycells] = polysplit(parts(i).x, parts(i).y);
%         for j = 1:numel(xcells)
%             patch(xcells{j}, ycells{j}, 'r');
%         end
%     else
%         patch(parts(i).x, parts(i).y, 'r');
%     end
% end