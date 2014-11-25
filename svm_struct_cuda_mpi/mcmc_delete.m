% MCMC delete
function [O_new, C_new, alpha_new, center_new, cad_label_new, flag_new, anchor_new] = ...
    mcmc_delete(O, C, alpha, center, cad_label, par, flag, anchor, index)

% delete one object
num = size(O, 2);
if num ~= 1
    if index ~= anchor
        O_new = O;
        O_new(:,index) = [];
        C_new = C;
        alpha_new = alpha;
        alpha_new(index) = [];
        center_new = center;
        if index < anchor
            anchor_new = anchor - 1;
        else
            anchor_new = anchor;
        end
    else
        % randomly select a new anchor object
        while 1
            ind = randsample(num, 1);
            if ind ~= anchor
                break;
            end
        end

        origin = O(:,ind);                
        % rotation around z-axis by a
        a = alpha(ind);
        R = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];
        C_new = R*(C - origin);

        a = atan2(C_new(1), -C_new(2));
        if a < 0
            a = a + 2*pi;
        end
        d = norm(C_new);
        e = asin(C_new(3) / d);
        P_new = projection(a*180/pi, e*180/pi, d);

        % project O(:,ind) onto the image, compute the new center
        a = atan2(C(1), -C(2));
        if a < 0
            a = a + 2*pi;
        end
        d = norm(C);
        e = asin(C(3) / d);
        P = projection(a*180/pi, e*180/pi, d);
        x = P([1 2 4], :) * [O(:,ind); 1];
        x = x ./ x(3);
        x = x(1:2);
        x = x * par.viewport;
        x(2) = -1 * x(2);
        center_new = x' + center;

        % change coordinate system
        O_new = zeros(3, size(O,2));
        alpha_new = zeros(size(O,2),1);
        for i = 1:size(O_new,2)
            if i == ind
                continue;
            end
            x = P([1 2 4], :) * [O(:,i); 1];
            x = x ./ x(3);
            x = x(1:2);
            x = x * par.viewport;
            x(2) = -1 * x(2);
            x = x' + center;

            % compute object center in anchor object's coordinate system
            x = x - center_new;
            x(2) = -1 * x(2);
            x = x ./ par.viewport;
            % backprojection
            X = pinv(P_new([1 2 4], :)) * [x(1); x(2); 1];
            X = X ./ X(4);
            X = X(1:3);
            % compute the ray
            X = X - C_new;
            % normalization
            X = X ./ norm(X);
            % 3D location
            d = norm(C - O(:,i));
            O_new(:,i) = C_new + d .* X;

            % relative azimuth
            Ci = C_new - O_new(:,i);
            ai = atan2(Ci(1), -Ci(2));
            Ci = C - O(:,i);
            a = atan2(Ci(1), -Ci(2)) + alpha(i);            
            alpha_new(i) = a - ai;
        end
        O_new(:,anchor) = [];
        alpha_new(anchor) = [];

        if anchor < ind
            anchor_new = ind - 1;
        else
            anchor_new = ind;
        end
    end
    cad_label_new = cad_label;
    cad_label_new(index) = [];
    flag_new = flag;
    flag_new(flag == index) = 0;
    flag_new(flag > index) = flag_new(flag > index) - 1;
else
    O_new = O;
    C_new = C;
    alpha_new = alpha;
    center_new = center;
    cad_label_new = cad_label;
    flag_new = flag;
    anchor_new = anchor;
end