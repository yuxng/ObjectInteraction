% compute project matrix P from azimuth a, elevation e and distance d 
% of camera pose. Rotate coordinate system by theta is equal to rotating
% the model by -theta.
function [P, C] = projection(a, e, d)

a = a*pi/180;
e = e*pi/180;

%camera center
C = zeros(3,1);
C(1) = d*cos(e)*sin(a);
C(2) = -d*cos(e)*cos(a);
C(3) = d*sin(e);

a = -a;
e = -(pi/2-e);

%rotation matrix
Rz = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];   %rotate by a
Rx = [1 0 0; 0 cos(e) -sin(e); 0 sin(e) cos(e)];   %rotate by e
R = Rx*Rz;

%orthographic project matrix
%P = [R -R*C; 0 0 0 1];

%perspective project matrix
P = [1 0 0 0; 0 1 0 0; 0 0 0 1; 0 0 -1 0] * [R -R*C; 0 0 0 1];