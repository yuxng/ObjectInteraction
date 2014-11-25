% render parts into an image
% d: viewpoint distance
% M: viewport size
function parts2d = generate_2d_parts(cls, chair, M, occ_per)

a = chair.azimuth;
e = chair.elevation;
d = chair.distance;
na = numel(a);
ne = numel(e);
nd = numel(d);
parts2d(na*ne*nd).azimuth = 345;
parts2d(na*ne*nd).elevation = 30;
parts2d(na*ne*nd).distance = 5;
pnames = chair.pnames;

% viewport size
R = M * [1 0 0.5; 0 -1 0.5; 0 0 1];
R(3,3) = 1;

count = 0;
for n = 1:na
    for m = 1:ne
        for o = 1:nd
            % initialize part
            count = count+1;
            %disp(count);
            parts2d(count).azimuth = a(n);
            parts2d(count).elevation = e(m);
            parts2d(count).distance = d(o);
            parts2d(count).viewport = M;
            parts2d(count).root = 0;
            parts2d(count).graph = zeros(numel(pnames));
            for i = 1:numel(pnames)
                parts2d(count).(pnames{i}) = [];
            end

            % render CAD model
            [parts, occluded, parts_unoccluded] = render(cls, chair, a(n), e(m), d(o));

            % part number
            N = numel(parts);
            parts2d(count).centers = zeros(N, 2);
            parts2d(count).homographies = cell(N, 1);
            
            root_num = 0;
            for i = 1:N
                if chair.roots(i) == 0
                    root_num = root_num + 1;
                    % occluded percentage
                    if occluded(i) > occ_per(root_num)
                        continue;
                    end                    
                else
                    root_name = pnames{chair.roots(i)};
                    if isempty(parts2d(count).(root_name)) == 1
                        continue;
                    end
                end

                % map to viewport
                p = R*[parts_unoccluded(i).x parts_unoccluded(i).y ones(numel(parts_unoccluded(i).x), 1)]';
                p = p(1:2,:)';
                c = R*[parts_unoccluded(i).center, 1]';
                c = c(1:2)';

                % translate the part center to the orignal
                parts2d(count).(pnames{i}) = p - repmat(c, size(p,1), 1);
                parts2d(count).centers(i,:) = c';

                % compute the homography for transfering current view of the part
                % to frontal view using four point correspondences
                % coefficient matrix
                A = zeros(8,9);
                % construct the coefficient matrix
                X = parts2d(count).(pnames{i});
                xprim = chair.parts2d_front(i).vertices;
                for j = 1:4
                    x = [X(j,:), 1];
                    A(2*j-1,:) = [zeros(1,3), -x, xprim(j,2)*x];
                    A(2*j, :) = [x, zeros(1,3), -xprim(j,1)*x];
                end
                [~, ~, V] = svd(A);
                % homography
                h = V(:,end);
                H = reshape(h, 3, 3)';
                % normalization
                H = H ./ H(3,3);      
                parts2d(count).homographies{i} = H;
            end
        end
    end
end