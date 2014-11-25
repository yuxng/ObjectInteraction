% render part from its frontal view
% d: viewpoint distance
% M: viewport size
function parts2d_front = render_part_front(chair, d, M)

parts = chair.parts;
N = numel(parts);
parts2d_front(N).width = 0;
parts2d_front(N).height = 0;
parts2d_front(N).distance = 0;

% viewport size M
R = M * [1 0 0.5; 0 -1 0.5; 0 0 1];
R(3,3) = 1;

for i = 1:N
    plane = parts(i).plane;
    e = asind(plane(3)/norm(plane(1:3)));
    if e > 87
        a = 0;
    else
        a = atan2(plane(1), -plane(2));
        a = a*180/pi;
    end
    % fprintf('%s: a = %.2f, e = %.2f\n', chair.pnames{i}, a, e);
    P = projection(a, e, d);
    P1 = R*P([1 2 4], :);
    F = parts(i).vertices;
    part = P1*[F ones(size(F,1), 1)]';
    part(1,:) = part(1,:) ./ part(3,:);
    part(2,:) = part(2,:) ./ part(3,:);
    part = part(1:2,:)';
    
    center = parts(i).center;
    c = P1*[center, 1]';
    c = c ./ c(3);
    c = c(1:2)';  
    
    % assign the front part
    parts2d_front(i).vertices = part - repmat(c, size(part,1), 1);
    parts2d_front(i).center = c;
    width = round(max(part(:,1))-min(part(:,1)));
    if mod(width, 6) >= 3
        width = width + 6 - mod(width, 6);
    else
        width = width - mod(width, 6);
    end
    parts2d_front(i).width = width;
    height = round(max(part(:,2))-min(part(:,2)));
    if mod(height, 6) >= 3
        height = height + 6 - mod(height, 6);
    else
        height = height - mod(height, 6);
    end
    parts2d_front(i).height = height;
    parts2d_front(i).distance = d;
    parts2d_front(i).viewport = M;
    parts2d_front(i).pname = chair.pnames{i};
     
%     figure(1);
%     hold on;
%     set(gca,'YDir','reverse');
%     axis equal;
%     patch(part(:,1), part(:,2), 'r');
%     plot(c(1), c(2), 'o');
%     pause;
%     clf;
end  