% build CAD model of aspectlets
function models = aspectlet_train(cad, symmetric)

% generate aspectlets
aspectlets = generate_aspectlets(cad, symmetric);
N = size(aspectlets, 1);

for i = 1:N
    pindex = find(aspectlets(i,:) == 1);
    models(i) = extract_aspectlet(cad, pindex);
end

view_num = get_view_num(models);
view_num = view_num / numel(cad.distance);
threshold = 5;
models = models(view_num > threshold);

fprintf('%d aspectlets are generated\n', numel(models));