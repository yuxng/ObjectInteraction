% MCMC inference, find the MAP sample
function [sample, example] = mcmc(I, y, cads, isfigure)

RandStream.setGlobalStream(RandStream('mt19937ar', 'seed', 3));

close all;
% N = 3000;
N = 100;

% intialization
[O, C, alpha, center, cad_label, flag, anchor, par, y, occld_per] = mcmc_initial(I, y, cads);
p = mcmc_joint(O, C, alpha, center, cad_label, flag, anchor, par, cads, y, occld_per, zeros(size(O,2),1));

count = 0;
sample = [];
for i = 1:N
    if isfigure == 1
        disp(i);
    end
    % draw sample
    [O_new, C_new, alpha_new, center_new, cad_label_new, flag_new, anchor_new, proposal_ratio] = ...
        mcmc_sampling(O, C, alpha, center, cad_label, par, cads, y, flag, anchor);
    
    % compute joint probability
    p_new = mcmc_joint(O_new, C_new, alpha_new, center_new, cad_label_new, flag_new, anchor_new, par, cads, y, occld_per, zeros(size(O_new,2),1));
    
    if size(O_new,2) == size(O,2) + 1
        posterior_ratio = p_new / (p * par.bg_pro);
    elseif size(O_new,2) == size(O,2) - 1
        posterior_ratio = (p_new * par.bg_pro) / p;
    else
        posterior_ratio = p_new / p;
    end
    
    if isnan(posterior_ratio) == 1 || isnan(proposal_ratio) == 1
        accept_ratio = 1;
    else
        accept_ratio = min(1, posterior_ratio * proposal_ratio);
    end
    
%             draw3D(I, cads, O, C, alpha, center, cad_label, flag, y);
%             pause;     
%     
%             draw3D(I, cads, O_new, C_new, alpha_new, center_new, cad_label_new, flag_new, y);
%             fprintf('p_new = %e, p = %e, ar = %f\n', p_new, p, accept_ratio);
%             pause;     
    
    if rand(1) < accept_ratio
%         fprintf('accept\n');
        O = O_new;
        C = C_new;
        alpha = alpha_new;
        center = center_new;
        cad_label = cad_label_new;
        flag = flag_new;
        anchor = anchor_new;
        p = p_new;
        
        % store the sample
%         if i > 1000
            count = count + 1;
            sample(count).O = O;
            sample(count).C = C;
            sample(count).alpha = alpha;
            sample(count).center = center;
            sample(count).cad_label = cad_label;
            sample(count).flag = flag;
            sample(count).anchor = anchor;
            sample(count).p = p_new;
%         end
    end
end
% fprintf('accept rate = %f\n', count / (N-1000));
fprintf('accept rate = %f\n', count / N);

% find the MAP
num = numel(sample);
if num == 0
    count = count + 1;
    sample(count).O = O;
    sample(count).C = C;
    sample(count).alpha = alpha;
    sample(count).center = center;
    sample(count).cad_label = cad_label;
    sample(count).flag = flag;
    sample(count).anchor = anchor;
    sample(count).p = p;
end

index = 1;
maxp = sample(1).p;
maxn = size(sample(1).O, 2);
for i = 2:num
    n = size(sample(i).O, 2);
    p = sample(i).p;
    temp = maxp;
    if maxn > n
        p = p * par.bg_pro^abs(maxn - n);
    elseif maxn < n
        temp = temp * par.bg_pro^abs(maxn - n);
    end
    if p > temp
        index = i;
        maxp = sample(i).p;
        maxn = n;
    end
end

% construct output
sample = sample(index);
[sample, example] = mcmc_output(sample, par, y, occld_per, cads);