% eliminate part with large tilt
function cad_new = remove_large_tilt(cad, tilt_threshold)

cad_new = cad;

pnames = cad.pnames;
parts2d = cad.parts2d;
N = numel(cad.parts);
a = cad.azimuth;
e = cad.elevation;
d = cad.distance;
na = numel(a);
ne = numel(e);
nd = numel(d);

count = 0;
for n = 1:na
    for m = 1:ne
        for o = 1:nd
            count = count+1;
            for i = 1:N
                if cad.roots(i) == 0
                    H = parts2d(count).homographies{i};
                    if isempty(H)
                        continue;
                    end
                    A = H(1:2,1:2);
                    [~, S, V] = svd(A);
                    tilt = S(1,1)/S(2,2);
                    theta = acosd(1/tilt);
                    if o == 1
                        if theta > tilt_threshold
                            cad_new.parts2d(count).(pnames{i}) = [];
                            cad_new.parts2d(count).centers(i,:) = [0 0];
                            cad_new.parts2d(count).homographies{i} = [];
                        end
                    else
                        index = (n-1)*ne*nd + (m-1)*nd + 1;
                        if isempty(cad_new.parts2d(index).(pnames{i})) == 1
                            cad_new.parts2d(count).(pnames{i}) = [];
                            cad_new.parts2d(count).centers(i,:) = [0 0];
                            cad_new.parts2d(count).homographies{i} = [];                       
                        end
                    end
                elseif cad_new.roots(i) ~= -1
                    root_node = cad_new.roots(i);
                    if isempty(cad_new.parts2d(count).(pnames{root_node})) == 1
                        cad_new.parts2d(count).(pnames{i}) = [];
                        cad_new.parts2d(count).centers(i,:) = [0 0];
                        cad_new.parts2d(count).homographies{i} = [];                       
                    end                    
                end
            end
            % construct graph
            for i = numel(pnames):-1:1
                if isempty(cad_new.parts2d(count).(pnames{i})) == 0
                    root = i;
                    break;
                end
            end
            cad_new.parts2d(count).root = root;
            cad_new.parts2d(count).graph = zeros(numel(pnames));
            for i = 1:numel(pnames)
                if i ~= root && isempty(cad_new.parts2d(count).(pnames{i})) == 0
                    if cad_new.roots(i) == 0
                        cad_new.parts2d(count).graph(i,root) = 1;
                    elseif cad_new.roots(i) ~= -1
                        root_node = cad_new.roots(i);
                        cad_new.parts2d(count).graph(i,root_node) = 1;
                    end
                end
            end
        end
    end
end