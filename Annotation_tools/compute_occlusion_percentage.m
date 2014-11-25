function percentage = compute_occlusion_percentage(cls, issave)

switch cls
    case 'car'
        N = 200;
        par.padx = 120;
        par.pady = 66;
        cls_cad = {'car'};
    case 'room'
        N = 300;
        par.padx = 168;
        par.pady = 120;
        cls_cad = {'bed', 'chair', 'sofa', 'table'};
end
path_anno = sprintf('../Annotations/%s', cls);
path_image = sprintf('../Images/%s', cls);

% load cad model
cad_num = numel(cls_cad);
cads = cell(cad_num, 1);
for i = 1:cad_num
    object = load(sprintf('../CAD/%s_full.mat', cls_cad{i}));
    cads{i} = object.(cls_cad{i});
end

percentage = zeros(N,1);
for i = 1:N
    disp(i);

    file_ann = sprintf('%s/%04d.mat', path_anno, i);
    image = load(file_ann);
    object = image.object;
    view = object.view;
    num = size(object.bbox, 1);
    BW = cell(num, 1);
    distance = zeros(num, 1);    
    
    file_img = sprintf('%s/%04d.jpg', path_image, i);
    I = imread(file_img);
    par.width = size(I, 2);
    par.height = size(I, 1);
    mask = ones(par.height+2*par.pady, par.width+2*par.padx) * (num+1);
    mask(par.pady+1:par.height+par.pady, par.padx+1:par.width+par.padx) = 0;    
    
    % compute the convex hull for each label
    for j = 1:num
        cad_index = strcmp(object.class{j}, cls_cad) == 1;
        cad = cads{cad_index};
        a = cad.azimuth;
        e = cad.elevation;
        d = cad.distance;
        pnames = cad.pnames;
        part_num = numel(pnames);        
        
        distance(j) = view(j,3);
        if view(j,1) == 0 && view(j,2) == 0 && view(j,3) == 0
            BW{j} = [];
        else
            aind = find(a == view(j,1))-1;
            eind = find(e == view(j,2))-1;
            dind = find(d == view(j,3))-1;
            index = aind*numel(e)*numel(d) + eind*numel(d) + dind + 1;
            part2d = cad.parts2d(index);
            
            if strcmp(object.class{j}, 'car') == 1
                % change the mask
                parts = zeros(4*part_num, 2);
                for k = 1:part_num
                    % only for aspect part
                    if cad.roots(k) == 0 && isempty(part2d.(pnames{k})) == 0 && object.part{j}.(pnames{k})(1) ~= 0
                        % compute part center
                        c = object.part{j}.(pnames{k}) + [par.padx par.pady];
                        % part shape
                        part = part2d.(pnames{k}) + repmat(c, 5, 1);
                        parts(4*(k-1)+1:4*k,:) = part(1:4,:);
                    end
                end
                index_part = parts(:,1) ~= 0;
                parts = parts(index_part,:);
                hull = convhull(parts(:,1), parts(:,2));
                BW{j} = poly2mask(parts(hull,1)', parts(hull,2)', par.height+2*par.pady, par.width+2*par.padx);
            else
                BW{j} = zeros(par.height+2*par.pady, par.width+2*par.padx);
                for k = 1:part_num
                    % only for aspect part
                    if cad.roots(k) == 0 && isempty(part2d.(pnames{k})) == 0 && object.part{j}.(pnames{k})(1) ~= 0
                        % compute part center
                        c = object.part{j}.(pnames{k}) + [par.padx par.pady];
                        % part shape
                        part = part2d.(pnames{k}) + repmat(c, 5, 1);
                        part = part(1:4,:);
                        hull = convhull(part(:,1), part(:,2));
                        temp = poly2mask(part(hull,1)', part(hull,2)', par.height+2*par.pady, par.width+2*par.padx);
                        BW{j} = BW{j} | temp;
                    end
                end
            end
        end
    end
    
    % sort objects by distance and occlusion annotation
    if cad_num == 1
        [~, index] = sort(distance);
        dis = unique(distance);
        for j = 1:numel(dis)
            ind = find(distance(index) == dis(j));
            if numel(ind) ~= 1
                occlude = object.occlude(index(ind));
                [~, index_energy] = sort(occlude);
                temp = index(ind);
                index(ind) = temp(index_energy);
            end
        end
    else
        index = 1:num;
    end
    
    object.occld_per = zeros(num,1);
    for j = 1:num
        ind = index(j);
        if isempty(BW{ind}) == 1
            object.occld_per(ind) = 0.95;
        else
            area_total = sum(sum(BW{ind}));
            temp = (BW{ind} == 1) & (mask == 0);
            area_vis = sum(sum(temp));
            object.occld_per(ind) = 1 - area_vis / area_total;
            mask(temp) = ind;
        end
    end
    percentage(i) = min(max(object.occld_per), 0.95);
    
%     occld_per = zeros(num, num+1);
%     object.occld_per = zeros(num,1);
%     for j = 1:num
%         if isempty(BW{j}) == 1
%             object.occld_per(j) = 0.95;
%             continue;
%         end        
%         if object.occlude(j) == 1
%             dj = view(j,3);
%             area = sum(sum(BW{j}));
%             for k = 1:j-1
%                 if view(k,1) == 0 && view(k,2) == 0 && view(k,3) == 0
%                     continue;
%                 end                  
%                 dk = view(k,3);
%                 if dk <= dj
%                     inter = BW{j} & BW{k};
%                     occld_per(j,k) = sum(sum(inter)) / area;
%                 end
%             end
%         end
%         if object.truncate(j) == 1
%             area = sum(sum(BW{j}));
%             inter = BW{j} & mask;
%             occld_per(j,num+1) = sum(sum(inter)) / area;
%         end
%         object.occld_per(j) = min(sum(occld_per(j,:)), 0.95);
%     end
%     percentage(i) = max(object.occld_per);
    
    if issave == 1
        save(file_ann, 'object');
    end
end