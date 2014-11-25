function rename_images

src_path = '/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/Umich_car/campus';
dst_path = '/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/car';

files = dir(src_path);
N = numel(files);
count = 151;
for i = 1:N
    disp(i);
    if files(i).isdir == 0
        filename = files(i).name;
        [pathstr, name, ext] = fileparts(filename);
        if isempty(imformats(ext(2:end))) == 0
            I = imread(fullfile(src_path, filename));
            dst_name = sprintf('%04d.jpg', count);
            imwrite(I, fullfile(dst_path, dst_name), 'jpg');
            count = count + 1;
        end
    end
end