function draw_aspectlets(cad, index, ap)

if nargin >= 2
    num = numel(index);
else
    num = numel(cad);
    index = 1:num;
end

if nargin < 3
    ap = [];
end

for i = 2:num
%     if i ~= 1 && mod(i-1, 16) == 0
%         pause;
%     end
%     ind = mod(i-1,16)+1;    
%     
%     subplot(4, 4, ind);
    subplot(9, 6, i-1);
    cla;
    hold on;
%     figure(1);
%     cla;
%     hold on;
    % draw_model(cad(index(i)));
    draw(cad(1), cad(index(i)));
    if isempty(ap) ==0
        til = sprintf('aspectlet %d, ap = %.2f', i-1, ap(index(i)));
    else
        til = sprintf('3D aspectlet %d', i-1);
    end
    title(til);    
    hold off;
%     hf = figure(1);
%     saveas(hf, sprintf('../%02d.png', i));     
end

function draw_model(model)

parts = model.parts;

for i = 1:numel(parts)
    F = parts(i).vertices;
    patch(F(:,1), F(:,2), F(:,3), 'r', 'FaceAlpha', 0.5);
end
axis equal;
axis tight;
view(330, 30);
axis off;