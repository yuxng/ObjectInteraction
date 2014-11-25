function show_samples(I, cads, sample, par)

N = numel(sample);

for i = 1:N
    draw3D(I, cads, sample(i).O, sample(i).C, sample(i).alpha, sample(i).center, sample(i).cad_label, par);
    pause;
end