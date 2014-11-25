function test(cls, cads, labels, samples)

N = numel(samples);

for i = 1:N
    disp(i);
    sample = samples{i};
    filename = sprintf('../Images/%s/%04d.jpg', cls, i);
    I = imread(filename);
    % load detections
%     filename = sprintf('results/car_vote_%03d.mat', i);
%     object = load(filename, 'y');
%     y = object.y;    
    y = labels{i};
    draw3D(I, cads, sample.O, sample.C, sample.alpha, sample.center, sample.cad_label, sample.flag, y);
    pause;
end