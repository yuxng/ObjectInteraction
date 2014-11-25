% MCMC sampling
% proposal moves
% 1. change object's position in 3D
% 2. rotate object in the x-y plane
% 3. change camera position in 3D
% 4. add one object
% 5. delete one object
% 6. switch anchor object
% 7. switch the cad label
function [O_new, C_new, alpha_new, center_new, cad_label_new, flag_new, anchor_new, proposal_ratio] = ...
    mcmc_sampling(O, C, alpha, center, cad_label, par, cads, y, flag, anchor)

% sample move type
type = randsample(numel(par.move), 1, true, par.move);
% fprintf('move type %d\n', type);

switch type
    case 1
        % change object's location in 3D
        % select the object to be moved
        num = size(O, 2);
        index = randsample(num, 1);
        % sample new 3D position for the object
        R = chol(par.Sigma);
        X = O(:,index) + (randn(1,3)*R)';
        if index ~= anchor
            center_new = center;
            O_new = O;
            O_new(:,index) = X;
            C_new = C;
        else
            % project X onto the image, compute the new center
            a = atan2(C(1), -C(2));
            if a < 0
                a = a + 2*pi;
            end
            d = norm(C);
            e = asin(C(3) / d);
            P = projection(a*180/pi, e*180/pi, d);
            x = P([1 2 4], :) * [X; 1];
            x = x ./ x(3);
            x = x(1:2);
            x = x * par.viewport;
            x(2) = -1 * x(2);
            center_new = x' + center;
            
            % shift the coordinate system
            O_new = O;
            for i = 1:num
                if i ~= anchor
                    O_new(:,i) = O_new(:,i) - X;
                end
            end
            C_new = C - X;
        end
        alpha_new = alpha;
        cad_label_new = cad_label;
        flag_new = flag;
        anchor_new = anchor;
        proposal_ratio = 1;
    case 2
        % change object's x-y plane angle in 3D
        % select the object to be rotated
        num = size(O, 2);
        index = randsample(num, 1);
        % sample new anlge for the object
        a = alpha(index) + par.sigma_angle * randn(1);
        if index ~= anchor
            C_new = C;
            O_new = O;
            alpha_new = alpha;
            alpha_new(index) = a;
        else
            % rotation around z-axis by -a
            R = [cos(-a) -sin(-a) 0; sin(-a) cos(-a) 0; 0 0 1];
            C_new = R*C;
            O_new = O;
            for i = 1:num
                if i ~= anchor
                    O_new(:,i) = R*O_new(:,i);
                end
            end
            
            alpha_new = alpha;
            for i = 1:num
                if i ~= anchor
                    alpha_new(i) = alpha_new(i) + a;
                end
            end
        end
        center_new = center;
        cad_label_new = cad_label;
        flag_new = flag;
        anchor_new = anchor;
        proposal_ratio = 1;
    case 3
        % sample new 3D position for the camera
        R = chol(par.Sigma_camera);
        C_new = C + (randn(1,3)*R)';
        
        O_new = O;
        alpha_new = alpha;
        center_new = center;
        cad_label_new = cad_label;
        flag_new = flag;
        anchor_new = anchor;
        proposal_ratio = 1;
    case 4
        % add one object into the scene
        index = find(flag == 0);
        num = numel(index);
        if num ~= 0
            % proposal distribution for add move
            energy = zeros(num, 1);
            for i = 1:num
                energy(i) = y(index(i)).energy;
            end
            energy = energy ./ sum(energy);

            % sample new object to be added
            ind = randsample(num, 1, true, energy);
            qadd = energy(ind);
            
