% read one sample from file
function example = read_sample(fid, cad, flag)

if flag == 1
    example.object_label = fscanf(fid, '%d', 1);
    if example.object_label == 1
        example.cad_label = fscanf(fid, '%d', 1);
        example.view_label = fscanf(fid, '%d', 1);
        part_num = numel(cad.pnames);
        example.part_label = fscanf(fid, '%f', part_num*2);
        example.part_label = reshape(example.part_label, part_num, 2);
        example.occlusion = fscanf(fid, '%d', part_num);
        example.bbox = fscanf(fid, '%f', 4);
    end
    dims_num = fscanf(fid, '%d', 1);
    dims = fscanf(fid, '%d', dims_num);
    example.image = fscanf(fid, '%u', prod(dims));
    example.image = reshape(example.image, dims');
else
    example.object_label = fscanf(fid, '%d', 1);
    example.cad_label = fscanf(fid, '%d', 1);
    example.view_label = fscanf(fid, '%d', 1);
    example.energy = fscanf(fid, '%f', 1);
    part_num = numel(cad.pnames);
    example.part_label = fscanf(fid, '%f', part_num*2);
    example.part_label = reshape(example.part_label, part_num, 2);
    example.bbox = fscanf(fid, '%f', 4);
end