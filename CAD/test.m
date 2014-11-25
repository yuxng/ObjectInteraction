function test(cls, cad)

N = numel(cad);

for i = 1:N
    disp(i);
    if i == 1
        draw(cad(1));
    else
        draw(cad(1), cad(i));
    end
    hf = figure(1);
    saveas(hf, sprintf('eps/%s_aspeclet%02d.eps', cls, i), 'psc2');    
end