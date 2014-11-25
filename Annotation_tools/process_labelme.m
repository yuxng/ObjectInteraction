function process_labelme

src_image = '/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/LabelMe_car';
src_xml = '/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/LabelMe_car/Annotations';
dst_image = '/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/LabelMe_image';
dst_xml = '/n/ludington/v/yuxiang/Projects/ObjectInteraction/Images/LabelMe_xml';

folders = dir(src_image);
count = 0;
for i = 3:numel(folders)
    fold_name = folders(i).name;
    files = dir(fullfile(src_image, fold_name));
    N = numel(files);
    for j = 1:N
        if files(j).isdir == 0
            filename = files(j).name;
            [pathstr, name, ext] = fileparts(filename);
            if isempty(imformats(ext(2:end))) == 0
                count = count + 1;
                disp(count);
                image_name = fullfile(dst_image, sprintf('%04d.jpg', count));
                xml_name = fullfile(dst_xml, sprintf('%04d.xml', count));
                image = fullfile(src_image, fold_name, filename);
                xml = fullfile(src_xml, fold_name, [name '.xml']);
                copyfile(image, image_name);
                copyfile(xml, xml_name);
            end
        end
    end
end