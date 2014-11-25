function aspectlet_num = get_aspectlet_num(cad)

view_num = numel(cad.parts2d);
aspectlet_num = zeros(view_num, 1);
index = cad.roots == 1;

for i = 1:view_num
    aspectlet_num(i) = numel(find(cad.parts2d(i).centers(index,1) ~= 0));
end