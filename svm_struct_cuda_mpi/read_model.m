function model = read_model(filename, cad)

fid = fopen(filename, 'r');

model.C = fscanf(fid, '%f', 1);
model.loss_function = fscanf(fid, '%d', 1);
model.object_loss = fscanf(fid, '%f', 1);
model.cad_loss = fscanf(fid, '%f', 1);
model.view_loss = fscanf(fid, '%f', 1);
model.location_loss = fscanf(fid, '%f', 1);
model.loss_value = fscanf(fid, '%f', 1);
model.wxy = fscanf(fid, '%f', 1);
model.psi_size = fscanf(fid, '%d', 1);
model.weights = fscanf(fid, '%f', model.psi_size);

fclose(fid);

count = 1;
cad_num = numel(cad);
model.cad = cell(cad_num, 1);
for i = 1:cad_num
    pnames = cad{i}.pnames;
    part_num = numel(pnames);
    for j = 1:part_num
        b0 = cad{i}.parts2d_front(j).width / 6;
        b1 = cad{i}.parts2d_front(j).height / 6;
        model.cad{i}.(pnames{j}) = model.weights(count:count-1+b0*b1*32+1);
        count = count + b0*b1*32+1;
    end
end