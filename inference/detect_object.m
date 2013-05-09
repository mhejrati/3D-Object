% Perform 2D and 3D detection on an image, the 2D and 3D models should be
% for the same object
function detections = detect_object(im, model_2d, model_3d, thresh_2d)
  max_em_iter = 50;
  tol = 1;
  part_names = model_3d.part_names;
  
  % run 2D detector
  detections = detect_fast(im, model_2d, thresh_2d);
  
  % compute 2D points and put them into an array ordered based on 3D
  % model part names
  detections = box_to_points(model_2d, detections, part_names);
  
  % run 3D detector for each 2D detection
  for i = 1:length(detections)
    tmp_3d_detections = detect_3D(detections(i).point, model_3d, tol, max_em_iter);
    detections(i).point_3D = tmp_3d_detections.point_3D;
    detections(i).rotation = tmp_3d_detections.rotation;
    detections(i).translation = tmp_3d_detections.translation;
    detections(i).basis_coefficients = tmp_3d_detections.basis_coefficient;
  end
  
  
% compute 2D points and put them into an array ordered based on 3D
% model part names  
function detections = box_to_points(model, detections, part_names)
  for i = 1:length(detections)
    detection = detections(i);
    tmp_points = zeros(size(detection.part_boxes,1),2);
    tmp_part_boxes = detection.part_boxes;
    tmp_filterid = detection.filterid;
    for j = 1:size(detection.part_boxes,1)
      tx = mean(detection.part_boxes(j,[1 3]));
      ty = mean(detection.part_boxes(j,[2 4]));
      tname = model.filters(detection.filterid(j)).name;
      tmp_id = find(strcmp(tname, part_names));
      tmp_points(tmp_id,:) = [tx ty];
      detections(i).point = tmp_points;
      detections(i).part_names = part_names;
      detections(i).part_boxes(tmp_id,:) = tmp_part_boxes(j,:);
      detections(i).filterid(tmp_id) = tmp_filterid(j);
    end
  end
