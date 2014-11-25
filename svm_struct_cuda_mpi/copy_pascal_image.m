function copy_pascal_image

VOC2006 = true;
pascal_init;
ids = textread(sprintf(VOCopts.imgsetpath, 'test'), '%s');
for i = 1:length(ids);
    disp(ids{i});
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    I = imread([VOCopts.datadir rec.imgname]);
    imwrite(I, sprintf('../Images/VOC2006_test/%04d.jpg',i), 'jpg');
end