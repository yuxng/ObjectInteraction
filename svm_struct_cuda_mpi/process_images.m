% prepare data for testing from images in a directory without annotation
% path_dir: directory contains the images
% image_num: total image num
function process_images(path_dir, image_num)

fid = fopen('data/temp.tst', 'w');

fprintf(fid, '%d\n', image_num);

files = dir(path_dir);
N = numel(files);
for i = 1:N
    disp(i);
    if files(i).isdir == 0
        filename = files(i).name;
        [~, ~, ext] = fileparts(filename);
        if isempty(imformats(ext(2:end))) == 0
            I = imread(fullfile(path_dir, filename));
            fprintf(fid, '-1 ');
            % write image size
            dim = size(I);
            fprintf(fid, '%d ', numel(dim));
            fprintf(fid, '%d ', dim);
            % write image pixel
            num = numel(I);
            I = reshape(I, num, 1);
            fprintf(fid, '%u ', I);
            fprintf(fid, '\n');
        end
    end
end

fclose(fid);