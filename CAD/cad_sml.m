function cad = cad_sml(cls)

% load aspectlets
filename = sprintf('%s_final.mat', cls);
object = load(filename);
cad_aspectlets = object.(cls);

% load full model
filename = sprintf('%s_full.mat', cls);
object = load(filename);
cad_full = object.(cls);

% order the full model as aspectlets
cad.pnames = cad_full.pnames;
cad.azimuth = cad_full.azimuth;
cad.elevation = cad_full.elevation;
cad.distance = cad_full.distance;
cad.parts = cad_full.parts;
cad.parts2d_front = cad_full.parts2d_front;
cad.parts2d = cad_full.parts2d;
cad.roots = cad_full.roots;

% add the aspectlets
num = numel(cad_aspectlets);
cad(2:num) = cad_aspectlets(2:num);

% add part and viewpoint correspondences
cad = add_part_view_cor(cad);