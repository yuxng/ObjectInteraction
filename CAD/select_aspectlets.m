% select the aspectlets with large discriminative powers and large coverage
function index = select_aspectlets(cls)

threshold = 3;

% load cad model
object = load(sprintf('../CAD/%s.mat', cls));
cads = object.(cls);
ap = object.ap;

% flag for viewpoint coverage
view_num = numel(cads(1).parts2d);
flag_view = zeros(view_num, 1);

% flag for part coverage
part_num = numel(find(cads(1).roots == 0));
flag_part = zeros(view_num, part_num);

% sort the detection AP
[~, index] = sort(ap, 'descend');

num = numel(ap);
flag = zeros(num, 1);

for i = 1:num-1
    ind = index(i);
    cad = cads(ind);

    % find the part correspondences between cad and cads(1)
    n = numel(find(cad.roots == 0));
    cor = zeros(n, 1);
    for j = 1:n
        tf = strcmp(cad.pnames{j}, cads(1).pnames);
        cor(j) = find(tf == 1);
    end
    
    % find the viewpoints cad covering
    vcor = zeros(view_num, 1);
    for j = 1:view_num
        if min(cads(1).parts2d(j).centers(cor,:)) ~= 0
            vcor(j) = 1;
            if min(flag_part(j, cor)) == 0 || flag_view(j) < threshold
                flag(ind) = 1;
            end
        end
    end
    
    % update the flags
    if flag(ind) == 1
        flag_part(vcor == 1, cor) = 1;
        flag_view(vcor == 1) = flag_view(vcor == 1) + 1;
    end
end

index = find(flag == 1);