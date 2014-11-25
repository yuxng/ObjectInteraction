function cad_voxel = voxelize(cls, cad)

delta = 0.05;
alpha = 0;
R = [cosd(alpha) -sind(alpha) 0; sind(alpha) cosd(alpha) 0; 0 0 1];
T = [0; 0; 0];

% extract plane for aspect parts
switch cls
    case 'car'
        N = 11;
        threshold = 0;
        num = 1;
        planes = cell(num, 1);
        
        zmin = inf;
        index = find(cad.roots == 1);
        n = numel(index);
        P = zeros(n+1, 4);
        for i = 1:n
            P(i,1:3) = (R * cad.parts(index(i)).plane(1:3))';
            % rotate and sift
            F = cad.parts(index(i)).vertices;
            F = R*F' + repmat(T, 1, 5);
            P(i,4) = -P(i,1:3)*F(:,1);            
            zmin = min(zmin, min(F(3,:)));
        end
        P(n+1,:) = [0 0 -1 zmin];
        planes{1} = P;
        rescale = 1;
    case 'bed'
        N = 15;
        threshold = 0;
        num = 2;
        planes = cell(num, 1);
        
        zmin = inf;
        index = find(cad.roots == 1);
        n = numel(index);
        P = zeros(n+1, 4);
        for i = 1:n
            P(i,1:3) = (R * cad.parts(index(i)).plane(1:3))';
            % rotate and sift
            F = cad.parts(index(i)).vertices;
            F = R*F' + repmat(T, 1, 5);
            P(i,4) = -P(i,1:3)*F(:,1);            
            zmin = min(zmin, min(F(3,:)));
            
            if strcmp(cad.pnames{index(i)}, 'back') == 1
                P(i,:) = -1 * P(i,:);
            end
        end
        P(n+1,:) = [0 0 -1 zmin];
        planes{1} = P;
        
        % planes for the back of bed
        index = strcmp('back', cad.pnames) == 1;
        planes{2} = build_planes(cad.parts(index), delta, R, T);
        rescale = 1;
    case {'chair', 'sofa'}
        N = 15;
        threshold = 0;
        index = find(cad.roots == 1);
        num = numel(index);
        planes = cell(num, 1);
        for i = 1:num
            planes{i} = build_planes(cad.parts(index(i)), delta, R, T);
        end
        if strcmp(cls, 'chair') == 1
            rescale = 0.4;
        else
            rescale = 0.6;
        end
    case 'table'
        N = 15;
        threshold = -0.01;
        index = find(cad.roots == 1);
        num = numel(index);
        planes = cell(num, 1);
        for i = 1:num
            planes{i} = build_planes(cad.parts(index(i)), delta, R, T);
        end        
        rescale = 0.6;
end

interval = 1/N;
voxel = zeros(N, N, N);

T = [0.5; 0.5; 0.5];
R = [1 0 0; 0 0 1; 0 -1 0];

for k = 1:N
    z = (k-0.5)*interval;
    for i = 1:N
        x = (i-0.5)*interval;
        for j = 1:N
            y = (j-0.5)*interval;
            % coordinate transform
            X = R*([x; y; z] - T);
            % test if X is inside the object
            for t = 1:num
                P = planes{t};
                d = P*[X; 1];
                if isempty(find(d > threshold, 1)) == 1
                    voxel(j,i,k) = 1;
                    break;
                end
            end
        end
    end
end

cad_voxel.voxel = voxel;
cad_voxel.planes = planes;
cad_voxel.threshold = threshold;
cad_voxel.recale = rescale;

% build index
index = find(voxel == 1);
num = numel(index);
voxel_index = zeros(num, 3);
for i = 1:num
    ind = index(i) - 1;
    z = floor(ind / (N*N)) + 1;
    r = mod(ind, N*N);
    x = floor(r / N) + 1;
    y = mod(r, N) + 1;
    voxel_index(i,:) = [y x z];
end
cad_voxel.index = voxel_index;

function P = build_planes(part, delta, R, T)

plane = part.plane;
vertices = part.vertices;
center = part.center;

% rotate and shift
plane(1:3) = R * plane(1:3);
F = vertices;
F = R*F' + repmat(T, 1, 5);
plane(4) = -plane(1:3)'*F(:,1);
vertices = F';
center = (R*center' + T)';

P = zeros(6, 4);
% shift the plane
P(1,:) = [plane(1:3)' plane(4)+delta];
if P(1,:) * [center'; 1] > 0
    P(1,:) = -1 * P(1,:);
end

P(2,:) = [plane(1:3)' plane(4)-delta];
if P(2,:) * [center'; 1] > 0
    P(2,:) = -1 * P(2,:);
end

% shift the vertices
vertices_up = vertices(1:4,:) + delta * repmat(plane(1:3)', 4, 1);
vertices_down = vertices(1:4,:) - delta * repmat(plane(1:3)', 4, 1);

V = zeros(4, 4);
% plane 1
V(1,:) = [vertices_up(1,:) 1];
V(2,:) = [vertices_up(2,:) 1];
V(3,:) = [vertices_down(1,:) 1];
V(4,:) = [vertices_down(2,:) 1];
[~,~,v] = svd(V);
P(3,:) = v(:,end);
if P(3,:) * [center'; 1] > 0
    P(3,:) = -1 * P(3,:);
end

% plane 2
V(1,:) = [vertices_up(2,:) 1];
V(2,:) = [vertices_up(3,:) 1];
V(3,:) = [vertices_down(2,:) 1];
V(4,:) = [vertices_down(3,:) 1];
[~,~,v] = svd(V);
P(4,:) = v(:,end);
if P(4,:) * [center'; 1] > 0
    P(4,:) = -1 * P(4,:);
end

% plane 3
V(1,:) = [vertices_up(3,:) 1];
V(2,:) = [vertices_up(4,:) 1];
V(3,:) = [vertices_down(3,:) 1];
V(4,:) = [vertices_down(4,:) 1];
[~,~,v] = svd(V);
P(5,:) = v(:,end);
if P(5,:) * [center'; 1] > 0
    P(5,:) = -1 * P(5,:);
end

% plane 4
V(1,:) = [vertices_up(4,:) 1];
V(2,:) = [vertices_up(1,:) 1];
V(3,:) = [vertices_down(4,:) 1];
V(4,:) = [vertices_down(1,:) 1];
[~,~,v] = svd(V);
P(6,:) = v(:,end);
if P(6,:) * [center'; 1] > 0
    P(6,:) = -1 * P(6,:);
end