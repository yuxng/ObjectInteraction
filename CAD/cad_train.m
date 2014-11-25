% train a mean CAD model from a set of CAD models
function cad = cad_train(cls, isaspectlet)

switch cls
    case 'car'
        pnames = {'head', 'left', 'right', 'front', 'back', 'tail'};
        azimuth = 0:15:345;
        elevation = 0:15:15;
        distance = [3 4 5 7 9 11 15 19 23];
        d = 19;
        shinkage_width = [0.8 0.8 0.8 0.8 0.8 0.8];
        shinkage_height = [0.8 0.8 0.8 0.8 0.8 0.8];
        occ_per = [0.2 0.3 0.3 0.8 0.8 0.2];
        part_direction = [0 -1 0; -1 0 0; 1 0 0; 0 0 1; 0 0 1; 0 1 0];
        M = 5;
        viewport_size = 3000;
        tilt_threshold = 80;
        rescale = 1;
        partition = [2 2; 3 2; 3 2; 2 2; 2 2; 2 2];
        subpart_indicator = {[1 1 1 1], [1 0 1 1 1 0], [0 1 1 1 0 1], [1 1 1 1], [1 1 1 1], [1 1 1 1]};
        symmetric = [3 4 1 2 9 11 10 12 5 7 6 8 14 13 16 15 18 17 20 19 23 24 21 22];
    case 'bed'
        pnames = {'front', 'left', 'right', 'up', 'back'};
        part_direction = [0 -1 0; -1 0 0; 1 0 0; 0 0 1; 0 -1 0];
        azimuth = [0:15:90 270:15:345];
        elevation = 0:15:30;
        distance = [1.5 2 2.5 3 3.5 5];
        shinkage_width = [0.8 0.8 0.8 0.8 0.8];
        shinkage_height = [0.8 0.8 0.8 0.8 0.8];
        occ_per = [0.6 0.6 0.6 0.6 0.6];
        M = 5;
        d = 5;
        viewport_size = 1000;
        tilt_threshold = 75;
        rescale = 1;
        partition = [2 2; 2 2; 2 2; 2 2; 2 2];
        subpart_indicator = {[1 1 1 1], [1 1 1 1], [1 1 1 1], [1 1 1 1], [1 1 1 1]};
        symmetric = [3 4 1 2 10 9 12 11 6 5 8 7 14 13 16 15 19 20 17 18];
    case 'chair'
        pnames = {'back', 'seat', 'leg1', 'leg2', 'leg3', 'leg4'};
        azimuth = 0:15:345;
        elevation = 0:15:30;
        distance = [0.7 1 1.5 2 2.5 3];
        shinkage_width = [0.8 0.8 0.8 0.8 0.8 0.8];
        shinkage_height = [0.8 0.8 0.6 0.8 0.8 0.6];
        occ_per = [0.6 0.6 0.5 0.4 0.4 0.5];
        part_direction = [0 -1 0; 0 0 1; 0 -1 0; 0 -1 0; 0 -1 0; 0 -1 0];
        M = 15;
        d = 2.5;
        viewport_size = 1000;
        tilt_threshold = 80;
        rescale = 0.4;
        partition = [2 2; 2 2; 2 1; 2 1; 2 1; 2 1];
        subpart_indicator = {[1 1 1 1], [1 1 1 1], [1 1], [1 1], [1 1], [1 1]};
        symmetric = [2 1 4 3 7 8 5 6 16 15 14 13 12 11 10 9];
    case 'sofa'
        pnames = {'front', 'seat', 'back', 'left', 'right'};
        part_direction = [0 -1 0; 0 0 1; 0 -1 0; -1 0 0; 1 0 0];
        azimuth = [0:15:90 270:15:345];
        elevation = 0:15:30;
        distance = [0.9 1.2 1.5 2 2.5 3];
        shinkage_width = [0.9 1 0.8 0.8 0.8];
        shinkage_height = [0.8 0.8 0.8 0.8 0.8];
        occ_per = [0.6 0.6 0.6 0.05 0.05];
        M = 5;
        d = 3;
        viewport_size = 1000;
        tilt_threshold = 85;
        rescale = 0.6;
        partition = [2 2; 2 2; 2 2; 2 2; 2 2];
        subpart_indicator = {[1 1 1 1], [1 1 1 1], [1 1 1 1], [1 1 1 1], [1 1 1 1]};
        symmetric = [3 4 1 2 7 8 5 6 11 12 9 10 19 20 17 18 15 16 13 14];
    case 'table'
        pnames = {'top', 'leg1', 'leg2', 'leg3', 'leg4'};
        part_direction = [0 0 1; 0 -1 0; 0 -1 0; 0 -1 0; 0 -1 0];
        azimuth = [0:15:75 270:15:345];
        elevation = 0:15:30;
        distance = [0.9 1.2 1.5 2 2.5 3];        
        shinkage_width = [0.9 0.8 0.8 0.8 0.8];
        shinkage_height = [0.8 0.6 0.6 0.6 0.6];
        occ_per = [0.6 0.5 0.5 0.5 0.5];
        M = 5;
        d = 3;
        viewport_size = 1000;
        tilt_threshold = 82;
        rescale = 0.6;
        partition = [2 2; 2 1; 2 1; 2 1; 2 1];
        subpart_indicator = {[1 1 1 1], [1 1], [1 1], [1 1], [1 1]};
        symmetric = [3 4 1 2 12 11 10 9 8 7 6 5];
    otherwise
        return;
