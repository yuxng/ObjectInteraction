function occlude_image(cls)

path_image = sprintf('../Images/%s', cls);
path_anno = sprintf('../Annotations/%s', cls);
dst_image = sprintf('../Images/%s_occld', cls);
dst_anno = sprintf('../Annotations/%s_occld', cls);

switch cls
    case 'car'
        N = 150;
        cls_cad = 'car';
    case 'car_3D'
        N = 480;
        cls_cad = 'car';
    case 'room'
        N = 300;
    otherwise
        return;
end

cad = load(sprintf('../CAD/%s.mat', cls_cad));
cad = cad.(cls_cad);
pnames = cad.pnames;

a = cad.azimuth;
e = cad.elevation;
d = cad.distance;

count = 0;
for i = 1:N
    disp(i);
    
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object_origin = image.object;
    bbox = object_origin.bbox;
    
    % read original image and annotation
    file_img = sprintf('%s/%s', path_image, object_origin.image);
    I_origin = imread(file_img);
    w = size(I_origin,2);
    h = size(I_origin,1);

    n = size(bbox, 1);
    if isfield(object_origin, 'view')
        view = object_origin.view;
    end
    for j = 1:n
        if object_origin.difficult(j) == 1
            continue;
        end        
        if isfield(object_origin, 'view') == 0 || view(j,1) == -1
            continue;
        end
        % show aligned parts
        aind = find(a == view(j,1))-1;
        eind = find(e == view(j,2))-1;
        dind = find(d == view(j,3))-1;
        index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
        part2d = cad.parts2d(index);
        
        for k = 1:numel(cad.pnames)
            if isempty(part2d.(pnames{k})) == 0 && object_origin.part{j}.(pnames{k})(1) ~= 0 && cad.roots(k) > 0
                center = object_origin.part{j}.(pnames{k});
                shape = part2d.(pnames{k}) + repmat(center, 5, 1);
                mask = poly2mask(shape(:,1), shape(:,2), h, w);
                I = I_origin .* repmat(uint8(~mask), [1, 1, 3]);

                count = count + 1;
                filename = sprintf('%s/%04d.jpg', dst_image, count);
                imwrite(I, filename, 'jpg');
                
                object = object_origin;
                object.occlusion{j}.(pnames{k}) = 1;
                filename = sprintf('%s/%04d.mat', dst_anno, count);
                save(filename, 'object');
            end
        end
    end
end