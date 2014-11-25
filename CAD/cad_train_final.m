% obtain the final aspectlet model
function cad = cad_train_final(cls, iscopy)

switch cls
    case 'car'
        symmetric = [3 4 1 2 9 11 10 12 5 7 6 8 14 13 16 15 18 17 20 19 23 24 21 22];
    case 'bed'
        symmetric = [3 4 1 2 10 9 12 11 6 5 8 7 14 13 16 15 19 20 17 18];
    case 'chair'
        symmetric = [2 1 4 3 7 8 5 6 16 15 14 13 12 11 10 9];
    case 'sofa'
        symmetric = [3 4 1 2 7 8 5 6 11 12 9 10 19 20 17 18 15 16 13 14];
    case 'table'
        symmetric = [3 4 1 2 12 11 10 9 8 7 6 5];
end

% load cad model
object = load(sprintf('%s.mat', cls));
cads = object.(cls);
index = object.index;

% num = numel(index);
% cad(1) = cads(1);
% cad(2:num+1) = cads(index);
% 
% count = num+2;
% for i = 1:numel(index)
%     ind = index(i);
%     aspectlet = cads(ind);
%     
%     % find the part correspondences between aspectlet and cads(1)
%     n = numel(find(aspectlet.roots == 0));
%     cor = zeros(1, n);
%     for j = 1:n
%         tf = strcmp(aspectlet.pnames{j}, cads(1).pnames);
%         cor(j) = find(tf == 1);
%     end
%     cor = sort(cor);
%     
%     % find the symmetric aspectlet
%     cor_sym = symmetric(cor);
%     cor_sym = sort(cor_sym);
%     
%     if isequal(cor, cor_sym) == 0
%         cad(count) = extract_aspectlet(cads(1), cor_sym);
%         count = count + 1;
%     end
% end

if iscopy == 1
    path = '../svm_struct_cuda_mpi/data';
    for i = 1:numel(index)
        ind = index(i);
        src_name = sprintf('%s/%s_cad%03d.mod', path, cls, ind-1);
        dst_name = sprintf('%s/%s_final_cad%03d.mod', path, cls, i);
        if exist(dst_name) == 0
            copyfile(src_name, dst_name);
        end
    end
end

cad(1) = cads(1);
count = 2;
for i = 1:numel(index)
    ind = index(i);
    aspectlet = cads(ind);
    
    % find the part correspondences between aspectlet and cads(1)
    n = numel(find(aspectlet.roots == 0));
    cor = zeros(1, n);
    for j = 1:n
        tf = strcmp(aspectlet.pnames{j}, cads(1).pnames);
        cor(j) = find(tf == 1);
    end
    cor = sort(cor);
    
    % find the symmetric aspectlet
    cor_sym = symmetric(cor);
    cor_sym = sort(cor_sym);
    
    cad(count) = aspectlet;
    count = count + 1;    
    
    if isequal(cor, cor_sym) == 0
        cad(count) = extract_aspectlet(cads(1), cor_sym);
        count = count + 1;
    end
end