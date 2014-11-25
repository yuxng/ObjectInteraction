function show_result_mcmc(I, example)

N = numel(example);

figure;
imshow(I);
hold on;
for i = 1:N
    fprintf('object %d, energy = %.2f\n', i, example(i).energy);
    bbox_pr = example(i).bbox;
    bbox_pr(1) = max(bbox_pr(1), 1);
    bbox_pr(2) = max(bbox_pr(2), 1);
    bbox_pr(3) = min(bbox_pr(3), size(I, 2));
    bbox_pr(4) = min(bbox_pr(4), size(I, 1));
    
    % draw bounding box
    bbox_draw = [bbox_pr(1), bbox_pr(2), bbox_pr(3)-bbox_pr(1), bbox_pr(4)-bbox_pr(2)];
    rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth',2);
    text(bbox_pr(1), bbox_pr(2), num2str(i), 'BackgroundColor', 'r');
end

hold off;