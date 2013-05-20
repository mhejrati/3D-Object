% Perform 2D and 3D detection on an image, the 2D and 3D models should be
% for the same object
function detections = detect_object_given_bbox(im, model_2d, model_3d, annotation, overlap)
  max_em_iter = 50;
  tol = 1;
  part_names = model_3d.part_names;
  
  % run 2D detector
  detections = detect_max(im, model_2d, annotation, overlap, model_2d.thresh);
  
  % compute 2D points and put them into an array ordered based on 3D
  % model part names
  detections = box_to_points(model_2d, detections, part_names);
  
  % run 3D detector for each 2D detection
  detections = detect_3D(detections, model_3d, tol, max_em_iter);
%   for i = 1:length(detections)
%     tmp_3d_detections = detect_3D(detections(i).point, model_3d, tol, max_em_iter);
%     detections(i).point_3D = tmp_3d_detections.point_3D;
%     detections(i).rotation = tmp_3d_detections.rotation;
%     detections(i).translation = tmp_3d_detections.translation;
%     detections(i).basis_coefficients = tmp_3d_detections.basis_coefficient;
%   end