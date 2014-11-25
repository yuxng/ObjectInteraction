% MCMC add
function [O_new, C_new, alpha_new, center_new, cad_label_new, flag_new, anchor_new] = ...
    mcmc_add(O, C, alpha, center, cad_label, par, cads, y, flag, anchor, ind)

% set the flag
flag_new = flag;
flag_new(ind) = size(O,2) + 1;

% compute object center in object 1's coordinate system            
root_index = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).root;
x = y(ind).part_label(root_index,:);            
x = x - center;
x(2) = -1 * x(2);
x = x ./ par.viewport;

% backprojection
a = atan2(C(1), -C(2));
if a < 0
    a = a + 2*pi;
end
d = norm(C);
e = asin(C(3) / d);
P = projection(a*180/pi, e*180/pi, d);
X = pinv(P([1 2 4], :)) * [x(1); x(2); 1];
X = X ./ X(4);
X = X(1:3);
% compute the ray
X = X - C;
% normalization
X = X ./ norm(X);

% get azimuth and distance
a = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).azimuth;
d = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).distance;
if strcmp(y(ind).class, 'table') == 1
    dind = find(cads{y(ind).cad_label}(1).distance == d);
    if dind ~= 1
        d = cads{y(ind).cad_label}(1).distance(dind-1);
    end
end

% 3D location
O_new = O;
O_new(:,end+1) = C + d .* X;

% relative azimuth
alpha_new = alpha;
Ci = C - O_new(:,end);
ai = atan2(Ci(1), -Ci(2));
alpha_new(end+1) = a*pi/180 - ai;
cad_label_new = cad_label;
cad_label_new(end+1) = y(ind).cad_label;

C_new = C;
center_new = center;
anchor_new = anchor;