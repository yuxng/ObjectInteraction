function write_pascal_negative(cls)

fid = fopen(sprintf('data_new/%s.neg', cls), 'w');
VOC2006 = false;
pascal_init;
ids = textread(sprintf(VOCopts.imgsetpath, 'train'), '%s');
n = 0;
for i = 1:length(ids);
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    clsinds = strmatch(cls, {rec.objects(:).class}, 'exact');
    if isempty(clsinds)
        n = n + 1;
    end
end
fprintf('%d negative images\n', n);

fprintf(fid, '%d\n', n);
count = 0;
for i = 1:length(ids);
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    clsinds = strmatch(cls, {rec.objects(:).class}, 'exact');
    if isempty(clsinds)
        disp(ids{i});
        fprintf(fid, '-1 ');
        I = imread([VOCopts.datadir rec.imgname]);
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
fclose(fid);