function bbox_new = rescale_bbox(bbox, factor)

bbox_new = bbox;
w = bbox(3) - bbox(1);
h = bbox(4) - bbox(2);
bbox_new(3) = bbox(1) + factor*w;
bbox_new(4) = bbox(2) + factor*h;