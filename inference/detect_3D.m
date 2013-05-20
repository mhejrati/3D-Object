
function detection = detect_3D(points, model_3d, tol, max_em_iter)
  if isstruct(points)
    detection = points;
    [a,b] = size(detection(1).point');
    ndetections = length(detection);
    
    tmp_point = zeros(a*ndetections,b);
    for i = 1:ndetections
      tmp_point([i i+ndetections],:) = detection(i).point';
    end
    MD = zeros(size(tmp_point)./[2 1]);
    [point_3d, rotation, translation, basis_coefficient] = ...
                                em_sfm_known_shape(tmp_point, MD, model_3d, tol, max_em_iter);
    for i = 1:ndetections
      detection(i).point_3D = point_3d([i i+ndetections i+2*ndetections],:)';
      detection(i).rotation = rotation{i};
      detection(i).translation = translation(i,:);
      detection(i).basis_coefficient = basis_coefficient(i,:);
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