% intialization for MCMC inference
% generate objects in 3D and camera in 3D
function [O, C, alpha, center, cad_label, flag, anchor, par, y, occld_per] = mcmc_initial(I, y, cads)

max_num = 5;

if isempty(y) == 1
    fprintf('Error: none object for initialization\n');
    return;
end

% build the world coordinate system on the highest confident detection
ind = 1;
for i = 1:numel(y)
    root_index = cads{y(i).cad_label}(1).parts2d(y(i).view_label).root;
    center = y(i).part_label(root_index,:);
    if center(2) > (size(I,1) * 0.5)
        ind = i;
        break;
    end
end
par.ind = ind;

% compute the camera location
azimuth = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).azimuth;
% elevation = cads{y(1).cad_label}(1).parts2d(y(1).view_label).elevation;
elevation = 0;
distance = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).distance;
if strcmp(y(ind).class, 'table') == 1
    dind = find(cads{y(ind).cad_label}(1).distance == distance);
    if dind ~= 1
        distance = cads{y(ind).cad_label}(1).distance(dind-1);
    end
end
viewport = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).viewport;
[P, C] = projection(azimuth, elevation, distance);
% object center
root_index = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).root;
center = y(ind).part_label(root_index,:);
anchor = 1;

% number of objects
num = numel(y);
% 3D objects
O = zeros(3, num);
cad_label = zeros(num, 1);
cad_label(ind) = y(ind).cad_label;
alpha = zeros(num, 1);
flag = zeros(num, 1);
flag(ind) = 1;

cad_num = numel(cads);
count_cad = zeros(cad_num,1);
count_cad(y(ind).cad_label) = count_cad(y(ind).cad_label) + 1;

count = 1;
for i = 1:num
    root_index = cads{y(i).cad_label}(1).parts2d(y(i).view_label).root;
    if y(i).part_label(root_index,2) <= size(I,1) * 0.5 || count_cad(y(i).cad_label) >= 3
        flag(i) = -1;
        continue;
    end
    if i == ind
        continue;
    end
    count_cad(y(i).cad_label) = count_cad(y(i).cad_label) + 1;
    if count >= max_num
        continue;
    end    
%     if count >= max_num
%         break;
%     end
    count = count + 1;
    flag(i) = count;
    
    cad_label(i) = y(i).cad_label;
    a = cads{y(i).cad_label}(1).parts2d(y(i).view_label).azimuth;   
    d = cads{y(i).cad_label}(1).parts2d(y(i).view_label).distance;
    if strcmp(y(i).class, 'table') == 1
        dind = find(cads{y(i).cad_label}(1).distance == d);
        if dind ~= 1
            d = cads{y(i).cad_label}(1).distance(dind-1);
        end
    end
    
    % compute object center in object 1's coordinate system
    root_index = cads{y(i).cad_label}(1).parts2d(y(i).view_label).root;
    x = y(i).part_label(root_index,:);
    x = x - center;
    x(2) = -1 * x(2);
    x = x ./ viewport;
    % backprojection
    X = pinv(P([1 2 4], :)) * [x(1); x(2); 1];
    X = X ./ X(4);
    X = X(1:3);
    % compute the ray
    X = X - C;
    % normalization
    X = X ./ norm(X);
    % 3D location
    O(:,i) = C + d .* X;
    
    % relative azimuth
    Ci = C - O(:,i);
    ai = atan2(Ci(1), -Ci(2));
    alpha(i) = a*pi/180 - ai;
end

index = flag > 0;
O = O(:,index);
alpha = alpha(index);
cad_label = cad_label(index);

% initialize sampling parameters
par.viewport = viewport;
emax = -inf;
dmax = -inf;
for i = 1:numel(cads)
    for j = 1:numel(cads{i})
        emax = max(emax, max(cads{i}(j).elevation));
        dmax = max(dmax, max(cads{i}(j).distance));
    end
end
emax = min(emax, 90);

par.amin = 0;
par.amax = 2*pi;
par.emin = 0;
par.emax = (emax+1)*pi/180;
par.dmin = 1;
par.dmax = dmax+1;

