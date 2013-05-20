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
