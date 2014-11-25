% show image with annotation
function show_annotation(cls)

path_image = sprintf('../Images/%s', cls);
path_anno = sprintf('../Annotations/%s', cls);

switch cls
    case 'car'
        N = 200;
        cls_cad = {'car'};
    case 'car_3D'
        N = 480;
        cls_cad = {'car'};
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
    case 'room'
        N = 300;
        cls_cad = {'bed', 'chair', 'sofa', 'table'};
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

for i = 1:N
    disp(i);
    
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    bbox = object.bbox;
    
    % read original image and annotation
    file_img = sprintf('%s/%s', path_image, object.image);
    I_origin = imread(file_img);
    figure(1);
    imagesc(I_origin);
    axis equal;
    hold on;

    n = size(bbox, 1);
    if isfield(object, 'view')
        view = object.view;
    end
    for j = 1:n
        figure(1);
        if object.difficult(j) == 0
            rectangle('Position', bbox(j,:), 'EdgeColor', 'g', 'LineWidth',2);
        else
            rectangle('Position', bbox(j,:), 'EdgeColor', 'r', 'LineWidth',2);
            if view(j,1) == 0 && view(j,2) == 0 && view(j,3) == 0
                continue;
            end
        end
        til = sprintf('%d, a: %d, e:%d, d:%.1f', j, view(j,1), view(j,2), view(j,3));
        text(bbox(j,1), bbox(j,2), til, 'fontsize', 24, 'color', 'b');        
        if isfield(object, 'view') == 0 || view(j,1) == -1
            continue;
        end
        
        % find the cad model
        cad_label = strcmp(object.class{j}, cls_cad) == 1;
        cad = cads{cad_label};
        pnames = cad.pnames;
        a = cad.azimuth;
        e = cad.elevation;
        d = cad.distance;
        
        % show aligned parts
        aind = find(a == view(j,1))-1;
        eind = find(e == view(j,2))-1;
        dind = find(d == view(j,3))-1;
        index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
        part2d = cad.parts2d(index);
        if isempty(part2d) == 1
            continue;
        end
        for k = 1:numel(cad.pnames)
            if isempty(part2d.(pnames{k})) == 0
                if isfield(object.part{j}, pnames{k}) == 1 && object.part{j}.(pnames{k})(1) ~= 0
                % annotated part center
                    center = [object.part{j}.(pnames{k})(1), object.part{j}.(pnames{k})(2)];
                    plot(center(1), center(2), 'ro');
                    part = part2d.(pnames{k}) + repmat(center, 5, 1);
                    if isfield(object.occlusion{j}, pnames{k}) == 1 && object.occlusion{j}.(pnames{k}) == 0
                        patch('Faces', [1 2 3 4 5], 'Vertices', part, 'FaceColor', 'r', 'EdgeColor','r', 'FaceAlpha', 0.05);
                    else
                        patch('Faces', [1 2 3 4 5], 'Vertices', part, 'FaceColor', 'r', 'EdgeColor','r', 'FaceAlpha', 0.05, 'LineStyle', '--');
                    end
                elseif isfield(object.occlusion{j}, pnames{k}) == 1 && object.occlusion{j}.(pnames{k}) ~= 2
                    fprintf('missing part center %04d_%02d part %d\n', i, j, k);
                end 
            end
        end
    end
    
    figure(1);
    hold off;
    pause;
end