test3 = test;
for i = 1:length(test)
  tmp_3d = detect_3D(test(i).point, model_3d, tol, max_em_iter);
  test3(i).point = tmp_3d.point_3D;
  test3(i).rotation = tmp_3d.rotation;
  test3(i).translation = tmp_3d.translation;
  test3(i).basis_coefficient = tmp_3d.basis_coefficient;
end

test2= test;
[a,b] = size(test2(1).point');
tmp_point = zeros(a*length(test2),b);
for i = 1:length(test2)
  tmp_point([i i+length(test2)],:) = test2(i).point';
end
points = tmp_point;
MD = zeros(size(points)./[2 1]);
[point_3d, rotation, translation, basis_coefficient] = ...
                            em_sfm_known_shape(points, MD, model_3d, tol, max_em_iter);
for i = 1:length(test2)  
  test2(i).rotation = rotation{i};
  assert(isequal(test2(i).rotation,test3(i).rotation))
  
  test2(i).translation = translation(i,:);
  assert(isequal(test2(i).translation,test3(i).translation))
  
  test2(i).basis_coefficient = basis_coefficient(i,:);
  assert(isequal(test2(i).basis_coefficient,test3(i).basis_coefficient))
  
  test2(i).point = point_3d([i i+length(test2) i+2*length(test2)],:)';
  assert(isequal(test2(i).point,test3(i).point))
end

