% compute the overlapping volumn between two spheres, see Sphere-Sphere
% Intersection from MathWorld
function o = sphere_overlap(O1, O2, r)

% change coordinate system
% 1. Move origin to O1
O2 = O2 - O1;

% 2. rotate to have z=0, around x-axis
theta = -atan2(O2(3), O2(2));
R = [1 0 0; 0 cos(theta) -sin(theta); 0 sin(theta) cos(theta)];
O2 = R*O2;

% 3. rotate to have y=0, around z-axis
theta = -atan2(O2(2), O2(1));
R = [cos(theta) -sin(theta) 0; sin(theta) cos(theta) 0; 0 0 1];
O2 = R*O2;

% distance between sphere centers
d = O2(1);

% compute the overlapping volumn
if d >= 2*r
    o = 0;
else
    o = pi * (4*r+d) * (2*r-d)^2 / 12;
end