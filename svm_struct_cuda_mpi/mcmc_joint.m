% compute the joint probability
% O: 3D objects
% C: camera location in 3D
% alpha: relative azimuth with respect to the first object
function p = mcmc_joint(O, C, alpha, center, cad_label, flag, anchor, par, cads, y, occld_per, mask_object)

p = 1;

% camera prior
% % uniform distribution
% if a >= par.amin && a <= par.amax && e >= par.emin && e <= par.emax && d >= par.dmin && d <= par.dmax
%     p = (1/(par.amax-par.amin)) * (1/(par.emax-par.emin)) * (1/(par.dmax-par.dmin));
% else
%     p = 0;
%     return;
% end
 
% 3D object prior
u = 0;
num = size(O, 2);
% % unary potential: normal distribution
for i = 1:num
    if mask_object(i) == 1
        continue;
    end
    if O(3,i) > 0 && (y(flag==i).cad_label == 2 || y(flag==i).cad_label == 4)
        u = u + O(3,i)^2/(2*par.sigma_ct^2);
    else
        u = u + O(3,i)^2/(2*par.sigma^2);
    end
end
% pairwise potential: penalize overlap in 3D
for i = 1:num
    if mask_object(i) == 1
        continue;
    end    
    for j = i+1:num
        if mask_object(j) == 1
            continue;
        end        
        % compute overlapping volumn
        r = 0.5;
        o = sphere_overlap(O(:,i), O(:,j), r);
        % energy
%         u = u + par.rho * o / ((8/3)*pi*r^3 - o);
        if o > 0
            overlap1 = voxel_overlap(O(:,i), O(:,j), alpha(i), alpha(j), ...
                cads{cad_label(i)}(1), cads{cad_label(j)}(1), y(flag==i).class, y(flag==j).class);
            overlap2 = voxel_overlap(O(:,j), O(:,i), alpha(j), alpha(i), ...
                cads{cad_label(j)}(1), cads{cad_label(i)}(1), y(flag==j).class, y(flag==i).class); 
            if y(flag==i).cad_label == 2 || y(flag==i).cad_label == 4 || ...
                    y(flag==j).cad_label == 2 || y(flag==j).cad_label == 4
                u = u + par.rho_ct*max(overlap1, overlap2);
            else
                u = u + par.rho*max(overlap1, overlap2);
            end
        end
    end
end
p = p * exp(-u);

% find object 2D distances
view_label = zeros(num, 1);
distance = zeros(num, 1);
energy = zeros(num, 1);
for i = 1:num
    index = flag == i;
    view_label(i) = y(index).view_label;
    distance(i) = cads{cad_label(i)}(1).parts2d(view_label(i)).distance;
    if strcmp(y(index).class, 'table') == 1
        dind = find(cads{cad_label(i)}(1).distance == distance(i));
        if dind ~= 1
            distance(i) = cads{y(i).cad_label}(1).distance(dind-1);
        end
    end    
    energy(i) = y(index).energy;
end

% sort objects by distance and energy
[~, index] = sort(distance);
d = unique(distance);
for i = 1:numel(d)
    ind = find(distance(index) == d(i));
    if numel(ind) ~= 1
        e = energy(index(ind));
        [~, index_energy] = sort(e, 'descend');
        temp = index(ind);
        index(ind) = temp(index_energy);
    end
end     

% reason occlusion by projecting 3D objects to 2D
occlusion = cell(num, 1);
mask = ones(par.height+2*par.pady, par.width+2*par.padx);
mask(par.pady+1:par.height+par.pady, par.padx+1:par.width+par.padx) = 0;

for i = 1:num   
    ind = index(i);
    if mask_object(ind) == 1
        continue;
    end    
    index_label = flag == ind;
    view = view_label(ind);
    cad = cads{cad_label(ind)}(1);
    pnames = cad.pnames;
    part_num = numel(pnames);
    occlusion{ind} = zeros(part_num, num+1);
    % test for occlusion
    for j = 1:part_num
        % only test for visible subparts
        if cad.roots(j) == 0 && isempty(cad.parts2d(view).(pnames{j})) == 0
            % compute part center
            c = y(index_label).part_label(j,:) + [par.padx par.pady];
            pc = round(c);
            if pc(2) < 1 || pc(2) > size(mask,1) || pc(1) < 1 || pc(1) > size(mask,2)
                occlusion{ind}(j,num+1) = 1;
            else
                for k = 1:i-1
                    if mask_object(index(k)) == 1
                        continue;
                    end
                    if y(flag == index(k)).BW(pc(2), pc(1)) == 1
                        occlusion{ind}(j,index(k)) = 1;
                    end
                end
                if  mask(pc(2), pc(1)) == 1
                    occlusion{ind}(j,num+1) = 1;
                end
            end
        end
    end
end

% compute the 2D object likelihood, consider occlusion
for i = 1:num
    if mask_object(i) == 1
        continue;
    end
    index = flag == i;
    
%     s = y(index).energy;
    
    % reweighting for occlusion
    cad = cads{cad_label(i)};
    cad_num = numel(cad);
    w = zeros(cad_num, 1);
    for j = 1:cad_num
        [max_num, object_index] = max(sum(occlusion{i}(cad(j).cor,:)));
        if max_num ~= 0 && object_index <= num && y(flag == object_index).energy > par.occluder_energy
            w(j) = numel(find(sum(occlusion{i}(cad(j).cor,:),2) == 0)) / numel(find(cad(1).roots == 0));
        else
            w(j) = numel(find(cad(j).roots == 0)) / numel(find(cad(1).roots == 0));
        end
    end
    w(1) = 1;
    if sum(w) ~= 1
        w = w ./ (sum(w)-1);
    end
    w(1) = 1;
    s = w'*y(index).scores;
    
    % penalize large occlusion
    object_index = find(occld_per(index,:) >= par.occld);
%     d_occluded = find(cads{cad_label(i)}(1).distance == distance(i));
    for j = 1:numel(object_index)
        if object_index(j) == numel(y)+1
            s = par.background;
            break;
        elseif flag(object_index(j)) > 0
            ind = flag(object_index(j));
%             d_occluder = find(cads{cad_label(ind)}(1).distance == distance(ind));
%             if abs(d_occluded - d_occluder) >= 2 
            if abs(distance(i) - distance(ind)) >= 1 
                s = par.background;
                break;
            end
        end
    end

%     object_index = find(occld_per(index,:) >= par.occld);
%     for j = 1:numel(object_index)
%         if object_index(j) == numel(y)+1
%             s = par.background;
%             break;
%         elseif flag(object_index(j)) > 0
%             s = par.background;
%             break;
%         end
%     end

    
    p = p * s;
end

% check occlusion consistency of 2D detection scores
u = 0;
for i = 1:num
    if mask_object(i) == 1
        continue;
    end    
    score_occluded = y(flag == i).energy;
    % find occluded subparts
    temp = sum(occlusion{i},2);
    index = find(temp > 0);
    % occlusion
    for j = 1:numel(index)
        object_index = occlusion{i}(index(j),:);
        for k = 1:num
            if object_index(k) == 1
                score_occluder = y(flag == k).energy;
                if occld_per(flag == i, flag == k) > par.min_occld && ...
                        score_occluder < score_occluded && strcmp(y(flag==i).class, y(flag==k).class) == 1
                    u = u + par.rho1 * score_occluded / score_occluder;
                end
            end
        end
    end
end
p = p * exp(-u);

% always keep the first object
% if flag(par.ind) == 0
%     p = p * par.background;
% end

% disp(p);