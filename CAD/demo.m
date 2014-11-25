function demo(cad)

% % part num
% num = numel(cad.parts);
% % sample num
% N = 5;
% for i = 1:num
%     c = cad.parts(i).center;
% 
%     % rand aspectlet
%     for k = 1:N
%         E = rand_ellipsoid();
% 
%         % check which parts are inside the ellipsoid
%         flag = zeros(num, 1);
%         for j = 1:num
%             center = cad.parts(j).center;
%             if (center-c)*E.V*diag(1./E.D)*E.V'*(center-c)' <= 1
%                 flag(j) = 1;
%             end
%         end
%         figure(1);
%         hold on;
%         draw_model(cad, flag);
%         draw_ellipsoid(E, c);
%         pause;
%         figure(1)
%         hold off;
%         cla;
%     end
% end

% part num
num = numel(cad.parts);

figure(1);
hold on;
draw_model(cad, zeros(num,1));

% sample num
N = 1;

% rand aspectlet
for k = 1:N
    E = rand_ellipsoid();
    ind = randsample(num, 1);
    c = cad.parts(ind).center;
    draw_ellipsoid(E, c);
end

hold off;


% rand an ellipsoid
function ellipsoid = rand_ellipsoid()

A = rand(3);
[V, D] = eig((A+A')/2);
a = 0.01;
%b = 0.2;
b = 0.1;
D = a + (b-a).*rand(3,1);

ellipsoid.V = V;
ellipsoid.D = D;

function draw_model(model, flag)

parts = model.parts;
for i = 1:numel(parts)
    F = parts(i).vertices;
    if flag(i) == 1
        patch(F(:,1), F(:,2), F(:,3), 'b', 'FaceAlpha', 0.3);
    else
        patch(F(:,1), F(:,2), F(:,3), 'r', 'FaceAlpha', 0.5);
    end
end
axis equal;
axis tight;
% axis off;
view(330, 30);

function draw_model_only(model, flag)

parts = model.parts;
for i = 1:numel(parts)
    F = parts(i).vertices;
    if flag(i) == 1
        patch(F(:,1), F(:,2), F(:,3), 'r', 'FaceAlpha', 0.3);
    end
end
axis equal;
axis tight;
axis off;
view(330, 30);

function draw_ellipsoid(E, c)

[x, y, z] = ellipsoid(0, 0, 0, E.D(1)^0.5, E.D(2)^0.5, E.D(3)^0.5);

% rotate data with orientation matrix V and center c
V = E.V;
x = kron(V(:,1), x);
y = kron(V(:,2), y);
z = kron(V(:,3), z);
data = x + y + z;
n = size(data, 2);
x = data(1:n,:) + c(1);
y = data(n+1:2*n,:) + c(2);
z = data(2*n+1:end,:) + c(3);        

mesh(x, y, z, 'FaceAlpha', 0);
axis equal;