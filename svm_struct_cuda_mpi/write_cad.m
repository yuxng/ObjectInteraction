% write cad model to file

function write_cad(cads, cls)

filename = sprintf('data_new/%s.cad', cls);
fid = fopen(filename, 'w');

% write number of cad models
fprintf(fid, '%d\n', numel(cads));

% write each cad models
for c = 1:numel(cads)
    cad = cads(c);

    % write part number
    part_num = numel(cad.pnames);
    fprintf(fid, '%d\n', part_num);

    % write part names
    for i = 1:part_num
        fprintf(fid, '%s\n', cad.pnames{i});
    end
    
    % write root index
    fprintf(fid, '%d ', cad.roots);
    fprintf(fid, '\n');

    % write part 2d front
    for i = 1:part_num
        fprintf(fid, '%d ', cad.parts2d_front(i).width);
        fprintf(fid, '%d ', cad.parts2d_front(i).height);
    end
    fprintf(fid, '\n');

    % write view number
    view_num = numel(cad.parts2d);
    fprintf(fid, '%d\n', view_num);

    % write part 2d
    for i = 1:view_num
        fprintf(fid, '%f ', cad.parts2d(i).azimuth);
        fprintf(fid, '%f ', cad.parts2d(i).elevation);
        fprintf(fid, '%f ', cad.parts2d(i).distance);
        fprintf(fid, '%d ', cad.parts2d(i).viewport);
        centers = reshape(cad.parts2d(i).centers, 2*part_num, 1);
        fprintf(fid, '%f ', centers);
        for j = 1:part_num
            if isempty(cad.parts2d(i).homographies{j}) == 0
                H = reshape(cad.parts2d(i).homographies{j}, 9, 1);
                fprintf(fid, '%.12f ', H);
            end
        end
        for j = 1:part_num
            if isempty(cad.parts2d(i).(cad.pnames{j})) == 0
                P = reshape(cad.parts2d(i).(cad.pnames{j})(1:4,:), 8, 1);
                fprintf(fid, '%f ', P);
            end
        end
        fprintf(fid, '%d ', cad.parts2d(i).graph);
        fprintf(fid, '%d\n', cad.parts2d(i).root-1);
    end
end

fclose(fid);