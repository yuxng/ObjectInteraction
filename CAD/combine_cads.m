function cad = combine_cads(cls)

filename = sprintf('%s_final.mat', cls);
object = load(filename);
cad_final = object.(cls);

filename = sprintf('%s_full.mat', cls);
object = load(filename);
cad_full = object.(cls);

cad = cad_final;
cad(1).pnames = cad_full.pnames;
cad(1).azimuth = cad_full.azimuth;
cad(1).elevation = cad_full.elevation;
cad(1).distance = cad_full.distance;
cad(1).parts = cad_full.parts;
cad(1).parts2d_front = cad_full.parts2d_front;
cad(1).parts2d = cad_full.parts2d;
cad(1).roots = cad_full.roots;
