
function detection = detect_3D(points, model_3d, tol, max_em_iter)
  if isempty(points)
    detection = [];
    return;
  end
  
  if isstruct(points)
    detection = points;
    [a,b] = size(detection(1).point');
    
    start_ids = 1:1000:length(detection);
    if length(detection)>start_ids(end)-1
      start_ids(end+1) = length(detection);
    end
    for j = 1:length(start_ids)-1
      tmp_ids = start_ids(j):start_ids(j+1)-1;
      tdetection = detection(tmp_ids);
      ndetections = length(tdetection);
      tmp_point = zeros(a*ndetections,b);
      for i = 1:ndetections
        tmp_point([i i+ndetections],:) = tdetection(i).point';
      end
      MD = zeros(size(tmp_point)./[2 1]);
      [point_3d, rotation, translation, basis_coefficient] = ...
                                  em_sfm_known_shape(tmp_point, MD, model_3d, tol, max_em_iter);
      for i = 1:ndetections
        detection(tmp_ids(i)).point_3D = point_3d([i i+ndetections i+2*ndetections],:)';
        detection(tmp_ids(i)).rotation = rotation{i};
        detection(tmp_ids(i)).translation = translation(i,:);
        detection(tmp_ids(i)).basis_coefficient = basis_coefficient(i,:);
      end
      
    end
  else
    points = points';
    MD = zeros(size(points)./[2 1]);
    [point_3d, rotation, translation, basis_coefficient] = ...
                              em_sfm_known_shape(points, MD, model_3d, tol, max_em_iter);
    detection.point_3D = point_3d';
    detection.rotation = rotation{1};
    detection.translation = translation;
    detection.basis_coefficient = basis_coefficient;
  end