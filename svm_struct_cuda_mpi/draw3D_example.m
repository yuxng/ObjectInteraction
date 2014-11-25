% display a set of CAD models
function draw3D_example(I, cads, sample, example, index_show)

if nargin < 5
    index_show = 1:size(sample.O,2);
else
    index_show = sample.flag(index_show);
    index_show(index_show == 0) = [];
end

O = sample.O;
C = sample.C;
alpha = sample.alpha;
center = sample.center;
cad_label = sample.cad_label;
flag = sample.flag;

[par.padx, par.pady] = get_padding(cads);
par.width = size(I, 2);
par.height = size(I, 1);

num = size(O,2);
figure(1);
% plot 2D
% subplot(1,2,1);
imshow(I);
hold on;

% compute projection matrix
a = atan2(C(1), -C(2));
if a < 0
    a = a + 2*pi;
end
d = norm(C);
e = asin(C(3) / d);
P = projection(a*180/pi, e*180/pi, d);

fprintf('center = (%.2f,%.2f)\n', center(1), center(2));
o = zeros(2, num);
for i = 1:num
    if isempty(find(index_show == i, 1)) == 1
        continue;
    end
    cad = cads{cad_label(i)}(1);
    tmp = find(flag == i);
    index = find(sample.index == tmp);
    view_label = example(index).view_label;
    
    % find the image 2D location
    viewport = cads{cad_label(i)}(1).parts2d(view_label).viewport;
    x = P([1 2 4], :) * [O(:,i); 1];
    x = x ./ x(3);
    x = x(1:2);
    x = x * viewport;
    x(2) = -1 * x(2);
    o(:,i) = x + center';
    o(:,i) = o(:,i) + [par.padx; par.pady];
    
    fprintf('Object %d, o=(%.2f,%.2f), energy = %f\n', i, o(1,i), o(2,i), example(index).energy);
    
    pnames = cad.pnames;
    part_num = numel(pnames);
    part2d = cad.parts2d(view_label);

    x1 = inf;
    x2 = -inf;
    y1 = inf;
    y2 = -inf;
    for j = 1:part_num
        if cad.roots(j) >= 0 && isempty(part2d.homographies{j}) == 0
            c = example(index).part_label(j,:);
            % render parts
            part_shape = part2d.(pnames{j}) + repmat(c, 5, 1);
            patch('Faces', [1 2 3 4 5], 'Vertices', part_shape, 'EdgeColor', 'r', 'FaceColor', 'r', 'FaceAlpha', 0.1);           
            x1 = min(x1, min(part_shape(:,1)));
            x2 = max(x2, max(part_shape(:,1)));
            y1 = min(y1, min(part_shape(:,2)));
            y2 = max(y2, max(part_shape(:,2)));            
        end
    end
    bbox = example(index).bbox;
    bbox = [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)];
    rectangle('Position', bbox, 'EdgeColor', 'g', 'LineWidth', 2);
    text(bbox(1), bbox(2), num2str(index), 'BackgroundColor', 'r');
%     pause;
%     hold off;
%     imshow(I);
end
hold off;

% plot 3D
%subplot(1,2,2);
figure(2);
cla;
hold on;

for i = 1:num
    if isempty(find(index_show == i, 1)) == 1
        continue;
    end    
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
    fprintf('object %d, (%.2f, %.2f, %.2f), alpha=%.2f, cad_label=%d\n', i, ...
        O(1,i), O(2, i), O(3,i), alpha(i)*180/pi, cad_label(i));
end

