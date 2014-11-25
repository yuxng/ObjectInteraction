% extract subparts from the cad model
function cad_new = extract_subparts(cad)

pindex = find(cad.roots == 0);

cad_new.pnames = cad.pnames(pindex);
cad_new.azimuth = cad.azimuth;
cad_new.elevation = cad.elevation;
cad_new.distance = cad.distance;
cad_new.parts = cad.parts(pindex);
cad_new.parts2d_front = cad.parts2d_front(pindex);

view_num = numel(cad.parts2d);
for i = 1:view_num
    cad_new.parts2d(i).azimuth = cad.parts2d(i).azimuth;
    cad_new.parts2d(i).elevation = cad.parts2d(i).elevation;
    cad_new.parts2d(i).distance = cad.parts2d(i).distance;
    cad_new.parts2d(i).viewport = cad.parts2d(i).viewport;
    for j = 1:numel(cad_new.pnames)
        pname = cad_new.pnames{j};
        cad_new.parts2d(i).(pname) = cad.parts2d(i).(pname);
    end
    cad_new.parts2d(i).centers = cad.parts2d(i).centers(pindex,:);
    cad_new.parts2d(i).homographies = cad.parts2d(i).homographies(pindex);
end