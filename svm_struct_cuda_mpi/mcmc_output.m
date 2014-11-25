% construct output from the MAP sample
% find the 2D detection scores by marginalization
function [sample, example] = mcmc_output(sample, par, y, occld_per, cads)

% y = refine_bbox(sample, par, y, cads);

% construct output
O = sample.O;
C = sample.C;
cad_label = sample.cad_label;
alpha = sample.alpha;
center = sample.center;
flag = sample.flag;
anchor = sample.anchor;
p = sample.p;

num = numel(y);
example = y;
for i = 1:num
    % object inside the MAP
    if flag(i) > 0
        ind = flag(i);
        mask = zeros(size(O,2),1);
        mask(ind) = 1;
        p_new = mcmc_joint(O, C, alpha, center, cad_label, flag, anchor, par, cads, y, occld_per, mask);
        example(i).energy = log(p / p_new);
        if p_new == 0
            fprintf('error\n');
        end
    else
        % add the object into MAP
        [O_new, C_new, alpha_new, center_new, cad_label_new, flag_new, anchor_new] = ...
            mcmc_add(O, C, alpha, center, cad_label, par, cads, y, flag, anchor, i);
        p_new = mcmc_joint(O_new, C_new, alpha_new, center_new, cad_label_new, flag_new, anchor_new, par, cads, y, occld_per, zeros(size(O_new,2),1));
        example(i).energy = log(p_new / p);
    end
end

% sort example
num = numel(example);
p = zeros(num, 1);
for i = 1:num
    p(i) = example(i).energy;
end
[pnew, index] = sort(p, 'descend');
example = example(index);
example(pnew == -inf) = [];
index(pnew == -inf) = [];

% nms
% num = numel(example);
% flag = zeros(num, 1);
% for i = 1:num
%     flag(i) = 1;
%     for j = 1:i-1
%         o = box_overlap(example(i).bbox, example(j).bbox);
%         if flag(j) > 0 && o >= 0.5
%             flag(i) = 0;
%         end
%     end
% end
% example = example(flag > 0);
% index = index(flag > 0);
sample.index = index;