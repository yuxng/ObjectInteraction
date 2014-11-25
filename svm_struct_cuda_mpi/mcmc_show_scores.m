function mcmc_show_scores(I, scores, isview)

num = numel(scores);

if isview == 1
    view_num = 8;
    figure;
    count = 1;
    for i = 1:num
        subplot(2*num, 5, count);
        imshow(I);
        count = count + 1;
        score = linear_mapping(scores{i});
        for j = 1:view_num
            subplot(2*num, 5, count);
            image(score(:,:,j), 'CDataMapping', 'direct');
            tit = sprintf('max %f', max(max(scores{i}(:,:,j))));
            title(tit);
            axis equal;
            count = count + 1;
        end
    end
else
    figure;
    count = 1;
    for i = 1:num
        subplot(num, 2, count);
        imshow(I);
        count = count + 1;

        subplot(num, 2, count);
        imagesc(scores{i});
        tit = sprintf('max %f', max(max(scores{i})));
        title(tit);
        axis equal;
        count = count + 1;
    end
end

function scores_new = linear_mapping(scores)

x1 = min(min(min(scores)));
x2 = max(max(max(scores)));
y1 = 1;
y2 = length(get(gcf,'Colormap'));

a = (y2-y1) / (x2-x1);
b = y1 - a*x1;

scores_new = floor(a*scores + b);
index = scores_new < 1;
scores_new(index) = 1;
index = scores_new > y2;
scores_new(index) = y2;