% 3D object prior
% for car
% par.sigma = 0.5;
par.sigma_ct = 0.1;
par.sigma = 0.25;
% par.rho = 1;
par.rho_ct = 0.1;
par.rho = 10;
% par.rho1 = 1;
par.rho1 = 0.1;
[par.padx, par.pady] = get_padding(cads);
par.width = size(I, 2);
par.height = size(I, 1);

% sampling parameters
par.move = [0 0 0 1/3 1/3 1/3 0];
% change object's location in 3D
par.Sigma = 0.001*[1 0 0; 0 1 0; 0 0 1];
% change camera's location in 3D
par.Sigma_camera = [0.001 0 0; 0 0.001 0; 0 0 1];
% change object's x-y plane angle in 3D
par.sigma_angle = 0.001;
% occlusion percentage threshold
% par.occld = 0.8;
par.occld = 0.8;
% par.min_occld = 1/3;
par.min_occld = 1/3;
par.occluder_energy = 0.2;
% par.occluder_energy = 0.05;
% background probability
par.bg_pro = inf;
energy = zeros(num,1);
for i = 1:num
    if flag(i) >= 0
        energy(i) = y(i).energy;
    end
end
energy = sort(energy, 'descend');
par.bg_pro = energy(min(5,num));
par.background = par.bg_pro^2;

% compute the convex hull for each label
for i = 1:num
    view = y(i).view_label;
    cad = cads{y(i).cad_label}(1);
    pnames = cad.pnames;
    part_num = numel(pnames);
    if isfield(y(i), 'class') == 0 || strcmp(y(i).class, 'car') == 1
        % change the mask
        parts = zeros(4*part_num, 2);
        for j = 1:part_num
            % only for aspect part
            if cad.roots(j) == 0 && isempty(cad.parts2d(view).(pnames{j})) == 0
                % compute part center
                c = y(i).part_label(j,:) + [par.padx par.pady];
                % part shape
                part = cad.parts2d(view).(pnames{j}) + repmat(c, 5, 1);
                parts(4*(j-1)+1:4*j,:) = part(1:4,:);
            end
        end
        index_part = parts(:,1) ~= 0;
        parts = parts(index_part,:);
        hull = convhull(parts(:,1), parts(:,2));
        BW = poly2mask(parts(hull,1)', parts(hull,2)', par.height+2*par.pady, par.width+2*par.padx);
    else
        BW = zeros(par.height+2*par.pady, par.width+2*par.padx);
        for j = 1:part_num
            % only for aspect part
            if cad.roots(j) == 1 && isempty(cad.parts2d(view).(pnames{j})) == 0
                % compute part center
                c = y(i).part_label(j,:) + [par.padx par.pady];
                % part shape
                part = cad.parts2d(view).(pnames{j}) + repmat(c, 5, 1);
                part = part(1:4,:);
                hull = convhull(part(:,1), part(:,2));
                temp = poly2mask(part(hull,1)', part(hull,2)', par.height+2*par.pady, par.width+2*par.padx);
                BW = BW | temp;
            end
        end        
    end
    y(i).BW = BW;
end

% compute occlusion percentage
mask = ones(par.height+2*par.pady, par.width+2*par.padx);
mask(par.pady+1:par.height+par.pady, par.padx+1:par.width+par.padx) = 0;
occld_per = zeros(num, num+1);
for i = 1:num
    di = cads{y(i).cad_label}(1).parts2d(y(i).view_label).distance;
    if strcmp(y(i).class, 'table') == 1
        dind = find(cads{y(i).cad_label}(1).distance == di);
        if dind ~= 1
            di = cads{y(i).cad_label}(1).distance(dind-1);
        end
    end    
    
    ei = y(i).energy;
    area = sum(sum(y(i).BW));
    for j = 1:num
        dj = cads{y(j).cad_label}(1).parts2d(y(j).view_label).distance;
        ej = y(j).energy;
        if j ~= i && (dj < di || (dj == di && ej > ei))
            inter = y(i).BW & y(j).BW;
            occld_per(i,j) = sum(sum(inter)) / area;
        end
    end
    inter = y(i).BW & mask;
    occld_per(i,num+1) = sum(sum(inter)) / area;
end