% draw the camera
theta = atan2(C(1), -C(2));
R = angle2dcm(theta, 0*pi/180, -90*pi/180);
R_c2w = inv(R);
T_c2w = C;
CameraVertex = zeros(5,3);
CameraVertex(1,:) = [0 0 0];
CameraVertex(2,:) = [-0.15  0.15  0.50];
CameraVertex(3,:) = [ 0.15  0.15  0.50];
CameraVertex(4,:) = [-0.15 -0.15  0.50];
CameraVertex(5,:) = [ 0.15 -0.15  0.50];
CameraVertex = ([R_c2w T_c2w]*[(CameraVertex');ones(1,5)])';
IndSetCamera = {[1 2 3 1] [1 4 2 1] [1 5 4 1] [1 5 3 1] [2 3 5 4 2]};
for iter_indset = 1:length(IndSetCamera)
    patch('Faces', IndSetCamera{iter_indset}, 'Vertices', CameraVertex, 'FaceColor', 'b', 'FaceAlpha', 0.5);           
end

fprintf('camera: %.2f, %.2f, %.2f\n', C(1), C(2), C(3));
% plot3(C(1), C(2), C(3), 'o', 'LineWidth', 1);
axis equal;
axis tight;
xlabel('x');
ylabel('y');
zlabel('z');
hold off;
view(45, 30);

% occlusion mask
figure(3);

% find object 2D distances
view_label = zeros(num, 1);
distance = zeros(num, 1);
energy = zeros(num, 1);
for i = 1:num
    tmp = find(flag == i);
    index = find(sample.index == tmp);
    view_label(i) = example(index).view_label;
    distance(i) = cads{cad_label(i)}(1).parts2d(view_label(i)).distance;
    if isfield(example(index), 'class') == 1 && strcmp(example(index).class, 'table') == 1
        dind = find(cads{cad_label(i)}(1).distance == distance(i));
        if dind ~= 1
            distance(i) = cads{cad_label(i)}(1).distance(dind-1);
        end
    end     
    energy(i) = example(index).energy;
end

% sort objects by distance and energy
[~, index] = sort(distance);
d = unique(distance);
for i = 1:numel(d)
    ind = find(distance(index) == d(i));
    if numel(ind) ~= 1
        e = energy(index(ind));
        [~, index_energy] = sort(e, 'descend');
        temp = index(ind);
        index(ind) = temp(index_energy);
    end
end 
    
mask = ones(par.height+2*par.pady, par.width+2*par.padx) * (numel(index_show)+1);%(num+1);
mask(par.pady+1:par.height+par.pady, par.padx+1:par.width+par.padx) = 0;
for i = 1:num  
    ind = index(i);
    
    tmp = find(flag == ind);
    index_example = sample.index == tmp;    
    
    if isempty(find(index_show == ind, 1)) == 1
        continue;
    end      
    view_index = view_label(ind);
    cad = cads{cad_label(ind)}(1);
    pnames = cad.pnames;
    part_num = numel(pnames);
    % change the mask
    if isfield(example(index_example), 'class') == 0 || strcmp(example(index_example).class, 'car') == 1
        parts = zeros(4*part_num, 2);
        for j = 1:part_num
            % only for aspect part
            if cad.roots(j) == 0 && isempty(cad.parts2d(view_index).(pnames{j})) == 0
                % compute part center
                c = example(index_example).part_label(j,:) + [par.padx par.pady];
                % part shape
                part = cad.parts2d(view_index).(pnames{j}) + repmat(c, 5, 1);
                parts(4*(j-1)+1:4*j,:) = part(1:4,:);

            end
        end
        index_part = parts(:,1) ~= 0;
        parts = parts(index_part,:);
        hull = convhull(parts(:,1), parts(:,2));
        BW = poly2mask(parts(hull,1)', parts(hull,2)', size(mask,1), size(mask,2));
    else
        BW = zeros(par.height+2*par.pady, par.width+2*par.padx);
        for j = 1:part_num
            % only for aspect part
            if cad.roots(j) == 1 && isempty(cad.parts2d(view_index).(pnames{j})) == 0
                % compute part center
                c = example(index_example).part_label(j,:) + [par.padx par.pady];
                % part shape
                part = cad.parts2d(view_index).(pnames{j}) + repmat(c, 5, 1);
                part = part(1:4,:);
                hull = convhull(part(:,1), part(:,2));
                temp = poly2mask(part(hull,1)', part(hull,2)', size(mask,1), size(mask,2));
                BW = BW | temp;
            end
        end
    end
    temp = (BW == 1) & (mask == 0);
    mask(temp) = find(index_show == ind);%ind;    
end

imagesc(mask);