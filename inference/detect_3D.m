
function detection = detect_3D(points, model_3d, tol, max_em_iter)
  points = points';
  MD = zeros(size(points)./[2 1]);
  [point_3d, rotation, translation, basis_coefficient] = ...
                            em_sfm_known_shape(points, MD, model_3d, tol, max_em_iter);
  detection.point_3D = point_3d';
  detection.rotation = rotation{1};
  detection.translation = translation;
  detection.basis_coefficient = basis_coefficient;