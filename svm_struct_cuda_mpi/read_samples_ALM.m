% read one sample from file
function examples = read_samples_ALM(cls, cads, cads_ALM)

switch cls
    case 'car'
        N = 200;
        cls_cad = {'car'};
    case 'room'
        N = 300;
        cls_cad = {'bed', 'chair', 'sofa', 'table'};       
end

examples = cell(N,1);
for i = 1:numel(cls_cad)
    disp(i);
    cad = cads{i}(1);
    cad_ALM = cads_ALM{i};
    tmp = read_samples([cls_cad{i} '_ALM']);
    for j = 1:N
        for k = 1:numel(tmp{j})
            % change cad label
            tmp{j}(k).cad_label = i;
            tmp{j}(k).view_label = find_view_cor(tmp{j}(k), cad, cad_ALM);
            part_label = tmp{j}(k).part_label;
            label = zeros(numel(cad.pnames),2);
            for l = 1:numel(cad.pnames)
                index = find(strcmp(cad.pnames{l}, cad_ALM.pnames) == 1);
                if isempty(index) == 0
                    label(l,:) = part_label(index,:);
                end
            end
            tmp{j}(k).part_label = label;
        end
    end
    for j = 1:N
        examples{j} = [examples{j} tmp{j}];
    end
end

function view_label = find_view_cor(example, cad, cad_ALM)

view = example.view_label;
azimuth = cad_ALM.parts2d(view).azimuth;
elevation = cad_ALM.parts2d(view).elevation;
bbox_ALM = get_bbox(cad_ALM, view);

a = cad.azimuth;
e = cad.elevation;
d = cad.distance;

% show aligned parts
aind = find(a == azimuth)-1;
eind = find(e == elevation)-1;
if isempty(eind) == 1
    eind = 0;
    dind = 0;
    num = numel(e)*numel(d);
else
    dind = 0;
    num = numel(d);
end
start = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;

overlap = zeros(num,1);
for i = 1:num
    bbox = get_bbox(cad, start+i-1);
    overlap(i) = box_overlap(bbox, bbox_ALM);
end

[~, dind] = max(overlap);
dind = dind - 1;
view_label = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
    
function bbox = get_bbox(cad, view_label)

part2d = cad.parts2d(view_label);
viewport = part2d.viewport;
pnames = cad.pnames;
part_num = numel(pnames);

x1 = inf;
x2 = -inf;
y1 = inf;
y2 = -inf;
for j = 1:part_num
    if isempty(part2d.homographies{j}) == 0 
        c = part2d.centers(j,:) - [viewport/2 viewport/2];
        % render parts
        part_shape = part2d.(pnames{j}) + repmat(c, 5, 1);
        x1 = min(x1, min(part_shape(:,1)));
        x2 = max(x2, max(part_shape(:,1)));
        y1 = min(y1, min(part_shape(:,2)));
        y2 = max(y2, max(part_shape(:,2)));            
    end
end
bbox = [x1 y1 x2 y2];