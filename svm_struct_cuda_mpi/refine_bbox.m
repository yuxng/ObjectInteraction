function y = refine_bbox(sample, par, y, cads)

O = sample.O;
flag = sample.flag;
cad_label = sample.cad_label;

num = size(O,2);

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
    
mask = ones(par.height+2*par.pady, par.width+2*par.padx) * (num+1);
mask(par.pady+1:par.height+par.pady, par.padx+1:par.width+par.padx) = 0;
bbox = zeros(1,4);
for i = 1:num  
    ind = index(i);
    BW = y(flag == ind).BW;
    temp = (BW == 1) & (mask == 0);
    if sum(sum(BW)) ~= sum(sum(temp))
        xextent = find(sum(temp) > 0);
        yextent = find(sum(temp,2) > 0);
        if isempty(xextent) == 0 && isempty(yextent) == 0
            bbox(1) = min(xextent) - par.padx;
            bbox(3) = max(xextent) - par.padx;
            bbox(2) = min(yextent) - par.pady;
            bbox(4) = max(yextent) - par.pady;
            y(flag == ind).bbox = bbox;
        end
    end
    if y(flag == ind).energy > par.occluder_energy
        mask(temp) = ind;
    end
end