%             % proposal distribution for delete move
%             n = size(O,2);
%             energy = zeros(n+1, 1);
%             for i = 1:n
%                 a = flag == i;
%                 energy(i) = y(a).energy;
%             end
%             energy(n+1) = y(index(ind)).energy;
%             energy = energy ./ sum(energy);
%             qdelete = energy(n+1);            
            
            % proposal distribution for delete move
            qdelete = 1/(size(O,2)+1);
            
            proposal_ratio = qdelete / qadd;
            
            ind = index(ind);
            % set the flag
            flag_new = flag;
            flag_new(ind) = size(O,2) + 1;

            % compute object center in the anchor object's coordinate system            
            root_index = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).root;
            x = y(ind).part_label(root_index,:);            
            x = x - center;
            x(2) = -1 * x(2);
            x = x ./ par.viewport;
            
            % backprojection
            a = atan2(C(1), -C(2));
            if a < 0
                a = a + 2*pi;
            end
            d = norm(C);
            e = asin(C(3) / d);
            P = projection(a*180/pi, e*180/pi, d);
            X = pinv(P([1 2 4], :)) * [x(1); x(2); 1];
            X = X ./ X(4);
            X = X(1:3);
            % compute the ray
            X = X - C;
            % normalization
            X = X ./ norm(X);
            
            % get azimuth and distance
            a = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).azimuth;
            d = cads{y(ind).cad_label}(1).parts2d(y(ind).view_label).distance;
            if strcmp(y(ind).class, 'table') == 1
                dind = find(cads{y(ind).cad_label}(1).distance == d);
                if dind ~= 1
                    d = cads{y(ind).cad_label}(1).distance(dind-1);
                end
            end            
            
            % 3D location
            O_new = O;
            O_new(:,end+1) = C + d .* X;

            % relative azimuth
            alpha_new = alpha;
            Ci = C - O_new(:,end);
            ai = atan2(Ci(1), -Ci(2));
            alpha_new(end+1) = a*pi/180 - ai;
            cad_label_new = cad_label;
            cad_label_new(end+1) = y(ind).cad_label;
        else
            O_new = O;
            alpha_new = alpha;
            cad_label_new = cad_label;
            flag_new = flag;
            proposal_ratio = 1;
        end
        C_new = C;
        center_new = center;
        anchor_new = anchor;
    case 5
        % delete one object
        num = size(O, 2);
        if num ~= 1
%             % proposal distribution for delete move
%             energy = zeros(num, 1);
%             for i = 1:num
%                 ind = flag == i;
%                 energy(i) = y(ind).energy;
%             end
%             energy = energy ./ sum(energy);
% 
%             % sample object to be deleted
%             index = randsample(num, 1, true, energy);
%             qdelete = energy(index);            
            
            % proposal distribution for delete move
            index = randsample(num, 1);
            qdelete = 1/num;
            
            % compute proposal ratio
            temp = flag;
            a = find(flag == index);
            temp(a) = 0;
            ind = find(temp == 0);
            n = numel(ind);
            energy = zeros(n, 1);
            for i = 1:n
                energy(i) = y(ind(i)).energy;
            end
            energy = energy ./ sum(energy);
            b = ind == a;
            proposal_ratio = energy(b) / qdelete;
            
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
            proposal_ratio = 1;
        end
    case 6
        % switch anchor object
        num = size(O, 2);
        if num ~= 1
            while 1
                index = randsample(num, 1);
                if index ~= anchor
                    break;
                end
            end
            anchor_new = index;

            origin = O(:,index);                
            % rotation around z-axis by a
            a = alpha(index);
            R = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];
            C_new = R*(C - origin);

            a = atan2(C_new(1), -C_new(2));
            if a < 0
                a = a + 2*pi;
            end
            d = norm(C_new);
            e = asin(C_new(3) / d);
            P_new = projection(a*180/pi, e*180/pi, d);

            % project O(:,index) onto the image, compute the new center
            a = atan2(C(1), -C(2));
            if a < 0
                a = a + 2*pi;
            end
            d = norm(C);
            e = asin(C(3) / d);
            P = projection(a*180/pi, e*180/pi, d);
            x = P([1 2 4], :) * [O(:,index); 1];
            x = x ./ x(3);
            x = x(1:2);
            x = x * par.viewport;
            x(2) = -1 * x(2);
            center_new = x' + center;

            % change coordinate system
            O_new = zeros(3, size(O,2));
            alpha_new = zeros(size(O,2),1);
            for i = 1:size(O_new,2)
                if i == index
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
        else
            O_new = O;
            C_new = C;
            alpha_new = alpha;
            center_new = center;
            anchor_new = anchor;
        end            
        
        cad_label_new = cad_label;
        flag_new = flag;
        proposal_ratio = 1;
    case 7
        % switch cad label
        cad_num = numel(cads);
        if cad_num ~= 1
            % sample one object to change
            num = size(O, 2);
            index = randsample(num, 1);
            % sample the target cad label
            l = randsample(cad_num-1, 1);
            temp = 1:cad_num;
            temp(cad_label(index)) = [];

            cad_label_new = cad_label;
            cad_label_new(index) = temp(l);
        else
            cad_label_new = cad_label;
        end
        
        O_new = O;
        C_new = C;
        alpha_new = alpha;
        center_new = center;
        flag_new = flag;
        anchor_new = anchor;
        proposal_ratio = 1;
end