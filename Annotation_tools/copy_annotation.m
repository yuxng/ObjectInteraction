function copy_annotation

path_image = '../Images/room';
path_anno = '../Annotations/room_all';
path_dst = '../Annotations/room';

files = dir(path_image);
N = numel(files);
i = 1;
count = 0;
while i <= N
    if files(i).isdir == 0
        filename = files(i).name;
        [pathstr, name, ext] = fileparts(filename);
        if isempty(imformats(ext(2:end))) == 0
            count = count + 1;
            disp(count);
            I = imread(fullfile(path_image, filename));
            file_image = sprintf('../%04d.jpg', count);
            imwrite(I, file_image, 'jpg');
            file_anno = sprintf('%s/%s.mat', path_anno, name);
            image = load(file_anno);
            object = image.object;
            object.image = sprintf('%04d.jpg', count);
            file_anno = sprintf('%s/%04d.mat', path_dst, count);
            save(file_anno, 'object');
        end
    end
    i = i + 1;
end
