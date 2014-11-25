function cads_new = add_part_view_cor(cads)

a = cads(1).azimuth;
e = cads(1).elevation;
d = cads(1).distance;

cad_num = numel(cads);
for i = 1:cad_num
    cad = cads(i);
    % find the part correspondences between cad and cads(1)
    index = find(cad.roots == 0);
    n = numel(index);
    cor = zeros(n, 1);
    for j = 1:n
        ind = index(j);
        tf = strcmp(cad.pnames{ind}, cads(1).pnames);
        cor(j) = find(tf == 1);
    end
    cads(i).cor = cor;
    
    % find the part correspondences between cad and cads(1)
    view_num = numel(cad.parts2d);
    vcor = zeros(view_num, 1);
    for j = 1:view_num
        azimuth = cad.parts2d(j).azimuth;
        elevation = cad.parts2d(j).elevation;
        distance = cad.parts2d(j).distance;
        aind = find(a == azimuth)-1;
        eind = find(e == elevation)-1;
        dind = find(d == distance)-1;
        vcor(j) = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;         
    end
    cads(i).vcor = vcor;
end

cads_new = cads;