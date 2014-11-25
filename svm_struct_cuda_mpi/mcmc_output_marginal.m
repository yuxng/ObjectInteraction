% construct output from the 3D to 2D marginalization
function example = mcmc_output_marginal(sample, par, trees, cads)

% initialization
cad_num = numel(cads);
scores = cell(cad_num, 1);
for i = 1:cad_num
    view_num = numel(cads{i}(1).parts2d);
    scores{i} = cell(1,1);
    scores{i}{1} = zeros([size(trees{i}{1}(1).root_score) view_num]);
end

N = numel(sample);
sbin = 6;
count = 0;
for k = 1:N
    % construct output
    O = sample(k).O;
    C = sample(k).C;
    cad_label = sample(k).cad_label;
    alpha = sample(k).alpha;
    center = sample(k).center;

    % projection matrix
    a = atan2(C(1), -C(2));
    if a < 0
        a = a + 2*pi;
    end
    d = norm(C);
    e = asin(C(3) / d);
    P = projection(a*180/pi, e*180/pi, d);

    % 2D object likelihood from MAP
    num = size(O, 2);
    o = zeros(2, num);
    view_label = zeros(num, 1);
    distance = zeros(num, 1);
    for i = 1:num
        % get the azimuth, elevation and distance
        Ci = C - O(:,i);
        % alpha(i) is the relative azimuth with respect to the first object
        a = atan2(Ci(1), -Ci(2)) + alpha(i);
        while a < 0
            a = a + 2*pi;
        end
        while a > 2*pi
            a = a - 2*pi;
        end
        d = norm(Ci);
        e = asin(Ci(3) / d);

        % find the nearest discrete viewpoint
        cad = cads{cad_label(i)}(1);
        azimuth = [cad.azimuth 360];
        [~, aind] = min(abs(azimuth - a*180/pi));
        if aind == numel(azimuth)
            aind = 1;
        end
        aind = aind - 1;
        [~, eind] = min(abs(cad.elevation - e*180/pi));
        eind = eind - 1;
        [~, dind] = min(abs(cad.distance - d));
        distance(i) = cad.distance(dind);
        dind = dind - 1;
        view_label(i) = aind*numel(cad.elevation)*numel(cad.distance) + ...
            eind*numel(cad.distance) + dind + 1;

        % find the image 2D location
        viewport = cads{cad_label(i)}(1).parts2d(view_label(i)).viewport;
        x = P([1 2 4], :) * [O(:,i); 1];
        x = x ./ x(3);
        x = x(1:2);
        x = x * viewport;
        x(2) = -1 * x(2);
        o(:,i) = x + center';
        o(:,i) = o(:,i) + [par.padx; par.pady];
        
        % voting
        px = floor(o(1,i)/sbin)+1;
        py = floor(o(2,i)/sbin)+1;
        if px >= 1 && px <= size(scores{cad_label(i)}{1}, 2) && py >= 1 && py <= size(scores{cad_label(i)}{1}, 1)
            scores{cad_label(i)}{1}(py,px,view_label(i)) = scores{cad_label(i)}{1}(py,px,view_label(i)) + 1;
            count = count + 1;
        end
    end
end

% normalization
for i = 1:cad_num
    scores{i}{1} = scores{i}{1} / count;
end

example = mcmc_candidate(scores, trees, cads);