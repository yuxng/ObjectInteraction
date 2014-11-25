% intialization for MCMC inference
% generate objects in 3D and camera in 3D
function [O, C, alpha, center, cad_label, flag, anchor, par, object, occld_per] = reconstruct_ground_truth(I, object, cads)

if isempty(object.class) == 1
    O = [];
    C = [];
    alpha = [];
    center = [];
    cad_label = [];
    flag = [];
    anchor = [];
    par = [];
    occld_per = [];
    return;
end

if numel(cads) == 1
    cls_cad = {'car'};
else
    cls_cad = {'bed', 'chair', 'sofa', 'table'};
end

% build the world coordinate system on the first object
% ind = 1;
ind = randsample(numel(object.class), 1);
par.ind = ind;

% compute the camera location
cad_label = find(strcmp(object.class{ind}, cls_cad) == 1);
view_label = find_view_label(object.view(ind,:), cads{cad_label}(1));
azimuth = object.view(ind,1);
elevation = 0;
distance = object.view(ind,3);
if strcmp(object.class{ind}, 'table') == 1
    dind = find(cads{cad_label}(1).distance == distance);
    if dind ~= 1
        distance = cads{cad_label}(1).distance(dind-1);
    end
end
viewport = cads{cad_label}(1).parts2d(view_label).viewport;
[P, C] = projection(azimuth, elevation, distance);
% object center
root_index = cads{cad_label}(1).parts2d(view_label).root;
pnames = cads{cad_label}(1).pnames;
center = object.part{ind}.(pnames{root_index});
anchor = 1;

% number of objects
num = numel(object.class);
% 3D objects
O = zeros(3, num);
tmp = cad_label;
cad_label = zeros(num, 1);
cad_label(ind) = tmp;
alpha = zeros(num, 1);
flag = zeros(num, 1);
flag(ind) = 1;

count = 1;
for i = 1:num
    if i == ind
        continue;
    end
    count = count + 1;
    flag(i) = count;
    
    cad_label(i) = find(strcmp(object.class{i}, cls_cad) == 1);
    a = object.view(i,1);  
    d = object.view(i,3);
    if strcmp(object.class{i}, 'table') == 1
        dind = find(cads{cad_label(i)}(1).distance == d);
        if dind ~= 1
            d = cads{cad_label(i)}(1).distance(dind-1);
        end
    end
    
    % compute object center in object 1's coordinate system
    view_label = find_view_label(object.view(i,:), cads{cad_label(i)}(1));
    root_index = cads{cad_label(i)}(1).parts2d(view_label).root;
    pnames = cads{cad_label(i)}(1).pnames;
    x = object.part{i}.(pnames{root_index});
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

[par.padx, par.pady] = get_padding(cads);
par.width = size(I, 2);
par.height = size(I, 1);

% compute the convex hull for each label
object.BW = cell(num,1);
for i = 1:num
    view = find_view_label(object.view(i,:), cads{cad_label(i)}(1));
    cad = cads{cad_label(i)}(1);
    pnames = cad.pnames;
    part_num = numel(pnames);
    if strcmp(object.class{i}, 'car') == 1
        % change the mask
        parts = zeros(4*part_num, 2);
        for j = 1:part_num
            % only for aspect part
            if isfield(cad, 'roots') == 1 && cad.roots(j) == 0 && isempty(cad.parts2d(view).(pnames{j})) == 0
                % compute part center
                c = object.part{i}.(pnames{j}) + [par.padx par.pady];
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
            if isfield(cad, 'roots') == 1 && cad.roots(j) == 1 && isempty(cad.parts2d(view).(pnames{j})) == 0
                % compute part center
                c = object.part{i}.(pnames{j}) + [par.padx par.pady];
                % part shape
                part = cad.parts2d(view).(pnames{j}) + repmat(c, 5, 1);
                part = part(1:4,:);
                hull = convhull(part(:,1), part(:,2));
                temp = poly2mask(part(hull,1)', part(hull,2)', par.height+2*par.pady, par.width+2*par.padx);
                BW = BW | temp;
            end
        end        
    end
    object.BW{i} = BW;
end

% compute occlusion percentage
mask = ones(par.height+2*par.pady, par.width+2*par.padx);
mask(par.pady+1:par.height+par.pady, par.padx+1:par.width+par.padx) = 0;
occld_per = zeros(num, num+1);
for i = 1:num
    di = object.view(i,3);
    if strcmp(object.class{i}, 'table') == 1
        dind = find(cads{cad_label(i)}(1).distance == di);
        if dind ~= 1
            di = cads{cad_label(i)}(1).distance(dind-1);
        end
    end    
    
    ei = object.occlude(i);
    area = sum(sum(object.BW{i}));
    for j = 1:num
        dj = object.view(j,3);
        if strcmp(object.class{j}, 'table') == 1
            dind = find(cads{cad_label(j)}(1).distance == dj);
            if dind ~= 1
                dj = cads{cad_label(j)}(1).distance(dind-1);
            end
        end         
        ej = object.occlude(j);
        if j ~= i && (dj < di || (dj == di && ej < ei))
            inter = object.BW{i} & object.BW{j};
            occld_per(i,j) = sum(sum(inter)) / area;
        end
    end
    inter = object.BW{i} & mask;
    occld_per(i,num+1) = sum(sum(inter)) / area;
end

function view_label = find_view_label(view, cad)

a = cad.azimuth;
e = cad.elevation;
d = cad.distance;

% show aligned parts
aind = find(a == view(1))-1;
eind = find(e == view(2))-1;
dind = find(d == view(3))-1;
view_label = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;