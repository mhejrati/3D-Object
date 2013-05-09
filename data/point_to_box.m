% Compute bounding boxes for every part
function object = point_to_box(object)

for n = 1:length(object)
    box_size = floor(object(n).part_size/2);
    points = object(n).point;
    for p = 1:size(points,1)
      object(n).x1(p) = points(p,1) - box_size/2;
      object(n).y1(p) = points(p,2) - box_size/2;
      object(n).x2(p) = points(p,1) + box_size/2;
      object(n).y2(p) = points(p,2) + box_size/2;
    end
end