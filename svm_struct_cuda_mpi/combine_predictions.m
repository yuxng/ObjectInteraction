function combine_predictions(cls, N)

fid = fopen(sprintf('data/%s.pre', cls), 'w');

for i = 1:N
    filename = sprintf('data/%s.pre_rank%d', cls, i-1);
    %filename = sprintf('data/%s_%02d.pre', cls, i);
    fp = fopen(filename, 'r');
    tline = fgets(fp);
    while ischar(tline)
        fprintf(fid, '%s', tline);
        tline = fgets(fp);
    end
    fclose(fp);
end

fclose(fid);