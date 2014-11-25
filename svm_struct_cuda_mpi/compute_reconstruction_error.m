function compute_reconstruction_error(cls, examples)

switch cls
    case 'car'
        N = 200;
    case 'room'
        N = 300;
end

object = load(sprintf('work_%s.mat', cls), 'cads');
cads = object.cads;

num_object = 0;
count = 0;
error = 0;
error_order = 0;
for i = 1:N
    disp(i);
    filename = sprintf('../Images/%s/%04d.jpg', cls, i);
    I = imread(filename);
    % load annotation
    filename = sprintf('../Annotations/%s/%04d.mat', cls, i);
    object = load(filename);
    object = object.object;   
    object_new = assign_to_ground_truth(I, object, examples{i}, cads);
    object.difficult = object_new.difficult;
    
    object_new = remove_difficult(object_new);
    [O_new, C_new] = reconstruct_ground_truth(I, object_new, cads);
    if isempty(O_new) == 1
        fprintf('No object in image %d\n', i);
    end
    num = size(O_new,2);
    if num == 1
        fprintf('1 object detected\n');
    end
    O_new = O_new - repmat(C_new, 1, num);
    num_object = num_object + num;
    
    object = remove_difficult(object);
    [O, C] = reconstruct_ground_truth(I, object, cads);
    O = O - repmat(C, 1, num);
    for j = 1:num
        for k = j+1:num
            d = norm(O(:,j)-O(:,k));
            d_new = norm(O_new(:,j)-O_new(:,k));
            error = error + abs(d - d_new);
            count = count + 1;
            
            if compute_order(object_new, j, k, cads) ~= compute_order(object, j, k, cads)
                error_order = error_order + 1;
            end
        end
    end
end

error = error / count;
fprintf('%d objects detected, %d pairs of distances, error = %f, error_order = %d\n',...
    num_object, count, error, error_order);

function object_new = remove_difficult(object)

index = find(object.difficult == 0);
object_new.image = object.image;
object_new.bbox = object.bbox(index,:);
object_new.difficult = object.difficult(index);
object_new.class = object.class(index);
object_new.part = object.part(index);
object_new.occlusion = object.occlusion(index);
object_new.view = object.view(index,:);
object_new.truncate = object.truncate(index);
object_new.occlude = object.occlude(index);
object_new.occld_per = object.occld_per(index);
if isfield(object, 'energy') == 1
    object_new.energy = object.energy(index);
end

function order = compute_order(object, i, j, cads)

if numel(cads) == 1
    cls_cad = {'car'};
else
    cls_cad = {'bed', 'chair', 'sofa', 'table'};
end

di = object.view(i,3);
cad_label = find(strcmp(object.class{i}, cls_cad) == 1);
if strcmp(object.class{i}, 'table') == 1
    dind = find(cads{cad_label}(1).distance == di);
    if dind ~= 1
        di = cads{cad_label}(1).distance(dind-1);
    end
end    
if isfield(object, 'energy') == 0
    ei = object.occlude(i);
else
    ei = object.energy(i);
end

dj = object.view(j,3);
cad_label = find(strcmp(object.class{j}, cls_cad) == 1);
if strcmp(object.class{j}, 'table') == 1
    dind = find(cads{cad_label}(1).distance == dj);
    if dind ~= 1
        dj = cads{cad_label}(1).distance(dind-1);
    end
end
if isfield(object, 'energy') == 0
    ej = object.occlude(j);
else
    ej = object.energy(i);
end

if isfield(object, 'energy') == 0
    if dj < di || (dj == di && ej < ei)
        order = 1;
    else
        order = 0;
    end
else
    if dj < di || (dj == di && ej > ei)
        order = 1;
    else
        order = 0;
    end
end