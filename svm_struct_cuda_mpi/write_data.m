% write training samples to file

function write_data(filename, pos, neg)

fid = fopen(filename, 'w');

% write sample number
np = numel(pos);
nn = numel(neg);
n = np + nn;
fprintf(fid, '%d\n', n);

% write samples
for i = 1:n
    if i <= np
        s = pos(i);
    else
        s = neg(i-np);
    end
    % write object label
    fprintf(fid, '%d ', s.object_label);
    if s.object_label == 1
        % write cad label
        fprintf(fid, '%d ', s.cad_label-1);
        % write view label
        fprintf(fid, '%d ', s.view_label-1);        
        % write part label
        num = numel(s.part_label);
        P = reshape(s.part_label, num, 1);
        fprintf(fid, '%f ', P);
        % write occlusion label
        fprintf(fid, '%d ', s.occlusion);
        % write bounding box
        bbox = [s.bbox(1) s.bbox(2) s.bbox(1)+s.bbox(3) s.bbox(2)+s.bbox(4)];
        fprintf(fid, '%f ', bbox);
    end
    % write image size
    dim = size(s.image);
    fprintf(fid, '%d ', numel(dim));
    fprintf(fid, '%d ', dim);
    % write image pixel
    num = numel(s.image);
    I = reshape(s.image, num, 1);
    fprintf(fid, '%u ', I);
    fprintf(fid, '\n');
end

fclose(fid);