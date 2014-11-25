% generate a pool of aspectlets
function aspectlets = generate_aspectlets(cad, symmetric)

% part num
num = numel(cad.parts);
% sample num
N = 3000;
Nmax = 3000;
threshold_part = 3;
threshold_bbox = 0.75;
parts2d = cad.parts2d;
view_num = numel(parts2d);

count = 1;
% for each part
for i = 1:num
    disp(i);
    c = cad.parts(i).center;

    % rand aspectlet
    aspectlet = zeros(N, num);
    k = 1;
    iter = 0;
    while k <= N && iter < Nmax
        iter = iter + 1;
        E = rand_ellipsoid();

        % check which parts are inside the ellipsoid
        flag = zeros(num, 1);
        for j = 1:num
            center = cad.parts(j).center;
            if (center-c)*E.V*diag(1./E.D)*E.V'*(center-c)' <= 1
                flag(j) = 1;
            end
        end
        
        cor = find(flag == 1);
        flag_choose = 0;
        if numel(cor) >= threshold_part
            for j = 1:view_num
                if min(parts2d(j).centers(cor,:)) ~= 0
                    % compute bounding box overlap
                    bbox = compute_bbox_aspectlet(parts2d(j), cad.pnames, 1:num);
                    bbox_aspect = compute_bbox_aspectlet(parts2d(j), cad.pnames, cor);
                    o = box_overlap(bbox_aspect, bbox);
                    if o >= threshold_bbox
                        break;
                    end
                    % check bounded parts
                    flag_inview = 1;
                    for kk = 1:num
                        if parts2d(j).centers(kk,1) ~= 0
                            cx = parts2d(j).centers(kk,1);
                            cy = parts2d(j).centers(kk,2);
                            if cx >= bbox_aspect(1) && cx <= bbox_aspect(3) && cy >= bbox_aspect(2) && cy <= bbox_aspect(4)
                                if flag(kk) ~= 1
                                    flag_inview = 0;
                                    break;
                                end
                            end
                        end
                    end
                    if flag_inview == 1
                        flag_choose = 1;
                        break;
                    end
                end
            end
        end
        
        % decide whether to use the aspectlet or not
        if flag_choose == 1
            aspectlet(k,:) = flag;
            k = k + 1;
        end
    end
    
    % select aspectlet
    aspectlet = unique(aspectlet, 'rows');
    
    a = max(aspectlet, [], 2);
    aspectlet(a == 0,:) = [];
    
    n = size(aspectlet, 1);
    aspectlets(count:count+n-1,:) = aspectlet;
    count = count + n;
    
    fprintf('%d aspectlets found, %d unique\n', k, n);    
end

aspectlets = unique(aspectlets, 'rows');

% remove symmetric aspectlets
n = size(aspectlets, 1);
flag = zeros(n, 1);
flag(1) = 1;
for i = 2:n
    aspectlet = aspectlets(i,:);
    temp = zeros(1,num);
    ind = aspectlet == 1;
    ind = symmetric(ind);
    temp(ind) = 1;
    flag_choose = 1;
    for j = 1:i-1
        if flag(j) == 1 && isequal(aspectlets(j,:), temp) == 1
            flag_choose = 0;
            break;
        end
    end
    flag(i) = flag_choose;
end
aspectlets = aspectlets(flag == 1, :);            

% N = size(aspectlets, 1);
% flag = zeros(N,1);
% 
% % add aspectlets with Hamming distance larger than 1
% for i = 1:N
%     if flag(i) == 1
%         continue;
%     end
%     flag(i) = 1;
%     for j = 1:N
%         if i ~= j && flag(j) == 1
%             if sum(xor(aspectlets(i,:), aspectlets(j,:))) <= 1
%                 flag(i) = 0;
%                 break;
%             end
%         end
%     end
% end
% 
% aspectlets = aspectlets(flag == 1, :);

% rand an ellipsoid
function ellipsoid = rand_ellipsoid()

A = rand(3);
[V, D] = eig((A+A')/2);
a = 0.01;
b = 0.2;
D = a + (b-a).*rand(3,1);

ellipsoid.V = V;
ellipsoid.D = D;

% compute the bounding box of aspect parts
function bbox = compute_bbox_aspectlet(part2d, pnames, index)

part_label = part2d.centers(index, :);

x1 = inf;
x2 = -inf;
y1 = inf;
y2 = -inf;
for k = 1:size(part_label, 1)
    if part_label(k,1) ~= 0
        part = part2d.(pnames{index(k)}) + repmat(part_label(k,:), 5, 1);
        x1 = min(x1, min(part(:,1)));
        x2 = max(x2, max(part(:,1)));
        y1 = min(y1, min(part(:,2)));
        y2 = max(y2, max(part(:,2)));
    end
end

bbox = [x1 y1 x2 y2];