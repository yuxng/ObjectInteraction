% add root parts to the CAD model
function cad_new = add_root_parts(cad, distance, vnum)

cad_new = cad;
pnames = cad.pnames;
part_num = numel(pnames);

width = zeros(vnum,1);
height = zeros(vnum,1);
center = zeros(vnum,2);

for k = 1:vnum
    count = 0;
    w = [];
    h = [];
    c = zeros(1,2);
    for i = 1:numel(cad.parts2d)
        part2d = cad.parts2d(i);
        index = find_interval(part2d.azimuth, vnum);
        if part2d.distance ~= distance || index ~= k
            continue;
        end
        x1 = inf;
        x2 = -inf;
        y1 = inf;
        y2 = -inf;
        for j = 1:part_num
            if isempty(part2d.(pnames{j})) == 0
                part = part2d.(pnames{j}) + repmat(part2d.centers(j,:), 5, 1);
                x1 = min([x1; part(:,1)]);
                x2 = max([x2; part(:,1)]);
                y1 = min([y1; part(:,2)]);
                y2 = max([y2; part(:,2)]);
            end
        end
        count = count + 1;
        w(count) = x2 - x1;
        h(count) = y2 - y1;
        c = c + [(x1+x2)/2 (y1+y2)/2];
    end
        
    aspects = h./w;
    aspect = mean(aspects);

    areas = h.*w;
    area = 0.8*mean(areas);

    % pick dimensions
    width(k) = sqrt(area/aspect);
    height(k) = width(k)*aspect;
    center(k,:) = c ./ count;
end

% add frontal root parts
w = width;
h = height;
count = 0;
for i = 1:vnum
    if isnan(w(i)) == 1
        continue;
    end
    count = count + 1;
    x1 = center(i,1) - w(i)/2;
    x2 = center(i,1) + w(i)/2;
    y1 = center(i,2) - h(i)/2;
    y2 = center(i,2) + h(i)/2;
    part = [x1 y1;x1 y2; x2 y2; x2 y1; x1 y1];
    c = center(i,:);
    % assign the front part
    cad_new.parts2d_front(part_num+count).vertices = part - repmat(c, size(part,1), 1);
    cad_new.parts2d_front(part_num+count).center = c;
    width = round(max(part(:,1))-min(part(:,1)));
    if mod(width, 6) >= 3
        width = width + 6 - mod(width, 6);
    else
        width = width - mod(width, 6);
    end
    cad_new.parts2d_front(part_num+count).width = width;
    height = round(max(part(:,2))-min(part(:,2)));
    if mod(height, 6) >= 3
        height = height + 6 - mod(height, 6);
    else
        height = height - mod(height, 6);
    end
    cad_new.parts2d_front(part_num+count).height = height;
    cad_new.parts2d_front(part_num+count).distance = distance;
    cad_new.parts2d_front(part_num+count).viewport = cad.parts2d_front(1).viewport;
    cad_new.parts2d_front(part_num+count).pname = sprintf('view%d', i);
    cad_new.pnames{part_num+count} = sprintf('view%d', i);
    cad_new.roots(part_num+count) = -1;
end

% add root part for each viewpoint
flag = zeros(numel(cad.parts2d),1);
for i = 1:numel(cad.parts2d)
    part2d = cad.parts2d(i);
    x1 = inf;
    x2 = -inf;
    y1 = inf;
    y2 = -inf;
    for j = 1:part_num
        if isempty(part2d.(pnames{j})) == 0
            part = part2d.(pnames{j}) + repmat(part2d.centers(j,:), 5, 1);
            x1 = min([x1; part(:,1)]);
            x2 = max([x2; part(:,1)]);
            y1 = min([y1; part(:,2)]);
            y2 = max([y2; part(:,2)]);
        end
    end
    part = [x1 y1;x1 y2; x2 y2; x2 y1; x1 y1];
    center = [(x1+x2)/2 (y1+y2)/2];
    % assign the root part
    index = find_interval(part2d.azimuth, vnum);
    view_name = sprintf('view%d', index);
    for j = 1:count
        part_name = cad_new.pnames{part_num+j};
        if strcmp(part_name, view_name) == 1
            cad_new.parts2d(i).(part_name) = part - repmat(center, size(part,1), 1);
            cad_new.parts2d(i).centers(part_num+j,:) = center;
            % compute the homography for transfering current view of the part
            % to frontal view using four point correspondences
            % coefficient matrix
            A = zeros(8,9);
            % construct the coefficient matrix
            X = cad_new.parts2d(i).(part_name);
            xprim = cad_new.parts2d_front(part_num+j).vertices;
            for k = 1:4
                x = [X(k,:), 1];
                A(2*k-1,:) = [zeros(1,3), -x, xprim(k,2)*x];
                A(2*k, :) = [x, zeros(1,3), -xprim(k,1)*x];
            end
            [~, ~, V] = svd(A);
            % homography
            h = V(:,end);
            H = reshape(h, 3, 3)';
            % normalization
            H = H ./ H(3,3);
            cad_new.parts2d(i).homographies{part_num+j} = H;
            cad_new.parts2d(i).root = part_num+j;
        else
            cad_new.parts2d(i).(part_name) = [];
            cad_new.parts2d(i).centers(part_num+j,:) = [0 0];
            cad_new.parts2d(i).homographies{part_num+j} = [];
        end
    end
    % construct graph, each row stores the parents of the node
    cad_new.parts2d(i).graph = zeros(numel(cad_new.pnames));
    if isfield(cad_new.parts2d(i), 'root') == 0 || isempty(cad_new.parts2d(i).root) == 1
        flag(i) = 1;
        fprintf('root is empty of part2d %d\n', i);
        continue;
    end
    root = cad_new.parts2d(i).root;
    for j = 1:numel(cad_new.pnames)
        if j ~= root && isempty(cad_new.parts2d(i).(cad_new.pnames{j})) == 0
            if cad_new.roots(j) == 0
                cad_new.parts2d(i).graph(j,root) = 1;
            elseif cad_new.roots(j) ~= -1
                root_node = cad_new.roots(j);
                cad_new.parts2d(i).graph(j,root_node) = 1;
            end
        end
    end
end
cad_new.parts2d(flag == 1) = [];

function ind = find_interval(azimuth, num)

if num == 8
    a = 22.5:45:337.5;
elseif num == 24
    a = 7.5:15:352.5;
elseif num == 16
    a = 11.25:22.5:348.75;
end

for i = 1:numel(a)
    if azimuth < a(i)
        break;
    end
end
ind = i;
if azimuth > a(end)
    ind = 1;
end