end
cad.azimuth = azimuth;
cad.elevation = elevation;
cad.distance = distance;
N = numel(pnames);

% figure;
% hold on;
% axis equal;
% colors = {'y', 'm', 'c', 'r', 'g', 'b'};
count = 0;
for i = 1:N
    part_vertices = [];
    for j = 1:M
        filename = sprintf('%s/%02d_%s.off', cls, j, pnames{i});
        vertices = load_off_file(filename);
        % rescale cad model
        vertices = vertices*rescale;
        part_vertices = [part_vertices; vertices];
    end

%   plot3(part_vertices(:,1), part_vertices(:,2), part_vertices(:,3), [colors{i} 'o']);
    [F, P, center, xaxis, yaxis] = fit_plane(part_vertices, shinkage_width(i), shinkage_height(i), ...
        part_direction(i,:), partition(i,:), subpart_indicator{i});
    
    for k = 1:numel(F)
        count = count + 1;
        
        % keep track of the root for each subparts
        if k == 1
            root = count;
            cad.roots(count) = 0;
            cad.pnames{count} = pnames{i};
        else
            cad.roots(count) = root;
            cad.pnames{count} = sprintf('%s%d', pnames{i}, k-1);
        end
        
        cad.parts(count).vertices = F{k};
        cad.parts(count).plane = P;
        cad.parts(count).center = center{k};
        cad.parts(count).xaxis = xaxis;
        cad.parts(count).yaxis = yaxis;
    end
end

% render part from its frontal view
parts2d_front = render_part_front(cad, d, viewport_size);
cad.parts2d_front = parts2d_front;

% render parts into an image
parts2d = generate_2d_parts(cls, cad, viewport_size, occ_per);
cad.parts2d = parts2d;

% add root parts
vnum = 8;
cad = add_root_parts(cad, d, vnum);

% eliminate part with large tilt
cad = remove_large_tilt(cad, tilt_threshold);

% change cad.roots
index1 = cad.roots == 0;
index2 = cad.roots > 0;
cad.roots(index1) = 1;
cad.roots(index2) = 0;

cad.viewport = viewport_size;
cad.tilt_threshold = tilt_threshold;
cad.occ_per = occ_per;

if isaspectlet == 1
    % only select subparts
    cad = extract_subparts(cad);

    % generate aspectlets
    aspectlets = aspectlet_train(cad, symmetric);

    % build the cad model with all the parts
    cad.roots = zeros(numel(cad.pnames),1);
    cad = add_root_parts(cad, d, vnum);

    num = numel(aspectlets);
    cad(2:num+1) = aspectlets;
end

% xlabel('x');
% ylabel('y');
% zlabel('z');
% axis equal;