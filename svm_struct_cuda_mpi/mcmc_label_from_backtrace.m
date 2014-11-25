% back trace to find part labels
function part_label = mcmc_label_from_backtrace(index, px, py, view, part_label, sbin, padx, pady)

if index == double(view.root_index)
    xmax = px;
    ymax = py;
else
    xmax = double(view.parts(index).location(py, px, 1));
    ymax = double(view.parts(index).location(py, px, 2));
end
part_label(index, 1) = sbin*xmax + sbin/2 - padx;
part_label(index, 2) = sbin*ymax + sbin/2 - pady;

for i = 1:numel(view.parts(index).children)
    child = double(view.parts(index).children(i));
    part_label = mcmc_label_from_backtrace(child, xmax+1, ymax+1, view, part_label, sbin, padx, pady);
end