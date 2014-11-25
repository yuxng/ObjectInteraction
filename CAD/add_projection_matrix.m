function cad = add_projection_matrix(cls)

% load CAD model
object = load([cls '.mat']);
cad = object.(cls);

for i = 1:numel(cad.parts2d)
    a = cad.parts2d(i).azimuth;
    e = cad.parts2d(i).elevation;
    d = cad.parts2d(i).distance;
    [P, C] = projection(a, e, d);
    cad.parts2d(i).INVP = pinv(P([1 2 4], :));
    cad.parts2d(i).C = C;
end