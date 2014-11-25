function modify_annotation(cls)

switch cls
    case 'car'
        N = 200;
    case 'room'
        N = 300;
    case 'chair'
        N = 770;
    case 'bed'
        N = 400;
    case 'sofa'
        N = 800;
    case 'table'
        N = 670;
end
path_anno = sprintf('../Annotations/%s', cls);

% for i = 1:N
%     disp(i);
%     file_ann = sprintf('%s/%04d.mat', path_anno, i);
%     image = load(file_ann);
%     object = image.object;
%     n = size(object.view, 1);
%     for j = 1:n
%         switch object.view(j,3)
%             case 1.5
%                 object.view(j,3) = 0.9;
%             case 2
%                 object.view(j,3) = 1.2;
%             case 2.5
%                 object.view(j,3) = 1.5;
%             case 3
%                 object.view(j,3) = 2;
%             case 3.5
%                 object.view(j,3) = 2.5;
%             case 5
%                 object.view(j,3) = 3;
%             otherwise
%                 fprintf('error!');
%         end
%     end   
%     save(file_ann, 'object');
% end

for i = 1:N
    disp(i);
    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    n = size(object.bbox, 1);
    for j = 1:n
        pnames = get_part_name(object.class{j});
        for k = 1:numel(pnames)
            if object.occlusion{j}.(pnames{k}) > 0
                object.occlude(j) = 1;
                break;
            end
        end
    end   
    save(file_ann, 'object');
end