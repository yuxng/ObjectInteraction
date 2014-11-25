function show_ground_truth_reconstruction(cls, examples)

switch cls
    case 'car'
        N = 200;
    case 'room'
        N = 300;
end

object = load(sprintf('work_%s.mat', cls), 'cads');
cads = object.cads;

for i = 1:N
    disp(i);
    filename = sprintf('../Images/%s/%04d.jpg', cls, i);
    I = imread(filename);
    % load detections
    filename = sprintf('../Annotations/%s/%04d.mat', cls, i);
    object = load(filename);
    object = object.object;
    object = assign_to_ground_truth(I, object, examples{i}, cads);
    [O, C, alpha, center, cad_label, flag, anchor, par, object, occld_per] = reconstruct_ground_truth(I, object, cads);
    draw3D_ground_truth(I, cads, O, C, alpha, center, cad_label, flag, object);
    pause;
end

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