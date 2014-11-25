function compare_cad_models(cad,cad1)

azimuth = 45;
elevation = 15;
distance = 3;

aind = find(cad.azimuth == azimuth)-1;
eind = find(cad.elevation == elevation)-1;
dind = find(cad.distance == distance)-1;
view_label = aind*numel(cad.elevation)*numel(cad.distance) + eind*numel(cad.distance) + dind + 1;

figure;
hold on;
axis equal;
% draw cad 
for i = numel(cad.parts):-1:1
    parts2d = cad.parts2d(view_label);
    part = parts2d.(cad.pnames{i});
    center = parts2d.centers(i,:);
    if isempty(part) == 0
        part = part + repmat(center, size(part,1), 1);
        set(gca,'YDir','reverse');
        patch(part(:,1), part(:,2), 'r');
    end
end

aind = find(cad1.azimuth == azimuth)-1;
eind = find(cad1.elevation == elevation)-1;
dind = find(cad1.distance == distance)-1;
view_label = aind*numel(cad1.elevation)*numel(cad1.distance) + eind*numel(cad1.distance) + dind + 1;

for i = numel(cad1.parts):-1:1
    parts2d = cad1.parts2d(view_label);
    part = parts2d.(cad1.pnames{i});
    center = parts2d.centers(i,:);
    if isempty(part) == 0
        part = part + repmat(center, size(part,1), 1);
        set(gca,'YDir','reverse');
        patch(part(:,1), part(:,2), 'y');
    end
end