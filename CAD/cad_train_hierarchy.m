% build the hierarchical cad model
function cad = cad_train_hierarchy(cls)

% load cad model
object = load(sprintf('%s.mat', cls));
cads = object.(cls);
index = object.index;

% intialize with the full model
cad = cads(1);
part_num = numel(cad.pnames);
view_num = numel(cad.parts2d);

% intialize the graph
% each row will store the parents of the node
for v = 1:view_num
    cad.parts2d(v).graph = zeros(part_num, part_num);
end

% sequentially adding aspectlets
count = 1;
for i = 1:numel(index)
    ind = index(i);
    aspectlet = cads(ind);
    
    % find the part correspondences between aspectlet and cads(1)
    n = numel(find(aspectlet.roots == 0));
    cor = zeros(n, 1);
    for j = 1:n
        tf = strcmp(aspectlet.pnames{j}, cads(1).pnames);
        cor(j) = find(tf == 1);
    end
    
    % check if the parts are on the same plane or not
    isplane = 1;
    for j = 2:n
        if isequal(cad.parts(cor(j)).plane, cad.parts(cor(j-1)).plane) == 0
            isplane = 0;
            break;
        end
    end
    
    if isplane == 1
        % build the large aspect part
        P = cad.parts(cor(1)).plane;
        pnorm2 = P(1:3)'*P(1:3);
        origin = -(P(4)/pnorm2)*P(1:3)';
        xaxis = cad.parts(cor(1)).xaxis;
        yaxis = cad.parts(cor(1)).yaxis;
        % collect vertices
        nv = 4*n;
        pvertices = zeros(nv, 3);
        for j = 1:n
            pvertices(4*(j-1)+1:4*j,:) = cad.parts(cor(j)).vertices(1:4,:);
        end
        % represent points in the plane using the local coordinates
        v2d = zeros(nv, 2);
        for j = 1:nv
            v2d(j,1) = dot(pvertices(j,:) - origin, xaxis);
            v2d(j,2) = dot(pvertices(j,:) - origin, yaxis);
        end
        % bounding box in the plane
        center = [(min(v2d(:,1))+max(v2d(:,1)))/2, (min(v2d(:,2))+max(v2d(:,2)))/2];
        width = max(v2d(:,1)) - min(v2d(:,1));
        height = max(v2d(:,2)) - min(v2d(:,2));

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
        C = center(1)*xaxis + center(2)*yaxis + origin;
        % build the face
        F = [p1; p2; p3; p4; p1];        
        
        temp.parts(1).vertices = F;
        temp.parts(1).plane = P;
        temp.parts(1).center = C;
        temp.parts(1).xaxis = xaxis;
        temp.parts(1).yaxis = yaxis;
        temp.pnames{1} = sprintf('aspeclet%d', count);
        parts2d_front = render_part_front(temp, cad.parts2d_front(1).distance, cad.parts2d_front(1).viewport);
        temp.parts2d_front = parts2d_front;
        
        % generate 2d parts
        temp.azimuth = cad.azimuth;
        temp.elevation = cad.elevation;
        temp.distance = cad.distance;
        temp.roots = 0;
        % note cls for chair and table, needs to rotate the plane
        parts2d = generate_2d_parts(temp.pnames{1}, temp, cad.parts2d_front(1).viewport, 1);
        
        % add aspectlet name
        pname = sprintf('aspeclet%d', count);
        cad.pnames{part_num+count} = pname;
        % add parts2d front
        cad.parts2d_front(part_num+count) = parts2d_front;
        
        % add parts2d
        for v = 1:numel(parts2d)
            if min(cad.parts2d(v).centers(cor,1)) ~= 0
                a = parts2d(v).azimuth;
                e = parts2d(v).elevation;
                d = parts2d(v).distance;

                aind = find(cad.azimuth == a) - 1;
                eind = find(cad.elevation == e) - 1;
                dind = find(cad.distance == d) - 1;
                view_label = aind*numel(cad.elevation)*numel(cad.distance) + eind*numel(cad.distance) + dind + 1;

                cad.parts2d(view_label).(pname) = parts2d(v).(pname);
                cad.parts2d(view_label).centers(part_num+count,:) = parts2d(v).centers(1,:);
                cad.parts2d(view_label).homographies{part_num+count} = parts2d(v).homographies{1};

                % update the graph
                root = cad.parts2d(view_label).root;
                graph = cad.parts2d(view_label).graph;
                cad.parts2d(view_label).graph = zeros(part_num+count, part_num+count);
                cad.parts2d(view_label).graph(1:part_num+count-1, 1:part_num+count-1) = graph;
                cad.parts2d(view_label).graph(cor, part_num+count) = 1;
                cad.parts2d(view_label).graph(part_num+count, root) = 1;
            end
        end
        % fill empty for parts2d
        for v = 1:view_num
            if isempty(cad.parts2d(v).(pname)) == 1
                cad.parts2d(v).(pname) = [];
                cad.parts2d(v).centers(part_num+count,:) = [0 0];
                cad.parts2d(v).homographies{part_num+count} = [];
                graph = cad.parts2d(v).graph;
                cad.parts2d(v).graph = zeros(part_num+count, part_num+count);
                cad.parts2d(v).graph(1:part_num+count-1, 1:part_num+count-1) = graph;                
            end
        end
        % add root index
        cad.roots(part_num+count) = 1;
        % increase aspectlet number
        count = count + 1;
    else
        root_index = find(aspectlet.roots == -1);
        for j = 1:numel(root_index)
            root_ind = root_index(j);

            % add aspectlet name
            pname = sprintf('aspeclet%d', count);
            cad.pnames{part_num+count} = pname;
            % add parts2d front
            cad.parts2d_front(part_num+count) = aspectlet.parts2d_front(root_ind);
            cad.parts2d_front(part_num+count).pname = pname;
            % add parts2d
            for v = 1:numel(aspectlet.parts2d)
                if isempty(aspectlet.parts2d(v).homographies{root_ind}) == 0
                    a = aspectlet.parts2d(v).azimuth;
                    e = aspectlet.parts2d(v).elevation;
                    d = aspectlet.parts2d(v).distance;

                    aind = find(cad.azimuth == a) - 1;
                    eind = find(cad.elevation == e) - 1;
                    dind = find(cad.distance == d) - 1;
                    view_label = aind*numel(cad.elevation)*numel(cad.distance) + eind*numel(cad.distance) + dind + 1;

                    cad.parts2d(view_label).(pname) = aspectlet.parts2d(v).(aspectlet.pnames{root_ind});
                    cad.parts2d(view_label).centers(part_num+count,:) = aspectlet.parts2d(v).centers(root_ind,:);
                    cad.parts2d(view_label).homographies{part_num+count} = aspectlet.parts2d(v).homographies{root_ind};

                    % update the graph
                    root = cad.parts2d(view_label).root;
                    graph = cad.parts2d(view_label).graph;
                    cad.parts2d(view_label).graph = zeros(part_num+count, part_num+count);
                    cad.parts2d(view_label).graph(1:part_num+count-1, 1:part_num+count-1) = graph;
                    cad.parts2d(view_label).graph(cor, part_num+count) = 1;
                    cad.parts2d(view_label).graph(part_num+count, root) = 1;
                end
            end
            % fill empty for parts2d
            for v = 1:view_num
                if isempty(cad.parts2d(v).(pname)) == 1
                    cad.parts2d(v).(pname) = [];
                    cad.parts2d(v).centers(part_num+count,:) = [0 0];
                    cad.parts2d(v).homographies{part_num+count} = [];
                    graph = cad.parts2d(v).graph;
                    cad.parts2d(v).graph = zeros(part_num+count, part_num+count);
                    cad.parts2d(v).graph(1:part_num+count-1, 1:part_num+count-1) = graph;                
                end
            end
            % add root index
            cad.roots(part_num+count) = 1;
            % increase aspectlet number
            count = count + 1;
        end
    end
end

% sanity check
for v = 1:view_num
    index = cad.parts2d(v).centers(:,1) > 0 & cad.roots == 0;
    if min(sum(cad.parts2d(v).graph(index,:),2)) == 0
        fprintf('view %d not fully covered\n', v);
    end
end