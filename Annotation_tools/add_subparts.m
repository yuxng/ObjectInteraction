function add_subparts(cls)

switch cls
    case 'car'
        N = 200;
        cls_cad = {'car'};
    case 'car_3D'
        N = 480;
        cls_cad = {'car'};
    case 'room'
        N = 300;
        cls_cad = {'bed', 'chair', 'sofa', 'table'};
    case 'bed'
        N = 400;
        cls_cad = {'bed'};
    case 'chair'
        N = 770;
        cls_cad = {'chair'};
    case 'sofa'
        N = 800;
        cls_cad = {'sofa'};
    case 'table'
        N = 670;
        cls_cad = {'table'};         
    otherwise
        return;
end

% load CAD model
cad_num = numel(cls_cad);
cads = cell(cad_num, 1);
for i = 1:cad_num
    temp = load(sprintf('../CAD/%s_full.mat', cls_cad{i}));
    cads{i} = temp.(cls_cad{i});
end

path_src = sprintf('../Annotations/%s', cls);

for i = 1:N
    disp(i);
    file_ann = sprintf('%s/%04d.mat', path_src, i);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    view = object.view;
    n = size(bbox, 1);
        
    for j = 1:n
        if view(j,1) == 0 && view(j,2) == 0 && view(j,3) == 0
            continue;
        end
        
        % find the cad model
        cad_label = strcmp(object.class{j}, cls_cad) == 1;
        cad = cads{cad_label};
        pnames = cad.pnames;
        a = cad.azimuth;
        e = cad.elevation;
        d = cad.distance;        
        
        aind = find(a == view(j,1))-1;
        eind = find(e == view(j,2))-1;
        dind = find(d == view(j,3))-1;
        index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
        part2d = cad.parts2d(index);
        if isempty(part2d) == 1
            continue;
        end
        
        % for each part
        for k = 1:numel(pnames)
            % if the part is subpart
            if cad.roots(k) == 0
                % find root node
                for r = k-1:-1:1
                    if cad.roots(r) == 1
                        root_node = r;
                        break;
                    end
                end
                if object.part{j}.(pnames{root_node})(1) ~= 0 && part2d.centers(root_node,1) ~= 0
                    cx2 = part2d.centers(k,1);
                    cy2 = part2d.centers(k,2);

                    cx1 = part2d.centers(root_node,1);
                    cy1 = part2d.centers(root_node,2);
                    dc = sqrt((cx1-cx2)*(cx1-cx2) + (cy1-cy2)*(cy1-cy2));
                    ac = atan2(cy2-cy1, cx2-cx1);        

                    x = object.part{j}.(pnames{root_node})(1);
                    y = object.part{j}.(pnames{root_node})(2);

                    object.part{j}.(pnames{k})(1) = x + dc*cos(ac);
                    object.part{j}.(pnames{k})(2) = y + dc*sin(ac);
                else
                    object.part{j}.(pnames{k})(1) = 0;
                    object.part{j}.(pnames{k})(2) = 0;
                end
                object.occlusion{j}.(pnames{k}) = object.occlusion{j}.(pnames{root_node});
            end
        end
    end
    save(file_ann, 'object');
end