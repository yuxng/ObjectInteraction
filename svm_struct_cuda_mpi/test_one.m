function test_one(cls, index, cads, labels, samples, index_object)

if nargin < 6
    index_object = [];
end

close all;
sample = samples{index};
filename = sprintf('../Images/%s/%04d.jpg', cls, index);
I = imread(filename);
% load detections
%     filename = sprintf('results/car_vote_%03d.mat', i);
%     object = load(filename, 'y');
%     y = object.y;    
y = labels{index};

if isempty(index_object) == 0
    draw3D(I, cads, sample.O, sample.C, sample.alpha, sample.center, sample.cad_label, sample.flag, y, index_object);
else
    draw3D(I, cads, sample.O, sample.C, sample.alpha, sample.center, sample.cad_label, sample.flag, y);
end