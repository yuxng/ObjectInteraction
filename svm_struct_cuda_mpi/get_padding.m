function [padx, pady] = get_padding(cads)

padx = 0;
pady = 0;
for i = 1:numel(cads)
    cad = cads{i};
    for j = 1:numel(cad)
        for k = 1:numel(cad(j).parts2d_front)
            width = cad(j).parts2d_front(k).width;
            if padx < width
                padx = width;
            end
            height = cad(j).parts2d_front(k).height;
            if pady < height
                pady = height;
            end
        end
    end
end