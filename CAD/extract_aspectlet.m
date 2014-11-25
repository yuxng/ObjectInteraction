% extract aspectlet according to the part index
function cad_new = extract_aspectlet(cad, pindex)

cad_new.pnames = cad.pnames(pindex);
cad_new.azimuth = cad.azimuth;
cad_new.elevation = cad.elevation;
cad_new.distance = cad.distance;
cad_new.parts = cad.parts(pindex);
cad_new.parts2d_front = cad.parts2d_front(pindex);

view_num = numel(cad.parts2d);
count = 0;
for i = 1:view_num
    if isempty(find(cad.parts2d(i).centers(pindex,:) == 0, 1)) == 1
        count = count + 1;
        cad_new.parts2d(count).azimuth = cad.parts2d(i).azimuth;
        cad_new.parts2d(count).elevation = cad.parts2d(i).elevation;
        cad_new.parts2d(count).distance = cad.parts2d(i).distance;
        cad_new.parts2d(count).viewport = cad.parts2d(i).viewport;
        for j = 1:numel(cad_new.pnames)
            pname = cad_new.pnames{j};
            cad_new.parts2d(count).(pname) = cad.parts2d(i).(pname);
        end
        cad_new.parts2d(count).centers = cad.parts2d(i).centers(pindex,:);
        cad_new.parts2d(count).homographies = cad.parts2d(i).homographies(pindex);
    end
end

% collect azimuth, elevation and distance
view_num = numel(cad_new.parts2d);
a = zeros(view_num, 1);
e = zeros(view_num, 1);
d = zeros(view_num, 1);
for i = 1:view_num
    a(i) = cad_new.parts2d(i).azimuth;
    e(i) = cad_new.parts2d(i).elevation;
    d(i) = cad_new.parts2d(i).distance;
end
cad_new.azimuth = sort(unique(a));
cad_new.elevation = sort(unique(e));
cad_new.distance = sort(unique(d));

% add root parts
vnum = 8;
d = cad_new.parts2d_front(1).distance;
cad_new.roots = zeros(numel(cad_new.pnames),1);
cad_new = add_root_parts(cad_new, d, vnum);