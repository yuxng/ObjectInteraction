function part_num = get_part_num(cad)

num = numel(cad);
part_num = zeros(num, 1);

for i = 1:num
    part_num(i) = numel(cad(i).parts);
end