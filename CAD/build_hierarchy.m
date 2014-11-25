% build the hierarchy of aspectlets
function [hierarchy, parents] = build_hierarchy(cls)

% load cad models
filename = sprintf('%s_final.mat', cls);
object = load(filename);
cads = object.(cls);

cad_num = numel(cads);
hierarchy = zeros(cad_num, cad_num);

% extract aspectlet
num = numel(find(cads(1).roots == 0));
aspectlet = zeros(cad_num, num);
aspectlet(1,:) = ones(1,num);
for i = 2:cad_num
    cad = cads(i);
    % find the part correspondences between cad and cads(1)
    n = numel(find(cad.roots == 0));
    cor = zeros(n, 1);
    for j = 1:n
        tf = strcmp(cad.pnames{j}, cads(1).pnames);
        cor(j) = find(tf == 1);
    end
    aspectlet(i,cor) = 1;
end

% decide the parents of each aspectlet
for i = 1:cad_num
    index = aspectlet(i,:) == 1;
    for j = 1:cad_num
        if i == j
            continue;
        end
        if min(aspectlet(j,index)) == 1
            hierarchy(i,j) = 1;
        end
    end
end     

% only keep the direct parents of each aspectlet
temp = hierarchy;
for i = 1:cad_num
    index = find(temp(i,:) == 1);
    for j = 1:numel(index)
        parent = temp(index(j),:) == 1;
        hierarchy(i,parent) = 0;
    end
end

% link all the aspectlets to the root
hierarchy(:,1) = 1;
hierarchy(1,1) = 0;

parents = cell(cad_num, 1);
for i = 1:cad_num
    parents{i} = find(hierarchy(i,:) == 1);
end