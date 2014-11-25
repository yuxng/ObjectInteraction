% show image with annotation
function show_annotation_file(cls)

addpath('../svm_struct_cuda_mpi');
path_file = sprintf('../svm_struct_cuda_mpi/data/%s.dat', cls);

switch cls
    case {'car', 'car_3D', 'car_3D_final', 'car_3D_full'}
        cls_cad = 'car';
    case {'bed', 'bed_final', 'bed_full'}
        cls_cad = 'bed';
    case {'chair', 'chair_final', 'chair_full'}
        cls_cad = 'chair';
    case {'sofa', 'sofa_final', 'sofa_full'}
        cls_cad = 'sofa'; 
    case {'table', 'table_final', 'table_full'}
        cls_cad = 'table';         
    otherwise
        return;
end

object = load(sprintf('../CAD/%s.mat', cls_cad));
cad = object.(cls_cad);
cad = cad(1);

fid = fopen(path_file, 'r');
N = fscanf(fid, '%d', 1);

figure;
for i = 1:N
    disp(i);
    example = read_sample(fid, cad, 1);
    % read original image and annotation
    I_origin = uint8(example.image);
    imagesc(I_origin);
    axis equal;
    hold on;

    if example.object_label == 1
        bbox = example.bbox;
        rectangle('Position', [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)], 'EdgeColor', 'g', 'LineWidth', 2);
        view_label = example.view_label + 1;
        cad_label = example.cad_label + 1;
        part_label = example.part_label;
        part2d = cad.parts2d(view_label);
        til = sprintf('cad=%d, a=%d, e=%d, d=%d', cad_label, part2d.azimuth, part2d.elevation, part2d.distance);
        title(til);          
        for k = 1:numel(cad.pnames)
            if part_label(k,1) ~= 0
                % annotated part center
                center = [part_label(k,1), part_label(k,2)];
                plot(center(1), center(2), 'ro');
                if isempty(part2d.(cad.pnames{k})) == 0
                    part = part2d.(cad.pnames{k}) + repmat(center, 5, 1);
                    % rendered part
%                     hold off;
%                     imagesc(I_origin);
%                     axis equal;
%                     hold on;
                    patch('Faces', [1 2 3 4 5], 'Vertices', part, 'EdgeColor', 'r', 'FaceColor', 'r', 'FaceAlpha', 0.1);
%                     pause;
                end
            end
        end
    end
    hold off;
    pause;
end