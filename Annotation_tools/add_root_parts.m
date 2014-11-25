function add_root_parts(cls)

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
end

vnum = 8;
path_src = sprintf('../Annotations/%s', cls);

% load cad model
cad_num = numel(cls_cad);
cads = cell(cad_num, 1);
for i = 1:cad_num
    object = load(sprintf('../CAD/%s_full.mat', cls_cad{i}));
    cads{i} = object.(cls_cad{i});
end

for i = 1:N
    disp(i);
    file_ann = sprintf('%s/%04d.mat', path_src, i);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    view = object.view;
    n = size(bbox, 1);
    for j = 1:n
        for k = 1:vnum
            part_name = sprintf('view%d', k);
            object.part{j}.(part_name) = [0 0];
        end
    end
        
    for j = 1:n
        if view(j,1) == 0 && view(j,2) == 0 && view(j,3) == 0
            continue;
        end
        azimuth = view(j,1);
        ind = find_interval(azimuth, vnum);
        part_name = sprintf('view%d', ind);
        if object.occlude(j) == 0 && object.truncate(j) == 0
            object.part{j}.(part_name) = [bbox(j,1)+bbox(j,3)/2 bbox(j,2)+bbox(j,4)/2];
        else
            cad_index = strcmp(object.class{j}, cls_cad) == 1;
            cad = cads{cad_index};            
            object.part{j}.(part_name) = predicate_root_center(object, cad, j);
        end
    end
    save(file_ann, 'object');
end

function center = predicate_root_center(object, cad, ind)

a = cad.azimuth;
e = cad.elevation;
d = cad.distance;
pnames = cad.pnames;

aind = find(a == object.view(ind,1))-1;
eind = find(e == object.view(ind,2))-1;
dind = find(d == object.view(ind,3))-1;
index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
part2d = cad.parts2d(index);

for i = numel(pnames):-1:1
    if part2d.centers(i,1) ~= 0
        cx2 = part2d.centers(i,1);
        cy2 = part2d.centers(i,2);
        break;
    end
end

center = [0 0];
count = 0;
for i = 1:numel(cad.parts)
    if part2d.centers(i,1) ~= 0 && object.part{ind}.(pnames{i})(1) ~= 0
        cx1 = part2d.centers(i,1);
        cy1 = part2d.centers(i,2);
        dc = sqrt((cx1-cx2)*(cx1-cx2) + (cy1-cy2)*(cy1-cy2));
        ac = atan2(cy2-cy1, cx2-cx1);        
        
        x = object.part{ind}.(pnames{i})(1);
        y = object.part{ind}.(pnames{i})(2);
        
        count = count + 1;
        center(1) = center(1) + x + dc*cos(ac);
        center(2) = center(2) + y + dc*sin(ac);
    end
end
center = center ./ count;
        

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