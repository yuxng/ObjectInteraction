% compute the weights for aspectlets
function weights = get_weights(cads)

cad_num = numel(cads);
weights = cell(cad_num, 1);

for i = 1:cad_num
    num = numel(cads{i});
    w = zeros(num, 1);
    for j = 1:num
        w(j) = numel(find(cads{i}(j).roots == 0)) / numel(find(cads{i}(1).roots == 0));
    end
    w = w ./ (sum(w)-1);
    w(1) = 1;
    weights{i} = w;
end