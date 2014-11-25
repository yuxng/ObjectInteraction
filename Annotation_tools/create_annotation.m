function create_annotation(cls)

switch cls
    case 'car'
        path_src = '../../FunctionRecognition/Annotations/car';
        path_dst = '../Annotations/car_3D';
        N = 480;
        pnames = {'head', 'left', 'right', 'front', 'back', 'tail', ...
            'view1', 'view2', 'view3', 'view4', 'view5', 'view6', 'view7', 'view8'};
    case 'bed'
        path_src = '../../FunctionRecognition/Annotations/bed';
        path_dst = '../Annotations/bed';
        N = 400;
        pnames = {'front', 'left', 'right', 'up', 'back', ...
            'view1', 'view2', 'view3', 'view4', 'view5', 'view6', 'view7', 'view8'};
    case 'chair'
        path_src = '../../FunctionRecognition/Annotations/chair';
        path_dst = '../Annotations/chair';
        N = 770;
        pnames = {'back', 'seat', 'leg1', 'leg2', 'leg3', 'leg4', ...
            'view1', 'view2', 'view3', 'view4', 'view5', 'view6', 'view7', 'view8'};
     case 'sofa'
        path_src = '../../FunctionRecognition/Annotations/sofa';
        path_dst = '../Annotations/sofa';
        N = 800;
        pnames = {'front', 'seat', 'back', 'left', 'right', ...
            'view1', 'view2', 'view3', 'view4', 'view5', 'view6', 'view7', 'view8'};
     case 'table'
        path_src = '../../FunctionRecognition/Annotations/table';
        path_dst = '../Annotations/table';
        N = 670;
        pnames = {'top', 'leg1', 'leg2', 'leg3', 'leg4', ...
            'view1', 'view2', 'view3', 'view4', 'view5', 'view6', 'view7', 'view8'};        
end

for i = 1:N
    disp(i);
    file_ann = sprintf('%s/%04d.mat', path_src, i);
    image = load(file_ann);
    object_old = image.object;
    
    object.image = object_old.image;
    object.bbox = object_old.bbox;
    n = size(object.bbox, 1);
    object.difficult = zeros(n,1);
    object.class = cell(n,1);
    for j = 1:n
        object.class{j} = cls;
    end
    
    % assign part
    object.part = cell(n,1);
    object.occlusion = cell(n,1);
    for j = 1:n
        for k = 1:numel(pnames)
            object.part{j}.(pnames{k}) = object_old.(pnames{k})(j,:);
            object.occlusion{j}.(pnames{k}) = 0;
        end
    end
    
    object.view = object_old.view;
    object.truncate = zeros(n,1);
    object.occlude = zeros(n,1);

    file_ann = sprintf('%s/%04d.mat', path_dst, i);
    save(file_ann, 'object');
end