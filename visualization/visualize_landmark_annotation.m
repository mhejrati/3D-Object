% Visualize 2D landmark annotation for an object
% visualize_landmark_annotation(object)

function visualize_landmark_annotation(object)
  im = imread(object.im);
  show_2D_point_cloud(im, object.point, hsv(size(object.point,1)), ...
                      object.part_names, object.visibility==1)
