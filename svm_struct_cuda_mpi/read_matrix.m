function A = read_matrix(filename)

fid = fopen(filename, 'r');
dims_num = fscanf(fid, '%d', 1);
dims = fscanf(fid, '%d', dims_num);
A = fscanf(fid, '%f');
A = reshape(A, dims');
fclose(fid);