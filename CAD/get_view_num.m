function view_num = get_view_num(cad)

num = numel(cad);
view_num = zeros(num, 1);

for i = 1:num
    view_num(i) = numel(cad(i).parts2d);
end