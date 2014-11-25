% vertices: points in 3D
% P: fitted plane in 3D
% C: rectangle center in 3D
% xaxis: the direction of largest variance of vertices
% yaxis: the direction of second largest variance of vertices
% F: constructed part face in 3D
function [F, P, C, xaxis, yaxis] = ...
    fit_plane(vertices, shinkage_width, shinkage_height, part_direction, partition, indicator)

% linear regression to fit a 2D plane
nv = size(vertices, 1);
vertices_homo = [vertices ones(nv, 1)];
[~,~,V] = svd(vertices_homo);
P = V(:,end);

angle = acos(dot(P(1:3), part_direction) / norm(P(1:3)));
if angle > pi/2
    P = -1 * P;
end

% project vertices to the plane
pnorm2 = P(1:3)'*P(1:3);
pvertices = zeros(nv, 3);
for i = 1:nv
    pvertices(i,:) = vertices(i,:) - ((vertices_homo(i,:)*P)/pnorm2)*P(1:3)';
end

% build a local coordinate system in the plane
origin = -(P(4)/pnorm2)*P(1:3)';
center = mean(pvertices);
temp = zeros(nv, 3);
for i = 1:nv
    temp(i,:) = pvertices(i,:) - center;
end
[~, ~, V] = svd(temp);
xaxis = V(:,1)';
yaxis = V(:,2)';

% form a right hand coordinate system
zaxis = cross(xaxis, yaxis);
if acos(dot(zaxis, P(1:3)/norm(P(1:3)))) > acos(dot(-zaxis, P(1:3)/norm(P(1:3))))
    xaxis = -1 * xaxis;
end

% represent points in the plane using the local coordinates
v2d = zeros(nv, 2);
for i = 1:nv
    v2d(i,1) = dot(pvertices(i,:) - origin, xaxis);
    v2d(i,2) = dot(pvertices(i,:) - origin, yaxis);
end

% bounding box in the plane
center = [(min(v2d(:,1))+max(v2d(:,1)))/2, (min(v2d(:,2))+max(v2d(:,2)))/2];
width = (max(v2d(:,1)) - min(v2d(:,1))) * shinkage_width;
height = (max(v2d(:,2)) - min(v2d(:,2))) * shinkage_height;

r1 = center + [-width/2 -height/2];
r2 = center + [width/2 -height/2];
r3 = center + [width/2 height/2];
r4 = center + [-width/2 height/2];

% find the 3d corrdinates of the 4 cornors of the rectangle
p1 = r1(1)*xaxis + r1(2)*yaxis + origin;
p2 = r2(1)*xaxis + r2(2)*yaxis + origin;
p3 = r3(1)*xaxis + r3(2)*yaxis + origin;
p4 = r4(1)*xaxis + r4(2)*yaxis + origin;

% find the 3d coordinates of the rectangle center
C = cell(1+sum(indicator), 1);
C{1} = center(1)*xaxis + center(2)*yaxis + origin;

% build the face
F = cell(1+sum(indicator), 1);
F{1} = [p1; p2; p3; p4; p1];

% build sub-parts
w = width / partition(1);
h = height / partition(2);
x0 = r1(1);
y0 = r1(2);
count = 1;
for i = 1:partition(1)
    for j = 1:partition(2)
        if indicator((i-1)*partition(2)+j) == 0
            continue;
        end
        x = x0 + (i-1) * w;
        y = y0 + (j-1) * h;
        
        r1 = [x y] + [0 0];
        r2 = [x y] + [w 0];
        r3 = [x y] + [w h];
        r4 = [x y] + [0 h];
        center = [x y] + [w/2 h/2];
        
        % find the 3d corrdinates of the 4 cornors of the rectangle
        p1 = r1(1)*xaxis + r1(2)*yaxis + origin;
        p2 = r2(1)*xaxis + r2(2)*yaxis + origin;
        p3 = r3(1)*xaxis + r3(2)*yaxis + origin;
        p4 = r4(1)*xaxis + r4(2)*yaxis + origin;

        count = count + 1;
        % find the 3d coordinates of the rectangle center
        C{count} = center(1)*xaxis + center(2)*yaxis + origin;

        % build the face
        F{count} = [p1; p2; p3; p4; p1]; 
    end
end