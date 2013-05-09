% Learn 3D shape model
% model_3d = train_3d_model(pos,experiment_name, experiment_name_suffix)

function [model_3d, pos, test] = train_3d_model(pos, test, n_basis, experiment_name, experiment_name_suffix)
  globals;
  n_pos = length(pos);
  use_lds = 0; % Don't use dynamics 
  max_em_iter = 200;
  tol = 1;

  cls = [experiment_name '_3DShape_' experiment_name_suffix];
  try
    load([cachedir cls],'model_3d');
  catch
    tmp_missing_data = cat(2,pos.visibility)';
    tmp_points = cat(3,pos.point);
    x = squeeze(tmp_points(:,1,:))';
    y = squeeze(tmp_points(:,2,:))';
    points_matrix = [x;y];

    % Missing data matrix, 3 options : 
    % 1- treat all parts as not missing
     missing_data = (tmp_missing_data > 2);
    % 2- treat any invisible (occluded + truncated) part as missing
    % missing_data = (tmp_missing_data >= 1);
    % 3- only treat truncated parts as missing
    % missing_data = (tmp_missing_data == 2);

    % Learning the shape basis from the training data, and estimate camera
    % rotation and basis shape coefficients for each training data
    [point_3d, mean_shape, deformation_shapes, rotations, translations, basis_coefficients, sigma_sq]...
      = em_sfm(points_matrix, missing_data, n_basis, use_lds, tol, max_em_iter);

    % Save 3D model
    model_3d.mean_shape = mean_shape;
    model_3d.deformation_shapes = deformation_shapes;
    model_3d.part_names = pos(1).part_names;
    model_3d.sigma_sq = sigma_sq;

    save([cachedir cls],'model_3d');
  end
  
%   for i = 1:n_pos
%     tmp_3d_point = point_3d([i i+n_pos i+n_pos*2],:);
%     pos(i).point_3D = tmp_3d_point';
%     pos(i).rotation = rotations{i};
%     pos(i).translation = translations(i,:);
%     pos(i).basis_coefficient = basis_coefficients(i,:);
%   end

  max_em_iter = 50;
  % Add 3D shape to positive images using ground truth landmark detections
  pos = reorder_points(pos, model_3d.part_names);
  for i = 1:length(pos)
    tmp_3d = detect_3D(pos(i).point, model_3d, tol, max_em_iter);
    pos(i).point_3D = tmp_3d.point_3D;
    pos(i).rotation = tmp_3d.rotation;
    pos(i).translation = tmp_3d.translation;
    pos(i).basis_coefficient = tmp_3d.basis_coefficient;
    fprintf('3D reconstruction: train image %d \n', i);
  end
  
  
  % Add 3D shape to test images using ground truth landmark detections
  test = reorder_points(test, model_3d.part_names);
  for i = 1:length(test)
    tmp_3d = detect_3D(test(i).point, model_3d, tol, max_em_iter);
    test(i).point_3D = tmp_3d.point_3D;
    test(i).rotation = tmp_3d.rotation;
    test(i).translation = tmp_3d.translation;
    test(i).basis_coefficient = tmp_3d.basis_coefficient;
    fprintf('3D reconstruction: test image %d \n', i);
  end
  
  
% compute 2D points and put them into an array ordered based on 3D
% model part names  
function test = reorder_points(test, part_names)
  for i = 1:length(test)
    tmp_test = test(i);
    tmp_ids = [];
    for j = 1:length(tmp_test.part_names)
      tname = tmp_test.part_names(j);
      tmp_ids(j) = find(strcmp(tname, part_names));
    end
    test(i).point = test(i).point(tmp_ids,:);
    test(i).visibility = test(i).visibility(tmp_ids);
    test(i).part_names = part_names;
    test(i).x1 = test(i).x1(tmp_ids);
    test(i).y1 = test(i).y1(tmp_ids);
    test(i).x2 = test(i).x2(tmp_ids);
    test(i).y2 = test(i).y2(tmp_ids);
  end
